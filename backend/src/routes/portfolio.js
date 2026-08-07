const express = require('express');
const { db, positionRowToJson, transactionRowToJson } = require('../db');
const { requireAuth } = require('../middleware/auth');

const router = express.Router();
router.use(requireAuth);

router.get('/positions', (req, res) => {
  const rows = db.prepare('SELECT * FROM positions WHERE user_id = ?').all(req.userId);
  res.json({ positions: rows.map(positionRowToJson) });
});

router.get('/transactions', (req, res) => {
  const rows = db
    .prepare('SELECT * FROM transactions WHERE user_id = ? ORDER BY timestamp DESC')
    .all(req.userId);
  res.json({ transactions: rows.map(transactionRowToJson) });
});

router.get('/summary', (req, res) => {
  const rows = db.prepare('SELECT * FROM positions WHERE user_id = ?').all(req.userId);
  const totalInvested = rows.reduce((sum, p) => sum + p.quantity * p.avg_buy_price, 0);
  const currentValue = rows.reduce((sum, p) => sum + p.quantity * p.current_price, 0);
  const totalProfitLoss = currentValue - totalInvested;
  const totalProfitLossPercent = totalInvested > 0 ? (totalProfitLoss / totalInvested) * 100 : 0;
  res.json({ totalInvested, currentValue, totalProfitLoss, totalProfitLossPercent });
});

module.exports = router;
