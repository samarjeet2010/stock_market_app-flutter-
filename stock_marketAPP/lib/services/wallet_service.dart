import 'package:flutter/foundation.dart';
import 'package:untitled_5/services/api_client.dart';
import 'package:untitled_5/services/auth_service.dart';

/// Result of creating a payment order on the backend.
class WalletOrder {
  final String orderId;
  final double amount;
  final String razorpayOrderId;
  final bool mock;
  final String? razorpayKeyId;

  WalletOrder({
    required this.orderId,
    required this.amount,
    required this.razorpayOrderId,
    required this.mock,
    this.razorpayKeyId,
  });
}

class WalletResult {
  final bool success;
  final String message;

  WalletResult({required this.success, required this.message});
}

/// Talks to /api/wallet/* to top up the user's virtual cash balance.
///
/// Two modes, both handled transparently:
/// - Real Razorpay: the backend has RAZORPAY_KEY_ID/SECRET configured, so
///   createOrder() returns a real Razorpay order that the UI opens via the
///   razorpay_flutter checkout, then calls verifyPayment() with the
///   payment/order/signature Razorpay hands back.
/// - Mock mode: no Razorpay keys configured on the backend, so the server
///   returns a "mock" order and confirmMock() credits the wallet directly —
///   this keeps Add Money fully testable without a real payment gateway
///   account.
class WalletService extends ChangeNotifier {
  final AuthService _authService;
  final ApiClient _api = ApiClient.instance;

  WalletService(this._authService);

  Future<WalletOrder?> createOrder(double amount) async {
    try {
      final resp = await _api.post('/wallet/create-order', {'amount': amount});
      if (!resp.ok) return null;
      final order = resp.data['order'] as Map<String, dynamic>;
      return WalletOrder(
        orderId: order['orderId'] as String,
        amount: (order['amount'] as num).toDouble(),
        razorpayOrderId: order['razorpayOrderId'] as String,
        mock: resp.data['mock'] == true,
        razorpayKeyId: resp.data['razorpayKeyId'] as String?,
      );
    } catch (e) {
      debugPrint('createOrder error: $e');
      return null;
    }
  }

  Future<WalletResult> verifyPayment({
    required String razorpayOrderId,
    required String razorpayPaymentId,
    required String razorpaySignature,
  }) async {
    try {
      final resp = await _api.post('/wallet/verify-payment', {
        'razorpayOrderId': razorpayOrderId,
        'razorpayPaymentId': razorpayPaymentId,
        'razorpaySignature': razorpaySignature,
      });
      if (resp.ok && resp.data['success'] == true) {
        await _authService.refreshUser();
        return WalletResult(success: true, message: 'Money added successfully');
      }
      return WalletResult(success: false, message: resp.errorMessage);
    } catch (e) {
      return WalletResult(success: false, message: 'Verification failed: $e');
    }
  }

  Future<WalletResult> confirmMock(String orderId) async {
    try {
      final resp = await _api.post('/wallet/confirm-mock', {'orderId': orderId});
      if (resp.ok && resp.data['success'] == true) {
        await _authService.refreshUser();
        return WalletResult(success: true, message: 'Money added successfully (test mode)');
      }
      return WalletResult(success: false, message: resp.errorMessage);
    } catch (e) {
      return WalletResult(success: false, message: 'Failed to confirm payment: $e');
    }
  }
}
