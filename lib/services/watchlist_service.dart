import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class WatchlistService extends ChangeNotifier {
  List<String> _watchlist = [];
  bool _isLoading = false;

  List<String> get watchlist => _watchlist;
  bool get isLoading => _isLoading;

  static const String _watchlistKey = 'user_watchlist';

  Future<void> initialize(String userId) async {
    _isLoading = true;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      final watchlistJson = prefs.getString('${_watchlistKey}_$userId');

      if (watchlistJson != null) {
        _watchlist = List<String>.from(jsonDecode(watchlistJson));
      } else {
        _watchlist = ['AAPL', 'GOOGL', 'MSFT', 'TSLA'];
        await _saveWatchlist(userId);
      }
    } catch (e) {
      debugPrint('Failed to load watchlist: $e');
      _watchlist = ['AAPL', 'GOOGL', 'MSFT', 'TSLA'];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  bool isInWatchlist(String symbol) => _watchlist.contains(symbol);

  Future<void> addToWatchlist(String symbol, String userId) async {
    if (!_watchlist.contains(symbol)) {
      _watchlist.add(symbol);
      await _saveWatchlist(userId);
      notifyListeners();
    }
  }

  Future<void> removeFromWatchlist(String symbol, String userId) async {
    _watchlist.remove(symbol);
    await _saveWatchlist(userId);
    notifyListeners();
  }

  Future<void> _saveWatchlist(String userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('${_watchlistKey}_$userId', jsonEncode(_watchlist));
    } catch (e) {
      debugPrint('Failed to save watchlist: $e');
    }
  }
}
