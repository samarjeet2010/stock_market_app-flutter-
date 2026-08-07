import 'package:flutter/foundation.dart';
import 'package:untitled_5/models/stock_model.dart';
import 'package:untitled_5/services/api_client.dart';
import 'package:untitled_5/services/auth_service.dart';
import 'package:untitled_5/services/portfolio_service.dart';
import 'package:untitled_5/services/market_data_service.dart';

class TradingService extends ChangeNotifier {
  final AuthService _authService;
  final PortfolioService _portfolioService;
  final MarketDataService _marketService;
  final ApiClient _api = ApiClient.instance;

  TradingService(this._authService, this._portfolioService, this._marketService);

  Future<TradingResult> buyStock(String symbol, int quantity) async {
    if (!_authService.isLoggedIn) {
      return TradingResult(success: false, message: 'User not logged in');
    }
    try {
      final resp = await _api.post('/trading/buy', {'symbol': symbol, 'quantity': quantity});
      if (resp.ok && resp.data['success'] == true) {
        await _portfolioService.refresh();
        await _authService.refreshUser();
        return TradingResult(success: true, message: resp.data['message'] as String);
      }
      return TradingResult(success: false, message: resp.errorMessage);
    } catch (e) {
      debugPrint('Buy error: $e');
      return TradingResult(success: false, message: 'Transaction failed: $e');
    }
  }

  Future<TradingResult> sellStock(String symbol, int quantity) async {
    if (!_authService.isLoggedIn) {
      return TradingResult(success: false, message: 'User not logged in');
    }
    try {
      final resp = await _api.post('/trading/sell', {'symbol': symbol, 'quantity': quantity});
      if (resp.ok && resp.data['success'] == true) {
        await _portfolioService.refresh();
        await _authService.refreshUser();
        return TradingResult(success: true, message: resp.data['message'] as String);
      }
      return TradingResult(success: false, message: resp.errorMessage);
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
