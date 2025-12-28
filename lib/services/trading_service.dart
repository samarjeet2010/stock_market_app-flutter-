import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import 'package:untitled_5/models/stock_model.dart';
import 'package:untitled_5/models/position_model.dart';
import 'package:untitled_5/models/transaction_model.dart';
import 'package:untitled_5/services/auth_service.dart';
import 'package:untitled_5/services/portfolio_service.dart';
import 'package:untitled_5/services/market_data_service.dart';

class TradingService extends ChangeNotifier {
  final AuthService _authService;
  final PortfolioService _portfolioService;
  final MarketDataService _marketService;

  TradingService(this._authService, this._portfolioService, this._marketService);

  Future<TradingResult> buyStock(String symbol, int quantity) async {
    try {
      final user = _authService.currentUser;
      if (user == null) {
        return TradingResult(success: false, message: 'User not logged in');
      }

      final stock = _marketService.getStock(symbol);
      if (stock == null) {
        return TradingResult(success: false, message: 'Stock not found');
      }

      final totalCost = stock.currentPrice * quantity;
      if (user.virtualBalance < totalCost) {
        return TradingResult(success: false, message: 'Insufficient balance');
      }

      final transaction = TransactionModel(
        transactionId: const Uuid().v4(),
        userId: user.userId,
        symbol: stock.symbol,
        stockName: stock.name,
        type: 'buy',
        quantity: quantity,
        price: stock.currentPrice,
        totalAmount: totalCost,
        timestamp: DateTime.now(),
      );

      await _portfolioService.addTransaction(transaction, user.userId);

      final existingPosition = _portfolioService.getPosition(symbol);
      if (existingPosition != null) {
        final newQuantity = existingPosition.quantity + quantity;
        final newAvgPrice = ((existingPosition.avgBuyPrice * existingPosition.quantity) + totalCost) / newQuantity;

        await _portfolioService.updatePosition(
          existingPosition.copyWith(
            quantity: newQuantity,
            avgBuyPrice: newAvgPrice,
            currentPrice: stock.currentPrice,
            updatedAt: DateTime.now(),
          ),
          user.userId,
        );
      } else {
        await _portfolioService.updatePosition(
          PositionModel(
            symbol: stock.symbol,
            stockName: stock.name,
            quantity: quantity,
            avgBuyPrice: stock.currentPrice,
            currentPrice: stock.currentPrice,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
          user.userId,
        );
      }

      await _authService.updateBalance(user.virtualBalance - totalCost);

      return TradingResult(
        success: true,
        message: 'Successfully bought $quantity shares of ${stock.symbol}',
      );
    } catch (e) {
      debugPrint('Buy error: $e');
      return TradingResult(success: false, message: 'Transaction failed: $e');
    }
  }

  Future<TradingResult> sellStock(String symbol, int quantity) async {
    try {
      final user = _authService.currentUser;
      if (user == null) {
        return TradingResult(success: false, message: 'User not logged in');
      }

      final stock = _marketService.getStock(symbol);
      if (stock == null) {
        return TradingResult(success: false, message: 'Stock not found');
      }

      final position = _portfolioService.getPosition(symbol);
      if (position == null) {
        return TradingResult(success: false, message: 'You do not own this stock');
      }

      if (position.quantity < quantity) {
        return TradingResult(success: false, message: 'Insufficient shares to sell');
      }

      final totalValue = stock.currentPrice * quantity;

      final transaction = TransactionModel(
        transactionId: const Uuid().v4(),
        userId: user.userId,
        symbol: stock.symbol,
        stockName: stock.name,
        type: 'sell',
        quantity: quantity,
        price: stock.currentPrice,
        totalAmount: totalValue,
        timestamp: DateTime.now(),
      );

      await _portfolioService.addTransaction(transaction, user.userId);

      if (position.quantity == quantity) {
        await _portfolioService.removePosition(symbol, user.userId);
      } else {
        await _portfolioService.updatePosition(
          position.copyWith(
            quantity: position.quantity - quantity,
            currentPrice: stock.currentPrice,
            updatedAt: DateTime.now(),
          ),
          user.userId,
        );
      }

      await _authService.updateBalance(user.virtualBalance + totalValue);

      return TradingResult(
        success: true,
        message: 'Successfully sold $quantity shares of ${stock.symbol}',
      );
    } catch (e) {
      debugPrint('Sell error: $e');
      return TradingResult(success: false, message: 'Transaction failed: $e');
    }
  }

  bool canBuy(StockModel stock, int quantity) {
    final user = _authService.currentUser;
    if (user == null) return false;
    final totalCost = stock.currentPrice * quantity;
    return user.virtualBalance >= totalCost;
  }

  bool canSell(String symbol, int quantity) {
    final position = _portfolioService.getPosition(symbol);
    if (position == null) return false;
    return position.quantity >= quantity;
  }
}

class TradingResult {
  final bool success;
  final String message;

  TradingResult({required this.success, required this.message});
}
