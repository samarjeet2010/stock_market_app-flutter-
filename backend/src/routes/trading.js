const express = require('express');
const { v4: uuidv4 } = require('uuid');
const { db, runInTransaction, userRowToJson, positionRowToJson } = require('../db');
const { requireAuth } = require('../middleware/auth');

const router = express.Router();
router.use(requireAuth);

router.post('/buy', (req, res) => {
  try {
    const { symbol, quantity } = req.body || {};
    const qty = Number(quantity);
    if (!symbol || !Number.isInteger(qty) || qty <= 0) {
      return res.status(400).json({ success: false, message: 'symbol and a positive integer quantity are required' });
    }

    const user = db.prepare('SELECT * FROM users WHERE id = ?').get(req.userId);
    const stock = db.prepare('SELECT * FROM stocks WHERE symbol = ?').get(symbol.toUpperCase());
    if (!stock) return res.status(404).json({ success: false, message: 'Stock not found' });

    const totalCost = stock.current_price * qty;
    if (user.virtual_balance < totalCost) {
      return res.status(400).json({ success: false, message: 'Insufficient balance' });
    }

    const now = new Date().toISOString();

    runInTransaction(() => {
      db.prepare(`
        INSERT INTO transactions (id, user_id, symbol, stock_name, type, quantity, price, total_amount, timestamp)
        VALUES (?, ?, ?, ?, 'buy', ?, ?, ?, ?)
      `).run(uuidv4(), req.userId, stock.symbol, stock.name, qty, stock.current_price, totalCost, now);

      const existing = db.prepare('SELECT * FROM positions WHERE user_id = ? AND symbol = ?').get(req.userId, stock.symbol);
      if (existing) {
        const newQuantity = existing.quantity + qty;
        const newAvgPrice = (existing.avg_buy_price * existing.quantity + totalCost) / newQuantity;
        db.prepare(`
          UPDATE positions SET quantity = ?, avg_buy_price = ?, current_price = ?, updated_at = ?
          WHERE user_id = ? AND symbol = ?
        `).run(newQuantity, newAvgPrice, stock.current_price, now, req.userId, stock.symbol);
      } else {
        db.prepare(`
          INSERT INTO positions (user_id, symbol, stock_name, quantity, avg_buy_price, current_price, created_at, updated_at)
          VALUES (?, ?, ?, ?, ?, ?, ?, ?)
        `).run(req.userId, stock.symbol, stock.name, qty, stock.current_price, stock.current_price, now, now);
      }

      db.prepare('UPDATE users SET virtual_balance = ?, updated_at = ? WHERE id = ?').run(
        user.virtual_balance - totalCost, now, req.userId
      );
    });

    const updatedUser = db.prepare('SELECT * FROM users WHERE id = ?').get(req.userId);
    const position = db.prepare('SELECT * FROM positions WHERE user_id = ? AND symbol = ?').get(req.userId, stock.symbol);

    res.json({
      success: true,
      message: `Successfully bought ${qty} shares of ${stock.symbol}`,
      user: userRowToJson(updatedUser),
      position: positionRowToJson(position),
    });
  } catch (err) {
    console.error('Buy error:', err);
    res.status(500).json({ success: false, message: 'Transaction failed' });
  }
});

router.post('/sell', (req, res) => {
  try {
    const { symbol, quantity } = req.body || {};
    const qty = Number(quantity);
    if (!symbol || !Number.isInteger(qty) || qty <= 0) {
      return res.status(400).json({ success: false, message: 'symbol and a positive integer quantity are required' });
    }

    const user = db.prepare('SELECT * FROM users WHERE id = ?').get(req.userId);
    const stock = db.prepare('SELECT * FROM stocks WHERE symbol = ?').get(symbol.toUpperCase());
    if (!stock) return res.status(404).json({ success: false, message: 'Stock not found' });

    const position = db.prepare('SELECT * FROM positions WHERE user_id = ? AND symbol = ?').get(req.userId, stock.symbol);
    if (!position) return res.status(400).json({ success: false, message: 'You do not own this stock' });
    if (position.quantity < qty) {
      return res.status(400).json({ success: false, message: 'Insufficient shares to sell' });
    }

    const totalValue = stock.current_price * qty;
    const now = new Date().toISOString();

    runInTransaction(() => {
      db.prepare(`
        INSERT INTO transactions (id, user_id, symbol, stock_name, type, quantity, price, total_amount, timestamp)
        VALUES (?, ?, ?, ?, 'sell', ?, ?, ?, ?)
      `).run(uuidv4(), req.userId, stock.symbol, stock.name, qty, stock.current_price, totalValue, now);

      if (position.quantity === qty) {
        db.prepare('DELETE FROM positions WHERE user_id = ? AND symbol = ?').run(req.userId, stock.symbol);
      } else {
        db.prepare(`
          UPDATE positions SET quantity = ?, current_price = ?, updated_at = ?
          WHERE user_id = ? AND symbol = ?
        `).run(position.quantity - qty, stock.current_price, now, req.userId, stock.symbol);
      }

      db.prepare('UPDATE users SET virtual_balance = ?, updated_at = ? WHERE id = ?').run(
        user.virtual_balance + totalValue, now, req.userId
      );
    });

    const updatedUser = db.prepare('SELECT * FROM users WHERE id = ?').get(req.userId);

    res.json({
      success: true,
      message: `Successfully sold ${qty} shares of ${stock.symbol}`,
      user: userRowToJson(updatedUser),
    });
  } catch (err) {
    console.error('Sell error:', err);
    res.status(500).json({ success: false, message: 'Transaction failed' });
  }
});

module.exports = router;
