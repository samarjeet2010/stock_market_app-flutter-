# 📈 Stock Market Simulator App

A modern Flutter-based **Stock Market Simulator** application that allows users to practice trading with virtual money using live market-style data. The app also includes an **AI Investment Advisor**, portfolio management, watchlist tracking, risk assessment, and user authentication.

This project is designed for students, beginners, and finance enthusiasts who want to learn stock trading in a risk-free environment.

---

# 🚀 Features

## 🔐 Authentication System

* User Login & Signup
* Persistent user session
* Secure local storage using Shared Preferences

## 📊 Live Market Experience

* Simulated real-time stock market data
* Stock price charts using `fl_chart`
* Detailed stock information screen

## 💼 Portfolio Management

* Buy and sell stocks virtually
* Track portfolio performance
* Monitor profit/loss
* Transaction history support

## ⭐ Watchlist System

* Add stocks to watchlist
* Quick stock monitoring
* Personalized trading experience

## 🤖 AI Investment Advisor

* AI-powered stock suggestions
* Risk-based investment recommendations
* Personalized market insights

## ⚠️ Risk Assessment Module

* Analyze investment behavior
* Suggest investment strategies based on risk profile

## 🎨 Beautiful UI

* Clean modern Flutter UI
* Responsive design
* Custom theme support
* Smooth navigation experience

---

# 🛠️ Tech Stack

## Frontend

* Flutter
* Dart

## State Management

* Provider

## Charts & Visualization

* fl_chart

## Routing

* go_router

## Local Storage

* shared_preferences

## Networking

* http package

## Utilities

* intl
* uuid
* google_fonts

---

# 📂 Project Structure

```bash
lib/
│
├── components/
│   └── stock_card.dart
│
├── models/
│   ├── position_model.dart
│   ├── stock_model.dart
│   ├── transaction_model.dart
│   └── user_model.dart
│
├── openai/
│   └── openai_config.dart
│
├── screens/
│   ├── ai_advisor_screen.dart
│   ├── home_screen.dart
│   ├── login_screen.dart
│   ├── main_screen.dart
│   ├── portfolio_screen.dart
│   ├── profile_screen.dart
│   ├── risk_assessment_screen.dart
│   ├── signup_screen.dart
│   ├── splash_screen.dart
│   ├── stock_detail_screen.dart
│   └── trading_screen.dart
│
├── services/
│   ├── auth_service.dart
│   ├── market_data_service.dart
│   ├── portfolio_service.dart
│   ├── settings_service.dart
│   ├── trading_service.dart
│   └── watchlist_service.dart
│
├── utils/
│   └── formatters.dart
│
├── theme.dart
├── nav.dart
└── main.dart
```

---

# ⚙️ Installation & Setup

## 1️⃣ Clone the Repository

```bash
git clone https://github.com/your-username/stock-market-simulator.git
```

## 2️⃣ Navigate to Project Folder

```bash
cd stock-market-simulator
```

## 3️⃣ Install Dependencies

```bash
flutter pub get
```

## 4️⃣ Run the App

```bash
flutter run
```

---

# 🌐 Build for Web

```bash
flutter build web
```

Generated files will be available inside:

```bash
build/web/
```

---

# 📱 Supported Platforms

* Android
* iOS
* Web
* Windows
* Linux
* macOS

---

# 🔑 Environment Configuration

If you are using the AI Advisor feature, configure your API key inside:

```bash
lib/openai/openai_config.dart
```

Example:

```dart
const String openAIApiKey = "YOUR_API_KEY";
```

---

# 📸 Screens Included

* Splash Screen
* Login & Signup
* Home Dashboard
* Stock Details
* Trading Screen
* Portfolio Screen
* AI Advisor
* Profile Screen
* Risk Assessment

---

# 📦 Main Dependencies

```yaml
provider: ^6.1.2
go_router: ^16.2.0
http: ^1.2.2
fl_chart: 0.68.0
shared_preferences: ^2.0.0
intl: 0.20.2
uuid: ^4.0.0
google_fonts: ^6.1.0
```

---

# 🧠 Future Improvements

* Real stock market API integration
* Firebase Authentication
* Dark Mode
* Push Notifications
* Advanced AI Prediction System
* News & Market Sentiment Analysis
* Multi-language support

---

# 👨‍💻 Author

Developed by **Shiva**

---

# ⭐ Contribution

Contributions are welcome.

1. Fork the repository
2. Create a new branch
3. Commit your changes
4. Push to your branch
5. Open a Pull Request

---

---

# 💡 Learning Purpose

This project was built for:

* Flutter development practice
* Stock market simulation learning
* Portfolio management understanding
* AI integration in mobile apps
* Real-world app architecture practice
  
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


# Author 
Samar Jeet










