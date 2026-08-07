require('dotenv').config();
const express = require('express');
const cors = require('cors');

const { tickPrices } = require('./db');
const authRoutes = require('./routes/auth');
const marketRoutes = require('./routes/market');
const portfolioRoutes = require('./routes/portfolio');
const tradingRoutes = require('./routes/trading');
const watchlistRoutes = require('./routes/watchlist');
const aiRoutes = require('./routes/ai');
const walletRoutes = require('./routes/wallet');

if (!process.env.JWT_SECRET) {
  console.warn('WARNING: JWT_SECRET is not set. Copy .env.example to .env and set a real secret before deploying.');
  process.env.JWT_SECRET = 'dev_only_insecure_secret_change_me';
}

const app = express();
app.use(cors());
app.use(express.json({ limit: '5mb' })); // generous limit to allow base64 avatar images

app.get('/api/health', (req, res) => res.json({ status: 'ok' }));

app.use('/api/auth', authRoutes);
app.use('/api/market', marketRoutes);
app.use('/api/portfolio', portfolioRoutes);
app.use('/api/trading', tradingRoutes);
app.use('/api/watchlist', watchlistRoutes);
app.use('/api/ai', aiRoutes);
app.use('/api/wallet', walletRoutes);

app.use((req, res) => res.status(404).json({ error: 'Not found' }));
// eslint-disable-next-line no-unused-vars
app.use((err, req, res, next) => {
  console.error(err);
  res.status(500).json({ error: 'Internal server error' });
});

const PORT = process.env.PORT || 3000;
const TICK_MS = Number(process.env.PRICE_TICK_INTERVAL_MS || 4000);

// Requiring './db' above already opens the SQLite file, creates the tables,
// and seeds the stock universe if it's empty — no separate async connect
// step needed like there was with MongoDB.
app.listen(PORT, () => {
  console.log(`MarketSage backend listening on http://localhost:${PORT}`);
  setInterval(() => {
    try {
      tickPrices();
    } catch (err) {
      console.error('tickPrices error:', err);
    }
  }, TICK_MS);
});
