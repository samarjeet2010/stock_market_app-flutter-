import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:untitled_5/utils/formatters.dart';
import 'package:untitled_5/models/stock_model.dart';
import 'package:untitled_5/theme.dart';
import 'package:fl_chart/fl_chart.dart';

class StockCard extends StatelessWidget {
  final StockModel stock;
  final bool isInWatchlist;
  final VoidCallback onTap;

  const StockCard({
    super.key,
    required this.stock,
    required this.isInWatchlist,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isPositive = stock.isPositive;
    final changeColor = isPositive ? LightModeColors.profitGreen : LightModeColors.lossRed;

    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: Padding(
          padding: AppSpacing.paddingMd,
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
                child: Center(
                  child: Text(
                    stock.symbol.substring(0, 1),
                    style: context.textStyles.titleLarge?.bold.withColor(
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
                    Text(
                      stock.symbol,
                      style: context.textStyles.titleMedium?.semiBold,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      stock.name,
                      style: context.textStyles.bodySmall?.withColor(
                        Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    Formatters.inr(stock.currentPrice),
                    style: context.textStyles.titleMedium?.semiBold,
                  ),
                  const SizedBox(height: 6),
                  SizedBox(
                    width: 90,
                    height: 28,
                    child: LineChart(
                      LineChartData(
                        gridData: FlGridData(show: false),
                        titlesData: FlTitlesData(show: false),
                        borderData: FlBorderData(show: false),
                        lineBarsData: [
                          LineChartBarData(
                            spots: [
                              for (int i = 0; i < stock.priceHistory.length; i++)
                                FlSpot(i.toDouble(), stock.priceHistory[i])
                            ],
                            isCurved: true,
                            color: changeColor,
                            barWidth: 2,
                            dotData: const FlDotData(show: false),
                          ),
                        ],
                        minY: stock.priceHistory.reduce((a, b) => a < b ? a : b),
                        maxY: stock.priceHistory.reduce((a, b) => a > b ? a : b),
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(
                        isPositive ? Icons.arrow_drop_up : Icons.arrow_drop_down,
                        color: changeColor,
                        size: 18,
                      ),
                      Text(
                        '${isPositive ? '+' : ''}${stock.changePercent.toStringAsFixed(2)}%',
                        style: context.textStyles.bodySmall?.semiBold.withColor(changeColor),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
