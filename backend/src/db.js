const path = require('path');
const fs = require('fs');
const { DatabaseSync } = require('node:sqlite');

const dataDir = path.join(__dirname, '..', 'data');
if (!fs.existsSync(dataDir)) fs.mkdirSync(dataDir, { recursive: true });

const db = new DatabaseSync(path.join(dataDir, 'marketsage.db'));
db.exec('PRAGMA journal_mode = WAL');

// node:sqlite's DatabaseSync has no built-in db.transaction() helper like
// better-sqlite3 did, so this wraps a block of statements in BEGIN/COMMIT
// (with ROLLBACK on error).
function runInTransaction(fn) {
  db.exec('BEGIN');
  try {
    const result = fn();
    db.exec('COMMIT');
    return result;
  } catch (err) {
    db.exec('ROLLBACK');
    throw err;
  }
}

db.exec(`
CREATE TABLE IF NOT EXISTS users (
  id TEXT PRIMARY KEY,
  email TEXT UNIQUE NOT NULL,
  password_hash TEXT NOT NULL,
  name TEXT NOT NULL,
  virtual_balance REAL NOT NULL,
  risk_profile TEXT NOT NULL,
  avatar_data TEXT,
  created_at TEXT NOT NULL,
  updated_at TEXT NOT NULL
);

CREATE TABLE IF NOT EXISTS stocks (
  symbol TEXT PRIMARY KEY,
  name TEXT NOT NULL,
  current_price REAL NOT NULL,
  change REAL NOT NULL,
  change_percent REAL NOT NULL,
  volume INTEGER NOT NULL,
  market_cap REAL,
  high REAL,
  low REAL,
  sector TEXT,
  description TEXT,
  updated_at TEXT NOT NULL,
  price_history TEXT NOT NULL,
  intraday_candles TEXT NOT NULL DEFAULT '[]',
  daily_candles TEXT NOT NULL DEFAULT '[]'
);

CREATE TABLE IF NOT EXISTS positions (
  user_id TEXT NOT NULL,
  symbol TEXT NOT NULL,
  stock_name TEXT NOT NULL,
  quantity INTEGER NOT NULL,
  avg_buy_price REAL NOT NULL,
  current_price REAL NOT NULL,
  created_at TEXT NOT NULL,
  updated_at TEXT NOT NULL,
  PRIMARY KEY (user_id, symbol)
);

CREATE TABLE IF NOT EXISTS transactions (
  id TEXT PRIMARY KEY,
  user_id TEXT NOT NULL,
  symbol TEXT NOT NULL,
  stock_name TEXT NOT NULL,
  type TEXT NOT NULL,
  quantity INTEGER NOT NULL,
  price REAL NOT NULL,
  total_amount REAL NOT NULL,
  timestamp TEXT NOT NULL
);

CREATE TABLE IF NOT EXISTS watchlist (
  user_id TEXT NOT NULL,
  symbol TEXT NOT NULL,
  PRIMARY KEY (user_id, symbol)
);

CREATE TABLE IF NOT EXISTS wallet_orders (
  id TEXT PRIMARY KEY,
  user_id TEXT NOT NULL,
  amount REAL NOT NULL,
  razorpay_order_id TEXT NOT NULL,
  razorpay_payment_id TEXT,
  status TEXT NOT NULL DEFAULT 'created',
  mock INTEGER NOT NULL DEFAULT 0,
  created_at TEXT NOT NULL,
  updated_at TEXT NOT NULL
);
`);

// ---- Stock universe (mirrors the original in-app mock data) ----
const STOCK_SEED = [
  { symbol: 'AAPL', name: 'Apple Inc.', sector: 'Technology' },
  { symbol: 'GOOGL', name: 'Alphabet Inc.', sector: 'Technology' },
  { symbol: 'MSFT', name: 'Microsoft Corporation', sector: 'Technology' },
  { symbol: 'AMZN', name: 'Amazon.com Inc.', sector: 'Consumer' },
  { symbol: 'TSLA', name: 'Tesla Inc.', sector: 'Automotive' },
  { symbol: 'META', name: 'Meta Platforms Inc.', sector: 'Technology' },
  { symbol: 'NVDA', name: 'NVIDIA Corporation', sector: 'Technology' },
  { symbol: 'JPM', name: 'JPMorgan Chase & Co.', sector: 'Finance' },
  { symbol: 'V', name: 'Visa Inc.', sector: 'Finance' },
  { symbol: 'WMT', name: 'Walmart Inc.', sector: 'Retail' },
  { symbol: 'DIS', name: 'The Walt Disney Company', sector: 'Entertainment' },
  { symbol: 'NFLX', name: 'Netflix Inc.', sector: 'Entertainment' },
  { symbol: 'BA', name: 'Boeing Company', sector: 'Aerospace' },
  { symbol: 'NKE', name: 'Nike Inc.', sector: 'Consumer' },
  { symbol: 'INTC', name: 'Intel Corporation', sector: 'Technology' },
  { symbol: 'RELIANCE', name: 'Reliance Industries', sector: 'Energy' },
  { symbol: 'TCS', name: 'Tata Consultancy Services', sector: 'Technology' },
  { symbol: 'HDFCBANK', name: 'HDFC Bank', sector: 'Finance' },
  { symbol: 'INFY', name: 'Infosys', sector: 'Technology' },
  { symbol: 'ICICIBANK', name: 'ICICI Bank', sector: 'Finance' },
  { symbol: 'SBIN', name: 'State Bank of India', sector: 'Finance' },
  { symbol: 'HINDUNILVR', name: 'Hindustan Unilever', sector: 'Consumer' },
  { symbol: 'ITC', name: 'ITC Limited', sector: 'Consumer' },
  { symbol: 'BHARTIARTL', name: 'Bharti Airtel', sector: 'Telecom' },
  { symbol: 'KOTAKBANK', name: 'Kotak Mahindra Bank', sector: 'Finance' },
  { symbol: 'LTIM', name: 'LTIMindtree', sector: 'Technology' },
  { symbol: 'WIPRO', name: 'Wipro', sector: 'Technology' },
  { symbol: 'TATASTEEL', name: 'Tata Steel', sector: 'Metals' },
  { symbol: 'TATAMOTORS', name: 'Tata Motors', sector: 'Automotive' },
  { symbol: 'ADANIENT', name: 'Adani Enterprises', sector: 'Conglomerate' },
  { symbol: 'ASIANPAINT', name: 'Asian Paints', sector: 'Consumer' },
  { symbol: 'MARUTI', name: 'Maruti Suzuki', sector: 'Automotive' },
  { symbol: 'SUNPHARMA', name: 'Sun Pharma', sector: 'Healthcare' },
  { symbol: 'ONGC', name: 'ONGC', sector: 'Energy' },
  { symbol: 'NTPC', name: 'NTPC', sector: 'Utilities' },
  { symbol: 'ULTRACEMCO', name: 'UltraTech Cement', sector: 'Materials' },
];

const INTRADAY_CANDLE_MS = 60 * 1000; // 1-minute candles
const MAX_INTRADAY_CANDLES = 390; // ~ one trading session
const MAX_DAILY_CANDLES = 400; // > 1 year
const MAX_PRICE_HISTORY = 120;

function randomBetween(min, max) {
  return min + Math.random() * (max - min);
}

function clampPrice(p) {
  return Math.min(Math.max(p, 1), 1000000000);
}

function round2(n) {
  return Math.round(n * 100) / 100;
}

function buildSeedDailyCandles(basePrice) {
  const candles = [];
  let price = basePrice;
  const dayMs = 24 * 60 * 60 * 1000;
  const now = Date.now();
  const days = 220;
  for (let i = days; i >= 0; i--) {
    const t = now - i * dayMs;
    const open = price;
    const drift = randomBetween(-0.02, 0.022) * price; // daily volatility
    let close = clampPrice(open + drift);
    const high = Math.max(open, close) + Math.abs(randomBetween(0, 0.012)) * price;
    const low = Math.max(1, Math.min(open, close) - Math.abs(randomBetween(0, 0.012)) * price);
    const volume = Math.floor(500000 + Math.random() * 4500000);
    candles.push({ t, o: round2(open), h: round2(high), l: round2(low), c: round2(close), v: volume });
    price = close;
  }
  return candles;
}

function seedStocksIfEmpty() {
  const count = db.prepare('SELECT COUNT(*) as c FROM stocks').get().c;
  if (count > 0) return;

  const insert = db.prepare(`
    INSERT INTO stocks (symbol, name, current_price, change, change_percent, volume, market_cap, high, low, sector, description, updated_at, price_history, intraday_candles, daily_candles)
    VALUES (@symbol, @name, @current_price, @change, @change_percent, @volume, @market_cap, @high, @low, @sector, @description, @updated_at, @price_history, @intraday_candles, @daily_candles)
  `);

  const now = new Date().toISOString();

  const rows = STOCK_SEED.map((s) => {
    const basePrice = randomBetween(50, 3500);
    const dailyCandles = buildSeedDailyCandles(basePrice);
    const current = dailyCandles[dailyCandles.length - 1].c;
    const first = dailyCandles[0].c;
    const change = current - first;
    const changePercent = (change / first) * 100;
    const priceHistory = dailyCandles.slice(-60).map((c) => c.c);
    const intradayCandles = [
      { t: Date.now(), o: current, h: current, l: current, c: current, v: 0 },
    ];

    return {
      symbol: s.symbol,
      name: s.name,
      current_price: current,
      change,
      change_percent: changePercent,
      volume: Math.floor(1000000 + Math.random() * 9000000),
      market_cap: current * Math.floor(500000000 + Math.random() * 1500000000),
      high: Math.max(...dailyCandles.slice(-30).map((c) => c.h)),
      low: Math.min(...dailyCandles.slice(-30).map((c) => c.l)),
      sector: s.sector,
      description: `Leading company in ${s.sector} sector`,
      updated_at: now,
      price_history: JSON.stringify(priceHistory),
      intraday_candles: JSON.stringify(intradayCandles),
      daily_candles: JSON.stringify(dailyCandles),
    };
  });

  runInTransaction(() => {
    for (const row of rows) insert.run(row);
  });
  console.log(`Seeded ${rows.length} stocks with daily candle history`);
}

// Runs on a timer; advances every stock's simulated price by a small random
// step and rolls that into the 1-minute intraday candle series (and keeps
// today's daily candle in sync too).
function tickPrices() {
  const stocks = db.prepare('SELECT * FROM stocks').all();
  const update = db.prepare(`
    UPDATE stocks SET current_price=@current_price, change=@change, change_percent=@change_percent,
      volume=@volume, high=@high, low=@low, updated_at=@updated_at, price_history=@price_history,
      intraday_candles=@intraday_candles, daily_candles=@daily_candles
    WHERE symbol=@symbol
  `);

  const now = Date.now();
  const bucket = Math.floor(now / INTRADAY_CANDLE_MS) * INTRADAY_CANDLE_MS;
  const nowIso = new Date(now).toISOString();

  const rows = stocks.map((stock) => {
    const priceChange = randomBetween(-1, 1) * Math.max(0.15, stock.current_price * 0.004);
    const newPrice = round2(clampPrice(stock.current_price + priceChange));
    const tickVolume = Math.floor(Math.random() * 5000);

    // Rolling raw price history (used for lightweight sparklines).
    const priceHistory = JSON.parse(stock.price_history);
    priceHistory.push(newPrice);
    if (priceHistory.length > MAX_PRICE_HISTORY) priceHistory.shift();

    // Intraday 1-minute candles.
    const intraday = JSON.parse(stock.intraday_candles);
    const last = intraday[intraday.length - 1];
    if (last && last.t === bucket) {
      last.h = Math.max(last.h, newPrice);
      last.l = Math.min(last.l, newPrice);
      last.c = newPrice;
      last.v += tickVolume;
    } else {
      intraday.push({ t: bucket, o: stock.current_price, h: Math.max(stock.current_price, newPrice), l: Math.min(stock.current_price, newPrice), c: newPrice, v: tickVolume });
    }
    while (intraday.length > MAX_INTRADAY_CANDLES) intraday.shift();

    // Keep today's daily candle (last one) in sync with the live price.
    const daily = JSON.parse(stock.daily_candles);
    const today = new Date(now).toISOString().slice(0, 10);
    const lastDaily = daily[daily.length - 1];
    const lastDailyDay = lastDaily ? new Date(lastDaily.t).toISOString().slice(0, 10) : null;
    if (lastDaily && lastDailyDay === today) {
      lastDaily.h = Math.max(lastDaily.h, newPrice);
      lastDaily.l = Math.min(lastDaily.l, newPrice);
      lastDaily.c = newPrice;
      lastDaily.v += tickVolume;
    } else {
      daily.push({ t: now, o: stock.current_price, h: Math.max(stock.current_price, newPrice), l: Math.min(stock.current_price, newPrice), c: newPrice, v: tickVolume });
    }
    while (daily.length > MAX_DAILY_CANDLES) daily.shift();

    const windowStart = priceHistory[0];
    const change = newPrice - windowStart;
    const changePercent = windowStart ? (change / windowStart) * 100 : 0;

    return {
      symbol: stock.symbol,
      current_price: newPrice,
      change,
      change_percent: changePercent,
      volume: stock.volume + tickVolume,
      high: Math.max(stock.high ?? newPrice, newPrice),
      low: Math.min(stock.low ?? newPrice, newPrice),
      updated_at: nowIso,
      price_history: JSON.stringify(priceHistory),
      intraday_candles: JSON.stringify(intraday),
      daily_candles: JSON.stringify(daily),
    };
  });

  runInTransaction(() => {
    for (const row of rows) update.run(row);
  });
}

function stockRowToJson(row) {
  return {
    symbol: row.symbol,
    name: row.name,
    currentPrice: row.current_price,
    change: row.change,
    changePercent: row.change_percent,
    volume: row.volume,
    marketCap: row.market_cap,
    high: row.high,
    low: row.low,
    sector: row.sector,
    description: row.description,
    updatedAt: row.updated_at,
    priceHistory: JSON.parse(row.price_history),
  };
}

// Converts stored {t,o,h,l,c,v} candles into the {time,open,high,low,close,volume}
// shape the Flutter candlestick chart expects.
function candlesToJson(candles) {
  return candles.map((c) => ({
    time: c.t,
    open: c.o,
    high: c.h,
    low: c.l,
    close: c.c,
    volume: c.v,
  }));
}

function getIntradayCandles(row) {
  return JSON.parse(row.intraday_candles);
}

function getDailyCandles(row) {
  return JSON.parse(row.daily_candles);
}

function userRowToJson(row) {
  if (!row) return null;
  return {
    userId: row.id,
    email: row.email,
    name: row.name,
    virtualBalance: row.virtual_balance,
    riskProfile: row.risk_profile,
    avatarData: row.avatar_data || null,
    createdAt: row.created_at,
    updatedAt: row.updated_at,
  };
}

function positionRowToJson(row) {
  return {
    symbol: row.symbol,
    stockName: row.stock_name,
    quantity: row.quantity,
    avgBuyPrice: row.avg_buy_price,
    currentPrice: row.current_price,
    createdAt: row.created_at,
    updatedAt: row.updated_at,
  };
}

function transactionRowToJson(row) {
  return {
    transactionId: row.id,
    userId: row.user_id,
    symbol: row.symbol,
    stockName: row.stock_name,
    type: row.type,
    quantity: row.quantity,
    price: row.price,
    totalAmount: row.total_amount,
    timestamp: row.timestamp,
  };
}

function walletOrderRowToJson(row) {
  return {
    orderId: row.id,
    amount: row.amount,
    razorpayOrderId: row.razorpay_order_id,
    razorpayPaymentId: row.razorpay_payment_id || null,
    status: row.status,
    mock: !!row.mock,
    createdAt: row.created_at,
  };
}

seedStocksIfEmpty();

module.exports = {
  db,
  runInTransaction,
  tickPrices,
  stockRowToJson,
  candlesToJson,
  getIntradayCandles,
  getDailyCandles,
  userRowToJson,
  positionRowToJson,
  transactionRowToJson,
  walletOrderRowToJson,
};
