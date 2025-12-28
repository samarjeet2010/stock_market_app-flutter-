import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:untitled_5/models/position_model.dart';
import 'package:untitled_5/models/transaction_model.dart';
import 'package:untitled_5/services/market_data_service.dart';

class PortfolioService extends ChangeNotifier {
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

  static const String _positionsKey = 'user_positions';
  static const String _transactionsKey = 'user_transactions';

  Future<void> initialize(String userId) async {
    _isLoading = true;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();

      final positionsJson = prefs.getString('${_positionsKey}_$userId');
      if (positionsJson != null) {
        final positionsList = List<Map<String, dynamic>>.from(jsonDecode(positionsJson));
        _positions = positionsList.map((json) => PositionModel.fromJson(json)).toList();
      }

      final transactionsJson = prefs.getString('${_transactionsKey}_$userId');
      if (transactionsJson != null) {
        final transactionsList = List<Map<String, dynamic>>.from(jsonDecode(transactionsJson));
        _transactions = transactionsList.map((json) => TransactionModel.fromJson(json)).toList();
      }
    } catch (e) {
      debugPrint('Failed to load portfolio: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

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

  Future<void> addTransaction(TransactionModel transaction, String userId) async {
    _transactions.add(transaction);
    await _saveTransactions(userId);
    notifyListeners();
  }

  Future<void> updatePosition(PositionModel position, String userId) async {
    final index = _positions.indexWhere((p) => p.symbol == position.symbol);
    if (index >= 0) {
      _positions[index] = position;
    } else {
      _positions.add(position);
    }
    await _savePositions(userId);
    notifyListeners();
  }

  Future<void> removePosition(String symbol, String userId) async {
    _positions.removeWhere((p) => p.symbol == symbol);
    await _savePositions(userId);
    notifyListeners();
  }

  Future<void> _savePositions(String userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final positionsList = _positions.map((p) => p.toJson()).toList();
      await prefs.setString('${_positionsKey}_$userId', jsonEncode(positionsList));
    } catch (e) {
      debugPrint('Failed to save positions: $e');
    }
  }

  Future<void> _saveTransactions(String userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final transactionsList = _transactions.map((t) => t.toJson()).toList();
      await prefs.setString('${_transactionsKey}_$userId', jsonEncode(transactionsList));
    } catch (e) {
      debugPrint('Failed to save transactions: $e');
    }
  }
}
