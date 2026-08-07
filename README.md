# ⚙️ Setup & Installation

## 📋 Prerequisites

Make sure the following are installed on your system:

* **Flutter SDK**
* **Dart SDK** (Flutter ke saath included)
* **Node.js 22+**
* **npm**
* **Git**
* Android Studio (Android ke liye)
* Chrome (Web ke liye)

Check installations:

```bash
flutter --version
dart --version
node --version
npm --version
git --version
```

---

# 📥 1. Clone the Repository

```bash
git clone https://github.com/your-username/your-repository.git
```

Go to the project directory:

```bash
cd your-repository
```

---

# 🖥️ 2. Backend Setup

Backend folder mein jao:

```bash
cd backend
```

Dependencies install karo:

```bash
npm install
```

### Environment File

`.env.example` ko copy karke `.env` file banao.

### Windows

```bash
copy .env.example .env
```

### macOS / Linux

```bash
cp .env.example .env
```

`.env` file mein required configuration add karo:

```env
PORT=3000

JWT_SECRET=your_secret_key
JWT_EXPIRES_IN=30d

STARTING_BALANCE=100000

PRICE_TICK_INTERVAL_MS=4000

GEMINI_API_KEY=

RAZORPAY_KEY_ID=
RAZORPAY_KEY_SECRET=
```

> **Important:** `.env` file ko GitHub par upload mat karo.

---

# ▶️ 3. Start Backend

Backend development server start karo:

```bash
npm start
```

Agar project mein development script configured hai:

```bash
npm run dev
```

Backend normally yahan run hoga:

```text
http://localhost:3000
```

Health check:

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

# 📱 4. Flutter Setup

New terminal open karo aur Flutter project folder mein jao:

```bash
cd stock_marketAPP
```

Flutter dependencies install karo:

```bash
flutter pub get
```

Flutter environment check karo:

```bash
flutter doctor
```

Available devices check karo:

```bash
flutter devices
```

---

# 🔗 5. Configure Backend URL

Flutter app mein backend API URL configure karo.

### Local Web

```text
http://localhost:3000
```

### Android Emulator

Android Emulator ke liye:

```text
http://10.0.2.2:3000
```

### Production

Agar backend Render ya kisi aur hosting platform par deployed hai:

```text
https://your-backend-url.com
```

Example:

```dart
class ApiConfig {
  static const String baseUrl = 'https://your-backend-url.com';

  static String get apiUrl => '$baseUrl/api';
}
```

---

# 🌐 6. Run on Web

Available devices check karo:

```bash
flutter devices
```

Chrome par run karo:

```bash
flutter run -d chrome
```

Ya production web build:

```bash
flutter build web --release
```

Build output:

```text
build/web/
```

---

# 🤖 7. Run on Android

Android Emulator start karo ya physical Android device connect karo.

Check:

```bash
flutter devices
```

Run:

```bash
flutter run
```

Ya specific device:

```bash
flutter run -d <device-id>
```

---

# 📦 8. Build Android APK

Release APK banane ke liye:

```bash
flutter build apk --release
```

APK yahan milega:

```text
build/app/outputs/flutter-apk/app-release.apk
```

---

# 🧪 9. Run Tests

Flutter tests:

```bash
flutter test
```

---

# 🔐 API Keys Setup

## Gemini AI

AI Advisor use karne ke liye `.env` mein:

```env
GEMINI_API_KEY=your_gemini_api_key
```

API key **sirf backend** mein rakhein.

---

## Razorpay

Payment functionality ke liye:

```env
RAZORPAY_KEY_ID=your_razorpay_key
RAZORPAY_KEY_SECRET=your_razorpay_secret
```

> Razorpay secret ko Flutter app ya GitHub repository mein expose na karein.

---

# 🗄️ SQLite Database

Backend start hone par SQLite database automatically initialize ho jayega.

Database location:

```text
backend/data/marketsage.db
```

Required tables automatically create/seed ki ja sakti hain according to the backend configuration.

---

# 🚀 Complete Local Setup

Agar project ko fresh system par run karna hai:

### Terminal 1 — Backend

```bash
cd backend
npm install
npm start
```

### Terminal 2 — Flutter

```bash
cd stock_marketAPP
flutter pub get
flutter run
```

---

# 🌍 Production Setup

Production mein architecture:

```text
Flutter App
    │
    │ HTTPS
    ▼
Node.js / Express Backend
    │
    ▼
SQLite Database
```

Flutter app mein local URL:

```text
http://localhost:3000
```

ki jagah deployed backend URL configure karein:

```text
https://your-backend-url.com
```

---

# ⚠️ Troubleshooting

### Backend start nahi ho raha

Check Node.js:

```bash
node --version
```

Dependencies reinstall karein:

```bash
rm -rf node_modules
npm install
```

Windows:

```bash
rmdir /s /q node_modules
npm install
```

---

### Flutter dependencies error

Run:

```bash
flutter clean
flutter pub get
```

Then:

```bash
flutter run
```

---

### Android API connect nahi kar raha

Android Emulator ke liye:

```text
http://10.0.2.2:3000
```

use karein.

`localhost` Android Emulator ke andar **aapke computer ko refer nahi karta**.

---

### Backend connection check

Browser mein open karein:

```text
http://localhost:3000/api/health
```

Agar response aa raha hai:

```json
{
  "status": "ok"
}
```

to backend successfully running hai.

---

# ✅ Quick Start

```bash
# Clone
git clone https://github.com/your-username/your-repository.git

# Backend
cd backend
npm install
npm start

# New terminal
cd stock_marketAPP
flutter pub get
flutter run
```

🎉 **MarketSage is now ready to run locally.**
