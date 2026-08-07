const express = require('express');
const { db } = require('../db');
const { requireAuth } = require('../middleware/auth');

const router = express.Router();
router.use(requireAuth);

router.get('/', (req, res) => {
  const rows = db.prepare('SELECT symbol FROM watchlist WHERE user_id = ?').all(req.userId);
  res.json({ watchlist: rows.map((r) => r.symbol) });
});

router.post('/', (req, res) => {
  const { symbol } = req.body || {};
  if (!symbol) return res.status(400).json({ error: 'symbol is required' });
  db.prepare('INSERT OR IGNORE INTO watchlist (user_id, symbol) VALUES (?, ?)').run(req.userId, symbol.toUpperCase());
  const rows = db.prepare('SELECT symbol FROM watchlist WHERE user_id = ?').all(req.userId);
  res.json({ watchlist: rows.map((r) => r.symbol) });
});

router.delete('/:symbol', (req, res) => {
  db.prepare('DELETE FROM watchlist WHERE user_id = ? AND symbol = ?').run(req.userId, req.params.symbol.toUpperCase());
  const rows = db.prepare('SELECT symbol FROM watchlist WHERE user_id = ?').all(req.userId);
  res.json({ watchlist: rows.map((r) => r.symbol) });
});

module.exports = router;
