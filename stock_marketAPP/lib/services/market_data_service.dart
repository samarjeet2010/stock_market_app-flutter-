import 'package:flutter/foundation.dart';
import 'package:untitled_5/models/stock_model.dart';
import 'package:untitled_5/models/candle_model.dart';
import 'package:untitled_5/services/api_client.dart';

class MarketDataService extends ChangeNotifier {
  final ApiClient _api = ApiClient.instance;

  List<StockModel> _allStocks = [];
  bool _isLoading = false;
  DateTime? _lastUpdate;

  List<StockModel> get allStocks => _allStocks;
  bool get isLoading => _isLoading;
  DateTime? get lastUpdate => _lastUpdate;

  /// Fetches the full stock list from the backend.
  Future<void> initialize() async {
    _isLoading = true;
    notifyListeners();
    await _fetchStocks();
    _isLoading = false;
    notifyListeners();
  }

  /// Re-fetches live prices from the backend. The backend ticks prices on
  /// its own timer, so this just pulls the latest snapshot.
  Future<void> refreshPrices() async {
    await _fetchStocks();
    notifyListeners();
  }

  Future<void> _fetchStocks() async {
    try {
      final resp = await _api.get('/market/stocks');
      if (resp.ok) {
        final list = (resp.data['stocks'] as List).cast<Map<String, dynamic>>();
        _allStocks = list.map((json) => StockModel.fromJson(json)).toList();
        _lastUpdate = DateTime.now();
      }
    } catch (e) {
      debugPrint('Failed to load stocks: $e');
    }
  }

  StockModel? getStock(String symbol) {
    try {
      return _allStocks.firstWhere((s) => s.symbol == symbol);
    } catch (e) {
      return null;
    }
  }

  /// Fetches OHLC candle data for [symbol] over the given [range] (e.g.
  /// "1D", "1W", "1M", "3M", "1Y") for the candlestick chart.
  Future<List<CandleModel>> getCandles(String symbol, ChartRange range) async {
    try {
      final resp = await _api.get('/market/stocks/$symbol/candles?range=${range.apiValue}');
      if (resp.ok) {
        final list = (resp.data['candles'] as List).cast<Map<String, dynamic>>();
        return list.map((json) => CandleModel.fromJson(json)).toList();
      }
    } catch (e) {
      debugPrint('Failed to load candles: $e');
    }
    return [];
  }

  List<StockModel> searchStocks(String query) {
    if (query.isEmpty) return _allStocks;
    final lowerQuery = query.toLowerCase();
    return _allStocks.where((stock) =>
    stock.symbol.toLowerCase().contains(lowerQuery) ||
        stock.name.toLowerCase().contains(lowerQuery)
    ).toList();
  }
}
