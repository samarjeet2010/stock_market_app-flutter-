import 'package:flutter/foundation.dart';
import 'package:untitled_5/services/api_client.dart';

class WatchlistService extends ChangeNotifier {
  final ApiClient _api = ApiClient.instance;

  List<String> _watchlist = [];
  bool _isLoading = false;

  List<String> get watchlist => _watchlist;
  bool get isLoading => _isLoading;

  /// [userId] kept for compatibility with existing call sites; auth is
  /// actually handled via the bearer token.
  Future<void> initialize(String userId) async {
    _isLoading = true;
    notifyListeners();

    try {
      final resp = await _api.get('/watchlist');
      if (resp.ok) {
        _watchlist = (resp.data['watchlist'] as List).cast<String>();
      }
    } catch (e) {
      debugPrint('Failed to load watchlist: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  bool isInWatchlist(String symbol) => _watchlist.contains(symbol);

  Future<void> addToWatchlist(String symbol, String userId) async {
    try {
      final resp = await _api.post('/watchlist', {'symbol': symbol});
      if (resp.ok) {
        _watchlist = (resp.data['watchlist'] as List).cast<String>();
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Failed to add to watchlist: $e');
    }
  }

  Future<void> removeFromWatchlist(String symbol, String userId) async {
    try {
      final resp = await _api.delete('/watchlist/$symbol');
      if (resp.ok) {
        _watchlist = (resp.data['watchlist'] as List).cast<String>();
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Failed to remove from watchlist: $e');
    }
  }
}
