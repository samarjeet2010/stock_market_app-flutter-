import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:untitled_5/screens/login_screen.dart';
import 'package:untitled_5/screens/signup_screen.dart';
import 'package:untitled_5/screens/risk_assessment_screen.dart';
import 'package:untitled_5/screens/main_screen.dart';
import 'package:untitled_5/screens/stock_detail_screen.dart';
import 'package:untitled_5/models/stock_model.dart';
import 'package:untitled_5/screens/splash_screen.dart';

class AppRouter {
  static final GoRouter router = GoRouter(
    initialLocation: AppRoutes.splash,
    routes: [
      GoRoute(
        path: AppRoutes.splash,
        name: 'splash',
        pageBuilder: (context, state) => const NoTransitionPage(
          child: SplashScreen(),
        ),
      ),
      GoRoute(
        path: AppRoutes.login,
        name: 'login',
        pageBuilder: (context, state) => const NoTransitionPage(
          child: LoginScreen(),
        ),
      ),
      GoRoute(
        path: AppRoutes.signup,
        name: 'signup',
        pageBuilder: (context, state) => const MaterialPage(
          child: SignupScreen(),
        ),
      ),
      GoRoute(
        path: AppRoutes.riskAssessment,
        name: 'risk-assessment',
        pageBuilder: (context, state) {
          final userData = state.extra as Map<String, String>;
          return MaterialPage(
            child: RiskAssessmentScreen(userData: userData),
          );
        },
      ),
      GoRoute(
        path: AppRoutes.home,
        name: 'home',
        pageBuilder: (context, state) => const NoTransitionPage(
          child: MainScreen(),
        ),
      ),
      GoRoute(
        path: AppRoutes.stockDetail,
        name: 'stock-detail',
        pageBuilder: (context, state) {
          final stock = state.extra as StockModel;
          return MaterialPage(
            child: StockDetailScreen(stock: stock),
          );
        },
      ),
    ],
  );
}

class AppRoutes {
  static const String splash = '/splash';
  static const String login = '/login';
  static const String signup = '/signup';
  static const String riskAssessment = '/risk-assessment';
  static const String home = '/home';
  static const String stockDetail = '/stock-detail';
}
