const express = require('express');
const { db, stockRowToJson, candlesToJson, getIntradayCandles, getDailyCandles } = require('../db');

const router = express.Router();

router.get('/stocks', (req, res) => {
  const rows = db.prepare('SELECT * FROM stocks ORDER BY symbol').all();
  res.json({ stocks: rows.map(stockRowToJson) });
});

router.get('/search', (req, res) => {
  const q = String(req.query.q || '').toLowerCase();
  const rows = db.prepare('SELECT * FROM stocks ORDER BY symbol').all();
  const filtered = q
    ? rows.filter((r) => r.symbol.toLowerCase().includes(q) || r.name.toLowerCase().includes(q))
    : rows;
  res.json({ stocks: filtered.map(stockRowToJson) });
});

router.get('/stocks/:symbol', (req, res) => {
  const row = db.prepare('SELECT * FROM stocks WHERE symbol = ?').get(req.params.symbol.toUpperCase());
  if (!row) return res.status(404).json({ error: 'Stock not found' });
  res.json({ stock: stockRowToJson(row) });
});

// Candlestick data for the chart on the stock detail screen. Ranges map to
// either the rolling 1-minute intraday series (for "1D") or the daily OHLC
// series (for everything longer), matching how a real broker app like
// Angel One buckets its chart ranges.
router.get('/stocks/:symbol/candles', (req, res) => {
  const row = db.prepare('SELECT * FROM stocks WHERE symbol = ?').get(req.params.symbol.toUpperCase());
  if (!row) return res.status(404).json({ error: 'Stock not found' });

  const range = String(req.query.range || '1D').toUpperCase();
  let candles;

  if (range === '1D') {
    candles = getIntradayCandles(row);
  } else {
    const daily = getDailyCandles(row);
    const counts = { '1W': 7, '1M': 30, '3M': 90, '6M': 180, '1Y': 365, ALL: daily.length };
    const n = counts[range] ?? 30;
    candles = daily.slice(-n);
  }

  res.json({ symbol: row.symbol, range, candles: candlesToJson(candles) });
});

module.exports = router;
