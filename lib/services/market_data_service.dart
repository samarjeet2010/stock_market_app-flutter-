import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'dart:math';
import 'package:untitled_5/models/stock_model.dart';

class MarketDataService extends ChangeNotifier {
  List<StockModel> _allStocks = [];
  bool _isLoading = false;
  DateTime? _lastUpdate;

  List<StockModel> get allStocks => _allStocks;
  bool get isLoading => _isLoading;
  DateTime? get lastUpdate => _lastUpdate;

  static const String _stocksKey = 'market_stocks';

  final List<Map<String, String>> _stockData = [
    {'symbol': 'AAPL', 'name': 'Apple Inc.', 'sector': 'Technology'},
    {'symbol': 'GOOGL', 'name': 'Alphabet Inc.', 'sector': 'Technology'},
    {'symbol': 'MSFT', 'name': 'Microsoft Corporation', 'sector': 'Technology'},
    {'symbol': 'AMZN', 'name': 'Amazon.com Inc.', 'sector': 'Consumer'},
    {'symbol': 'TSLA', 'name': 'Tesla Inc.', 'sector': 'Automotive'},
    {'symbol': 'META', 'name': 'Meta Platforms Inc.', 'sector': 'Technology'},
    {'symbol': 'NVDA', 'name': 'NVIDIA Corporation', 'sector': 'Technology'},
    {'symbol': 'JPM', 'name': 'JPMorgan Chase & Co.', 'sector': 'Finance'},
    {'symbol': 'V', 'name': 'Visa Inc.', 'sector': 'Finance'},
    {'symbol': 'WMT', 'name': 'Walmart Inc.', 'sector': 'Retail'},
    {'symbol': 'DIS', 'name': 'The Walt Disney Company', 'sector': 'Entertainment'},
    {'symbol': 'NFLX', 'name': 'Netflix Inc.', 'sector': 'Entertainment'},
    {'symbol': 'BA', 'name': 'Boeing Company', 'sector': 'Aerospace'},
    {'symbol': 'NKE', 'name': 'Nike Inc.', 'sector': 'Consumer'},
    {'symbol': 'INTC', 'name': 'Intel Corporation', 'sector': 'Technology'},
    // India Large Caps
    {'symbol': 'RELIANCE', 'name': 'Reliance Industries', 'sector': 'Energy'},
    {'symbol': 'TCS', 'name': 'Tata Consultancy Services', 'sector': 'Technology'},
    {'symbol': 'HDFCBANK', 'name': 'HDFC Bank', 'sector': 'Finance'},
    {'symbol': 'INFY', 'name': 'Infosys', 'sector': 'Technology'},
    {'symbol': 'ICICIBANK', 'name': 'ICICI Bank', 'sector': 'Finance'},
    {'symbol': 'SBIN', 'name': 'State Bank of India', 'sector': 'Finance'},
    {'symbol': 'HINDUNILVR', 'name': 'Hindustan Unilever', 'sector': 'Consumer'},
    {'symbol': 'ITC', 'name': 'ITC Limited', 'sector': 'Consumer'},
    {'symbol': 'BHARTIARTL', 'name': 'Bharti Airtel', 'sector': 'Telecom'},
    {'symbol': 'KOTAKBANK', 'name': 'Kotak Mahindra Bank', 'sector': 'Finance'},
    {'symbol': 'LTIM', 'name': 'LTIMindtree', 'sector': 'Technology'},
    {'symbol': 'WIPRO', 'name': 'Wipro', 'sector': 'Technology'},
    {'symbol': 'TATASTEEL', 'name': 'Tata Steel', 'sector': 'Metals'},
    {'symbol': 'TATAMOTORS', 'name': 'Tata Motors', 'sector': 'Automotive'},
    {'symbol': 'ADANIENT', 'name': 'Adani Enterprises', 'sector': 'Conglomerate'},
    {'symbol': 'ASIANPAINT', 'name': 'Asian Paints', 'sector': 'Consumer'},
    {'symbol': 'MARUTI', 'name': 'Maruti Suzuki', 'sector': 'Automotive'},
    {'symbol': 'SUNPHARMA', 'name': 'Sun Pharma', 'sector': 'Healthcare'},
    {'symbol': 'ONGC', 'name': 'ONGC', 'sector': 'Energy'},
    {'symbol': 'NTPC', 'name': 'NTPC', 'sector': 'Utilities'},
    {'symbol': 'ULTRACEMCO', 'name': 'UltraTech Cement', 'sector': 'Materials'},
  ];

  Future<void> initialize() async {
    _isLoading = true;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      final stocksJson = prefs.getString(_stocksKey);

      if (stocksJson != null) {
        final stocksList = List<Map<String, dynamic>>.from(jsonDecode(stocksJson));
        _allStocks = stocksList.map((json) => StockModel.fromJson(json)).toList();
        _lastUpdate = _allStocks.isNotEmpty ? _allStocks.first.updatedAt : null;
      } else {
        await _generateInitialData();
      }
    } catch (e) {
      debugPrint('Failed to load stocks: $e');
      await _generateInitialData();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _generateInitialData() async {
    final random = Random();
    _allStocks = _stockData.map((data) {
      final basePrice = 50 + random.nextDouble() * 450;
      // Generate a price history using a random walk
      final historyLength = 60; // last 60 points
      final List<double> history = [];
      var price = basePrice;
      for (int i = 0; i < historyLength; i++) {
        final step = (random.nextDouble() * 4 - 2); // -2 to +2 move
        price = (price + step).clamp(1.0, 1000000.0);
        history.add(double.parse(price.toStringAsFixed(2)));
      }
      final current = history.last;
      final change = current - history.first;
      final changePercent = (change / history.first) * 100;

      return StockModel(
        symbol: data['symbol']!,
        name: data['name']!,
        currentPrice: current,
        change: change,
        changePercent: changePercent,
        volume: 1000000 + random.nextInt(9000000),
        marketCap: current * (500000000 + random.nextInt(1500000000)),
        high: history.reduce(max),
        low: history.reduce(min),
        sector: data['sector'],
        description: 'Leading company in ${data['sector']} sector',
        updatedAt: DateTime.now(),
        priceHistory: history,
      );
    }).toList();

    _lastUpdate = DateTime.now();
    await _saveToStorage();
  }

  Future<void> refreshPrices() async {
    if (_allStocks.isEmpty) return;

    final random = Random();
    _allStocks = _allStocks.map((stock) {
      final priceChange = (random.nextDouble() * 4 - 2);
      final newPrice = (stock.currentPrice + priceChange).clamp(1.0, 1000000000.0);
      final newHistory = List<double>.from(stock.priceHistory)..add(double.parse(newPrice.toStringAsFixed(2)));
      if (newHistory.length > 120) {
        newHistory.removeAt(0);
      }
      final change = newPrice - newHistory.first;
      final changePercent = (change / newHistory.first) * 100;

      return stock.copyWith(
        currentPrice: newPrice,
        change: change,
        changePercent: changePercent,
        volume: stock.volume + random.nextInt(100000),
        high: max(stock.high ?? newPrice, newPrice),
        low: min(stock.low ?? newPrice, newPrice),
        updatedAt: DateTime.now(),
        priceHistory: newHistory,
      );
    }).toList();

    _lastUpdate = DateTime.now();
    await _saveToStorage();
    notifyListeners();
  }

  StockModel? getStock(String symbol) {
    try {
      return _allStocks.firstWhere((s) => s.symbol == symbol);
    } catch (e) {
      return null;
    }
  }

  List<StockModel> searchStocks(String query) {
    if (query.isEmpty) return _allStocks;
    final lowerQuery = query.toLowerCase();
    return _allStocks.where((stock) =>
    stock.symbol.toLowerCase().contains(lowerQuery) ||
        stock.name.toLowerCase().contains(lowerQuery)
    ).toList();
  }

  Future<void> _saveToStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final stocksList = _allStocks.map((s) => s.toJson()).toList();
      await prefs.setString(_stocksKey, jsonEncode(stocksList));
    } catch (e) {
      debugPrint('Failed to save stocks: $e');
    }
  }
}
