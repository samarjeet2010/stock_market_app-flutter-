import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:untitled_5/services/auth_service.dart';
import 'package:untitled_5/theme.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  double _opacity = 0;
  double _scale = 0.92;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      setState(() {
        _opacity = 1;
        _scale = 1.0;
      });
    });

    _timer = Timer(const Duration(milliseconds: 1400), () {
      if (!mounted) return;
      final isLoggedIn = context.read<AuthService>().isLoggedIn;
      context.go(isLoggedIn ? '/home' : '/login');
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              colors.primaryContainer,
              colors.primary.withValues(alpha: 0.1),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Center(
          child: AnimatedOpacity(
            opacity: _opacity,
            duration: const Duration(milliseconds: 600),
            curve: Curves.easeOut,
            child: AnimatedScale(
              scale: _scale,
              duration: const Duration(milliseconds: 700),
              curve: Curves.easeOutBack,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: colors.surface,
                      borderRadius: BorderRadius.circular(AppRadius.xl),
                      border: Border.all(color: colors.outline.withValues(alpha: 0.25)),
                    ),
                    child: Icon(Icons.trending_up, size: 48, color: colors.primary),
                  ),
                  const SizedBox(height: 16),
                  Text('MarketSage', style: Theme.of(context).textTheme.headlineLarge?.bold),
                  const SizedBox(height: 8),
                  Text(
                    'AI-Powered Paper Trading',
                    style: Theme.of(context).textTheme.labelLarge?.withColor(colors.onSurfaceVariant),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
