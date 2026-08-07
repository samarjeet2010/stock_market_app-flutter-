# 📈 MarketSage — Stock Market Simulator

> **A full-stack stock market paper-trading application built with Flutter, Node.js, Express and SQLite, featuring virtual trading, portfolio management, watchlists, AI investment guidance and wallet management.**

MarketSage is a **risk-free stock market simulation platform** that allows users to explore the stock market, buy and sell stocks using virtual money, track portfolio performance, create watchlists and receive AI-powered investment insights.

The project consists of a **Flutter frontend** and a **Node.js/Express backend** powered by a lightweight **SQLite database**.

---

## 🚀 Features

### 🔐 Authentication

* User registration and login
* JWT-based authentication
* Secure password hashing using bcrypt
* User profile management
* Profile avatar support
* Persistent authentication

### 📊 Market Dashboard

* Stock market overview
* Search stocks by symbol/name
* Stock details
* Current simulated stock prices
* Price changes and percentage changes
* Trading volume
* Market capitalization
* High/low prices
* Sector information

### 📈 Stock Charts

* Interactive stock price charts
* Intraday candle data
* Daily candle data
* Historical price information
* Candlestick visualization using `fl_chart`

### 💰 Paper Trading

Users receive virtual cash and can practice trading without risking real money.

* Buy stocks
* Sell stocks
* Automatic portfolio updates
* Average buy price calculation
* Current position tracking
* Transaction history
* Profit/loss tracking

### 📁 Portfolio Management

* View current holdings
* Track quantity owned
* Average purchase price
* Current market value
* Portfolio summary
* Transaction history
* Virtual cash balance

### ⭐ Watchlist

Users can create a personalized stock watchlist.

* Add stocks to watchlist
* Remove stocks
* View saved stocks
* Quickly access stock details

### 🤖 AI Investment Advisor

The application includes an AI-powered advisor endpoint that can provide investment-related insights based on the user's portfolio and market information.

The backend supports **Google Gemini API** integration.

> ⚠️ AI-generated information is for educational/simulation purposes and should not be considered financial advice.

### 💳 Virtual Wallet

The application supports adding virtual money to the trading account.

* Create wallet orders
* Payment verification
* Razorpay integration
* Mock payment mode for local development
* Wallet order history

If Razorpay credentials are not configured, the backend can use its built-in mock payment flow for testing.

### 🎯 Risk Assessment

Users can complete a risk assessment to determine their risk profile and use it as part of their investment experience.




# UI Preview


<p align="center">
  <img src="https://github.com/user-attachments/assets/a418b0c9-bbd8-4892-aefc-465ca05d374d" width="250"/>
  &nbsp;&nbsp;&nbsp;
  <img src="https://github.com/user-attachments/assets/88f9b5e9-cf41-4575-bd40-da0da38daf91" width="250"/>
</p>

<p align="center">
  <img src="https://github.com/user-attachments/assets/734f7100-678a-4339-a1d2-54117517999b" width="250"/>
  &nbsp;&nbsp;&nbsp;
  <img src="https://github.com/user-attachments/assets/e00a73bd-31d0-40c1-945d-3d68a4f53eb1" width="250"/>
</p>

<p align="center">
  <img src="https://github.com/user-attachments/assets/0f2d2689-70fe-430c-83bd-c303682c15e6" width="250"/>
  &nbsp;&nbsp;&nbsp;
  <img src="https://github.com/user-attachments/assets/b902f8ce-1648-4885-bfd2-374c2bbe0247" width="250"/>
</p>






# 🏗️ Tech Stack

## Frontend

| Technology         | Purpose                |
| ------------------ | ---------------------- |
| Flutter            | Cross-platform UI      |
| Dart               | Programming language   |
| Provider           | State management       |
| GoRouter           | Navigation             |
| HTTP               | REST API communication |
| FL Chart           | Stock charts           |
| Shared Preferences | Local storage          |
| Google Fonts       | UI typography          |
| Razorpay Flutter   | Payment integration    |

## Backend

| Technology    | Purpose                   |
| ------------- | ------------------------- |
| Node.js       | Backend runtime           |
| Express.js    | REST API                  |
| SQLite        | Database                  |
| JWT           | Authentication            |
| bcryptjs      | Password hashing          |
| CORS          | Cross-origin requests     |
| dotenv        | Environment configuration |
| Razorpay      | Payment integration       |
| UUID          | Unique identifiers        |
| Google Gemini | AI Advisor                |

---

# 📂 Project Structure

```text
final_version/
│
├── backend/
│   ├── src/
│   │   ├── db.js
│   │   ├── server.js
│   │   │
│   │   ├── middleware/
│   │   │   └── auth.js
│   │   │
│   │   └── routes/
│   │       ├── auth.js
│   │       ├── market.js
│   │       ├── trading.js
│   │       ├── portfolio.js
│   │       ├── watchlist.js
│   │       ├── ai.js
│   │       └── wallet.js
│   │
│   ├── .env.example
│   └── package.json
│
└── stock_marketAPP/
    ├── lib/
    │   ├── components/
    │   ├── models/
    │   ├── screens/
    │   ├── services/
    │   ├── utils/
    │   ├── theme.dart
    │   ├── nav.dart
    │   └── main.dart
    │
    ├── android/
    ├── web/
    ├── test/
    ├── pubspec.yaml
    └── README.md
```

---

# 🗄️ Database

MarketSage uses **SQLite** for data persistence.

The backend automatically creates the database and required tables when the server starts.

Main tables include:

```text
users
stocks
positions
transactions
watchlist
wallet_orders
```

The SQLite database is stored inside:

```text
backend/data/marketsage.db
```

The stock universe is automatically seeded when the database is empty.

---

# 📱 Supported Stocks

The simulator includes a collection of popular US and Indian companies, including:

* Apple
* Google
* Microsoft
* Amazon
* Tesla
* Meta
* NVIDIA
* JPMorgan
* Visa
* Walmart
* Netflix
* Boeing
* Nike
* Intel
* Reliance
* TCS
* HDFC Bank
* Infosys
* ICICI Bank
* SBI
* Hindustan Unilever
* ITC
* Bharti Airtel
* Kotak Mahindra Bank
* LTIMindtree
* Wipro
* Tata Steel
* Tata Motors
* Adani Enterprises
* Asian Paints
* Maruti Suzuki
* Sun Pharma
* ONGC
* NTPC
* UltraTech Cement

> Stock prices in this project are **simulated**, making the application suitable for paper trading and learning.

---

# 🔌 REST API

## Health Check

```http
GET /api/health
```

## Authentication

```http
POST /api/auth/signup
POST /api/auth/login
GET  /api/auth/me
PUT  /api/auth/profile
PUT  /api/auth/avatar
```

## Market

```http
GET /api/market/stocks
GET /api/market/search
GET /api/market/stocks/:symbol
GET /api/market/stocks/:symbol/candles
```

## Trading

```http
POST /api/trading/buy
POST /api/trading/sell
```

## Portfolio

```http
GET /api/portfolio/positions
GET /api/portfolio/transactions
GET /api/portfolio/summary
```

## Watchlist

```http
GET    /api/watchlist
POST   /api/watchlist
DELETE /api/watchlist/:symbol
```

## AI Advisor

```http
POST /api/ai/advice
```

## Wallet

```http
POST /api/wallet/create-order
POST /api/wallet/verify-payment
POST /api/wallet/confirm-mock
GET  /api/wallet/orders
```

---

# ⚙️ Requirements

Before running the project, install:

### Flutter

Flutter SDK with Dart

### Node.js

Node.js **22.5+** is recommended because the backend uses Node's built-in SQLite support.

Check your versions:

```bash
flutter --version
node --version
npm --version
```

---

# 🔧 Backend Setup

Go to the backend directory:

```bash
cd final_version/backend
```

Install dependencies:

```bash
npm install
```

Create an environment file:

```bash
copy .env.example .env
```

For macOS/Linux:

```bash
cp .env.example .env
```

Update `.env`:

```env
PORT=3000

JWT_SECRET=your_long_random_secret

JWT_EXPIRES_IN=30d

STARTING_BALANCE=100000

PRICE_TICK_INTERVAL_MS=4000

GEMINI_API_KEY=

RAZORPAY_KEY_ID=

RAZORPAY_KEY_SECRET=
```

Start the backend:

```bash
npm start
```

For development:

```bash
npm run dev
```

The server will run on:

```text
http://localhost:3000
```

Test the server:

```text
http://localhost:3000/api/health
```

Expected response:

```json
{
  "status": "ok"
}
```

---

# 📱 Flutter Setup

Open a new terminal and go to the Flutter application:

```bash
cd final_version/stock_marketAPP
```

Install Flutter dependencies:

```bash
flutter pub get
```

Check available devices:

```bash
flutter devices
```

Run the application:

```bash
flutter run
```

### Android

```bash
flutter run -d <android-device>
```

### Web

```bash
flutter run -d chrome
```

---

# 🌐 Backend URL Configuration

The Flutter application communicates with the Node.js backend through REST APIs.

For local development:

```text
http://localhost:3000
```

For Android Emulator, the host machine can be accessed using:

```text
http://10.0.2.2:3000
```

For a deployed backend, replace the API base URL with your production backend URL.

Example:

```dart
static const String baseUrl = 'https://your-backend-url.com';

static String get apiUrl => '$baseUrl/api';
```

---

# 🔑 Environment Variables

| Variable                 | Description                     |
| ------------------------ | ------------------------------- |
| `PORT`                   | Backend server port             |
| `JWT_SECRET`             | Secret used for JWT tokens      |
| `JWT_EXPIRES_IN`         | JWT expiration duration         |
| `STARTING_BALANCE`       | Initial virtual cash            |
| `PRICE_TICK_INTERVAL_MS` | Simulated price update interval |
| `GEMINI_API_KEY`         | Google Gemini API key           |
| `RAZORPAY_KEY_ID`        | Razorpay key ID                 |
| `RAZORPAY_KEY_SECRET`    | Razorpay secret                 |

### Important

Never commit your real `.env` file to GitHub.

Make sure `.env` is included in `.gitignore`.

---

# 🔄 How the Application Works

```text
                 ┌─────────────────────┐
                 │   Flutter App       │
                 │                     │
                 │  Android / Web      │
                 └──────────┬──────────┘
                            │
                         REST API
                            │
                            ▼
                 ┌─────────────────────┐
                 │  Node.js + Express  │
                 │                     │
                 │ Authentication      │
                 │ Market              │
                 │ Trading             │
                 │ Portfolio           │
                 │ Watchlist           │
                 │ AI Advisor          │
                 │ Wallet              │
                 └──────────┬──────────┘
                            │
                            ▼
                 ┌─────────────────────┐
                 │       SQLite        │
                 │                     │
                 │ Users               │
                 │ Stocks              │
                 │ Positions           │
                 │ Transactions        │
                 │ Watchlist            │
                 │ Wallet Orders       │
                 └─────────────────────┘
```

---

# 📊 Simulated Market

This is a **paper-trading simulator**, not a real stock brokerage application.

The backend periodically updates simulated prices using the configured:

```env
PRICE_TICK_INTERVAL_MS=4000
```

This means prices can change approximately every 4 seconds during the simulation.

Historical candle data is also generated for chart visualization.

---

# 🛡️ Security

The project includes:

* JWT authentication
* Password hashing with bcrypt
* Protected API routes
* Environment variables for secrets
* Server-side payment credentials
* CORS configuration
* Authentication middleware

For production deployment:

* Use a strong random `JWT_SECRET`
* Never expose API secrets in Flutter
* Never commit `.env`
* Use HTTPS
* Configure production CORS
* Use production Razorpay credentials only when required

---

# 💳 Razorpay

The wallet module supports Razorpay integration.

For development, Razorpay credentials can be left empty and the application can use the built-in mock payment flow.

For real Razorpay testing, configure:

```env
RAZORPAY_KEY_ID=your_key_id
RAZORPAY_KEY_SECRET=your_key_secret
```

**Never expose `RAZORPAY_KEY_SECRET` inside the Flutter application.**

---

# 🤖 Gemini AI Setup

To enable the AI Advisor, create a Gemini API key and configure:

```env
GEMINI_API_KEY=your_gemini_api_key
```

The key should remain **server-side** and must not be included directly in the Flutter application.

---

# 🧪 Testing

Run Flutter tests using:

```bash
flutter test
```

For backend development, verify the health endpoint:

```text
GET /api/health
```

---

# 📦 Production Build

### Android APK

```bash
flutter build apk --release
```

Generated APK:

```text
build/app/outputs/flutter-apk/app-release.apk
```

### Android App Bundle

```bash
flutter build appbundle --release
```

### Web

```bash
flutter build web --release
```

The production web files will be generated inside:

```text
build/web/
```

---

# 🚀 Deployment

The application can be deployed using:

```text
Flutter Frontend
       ↓
Web Hosting / Android APK
       ↓
Node.js Backend
       ↓
SQLite Database
```

For backend deployment, make sure the hosting platform supports:

* Node.js 22+
* Persistent filesystem/storage if SQLite data must survive restarts
* Environment variables
* HTTP/HTTPS access

---

# ⚠️ Disclaimer

MarketSage is an **educational stock market simulation project**.

It does not execute real stock trades and does not provide guaranteed financial returns.

Any AI-generated market information or investment suggestions are for **educational and simulation purposes only** and should not be treated as professional financial advice.

---

# 👨‍💻 Project Purpose

This project was developed to demonstrate a complete full-stack application combining:

* Cross-platform Flutter development
* REST API development
* JWT authentication
* SQLite database management
* Paper trading logic
* Portfolio management
* Financial data visualization
* AI integration
* Payment integration
* Full-stack application architecture

---

# ⭐ Future Improvements

Possible future enhancements:

* Real-time stock market APIs
* WebSocket-based live prices
* Advanced technical indicators
* More financial instruments
* Stock news integration
* Advanced portfolio analytics
* Leaderboards
* Social trading
* Real-time notifications
* Improved AI financial analysis
* Production-grade database such as PostgreSQL
* Automated backend testing
* CI/CD deployment pipeline

---

#  Author
Samar Jeet



## ⭐ If you like this project

Give the repository a ⭐ on GitHub and feel free to explore, improve and extend the project.
