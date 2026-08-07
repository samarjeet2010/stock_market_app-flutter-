import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:untitled_5/services/auth_service.dart';
import 'package:untitled_5/services/wallet_service.dart';
import 'package:untitled_5/theme.dart';
import 'package:untitled_5/utils/formatters.dart';

class AddMoneyScreen extends StatefulWidget {
  const AddMoneyScreen({super.key});

  @override
  State<AddMoneyScreen> createState() => _AddMoneyScreenState();
}

class _AddMoneyScreenState extends State<AddMoneyScreen> {
  final _controller = TextEditingController();
  final List<int> _quickAmounts = const [1000, 5000, 10000, 25000, 50000, 100000];
  late final Razorpay _razorpay;
  String? _pendingRazorpayOrderId;
  String? _pendingMockOrderId;
  bool _processing = false;

  @override
  void initState() {
    super.initState();
    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _onPaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _onPaymentError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _onExternalWallet);
  }

  @override
  void dispose() {
    _razorpay.clear();
    _controller.dispose();
    super.dispose();
  }

  double? get _amount => double.tryParse(_controller.text.trim());

  Future<void> _startPayment() async {
    final amount = _amount;
    if (amount == null || amount < 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a valid amount')),
      );
      return;
    }

    setState(() => _processing = true);
    final wallet = context.read<WalletService>();
    final order = await wallet.createOrder(amount);
    if (!mounted) return;

    if (order == null) {
      setState(() => _processing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not start payment. Please try again.')),
      );
      return;
    }

    if (order.mock) {
      // No Razorpay keys configured on the backend — credit instantly in
      // mock/test mode so the flow is still fully testable end-to-end.
      _pendingMockOrderId = order.orderId;
      await _finishMock();
      return;
    }

    _pendingRazorpayOrderId = order.razorpayOrderId;
    final user = context.read<AuthService>().currentUser;

    final options = {
      'key': order.razorpayKeyId,
      'amount': (order.amount * 100).round(), // paise
      'order_id': order.razorpayOrderId,
      'name': 'MarketSage',
      'description': 'Add money to wallet',
      'prefill': {
        'email': user?.email ?? '',
      },
      'theme': {'color': '#1E3A5F'},
    };

    try {
      _razorpay.open(options);
    } catch (e) {
      setState(() => _processing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not open payment screen: $e')),
      );
    }
  }

  Future<void> _finishMock() async {
    final wallet = context.read<WalletService>();
    final result = await wallet.confirmMock(_pendingMockOrderId!);
    if (!mounted) return;
    setState(() => _processing = false);
    _showResult(result.success, result.message);
  }

  void _onPaymentSuccess(PaymentSuccessResponse response) async {
    final wallet = context.read<WalletService>();
    final result = await wallet.verifyPayment(
      razorpayOrderId: response.orderId ?? _pendingRazorpayOrderId ?? '',
      razorpayPaymentId: response.paymentId ?? '',
      razorpaySignature: response.signature ?? '',
    );
    if (!mounted) return;
    setState(() => _processing = false);
    _showResult(result.success, result.message);
  }

  void _onPaymentError(PaymentFailureResponse response) {
    if (!mounted) return;
    setState(() => _processing = false);
    _showResult(false, response.message ?? 'Payment failed or was cancelled');
  }

  void _onExternalWallet(ExternalWalletResponse response) {
    if (!mounted) return;
    setState(() => _processing = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Opened external wallet: ${response.walletName}')),
    );
  }

  void _showResult(bool success, String message) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        icon: Icon(
          success ? Icons.check_circle : Icons.error_outline,
          color: success ? LightModeColors.profitGreen : LightModeColors.lossRed,
          size: 40,
        ),
        title: Text(success ? 'Money Added' : 'Payment Failed'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              if (success) context.pop();
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthService>().currentUser;

    return Scaffold(
      appBar: AppBar(title: const Text('Add Money')),
      body: SingleChildScrollView(
        padding: AppSpacing.paddingLg,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              child: Padding(
                padding: AppSpacing.paddingLg,
                child: Column(
                  children: [
                    Text('Current Balance', style: context.textStyles.bodyMedium?.withColor(
                      Theme.of(context).colorScheme.onSurfaceVariant,
                    )),
                    const SizedBox(height: 4),
                    Text(
                      Formatters.inr(user?.virtualBalance ?? 0),
                      style: context.textStyles.headlineMedium?.bold,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            Text('Enter Amount', style: context.textStyles.titleMedium?.semiBold),
            const SizedBox(height: AppSpacing.sm),
            TextField(
              controller: _controller,
              keyboardType: const TextInputType.numberWithOptions(decimal: false),
              style: context.textStyles.headlineSmall?.bold,
              decoration: InputDecoration(
                prefixText: '₹ ',
                hintText: '0',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
              ),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: AppSpacing.md),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _quickAmounts.map((a) {
                return ActionChip(
                  label: Text(Formatters.inr(a, decimals: 0)),
                  onPressed: () => setState(() => _controller.text = a.toString()),
                );
              }).toList(),
            ),
            const SizedBox(height: AppSpacing.xl),
            Card(
              color: Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.3),
              child: Padding(
                padding: AppSpacing.paddingMd,
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: Theme.of(context).colorScheme.primary),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Text(
                        'This adds virtual cash for paper trading. Payments are processed securely via Razorpay.',
                        style: context.textStyles.bodySmall,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            FilledButton(
              onPressed: (_amount != null && _amount! >= 1 && !_processing) ? _startPayment : null,
              style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
              child: _processing
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : Text('Proceed to Pay${_amount != null && _amount! >= 1 ? ' ${Formatters.inr(_amount!, decimals: 0)}' : ''}'),
            ),
          ],
        ),
      ),
    );
  }
}
