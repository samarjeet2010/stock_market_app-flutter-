import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:untitled_5/theme.dart';
import 'package:untitled_5/nav.dart';
import 'package:untitled_5/services/auth_service.dart';
import 'package:untitled_5/services/market_data_service.dart';
import 'package:untitled_5/services/portfolio_service.dart';
import 'package:untitled_5/services/trading_service.dart';
import 'package:untitled_5/services/watchlist_service.dart';
import 'package:untitled_5/services/settings_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthService()),
        ChangeNotifierProvider(create: (_) => MarketDataService()),
        ChangeNotifierProvider(create: (_) => PortfolioService()),
        ChangeNotifierProvider(create: (_) => WatchlistService()),
        ChangeNotifierProvider(create: (_) => SettingsService()),
        ChangeNotifierProxyProvider3<AuthService, PortfolioService, MarketDataService, TradingService>(
          create: (context) => TradingService(
            context.read<AuthService>(),
            context.read<PortfolioService>(),
            context.read<MarketDataService>(),
          ),
          update: (context, auth, portfolio, market, previous) => TradingService(auth, portfolio, market),
        ),
      ],
      child: const AppInitializer(),
    );
  }
}

class AppInitializer extends StatefulWidget {
  const AppInitializer({super.key});

  @override
  State<AppInitializer> createState() => _AppInitializerState();
}

class _AppInitializerState extends State<AppInitializer> {
  @override
  void initState() {
    super.initState();
    _initializeServices();
  }

  Future<void> _initializeServices() async {
    final authService = context.read<AuthService>();
    final marketService = context.read<MarketDataService>();
    final settingsService = context.read<SettingsService>();

    await authService.initialize();
    await marketService.initialize();
    await settingsService.initialize();

    if (authService.isLoggedIn && authService.currentUser != null) {
      final portfolioService = context.read<PortfolioService>();
      final watchlistService = context.read<WatchlistService>();

      await portfolioService.initialize(authService.currentUser!.userId);
      await watchlistService.initialize(authService.currentUser!.userId);
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'MarketSage',
      debugShowCheckedModeBanner: false,
      theme: lightTheme,
      darkTheme: darkTheme,
      themeMode: context.select<SettingsService, ThemeMode>((s) => s.themeMode),
      routerConfig: AppRouter.router,
    );
  }
}
