# MarketSage — Full Stack (Flutter + Node.js backend)

This project has two parts:

```
backend/            Node.js + Express + SQLite REST API
stock_marketAPP/     Flutter app (frontend), talks to the backend
```

Everything (users, portfolio, trades, watchlist, wallet/payments) lives in a
local **SQLite** database file — no MongoDB, no external database server to
install or run. Features:

- Proper auth: passwords hashed with bcrypt, sessions use JWTs
- Simulated live stock prices ticking on the server (random walk), rolled
  into both 1-minute intraday candles and daily OHLC candles, so every
  connected client sees the same prices and the same chart
- A professional candlestick chart (1D/1W/1M/3M/1Y range tabs, live
  crosshair) on the stock detail screen, styled like a real broker app
- AI Advisor: all four Learning Resources cards (Stock Market Basics,
  Trading Strategies, Risk Management, Market Analysis) call the backend,
  which calls Gemini, and stream real generated content back into the app
- **Add Money**: real Razorpay payment gateway integration to top up your
  virtual cash balance (falls back to an automatic mock/test mode if no
  Razorpay keys are configured, so it still works end-to-end for local
  testing)
- Avatar / profile photos stored directly on the user's row as base64 (no
  separate file storage needed for this use case)
- The Gemini AI-advisor API key and Razorpay secret key live server-side
  only — never shipped inside the compiled app

## 1. Run the backend

```bash
cd backend
npm install
cp .env.example .env
# Edit .env:
#   - JWT_SECRET              set a real random secret
#   - GEMINI_API_KEY          optional, needed for the AI Advisor to work
#                              (https://aistudio.google.com/apikey)
#   - RAZORPAY_KEY_ID / SECRET  optional, needed for real Add Money payments
#                              (https://dashboard.razorpay.com/app/keys — use
#                              TEST mode keys, no business verification needed)
npm start
```

This starts the API on `http://localhost:3000`. On first run it seeds 36
mock stocks (US + Indian large caps) with ~220 days of daily OHLC history
each, and creates `backend/data/marketsage.db` (a SQLite file — no external
database server needed).

Requires **Node.js 22.5+** (uses Node's built-in `node:sqlite`, so there's no
native module to compile — no Visual Studio Build Tools or Python needed on
Windows). You'll see a one-line "SQLite is an experimental feature" warning
on startup; that's expected and harmless.

Health check: `curl http://localhost:3000/api/health`

If `GEMINI_API_KEY` is left blank, the AI Advisor endpoint returns a clear
503 error (the app will show "Failed to load content") instead of silently
failing — set the key to enable it.

If `RAZORPAY_KEY_ID`/`RAZORPAY_KEY_SECRET` are left blank, Add Money
automatically runs in **mock mode**: tapping "Proceed to Pay" credits the
wallet immediately without opening a real payment screen, so you can test
the full flow without a Razorpay account. Add real test keys to get the
actual Razorpay checkout UI.

### API summary

| Method | Path | Auth | Purpose |
|---|---|---|---|
| POST | /api/auth/signup | – | Create account, returns `{token, user}` |
| POST | /api/auth/login | – | Login, returns `{token, user}` |
| GET | /api/auth/me | ✓ | Get current user |
| PUT | /api/auth/profile | ✓ | Update name / risk profile |
| PUT | /api/auth/avatar | ✓ | Update avatar (base64) |
| GET | /api/market/stocks | – | All stocks with live prices |
| GET | /api/market/stocks/:symbol | – | One stock |
| GET | /api/market/stocks/:symbol/candles?range= | – | OHLC candles: 1D/1W/1M/3M/1Y |
| GET | /api/market/search?q= | – | Search stocks |
| GET | /api/portfolio/positions | ✓ | Current holdings |
| GET | /api/portfolio/transactions | ✓ | Trade history |
| GET | /api/portfolio/summary | ✓ | Invested / value / P&L |
| POST | /api/trading/buy | ✓ | `{symbol, quantity}` |
| POST | /api/trading/sell | ✓ | `{symbol, quantity}` |
| GET/POST/DELETE | /api/watchlist | ✓ | Manage watchlist |
| POST | /api/ai/advice | ✓ | `{topic}` → AI-generated guide |
| POST | /api/wallet/create-order | ✓ | `{amount}` → Razorpay order (or mock order) |
| POST | /api/wallet/verify-payment | ✓ | Verifies Razorpay signature, credits wallet |
| POST | /api/wallet/confirm-mock | ✓ | Credits wallet in mock mode |
| GET | /api/wallet/orders | ✓ | Payment history |

## 2. Run the Flutter app

```bash
cd stock_marketAPP
flutter pub get
flutter run
```

By default the app points at `http://localhost:3000/api`
(`lib/services/api_client.dart`). It auto-switches to `http://10.0.2.2:3000/api`
on the Android emulator, since `localhost` there refers to the emulator
itself, not your host machine.

- **Real device / different machine**: edit `baseUrl` in `api_client.dart`
  (or call `ApiClient.instance.overrideBaseUrl('http://<your-ip>:3000/api')`
  early in `main.dart`) to point at wherever the backend is reachable.
- **iOS simulator / desktop / web**: `localhost` works as-is.

## What changed: MongoDB → SQLite

This version replaces the MongoDB/Mongoose backend with Node's built-in
`node:sqlite` module:

- `backend/src/models/*.js` (Mongoose schemas) were removed entirely.
- `backend/src/db.js` now opens/creates `backend/data/marketsage.db`, runs
  `CREATE TABLE IF NOT EXISTS` for `users`, `stocks`, `positions`,
  `transactions`, `watchlist`, and `wallet_orders`, and exposes plain
  `db.prepare(...).run()/.get()/.all()` calls plus `*RowToJson` helpers.
  Candle data (`intradayCandles` / `dailyCandles`) is stored as JSON text
  columns and parsed on read, so the candlestick chart works exactly as
  before.
- Every route (`auth`, `market`, `portfolio`, `trading`, `watchlist`,
  `wallet`) was rewritten from Mongoose queries to parameterized SQL, using
  `runInTransaction()` (a manual `BEGIN`/`COMMIT`/`ROLLBACK` wrapper) for
  multi-statement writes like buy/sell so they stay atomic.
- `server.js` no longer connects to MongoDB on boot — just requiring `./db`
  opens the SQLite file and seeds stocks synchronously, so startup is
  simpler and doesn't need a running `mongod` / Atlas cluster.
- `backend/package.json` no longer depends on `mongoose`; `MONGODB_URI` was
  removed from `.env.example`.
- Nothing changed on the Flutter side — the API request/response shapes are
  identical, so no frontend code needed to change.

## Notes / next steps if you deploy this for real

- Set a strong, random `JWT_SECRET` in `backend/.env` before deploying.
- The SQLite file at `backend/data/marketsage.db` is the entire database —
  back it up, or swap in Postgres/MySQL later if you need to scale past one
  server process.
- Stock prices here are a simulated random walk for a paper-trading demo,
  not real market data. Swap `tickPrices()` in `backend/src/db.js` for a
  real market-data provider (e.g. an NSE/BSE data vendor) if you need live
  prices.
- Switch Razorpay from TEST keys to LIVE keys only after completing
  Razorpay's KYC/business verification — never ship TEST keys or LIVE
  secret keys inside the compiled app; they must stay server-side, which is
  already how this is wired.
- CORS is currently wide open (`app.use(cors())`) for easy local dev — lock
  it down to your app's actual origin(s) before shipping.
