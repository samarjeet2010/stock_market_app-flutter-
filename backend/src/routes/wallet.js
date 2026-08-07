const express = require('express');
const crypto = require('crypto');
const { v4: uuidv4 } = require('uuid');
const Razorpay = require('razorpay');
const { db, runInTransaction, userRowToJson, walletOrderRowToJson } = require('../db');
const { requireAuth } = require('../middleware/auth');

const router = express.Router();
router.use(requireAuth);

function getRazorpay() {
  const keyId = process.env.RAZORPAY_KEY_ID;
  const keySecret = process.env.RAZORPAY_KEY_SECRET;
  if (!keyId || !keySecret) return null;
  return new Razorpay({ key_id: keyId, key_secret: keySecret });
}

// Step 1: client asks the server to open a Razorpay order for `amount`
// rupees. If Razorpay isn't configured (no keys in .env), the server falls
// back to a "mock" order so Add Money still works end-to-end in local/dev
// testing without a real Razorpay account.
router.post('/create-order', async (req, res) => {
  try {
    const amount = Number((req.body || {}).amount);
    if (!Number.isFinite(amount) || amount < 1) {
      return res.status(400).json({ error: 'A valid amount (>= 1 INR) is required' });
    }
    if (amount > 500000) {
      return res.status(400).json({ error: 'Maximum add-money amount is ₹5,00,000 per transaction' });
    }

    const razorpay = getRazorpay();
    const now = new Date().toISOString();

    if (!razorpay) {
      // Mock mode: no real payment gateway is configured. Credits happen
      // immediately via /wallet/confirm-mock below.
      const id = uuidv4();
      const razorpayOrderId = `mock_order_${Date.now()}`;
      db.prepare(`
        INSERT INTO wallet_orders (id, user_id, amount, razorpay_order_id, razorpay_payment_id, status, mock, created_at, updated_at)
        VALUES (?, ?, ?, ?, NULL, 'created', 1, ?, ?)
      `).run(id, req.userId, amount, razorpayOrderId, now, now);

      const order = db.prepare('SELECT * FROM wallet_orders WHERE id = ?').get(id);
      return res.json({
        mock: true,
        order: walletOrderRowToJson(order),
        message: 'Razorpay is not configured on the server (missing RAZORPAY_KEY_ID/SECRET) — running in mock payment mode.',
      });
    }

    const rpOrder = await razorpay.orders.create({
      amount: Math.round(amount * 100), // paise
      currency: 'INR',
      receipt: `wallet_${req.userId}_${Date.now()}`,
      notes: { userId: req.userId },
    });

    const id = uuidv4();
    db.prepare(`
      INSERT INTO wallet_orders (id, user_id, amount, razorpay_order_id, razorpay_payment_id, status, mock, created_at, updated_at)
      VALUES (?, ?, ?, ?, NULL, 'created', 0, ?, ?)
    `).run(id, req.userId, amount, rpOrder.id, now, now);

    const order = db.prepare('SELECT * FROM wallet_orders WHERE id = ?').get(id);

    res.json({
      mock: false,
      order: walletOrderRowToJson(order),
      razorpayKeyId: process.env.RAZORPAY_KEY_ID,
      razorpayOrder: rpOrder,
    });
  } catch (err) {
    console.error('Wallet create-order error:', err);
    res.status(500).json({ error: 'Failed to create payment order' });
  }
});

// Step 2 (real Razorpay): client completes checkout in the Razorpay SDK and
// posts back the payment/order/signature triple so the server can verify it
// was genuinely signed by Razorpay before crediting the wallet.
router.post('/verify-payment', async (req, res) => {
  try {
    const { razorpayOrderId, razorpayPaymentId, razorpaySignature } = req.body || {};
    if (!razorpayOrderId || !razorpayPaymentId || !razorpaySignature) {
      return res.status(400).json({ error: 'razorpayOrderId, razorpayPaymentId and razorpaySignature are required' });
    }

    const keySecret = process.env.RAZORPAY_KEY_SECRET;
    if (!keySecret) {
      return res.status(503).json({ error: 'Razorpay is not configured on the server' });
    }

    const order = db.prepare('SELECT * FROM wallet_orders WHERE razorpay_order_id = ? AND user_id = ?').get(razorpayOrderId, req.userId);
    if (!order) return res.status(404).json({ error: 'Order not found' });
    if (order.status === 'paid') {
      const user = db.prepare('SELECT * FROM users WHERE id = ?').get(req.userId);
      return res.json({ success: true, user: userRowToJson(user), order: walletOrderRowToJson(order) });
    }

    const expectedSignature = crypto
      .createHmac('sha256', keySecret)
      .update(`${razorpayOrderId}|${razorpayPaymentId}`)
      .digest('hex');

    const now = new Date().toISOString();

    if (expectedSignature !== razorpaySignature) {
      db.prepare('UPDATE wallet_orders SET status = ?, updated_at = ? WHERE id = ?').run('failed', now, order.id);
      return res.status(400).json({ success: false, error: 'Payment signature verification failed' });
    }

    runInTransaction(() => {
      db.prepare('UPDATE wallet_orders SET status = ?, razorpay_payment_id = ?, updated_at = ? WHERE id = ?').run(
        'paid', razorpayPaymentId, now, order.id
      );
      db.prepare('UPDATE users SET virtual_balance = virtual_balance + ?, updated_at = ? WHERE id = ?').run(
        order.amount, now, req.userId
      );
    });
    const updatedUser = db.prepare('SELECT * FROM users WHERE id = ?').get(req.userId);
    const updatedOrder = db.prepare('SELECT * FROM wallet_orders WHERE id = ?').get(order.id);

    res.json({ success: true, user: userRowToJson(updatedUser), order: walletOrderRowToJson(updatedOrder) });
  } catch (err) {
    console.error('Wallet verify-payment error:', err);
    res.status(500).json({ error: 'Payment verification failed' });
  }
});

// Mock-mode confirmation, used only when RAZORPAY_KEY_ID/SECRET are not set
// on the server, so "Add Money" is still fully testable without a real
// payment gateway account.
router.post('/confirm-mock', async (req, res) => {
  try {
    const { orderId } = req.body || {};
    const order = db.prepare('SELECT * FROM wallet_orders WHERE id = ? AND user_id = ? AND mock = 1').get(orderId, req.userId);
    if (!order) return res.status(404).json({ error: 'Mock order not found' });

    if (order.status === 'paid') {
      const user = db.prepare('SELECT * FROM users WHERE id = ?').get(req.userId);
      return res.json({ success: true, user: userRowToJson(user), order: walletOrderRowToJson(order) });
    }

    const now = new Date().toISOString();
    const mockPaymentId = `mock_pay_${Date.now()}`;

    runInTransaction(() => {
      db.prepare('UPDATE wallet_orders SET status = ?, razorpay_payment_id = ?, updated_at = ? WHERE id = ?').run(
        'paid', mockPaymentId, now, order.id
      );
      db.prepare('UPDATE users SET virtual_balance = virtual_balance + ?, updated_at = ? WHERE id = ?').run(
        order.amount, now, req.userId
      );
    });

    const updatedUser = db.prepare('SELECT * FROM users WHERE id = ?').get(req.userId);
    const updatedOrder = db.prepare('SELECT * FROM wallet_orders WHERE id = ?').get(order.id);

    res.json({ success: true, user: userRowToJson(updatedUser), order: walletOrderRowToJson(updatedOrder) });
  } catch (err) {
    console.error('Wallet confirm-mock error:', err);
    res.status(500).json({ error: 'Failed to confirm mock payment' });
  }
});

router.get('/orders', (req, res) => {
  const orders = db
    .prepare('SELECT * FROM wallet_orders WHERE user_id = ? ORDER BY created_at DESC LIMIT 50')
    .all(req.userId);
  res.json({ orders: orders.map(walletOrderRowToJson) });
});


module.exports = router;
