import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:untitled_5/utils/formatters.dart';
import 'package:go_router/go_router.dart';
import 'package:untitled_5/services/market_data_service.dart';
import 'package:untitled_5/services/auth_service.dart';
import 'package:untitled_5/services/watchlist_service.dart';
import 'package:untitled_5/services/portfolio_service.dart';
import 'package:untitled_5/models/stock_model.dart';
import 'package:untitled_5/theme.dart';
import 'package:untitled_5/components/stock_card.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _searchController = TextEditingController();
  bool _isSearching = false;
  String _selectedSector = 'All';
  Timer? _liveTimer;

  @override
  void dispose() {
    _liveTimer?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _refreshData() async {
    final marketService = context.read<MarketDataService>();
    final portfolioService = context.read<PortfolioService>();

    await marketService.refreshPrices();
    await portfolioService.updatePrices(marketService);
  }

  @override
  Widget build(BuildContext context) {
    _liveTimer ??= Timer.periodic(const Duration(seconds: 3), (_) => _refreshData());
    final authService = context.watch<AuthService>();
    final marketService = context.watch<MarketDataService>();
    final watchlistService = context.watch<WatchlistService>();
    final portfolioService = context.watch<PortfolioService>();

    final user = authService.currentUser;
    final watchlistStocks = watchlistService.watchlist
        .map((symbol) => marketService.getStock(symbol))
        .where((stock) => stock != null)
        .cast<StockModel>()
        .toList();

    final allStocksBase = _isSearching
        ? marketService.searchStocks(_searchController.text)
        : marketService.allStocks;
    final sectors = ['All', ...{
      for (final s in marketService.allStocks)
        (s.sector ?? 'Other')
    }.toList()..sort()];
    final allStocks = _selectedSector == 'All'
        ? allStocksBase
        : allStocksBase.where((s) => (s.sector ?? 'Other') == _selectedSector).toList();

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Welcome, ${user?.name ?? 'Trader'}', style: context.textStyles.titleMedium?.semiBold),
            Text(
              Formatters.inr(user?.virtualBalance ?? 0),
              style: context.textStyles.bodySmall?.withColor(LightModeColors.profitGreen),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshData,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refreshData,
        child: SingleChildScrollView(
          padding: AppSpacing.paddingMd,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              PortfolioSummaryCard(
                totalValue: portfolioService.currentValue + (user?.virtualBalance ?? 0),
                profitLoss: portfolioService.totalProfitLoss,
                profitLossPercent: portfolioService.totalProfitLossPercent,
              ),
              const SizedBox(height: AppSpacing.lg),
              TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search stocks...',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _isSearching
                      ? IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () {
                      setState(() {
                        _searchController.clear();
                        _isSearching = false;
                      });
                    },
                  )
                      : null,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                ),
                onChanged: (value) {
                  setState(() => _isSearching = value.isNotEmpty);
                },
              ),
              const SizedBox(height: AppSpacing.lg),
              if (!_isSearching) ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('My Watchlist', style: context.textStyles.titleLarge?.semiBold),
                    TextButton.icon(
                      icon: const Icon(Icons.add, size: 18),
                      label: const Text('Add'),
                      onPressed: () => setState(() => _isSearching = true),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                if (watchlistStocks.isEmpty)
                  Center(
                    child: Padding(
                      padding: AppSpacing.paddingXl,
                      child: Text(
                        'No stocks in watchlist',
                        style: context.textStyles.bodyMedium?.withColor(
                          Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  )
                else
                  ...watchlistStocks.map((stock) => StockCard(
                    stock: stock,
                    isInWatchlist: true,
                    onTap: () => context.push('/stock-detail', extra: stock),
                  )),
                const SizedBox(height: AppSpacing.lg),
                Text('All Stocks', style: context.textStyles.titleLarge?.semiBold),
                const SizedBox(height: AppSpacing.sm),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      for (final sector in sectors)
                        Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: ChoiceChip(
                            label: Text(sector),
                            selected: _selectedSector == sector,
                            onSelected: (_) => setState(() => _selectedSector = sector),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
              ],
              ...allStocks.map((stock) => StockCard(
                stock: stock,
                isInWatchlist: watchlistService.isInWatchlist(stock.symbol),
                onTap: () => context.push('/stock-detail', extra: stock),
              )),
            ],
          ),
        ),
      ),
    );
  }
}

class PortfolioSummaryCard extends StatelessWidget {
  final double totalValue;
  final double profitLoss;
  final double profitLossPercent;

  const PortfolioSummaryCard({
    super.key,
    required this.totalValue,
    required this.profitLoss,
    required this.profitLossPercent,
  });

  @override
  Widget build(BuildContext context) {
    final isProfit = profitLoss >= 0;
    final profitColor = isProfit ? LightModeColors.profitGreen : LightModeColors.lossRed;

    return Card(
      child: Padding(
        padding: AppSpacing.paddingMd,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Total Portfolio Value', style: context.textStyles.bodyMedium?.withColor(
              Theme.of(context).colorScheme.onSurfaceVariant,
            )),
            const SizedBox(height: AppSpacing.sm),
            Text(
              Formatters.inr(totalValue),
              style: context.textStyles.headlineMedium?.bold,
            ),
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                Icon(
                  isProfit ? Icons.trending_up : Icons.trending_down,
                  color: profitColor,
                  size: 18,
                ),
                const SizedBox(width: 4),
                Text(
                  '${isProfit ? '+' : ''}${Formatters.inr(profitLoss)}',
                  style: context.textStyles.bodyLarge?.semiBold.withColor(profitColor),
                ),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  '(${isProfit ? '+' : ''}${profitLossPercent.toStringAsFixed(2)}%)',
                  style: context.textStyles.bodyMedium?.withColor(profitColor),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
