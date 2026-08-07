import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:untitled_5/utils/formatters.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:untitled_5/services/portfolio_service.dart';
import 'package:untitled_5/services/auth_service.dart';
import 'package:untitled_5/theme.dart';

class PortfolioScreen extends StatelessWidget {
  const PortfolioScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final portfolioService = context.watch<PortfolioService>();
    final authService = context.watch<AuthService>();
    final user = authService.currentUser;

    final totalValue = portfolioService.currentValue + (user?.virtualBalance ?? 0);
    final invested = portfolioService.totalInvested;
    final profitLoss = portfolioService.totalProfitLoss;
    final profitLossPercent = portfolioService.totalProfitLossPercent;
    final isProfit = profitLoss >= 0;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Portfolio'),
      ),
      body: SingleChildScrollView(
        padding: AppSpacing.paddingMd,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              child: Padding(
                padding: AppSpacing.paddingLg,
                child: Column(
                  children: [
                    Text('Total Value', style: context.textStyles.bodyMedium?.withColor(
                      Theme.of(context).colorScheme.onSurfaceVariant,
                    )),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      Formatters.inr(totalValue),
                      style: context.textStyles.displaySmall?.bold,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          isProfit ? Icons.trending_up : Icons.trending_down,
                          color: isProfit ? LightModeColors.profitGreen : LightModeColors.lossRed,
                          size: 24,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${isProfit ? '+' : ''}${Formatters.inr(profitLoss)}',
                          style: context.textStyles.titleLarge?.bold.withColor(
                            isProfit ? LightModeColors.profitGreen : LightModeColors.lossRed,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Text(
                          '(${isProfit ? '+' : ''}${profitLossPercent.toStringAsFixed(2)}%)',
                          style: context.textStyles.titleMedium?.withColor(
                            isProfit ? LightModeColors.profitGreen : LightModeColors.lossRed,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            children: [
                              Text('Invested', style: context.textStyles.bodySmall?.withColor(
                                Theme.of(context).colorScheme.onSurfaceVariant,
                              )),
                              const SizedBox(height: 4),
                              Text(
                                Formatters.inr(invested, decimals: 0),
                                style: context.textStyles.titleMedium?.semiBold,
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          child: Column(
                            children: [
                              Text('Holdings Value', style: context.textStyles.bodySmall?.withColor(
                                Theme.of(context).colorScheme.onSurfaceVariant,
                              )),
                              const SizedBox(height: 4),
                              Text(
                                Formatters.inr(portfolioService.currentValue, decimals: 0),
                                style: context.textStyles.titleMedium?.semiBold,
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          child: Column(
                            children: [
                              Text('Cash', style: context.textStyles.bodySmall?.withColor(
                                Theme.of(context).colorScheme.onSurfaceVariant,
                              )),
                              const SizedBox(height: 4),
                              Text(
                                Formatters.inr(user?.virtualBalance ?? 0, decimals: 0),
                                style: context.textStyles.titleMedium?.semiBold,
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
            if (portfolioService.positions.isNotEmpty) ...[
              Text('Holdings', style: context.textStyles.titleLarge?.semiBold),
              const SizedBox(height: AppSpacing.md),
              ...portfolioService.positions.map((position) {
                final positionProfit = position.isProfit;
                final profitColor = positionProfit ? LightModeColors.profitGreen : LightModeColors.lossRed;

                return Card(
                  margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                  child: Padding(
                    padding: AppSpacing.paddingMd,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(position.symbol, style: context.textStyles.titleMedium?.bold),
                                  Text(
                                    '${position.quantity} shares',
                                    style: context.textStyles.bodySmall?.withColor(
                                      Theme.of(context).colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  Formatters.inr(position.currentValue),
                                  style: context.textStyles.titleMedium?.semiBold,
                                ),
                                Row(
                                  children: [
                                    Icon(
                                      positionProfit ? Icons.arrow_drop_up : Icons.arrow_drop_down,
                                      color: profitColor,
                                      size: 18,
                                    ),
                                    Text(
                                      '${positionProfit ? '+' : ''}${position.profitLossPercent.toStringAsFixed(2)}%',
                                      style: context.textStyles.bodySmall?.semiBold.withColor(profitColor),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Divider(height: 1, color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2)),
                        const SizedBox(height: AppSpacing.sm),
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Avg Cost', style: context.textStyles.bodySmall?.withColor(
                                    Theme.of(context).colorScheme.onSurfaceVariant,
                                  )),
                                  Text(
                                    Formatters.inr(position.avgBuyPrice),
                                    style: context.textStyles.bodyMedium?.semiBold,
                                  ),
                                ],
                              ),
                            ),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Current Price', style: context.textStyles.bodySmall?.withColor(
                                    Theme.of(context).colorScheme.onSurfaceVariant,
                                  )),
                                  Text(
                                    Formatters.inr(position.currentPrice),
                                    style: context.textStyles.bodyMedium?.semiBold,
                                  ),
                                ],
                              ),
                            ),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text('P&L', style: context.textStyles.bodySmall?.withColor(
                                    Theme.of(context).colorScheme.onSurfaceVariant,
                                  )),
                                  Text(
                                    '${positionProfit ? '+' : ''}${Formatters.inr(position.profitLoss)}',
                                    style: context.textStyles.bodyMedium?.semiBold.withColor(profitColor),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ] else
              Center(
                child: Padding(
                  padding: AppSpacing.paddingXl,
                  child: Column(
                    children: [
                      Icon(
                        Icons.pie_chart_outline,
                        size: 64,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(height: AppSpacing.md),
                      Text(
                        'No holdings yet',
                        style: context.textStyles.titleMedium?.semiBold,
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        'Start trading to build your portfolio',
                        style: context.textStyles.bodyMedium?.withColor(
                          Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
