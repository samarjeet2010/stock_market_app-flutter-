import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:untitled_5/utils/formatters.dart';
import 'package:untitled_5/services/auth_service.dart';
import 'package:untitled_5/services/portfolio_service.dart';
import 'package:untitled_5/theme.dart';
import 'package:untitled_5/openai/openai_config.dart';

class AIAdvisorScreen extends StatelessWidget {
  const AIAdvisorScreen({super.key});

  void _openLearning(BuildContext context, String topic) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (ctx) {
        final client = const GeminiClient();
        return Padding(
          padding: AppSpacing.paddingLg,
          child: FutureBuilder<String>(
            future: client.generateLearningContent(topic: topic),
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
                      'Generating...',
                      style: context.textStyles.bodySmall?.withColor(
                        Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                );
              }

              if (snapshot.hasError) {
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _header(ctx, topic, error: true),
                    const SizedBox(height: 12),
                    Text(
                      'Failed to load content. Please try again.',
                      style: context.textStyles.bodyMedium,
                    ),
                  ],
                );
              }

              return SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _header(ctx, topic),
                    const SizedBox(height: 12),
                    Text(
                      snapshot.data ?? '',
                      style: context.textStyles.bodyMedium,
                    ),
                  ],
                ),
              );
            },
          ),
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
