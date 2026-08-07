import 'package:flutter/foundation.dart';
import 'package:untitled_5/models/position_model.dart';
import 'package:untitled_5/models/transaction_model.dart';
import 'package:untitled_5/services/api_client.dart';
import 'package:untitled_5/services/market_data_service.dart';

class PortfolioService extends ChangeNotifier {
  final ApiClient _api = ApiClient.instance;

  List<PositionModel> _positions = [];
  List<TransactionModel> _transactions = [];
  bool _isLoading = false;

  List<PositionModel> get positions => _positions;
  List<TransactionModel> get transactions => _transactions;
  bool get isLoading => _isLoading;

  double get totalInvested => _positions.fold(0.0, (sum, p) => sum + p.totalInvested);
  double get currentValue => _positions.fold(0.0, (sum, p) => sum + p.currentValue);
  double get totalProfitLoss => currentValue - totalInvested;
  double get totalProfitLossPercent => totalInvested > 0 ? (totalProfitLoss / totalInvested) * 100 : 0.0;

  /// Loads this user's positions & transactions from the backend.
  /// [userId] is kept in the signature for compatibility with existing
  /// call sites, but auth is actually handled via the bearer token.
  Future<void> initialize(String userId) async {
    _isLoading = true;
    notifyListeners();
    await refresh();
    _isLoading = false;
    notifyListeners();
  }

  /// Re-fetches positions and transactions from the backend, e.g. after a
  /// buy/sell trade completes server-side.
  Future<void> refresh() async {
    try {
      final positionsResp = await _api.get('/portfolio/positions');
      if (positionsResp.ok) {
        final list = (positionsResp.data['positions'] as List).cast<Map<String, dynamic>>();
        _positions = list.map((json) => PositionModel.fromJson(json)).toList();
      }

      final txResp = await _api.get('/portfolio/transactions');
      if (txResp.ok) {
        final list = (txResp.data['transactions'] as List).cast<Map<String, dynamic>>();
        _transactions = list.map((json) => TransactionModel.fromJson(json)).toList();
      }
      notifyListeners();
    } catch (e) {
      debugPrint('Failed to load portfolio: $e');
    }
  }

  /// Updates locally cached position prices from the latest market data
  /// without hitting the backend again (used right after
  /// MarketDataService.refreshPrices()).
  Future<void> updatePrices(MarketDataService marketService) async {
    for (int i = 0; i < _positions.length; i++) {
      final stock = marketService.getStock(_positions[i].symbol);
      if (stock != null) {
        _positions[i] = _positions[i].copyWith(
          currentPrice: stock.currentPrice,
          updatedAt: DateTime.now(),
        );
      }
    }
    notifyListeners();
  }

  PositionModel? getPosition(String symbol) {
    try {
      return _positions.firstWhere((p) => p.symbol == symbol);
    } catch (e) {
      return null;
    }
  }

  List<TransactionModel> getRecentTransactions({int limit = 10}) {
    final sorted = List<TransactionModel>.from(_transactions)
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return sorted.take(limit).toList();
  }
}
