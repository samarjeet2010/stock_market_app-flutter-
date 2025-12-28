import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:untitled_5/utils/formatters.dart';
import 'package:go_router/go_router.dart';
import 'package:untitled_5/models/stock_model.dart';
import 'package:untitled_5/services/auth_service.dart';
import 'package:untitled_5/services/watchlist_service.dart';
import 'package:untitled_5/services/trading_service.dart';
import 'package:untitled_5/services/portfolio_service.dart';
import 'package:untitled_5/services/market_data_service.dart';
import 'package:untitled_5/theme.dart';
import 'package:fl_chart/fl_chart.dart';

class StockDetailScreen extends StatefulWidget {
  final StockModel stock;

  const StockDetailScreen({super.key, required this.stock});

  @override
  State<StockDetailScreen> createState() => _StockDetailScreenState();
}

class _StockDetailScreenState extends State<StockDetailScreen> {
  int _quantity = 1;
  Timer? _liveTimer;

  void _showBuyDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => BuyDialog(
        stock: widget.stock,
        initialQuantity: _quantity,
        onQuantityChanged: (qty) => setState(() => _quantity = qty),
      ),
    );
  }

  void _showSellDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => SellDialog(
        stock: widget.stock,
        initialQuantity: _quantity,
        onQuantityChanged: (qty) => setState(() => _quantity = qty),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authService = context.watch<AuthService>();
    final watchlistService = context.watch<WatchlistService>();
    final portfolioService = context.watch<PortfolioService>();
    final marketService = context.read<MarketDataService>();
    _liveTimer ??= Timer.periodic(const Duration(seconds: 3), (_) async {
      await marketService.refreshPrices();
      if (mounted) {
        await context.read<PortfolioService>().updatePrices(marketService);
      }
    });

    final user = authService.currentUser;
    final isInWatchlist = watchlistService.isInWatchlist(widget.stock.symbol);
    final position = portfolioService.getPosition(widget.stock.symbol);
    final isPositive = widget.stock.isPositive;
    final changeColor = isPositive ? LightModeColors.profitGreen : LightModeColors.lossRed;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        actions: [
          IconButton(
            icon: Icon(isInWatchlist ? Icons.star : Icons.star_border),
            onPressed: () {
              if (isInWatchlist) {
                watchlistService.removeFromWatchlist(widget.stock.symbol, user!.userId);
              } else {
                watchlistService.addToWatchlist(widget.stock.symbol, user!.userId);
              }
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: AppSpacing.paddingLg,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                  child: Center(
                    child: Text(
                      widget.stock.symbol.substring(0, 1),
                      style: context.textStyles.headlineMedium?.bold.withColor(
                        Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(widget.stock.symbol, style: context.textStyles.headlineSmall?.bold),
                      Text(
                        widget.stock.name,
                        style: context.textStyles.bodyLarge?.withColor(
                          Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xl),
            // Price history chart
            Card(
              child: Padding(
                padding: AppSpacing.paddingMd,
                child: SizedBox(
                  height: 200,
                  child: Builder(builder: (context) {
                    final prices = widget.stock.priceHistory;
                    // Simple moving average (SMA)
                    List<double> sma(int window) {
                      final out = <double>[];
                      for (int i = 0; i < prices.length; i++) {
                        final start = (i - window + 1).clamp(0, prices.length - 1);
                        final slice = prices.sublist(start as int, i + 1);
                        out.add(slice.reduce((a, b) => a + b) / slice.length);
                      }
                      return out;
                    }
                    final sma8 = sma(8);

                    // Trade markers from transactions
                    final now = DateTime.now();
                    final symbolTx = portfolioService.transactions.where((t) => t.symbol == widget.stock.symbol).toList();
                    final maxIdx = prices.length - 1;
                    List<FlSpot> buySpots = [];
                    List<FlSpot> sellSpots = [];
                    for (final t in symbolTx) {
                      final secondsAgo = now.difference(t.timestamp).inSeconds;
                      final idx = (maxIdx - (secondsAgo ~/ 10)).clamp(0, maxIdx).toDouble();
                      final y = t.price;
                      if (t.isBuy) {
                        buySpots.add(FlSpot(idx, y));
                      } else {
                        sellSpots.add(FlSpot(idx, y));
                      }
                    }

                    return LineChart(
                      LineChartData(
                        gridData: FlGridData(show: true, drawVerticalLine: false, horizontalInterval: 1, getDrawingHorizontalLine: (value) => FlLine(color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.08), strokeWidth: 1)),
                        titlesData: FlTitlesData(show: false),
                        borderData: FlBorderData(show: false),
                        lineBarsData: [
                          // Price line
                          LineChartBarData(
                            spots: [
                              for (int i = 0; i < prices.length; i++) FlSpot(i.toDouble(), prices[i])
                            ],
                            isCurved: true,
                            color: isPositive ? LightModeColors.profitGreen : LightModeColors.lossRed,
                            barWidth: 2,
                            dotData: const FlDotData(show: false),
                            belowBarData: BarAreaData(
                              show: true,
                              color: (isPositive ? LightModeColors.profitGreen : LightModeColors.lossRed).withValues(alpha: 0.08),
                            ),
                          ),
                          // SMA overlay
                          LineChartBarData(
                            spots: [
                              for (int i = 0; i < sma8.length; i++) FlSpot(i.toDouble(), sma8[i])
                            ],
                            isCurved: true,
                            color: Theme.of(context).colorScheme.primary,
                            barWidth: 1.5,
                            dotData: const FlDotData(show: false),
                          ),
                          // Buy markers
                          if (buySpots.isNotEmpty)
                            LineChartBarData(
                              spots: buySpots,
                              isCurved: false,
                              color: Colors.transparent,
                              barWidth: 0,
                              dotData: FlDotData(show: true, getDotPainter: (spot, percent, bar, index) => FlDotCirclePainter(radius: 3.5, color: LightModeColors.profitGreen, strokeWidth: 1.5, strokeColor: Colors.white)),
                            ),
                          // Sell markers
                          if (sellSpots.isNotEmpty)
                            LineChartBarData(
                              spots: sellSpots,
                              isCurved: false,
                              color: Colors.transparent,
                              barWidth: 0,
                              dotData: FlDotData(show: true, getDotPainter: (spot, percent, bar, index) => FlDotCirclePainter(radius: 3.5, color: LightModeColors.lossRed, strokeWidth: 1.5, strokeColor: Colors.white)),
                            ),
                        ],
                      ),
                    );
                  }),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              Formatters.inr(widget.stock.currentPrice),
              style: context.textStyles.displaySmall?.bold,
            ),
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                Icon(
                  isPositive ? Icons.trending_up : Icons.trending_down,
                  color: changeColor,
                  size: 24,
                ),
                const SizedBox(width: 4),
                Text(
                  '${isPositive ? '+' : ''}${Formatters.inr(widget.stock.change)}',
                  style: context.textStyles.titleLarge?.semiBold.withColor(changeColor),
                ),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  '(${isPositive ? '+' : ''}${widget.stock.changePercent.toStringAsFixed(2)}%)',
                  style: context.textStyles.titleMedium?.withColor(changeColor),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xl),
            if (position != null) ...[
              Card(
                child: Padding(
                  padding: AppSpacing.paddingMd,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Your Position', style: context.textStyles.titleMedium?.semiBold),
                      const SizedBox(height: AppSpacing.md),
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Quantity', style: context.textStyles.bodySmall?.withColor(
                                  Theme.of(context).colorScheme.onSurfaceVariant,
                                )),
                                Text('${position.quantity} shares', style: context.textStyles.bodyLarge?.semiBold),
                              ],
                            ),
                          ),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Avg Cost', style: context.textStyles.bodySmall?.withColor(
                                  Theme.of(context).colorScheme.onSurfaceVariant,
                                )),
                                Text(
                                  NumberFormat.currency(symbol: '\$', decimalDigits: 2).format(position.avgBuyPrice),
                                  style: context.textStyles.bodyLarge?.semiBold,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.md),
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Current Value', style: context.textStyles.bodySmall?.withColor(
                                  Theme.of(context).colorScheme.onSurfaceVariant,
                                )),
                                Text(
                                  NumberFormat.currency(symbol: '\$', decimalDigits: 2).format(position.currentValue),
                                  style: context.textStyles.bodyLarge?.semiBold,
                                ),
                              ],
                            ),
                          ),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('P&L', style: context.textStyles.bodySmall?.withColor(
                                  Theme.of(context).colorScheme.onSurfaceVariant,
                                )),
                                Text(
                                  '${position.isProfit ? '+' : ''}${NumberFormat.currency(symbol: '\$', decimalDigits: 2).format(position.profitLoss)}',
                                  style: context.textStyles.bodyLarge?.semiBold.withColor(
                                    position.isProfit ? LightModeColors.profitGreen : LightModeColors.lossRed,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
            ],
            Card(
              child: Padding(
                padding: AppSpacing.paddingMd,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Stock Details', style: context.textStyles.titleMedium?.semiBold),
                    const SizedBox(height: AppSpacing.md),
                    StockDetailRow(
                      label: 'High',
                      value: Formatters.inr(widget.stock.high ?? 0),
                    ),
                    StockDetailRow(
                      label: 'Low',
                      value: Formatters.inr(widget.stock.low ?? 0),
                    ),
                    StockDetailRow(
                      label: 'Volume',
                      value: NumberFormat.compact().format(widget.stock.volume),
                    ),
                    StockDetailRow(
                      label: 'Market Cap',
                      value: Formatters.inr(widget.stock.marketCap ?? 0, decimals: 0),
                    ),
                    StockDetailRow(
                      label: 'Sector',
                      value: widget.stock.sector ?? 'N/A',
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: AppSpacing.paddingMd,
          child: Row(
            children: [
              Expanded(
                child: FilledButton(
                  onPressed: _showBuyDialog,
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: LightModeColors.profitGreen,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadius.md),
                    ),
                  ),
                  child: const Text('Buy'),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: FilledButton(
                  onPressed: position != null ? _showSellDialog : null,
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: LightModeColors.lossRed,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadius.md),
                    ),
                  ),
                  child: const Text('Sell'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _liveTimer?.cancel();
    super.dispose();
  }
}

class StockDetailRow extends StatelessWidget {
  final String label;
  final String value;

  const StockDetailRow({super.key, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: context.textStyles.bodyMedium?.withColor(
            Theme.of(context).colorScheme.onSurfaceVariant,
          )),
          Text(value, style: context.textStyles.bodyMedium?.semiBold),
        ],
      ),
    );
  }
}

class BuyDialog extends StatefulWidget {
  final StockModel stock;
  final int initialQuantity;
  final Function(int) onQuantityChanged;

  const BuyDialog({
    super.key,
    required this.stock,
    required this.initialQuantity,
    required this.onQuantityChanged,
  });

  @override
  State<BuyDialog> createState() => _BuyDialogState();
}

class _BuyDialogState extends State<BuyDialog> {
  late int _quantity;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _quantity = widget.initialQuantity;
  }

  Future<void> _executeBuy() async {
    setState(() => _isProcessing = true);

    final tradingService = context.read<TradingService>();
    final result = await tradingService.buyStock(widget.stock.symbol, _quantity);

    if (!mounted) return;

    setState(() => _isProcessing = false);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(result.message)),
    );

    if (result.success) {
      widget.onQuantityChanged(_quantity);
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final totalCost = widget.stock.currentPrice * _quantity;
    final user = context.watch<AuthService>().currentUser;
    final canAfford = user != null && user.virtualBalance >= totalCost;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: AppSpacing.lg,
        right: AppSpacing.lg,
        top: AppSpacing.lg,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Buy ${widget.stock.symbol}', style: context.textStyles.titleLarge?.bold),
          const SizedBox(height: AppSpacing.lg),
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.remove),
                onPressed: _quantity > 1 ? () => setState(() => _quantity--) : null,
              ),
              Expanded(
                child: Text(
                  '$_quantity shares',
                  style: context.textStyles.titleLarge?.semiBold,
                  textAlign: TextAlign.center,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.add),
                onPressed: () => setState(() => _quantity++),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Price per share', style: context.textStyles.bodyLarge),
              Text(
                Formatters.inr(widget.stock.currentPrice),
                style: context.textStyles.bodyLarge?.semiBold,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Total cost', style: context.textStyles.titleMedium?.semiBold),
              Text(
                Formatters.inr(totalCost),
                style: context.textStyles.titleMedium?.bold,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          if (!canAfford)
            Text(
              'Insufficient balance',
              style: context.textStyles.bodyMedium?.withColor(LightModeColors.lossRed),
              textAlign: TextAlign.center,
            ),
          const SizedBox(height: AppSpacing.md),
          FilledButton(
            onPressed: canAfford && !_isProcessing ? _executeBuy : null,
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              backgroundColor: LightModeColors.profitGreen,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
            ),
            child: _isProcessing
                ? const SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
            )
                : const Text('Confirm Buy'),
          ),
          const SizedBox(height: AppSpacing.md),
        ],
      ),
    );
  }
}

class SellDialog extends StatefulWidget {
  final StockModel stock;
  final int initialQuantity;
  final Function(int) onQuantityChanged;

  const SellDialog({
    super.key,
    required this.stock,
    required this.initialQuantity,
    required this.onQuantityChanged,
  });

  @override
  State<SellDialog> createState() => _SellDialogState();
}

class _SellDialogState extends State<SellDialog> {
  late int _quantity;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _quantity = widget.initialQuantity;
  }

  Future<void> _executeSell() async {
    setState(() => _isProcessing = true);

    final tradingService = context.read<TradingService>();
    final result = await tradingService.sellStock(widget.stock.symbol, _quantity);

    if (!mounted) return;

    setState(() => _isProcessing = false);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(result.message)),
    );

    if (result.success) {
      widget.onQuantityChanged(_quantity);
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final totalValue = widget.stock.currentPrice * _quantity;
    final portfolioService = context.watch<PortfolioService>();
    final position = portfolioService.getPosition(widget.stock.symbol);
    final maxShares = position?.quantity ?? 0;
    final canSell = _quantity <= maxShares;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: AppSpacing.lg,
        right: AppSpacing.lg,
        top: AppSpacing.lg,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Sell ${widget.stock.symbol}', style: context.textStyles.titleLarge?.bold),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'You own $maxShares shares',
            style: context.textStyles.bodyMedium?.withColor(
              Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.remove),
                onPressed: _quantity > 1 ? () => setState(() => _quantity--) : null,
              ),
              Expanded(
                child: Text(
                  '$_quantity shares',
                  style: context.textStyles.titleLarge?.semiBold,
                  textAlign: TextAlign.center,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.add),
                onPressed: _quantity < maxShares ? () => setState(() => _quantity++) : null,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Price per share', style: context.textStyles.bodyLarge),
              Text(
                Formatters.inr(widget.stock.currentPrice),
                style: context.textStyles.bodyLarge?.semiBold,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Total value', style: context.textStyles.titleMedium?.semiBold),
              Text(
                Formatters.inr(totalValue),
                style: context.textStyles.titleMedium?.bold,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          if (!canSell)
            Text(
              'You don\'t have enough shares',
              style: context.textStyles.bodyMedium?.withColor(LightModeColors.lossRed),
              textAlign: TextAlign.center,
            ),
          const SizedBox(height: AppSpacing.md),
          FilledButton(
            onPressed: canSell && !_isProcessing ? _executeSell : null,
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              backgroundColor: LightModeColors.lossRed,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
            ),
            child: _isProcessing
                ? const SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
            )
                : const Text('Confirm Sell'),
          ),
          const SizedBox(height: AppSpacing.md),
        ],
      ),
    );
  }
}
