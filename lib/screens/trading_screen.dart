import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import 'package:untitled_5/services/market_data_service.dart';
import 'package:untitled_5/theme.dart';
import 'package:untitled_5/components/stock_card.dart';
import 'package:untitled_5/services/watchlist_service.dart';

class TradingScreen extends StatefulWidget {
  const TradingScreen({super.key});

  @override
  State<TradingScreen> createState() => _TradingScreenState();
}

class _TradingScreenState extends State<TradingScreen> {
  final _searchController = TextEditingController();
  String _sortBy = 'name';
  Timer? _liveTimer;

  @override
  void dispose() {
    _liveTimer?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final marketService = context.watch<MarketDataService>();
    final watchlistService = context.watch<WatchlistService>();
    _liveTimer ??= Timer.periodic(const Duration(seconds: 4), (_) => marketService.refreshPrices());

    var stocks = marketService.searchStocks(_searchController.text);

    stocks = List.from(stocks)..sort((a, b) {
      switch (_sortBy) {
        case 'name':
          return a.name.compareTo(b.name);
        case 'price_high':
          return b.currentPrice.compareTo(a.currentPrice);
        case 'price_low':
          return a.currentPrice.compareTo(b.currentPrice);
        case 'change':
          return b.changePercent.compareTo(a.changePercent);
        default:
          return 0;
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('Trade Stocks'),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.sort),
            onSelected: (value) => setState(() => _sortBy = value),
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'name', child: Text('Name')),
              const PopupMenuItem(value: 'price_high', child: Text('Price: High to Low')),
              const PopupMenuItem(value: 'price_low', child: Text('Price: Low to High')),
              const PopupMenuItem(value: 'change', child: Text('Top Gainers')),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: AppSpacing.paddingMd,
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search stocks to trade...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    setState(() => _searchController.clear());
                  },
                )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
              ),
              onChanged: (value) => setState(() {}),
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: AppSpacing.paddingMd,
              itemCount: stocks.length,
              itemBuilder: (context, index) {
                final stock = stocks[index];
                return StockCard(
                  stock: stock,
                  isInWatchlist: watchlistService.isInWatchlist(stock.symbol),
                  onTap: () => context.push('/stock-detail', extra: stock),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
