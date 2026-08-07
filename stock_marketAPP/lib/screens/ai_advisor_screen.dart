import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:untitled_5/utils/formatters.dart';
import 'package:untitled_5/services/auth_service.dart';
import 'package:untitled_5/services/portfolio_service.dart';
import 'package:untitled_5/theme.dart';
import 'package:untitled_5/openai/openai_config.dart';

class AIAdvisorScreen extends StatelessWidget {
  const AIAdvisorScreen({super.key});

  /// Tries the AI-generated explanation first (needs GEMINI_API_KEY on the
  /// server). If that isn't configured or the request fails for any reason,
  /// falls back to the built-in guide below so the card always works.
  Future<String> _loadContent(String topic) async {
    try {
      final client = const GeminiClient();
      final aiContent = await client.generateLearningContent(topic: topic);
      if (aiContent.trim().isNotEmpty) return aiContent;
    } catch (_) {
      // Ignore and fall back to built-in content.
    }
    return LearningContent.data[topic] ??
        'Content for "$topic" is coming soon.';
  }

  void _openLearning(BuildContext context, String topic) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (ctx) {
        return DraggableScrollableSheet(
          initialChildSize: 0.85,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          expand: false,
          builder: (context, scrollController) {
            return Padding(
              padding: AppSpacing.paddingLg,
              child: FutureBuilder<String>(
                future: _loadContent(topic),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _header(ctx, topic),
                        const SizedBox(height: 16),
                        const LinearProgressIndicator(),
                        const SizedBox(height: 8),
                        Text(
                          'Loading...',
                          style: context.textStyles.bodySmall?.withColor(
                            Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    );
                  }

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _header(ctx, topic),
                      const SizedBox(height: 12),
                      Expanded(
                        child: SingleChildScrollView(
                          controller: scrollController,
                          child: Text(
                            snapshot.data ?? '',
                            style: context.textStyles.bodyMedium,
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            );
          },
        );
      },
    );
  }

  Widget _header(BuildContext ctx, String topic, {bool error = false}) {
    return Row(
      children: [
        IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(ctx).pop(),
        ),
        const SizedBox(width: 4),
        Icon(
          error ? Icons.error_outline : Icons.smart_toy,
          color: error ? LightModeColors.lossRed : Colors.blue,
        ),
        const SizedBox(width: 8),
        Text(topic, style: ctx.textStyles.titleLarge?.semiBold),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final authService = context.watch<AuthService>();
    final portfolioService = context.watch<PortfolioService>();
    final user = authService.currentUser;

    final insights = _generateInsights(
      user?.riskProfile ?? 'moderate',
      portfolioService.positions.length,
      portfolioService.totalProfitLossPercent,
      user?.virtualBalance ?? 0,
    );

    return Scaffold(
      appBar: AppBar(title: const Text('AI Advisor')),
      body: SingleChildScrollView(
        padding: AppSpacing.paddingMd,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _topCard(context, user?.riskProfile ?? 'moderate'),
            const SizedBox(height: AppSpacing.lg),
            Text('Portfolio Analysis',
                style: context.textStyles.titleLarge?.semiBold),
            const SizedBox(height: AppSpacing.md),
            ...insights.map((e) => InsightCard(
              icon: e['icon'],
              title: e['title'],
              description: e['description'],
              type: e['type'],
            )),
            const SizedBox(height: AppSpacing.lg),
            Text('Learning Resources',
                style: context.textStyles.titleLarge?.semiBold),
            const SizedBox(height: AppSpacing.md),
            _learning(context, 'Stock Market Basics',
                'Learn fundamental concepts of stock trading'),
            _learning(context, 'Trading Strategies',
                'Explore different investment approaches'),
            _learning(context, 'Risk Management',
                'Understand how to manage portfolio risk'),
            _learning(context, 'Market Analysis',
                'Technical and fundamental analysis techniques'),
          ],
        ),
      ),
    );
  }

  Widget _topCard(BuildContext context, String risk) {
    return Card(
      child: Padding(
        padding: AppSpacing.paddingLg,
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              child: Icon(
                Icons.smart_toy,
                size: 32,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('AI Investment Assistant',
                      style: context.textStyles.titleLarge?.bold),
                  const SizedBox(height: 4),
                  Text(
                    'Personalized advice based on your $risk risk profile',
                    style: context.textStyles.bodyMedium?.withColor(
                      Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _learning(BuildContext c, String t, String d) {
    return LearningCard(
      icon: Icons.school_outlined,
      title: t,
      description: d,
      onTap: () => _openLearning(c, t),
    );
  }

  List<Map<String, dynamic>> _generateInsights(
      String riskProfile,
      int positionCount,
      double profitLossPercent,
      double balance,
      ) {
    final List<Map<String, dynamic>> insights = [];

    if (positionCount == 0) {
      insights.add({
        'icon': Icons.trending_up,
        'title': 'Start Building Your Portfolio',
        'description':
        'You haven\'t made any investments yet. Start with diversified stocks.',
        'type': 'neutral',
      });
    } else if (positionCount < 3) {
      insights.add({
        'icon': Icons.warning_amber_outlined,
        'title': 'Diversification Needed',
        'description':
        'Only $positionCount stocks. Diversify across 5–8 stocks.',
        'type': 'warning',
      });
    } else {
      insights.add({
        'icon': Icons.check_circle_outline,
        'title': 'Good Diversification',
        'description': 'Your portfolio is well diversified.',
        'type': 'positive',
      });
    }

    if (profitLossPercent > 10) {
      insights.add({
        'icon': Icons.celebration,
        'title': 'Excellent Performance',
        'description':
        'Portfolio up ${profitLossPercent.toStringAsFixed(2)}%.',
        'type': 'positive',
      });
    } else if (profitLossPercent < -10) {
      insights.add({
        'icon': Icons.info_outline,
        'title': 'Portfolio Down',
        'description':
        'Down ${profitLossPercent.abs().toStringAsFixed(2)}%. Review calmly.',
        'type': 'warning',
      });
    }

    if (balance > 50000) {
      insights.add({
        'icon': Icons.account_balance_wallet_outlined,
        'title': 'High Cash Balance',
        'description':
        'You have ${Formatters.inr(balance, decimals: 0)} cash.',
        'type': 'neutral',
      });
    }

    return insights;
  }
}

/* ---------------- CARDS ---------------- */

class InsightCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final String type;

  const InsightCard({
    super.key,
    required this.icon,
    required this.title,
    required this.description,
    required this.type,
  });

  @override
  Widget build(BuildContext context) {
    Color iconColor;
    Color bg;

    switch (type) {
      case 'positive':
        iconColor = LightModeColors.profitGreen;
        bg = LightModeColors.profitGreen.withValues(alpha: 0.1);
        break;
      case 'warning':
        iconColor = Colors.orange;
        bg = Colors.orange.withValues(alpha: 0.1);
        break;
      default:
        iconColor = Theme.of(context).colorScheme.primary;
        bg = Theme.of(context)
            .colorScheme
            .primaryContainer
            .withValues(alpha: 0.3);
    }

    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Padding(
        padding: AppSpacing.paddingMd,
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration:
              BoxDecoration(color: bg, borderRadius: BorderRadius.circular(8)),
              child: Icon(icon, color: iconColor),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: context.textStyles.titleMedium?.semiBold),
                  const SizedBox(height: 4),
                  Text(description,
                      style: context.textStyles.bodyMedium),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class LearningCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final VoidCallback onTap;

  const LearningCard({
    super.key,
    required this.icon,
    required this.title,
    required this.description,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: AppSpacing.paddingMd,
          child: Row(
            children: [
              Icon(icon, size: 28),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style:
                        context.textStyles.titleMedium?.semiBold),
                    const SizedBox(height: 4),
                    Text(description,
                        style: context.textStyles.bodySmall),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }
}

/* ---------------- BUILT-IN LEARNING CONTENT ---------------- */

/// Static fallback guides shown when the AI advisor endpoint isn't
/// configured (no GEMINI_API_KEY) or the request fails, so every
/// Learning Resources card always shows something useful.
class LearningContent {
  static const Map<String, String> data = {
    'Stock Market Basics': '''
OVERVIEW
The stock market is a place where shares (small ownership units) of companies are bought and sold. When you buy a share, you become a part-owner of that company and can benefit if the company grows.

KEY CONCEPTS
• Share/Stock: A unit of ownership in a company.
• Exchange: NSE and BSE are India's main stock exchanges where shares are traded.
• Sensex/Nifty: Indices that track the overall performance of top companies.
• Demat Account: An account that holds your shares electronically.
• Broker: A licensed platform/person through which you buy and sell shares.
• Market Order vs Limit Order: A market order executes instantly at the current price; a limit order executes only at a price you set.
• Bull Market: Prices rising over time. Bear Market: Prices falling over time.

PRACTICAL TIPS
• Start small and only invest money you don't need immediately.
• Learn to read a stock's price chart before trading it.
• Diversify across sectors instead of putting money in one stock.

DO'S
1. Research a company before investing.
2. Keep an emergency fund separate from your investments.
3. Review your portfolio periodically.

DON'TS
1. Don't invest based on rumors or tips from social media.
2. Don't put all your money into a single stock.
3. Don't panic-sell during short-term price drops.
''',
    'Trading Strategies': '''
OVERVIEW
A trading strategy is a set of rules that decides when to buy and sell. Different strategies suit different goals, timeframes and risk appetites.

KEY CONCEPTS
• Intraday Trading: Buying and selling within the same day.
• Swing Trading: Holding positions for a few days to weeks to catch price "swings".
• Positional/Long-term Investing: Holding stocks for months or years based on company fundamentals.
• Value Investing: Buying undervalued stocks with strong fundamentals.
• Momentum Trading: Buying stocks that are trending strongly and riding the trend.
• Stop-Loss: A pre-set price at which you automatically exit to limit losses.
• Risk-Reward Ratio: Comparing potential loss to potential gain before entering a trade.

PRACTICAL TIPS
• Pick ONE strategy that matches your available time and temperament, don't mix too many.
• Always define your entry, target and stop-loss before placing a trade.
• Track your trades in a journal to learn from wins and losses.

DO'S
1. Backtest a strategy on past data before using real money.
2. Stick to your plan even when emotions say otherwise.
3. Start with a small position size while learning a new strategy.

DON'TS
1. Don't chase a stock after it has already moved sharply.
2. Don't trade without a stop-loss.
3. Don't switch strategies after every loss.
''',
    'Risk Management': '''
OVERVIEW
Risk management is about protecting your capital so a few bad trades don't wipe out your portfolio. It matters more than picking the "perfect" stock.

KEY CONCEPTS
• Position Sizing: Deciding how much money to put into a single trade/stock.
• Diversification: Spreading investments across sectors and asset types to reduce risk.
• Stop-Loss Order: An order that automatically sells a stock if it falls to a certain price.
• Risk Per Trade: The common rule is to risk only 1–2% of your total capital on a single trade.
• Volatility: How much a stock's price moves up and down; higher volatility means higher risk.
• Asset Allocation: Splitting money between stocks, bonds, cash etc. based on your risk profile.

PRACTICAL TIPS
• Never invest money that you'll need in the short term (e.g., emergency funds).
• Match your investments to your risk profile (conservative, moderate, aggressive).
• Rebalance your portfolio periodically to maintain your target allocation.

DO'S
1. Set a stop-loss on every trade.
2. Diversify across 8–10+ stocks and multiple sectors.
3. Reassess your risk profile as your life situation changes.

DON'TS
1. Don't use borrowed money you can't afford to lose.
2. Don't average down repeatedly on a falling stock without a clear reason.
3. Don't ignore position sizing just because you're "confident" about a trade.
''',
    'Market Analysis': '''
OVERVIEW
Market analysis helps you decide what to buy and when, using two broad approaches: fundamental analysis (is the company good?) and technical analysis (is the timing good?).

KEY CONCEPTS
• Fundamental Analysis: Studying a company's financials (revenue, profit, debt) and business quality to judge its true value.
• Technical Analysis: Studying price charts and patterns to predict future price movement.
• P/E Ratio: Price-to-Earnings ratio; shows how expensive a stock is relative to its earnings.
• Moving Average: The average price over a period, used to spot trends.
• Support & Resistance: Price levels where a stock tends to stop falling (support) or stop rising (resistance).
• Volume: The number of shares traded; confirms the strength of a price move.
• Candlestick Chart: A chart type showing open, high, low and close prices for a period.

PRACTICAL TIPS
• Use fundamental analysis to pick "what" to buy for long-term investing.
• Use technical analysis to help decide "when" to enter or exit a trade.
• Compare a company against its industry peers, not just its own past prices.

DO'S
1. Read the company's quarterly results before investing.
2. Combine both fundamental and technical views for a fuller picture.
3. Check overall market trend (Nifty/Sensex) before taking a big position.

DON'TS
1. Don't rely on a single indicator to make a decision.
2. Don't ignore red flags like rising debt or falling profits.
3. Don't confuse a short-term chart pattern with a long-term investment thesis.
''',
  };
}
