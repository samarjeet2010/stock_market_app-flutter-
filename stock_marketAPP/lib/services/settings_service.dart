import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsService extends ChangeNotifier {
  static const _notifKey = 'settings_notifications';
  static const _weeklyKey = 'settings_weekly_summary';
  static const _themeKey = 'settings_theme_mode';

  bool notificationsEnabled = true;
  bool weeklySummaryEnabled = false;
  ThemeMode themeMode = ThemeMode.system;

  Future<void> initialize() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      notificationsEnabled = prefs.getBool(_notifKey) ?? true;
      weeklySummaryEnabled = prefs.getBool(_weeklyKey) ?? false;
      final themeString = prefs.getString(_themeKey);
      switch (themeString) {
        case 'light':
          themeMode = ThemeMode.light;
          break;
        case 'dark':
          themeMode = ThemeMode.dark;
          break;
        default:
          themeMode = ThemeMode.system;
      }
    } catch (e) {
      debugPrint('Settings init error: $e');
    } finally {
      notifyListeners();
    }
  }

  Future<void> setNotifications(bool value) async {
    notificationsEnabled = value;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_notifKey, value);
    } catch (e) {
      debugPrint('Settings save error: $e');
    }
  }

  Future<void> setWeeklySummary(bool value) async {
    weeklySummaryEnabled = value;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_weeklyKey, value);
    } catch (e) {
      debugPrint('Settings save error: $e');
    }
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    themeMode = mode;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      final value = switch (mode) {
        ThemeMode.light => 'light',
        ThemeMode.dark => 'dark',
        _ => 'system',
      };
      await prefs.setString(_themeKey, value);
    } catch (e) {
      debugPrint('Settings save error: $e');
    }
  }
}
