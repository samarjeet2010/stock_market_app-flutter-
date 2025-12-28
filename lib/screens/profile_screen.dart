import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:untitled_5/utils/formatters.dart';
import 'package:go_router/go_router.dart';
import 'package:untitled_5/services/auth_service.dart';
import 'package:untitled_5/services/portfolio_service.dart';
import 'package:untitled_5/services/settings_service.dart';
import 'package:untitled_5/theme.dart';
import 'package:image_picker/image_picker.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  Future<void> _changePhoto(BuildContext context) async {
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(source: ImageSource.gallery, maxWidth: 600, imageQuality: 85);
      if (picked == null) return;
      final bytes = await picked.readAsBytes();
      final base64Data = base64Encode(bytes);
      await context.read<AuthService>().updateAvatar(base64Data);
    } catch (e) {
      debugPrint('Photo change error: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to update photo')));
      }
    }
  }

  void _openEditProfile(BuildContext context) {
    final auth = context.read<AuthService>();
    final nameController = TextEditingController(text: auth.currentUser?.name ?? '');
    String risk = auth.currentUser?.riskProfile ?? 'moderate';
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            left: AppSpacing.lg,
            right: AppSpacing.lg,
            top: AppSpacing.lg,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 16,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Edit Profile', style: ctx.textStyles.titleLarge?.bold),
              const SizedBox(height: 12),
              TextField(
                controller: nameController,
                decoration: InputDecoration(
                  labelText: 'Full Name',
                  prefixIcon: const Icon(Icons.person_outline),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
                ),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: risk,
                items: const [
                  DropdownMenuItem(value: 'conservative', child: Text('Conservative')),
                  DropdownMenuItem(value: 'moderate', child: Text('Moderate')),
                  DropdownMenuItem(value: 'aggressive', child: Text('Aggressive')),
                ],
                onChanged: (v) => risk = v ?? risk,
                decoration: InputDecoration(
                  labelText: 'Risk Profile',
                  prefixIcon: const Icon(Icons.shield_outlined),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
                ),
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: () async {
                  await auth.updateProfile(name: nameController.text.trim(), riskProfile: risk);
                  if (ctx.mounted) Navigator.of(ctx).pop();
                },
                icon: const Icon(Icons.save),
                label: const Text('Save Changes'),
              ),
            ],
          ),
        );
      },
    );
  }

  void _scrollToSettings(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(16),
        child: SingleChildScrollView(child: _SettingsCard()),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authService = context.watch<AuthService>();
    final portfolioService = context.watch<PortfolioService>();
    final user = authService.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
      ),
      body: SingleChildScrollView(
        padding: AppSpacing.paddingMd,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              child: Padding(
                padding: AppSpacing.paddingLg,
                child: Row(
                  children: [
                    Stack(
                      children: [
                        CircleAvatar(
                          radius: 32,
                          backgroundColor: Theme.of(context).colorScheme.primary,
                          backgroundImage: (user?.avatarData != null)
                              ? MemoryImage(base64Decode(user!.avatarData!))
                              : null,
                          child: (user?.avatarData == null)
                              ? Text(
                            user?.name.substring(0, 1).toUpperCase() ?? 'U',
                            style: context.textStyles.headlineMedium?.bold.withColor(Colors.white),
                          )
                              : null,
                        ),
                        Positioned(
                          right: 0,
                          bottom: 0,
                          child: InkWell(
                            onTap: () => _changePhoto(context),
                            borderRadius: BorderRadius.circular(16),
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.surface,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.3)),
                              ),
                              child: Icon(Icons.camera_alt, size: 16, color: Theme.of(context).colorScheme.primary),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(user?.name ?? 'User', style: context.textStyles.titleLarge?.bold),
                          const SizedBox(height: 4),
                          Text(
                            user?.email ?? '',
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
            ),
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _openEditProfile(context),
                    icon: const Icon(Icons.edit),
                    label: const Text('Edit Profile'),
                    style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14)),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _scrollToSettings(context),
                    icon: const Icon(Icons.settings_outlined),
                    label: const Text('Settings'),
                    style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            Text('Account Details', style: context.textStyles.titleLarge?.semiBold),
            const SizedBox(height: AppSpacing.md),
            ProfileDetailCard(
              icon: Icons.account_balance_wallet_outlined,
              title: 'Available Balance',
              value: Formatters.inr(user?.virtualBalance ?? 0),
              color: LightModeColors.profitGreen,
            ),
            ProfileDetailCard(
              icon: Icons.pie_chart_outline,
              title: 'Invested Amount',
              value: Formatters.inr(portfolioService.totalInvested),
              color: Theme.of(context).colorScheme.primary,
            ),
            ProfileDetailCard(
              icon: Icons.trending_up,
              title: 'Total P&L',
              value: Formatters.inr(portfolioService.totalProfitLoss),
              color: portfolioService.totalProfitLoss >= 0 ? LightModeColors.profitGreen : LightModeColors.lossRed,
            ),
            ProfileDetailCard(
              icon: Icons.business_center_outlined,
              title: 'Holdings',
              value: '${portfolioService.positions.length} positions',
              color: Theme.of(context).colorScheme.tertiary,
            ),
            const SizedBox(height: AppSpacing.lg),
            Text('Risk Profile', style: context.textStyles.titleLarge?.semiBold),
            const SizedBox(height: AppSpacing.md),
            Card(
              child: Padding(
                padding: AppSpacing.paddingMd,
                child: Row(
                  children: [
                    Icon(
                      _getRiskIcon(user?.riskProfile ?? 'moderate'),
                      color: _getRiskColor(user?.riskProfile ?? 'moderate'),
                      size: 28,
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _formatRiskProfile(user?.riskProfile ?? 'moderate'),
                            style: context.textStyles.titleMedium?.semiBold,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _getRiskDescription(user?.riskProfile ?? 'moderate'),
                            style: context.textStyles.bodySmall?.withColor(
                              Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text('Settings', style: context.textStyles.titleLarge?.semiBold),
            const SizedBox(height: AppSpacing.md),
            _SettingsCard(),
            const SizedBox(height: AppSpacing.lg),
            Text('Transaction History', style: context.textStyles.titleLarge?.semiBold),
            const SizedBox(height: AppSpacing.md),
            if (portfolioService.transactions.isEmpty)
              Center(
                child: Padding(
                  padding: AppSpacing.paddingXl,
                  child: Text(
                    'No transactions yet',
                    style: context.textStyles.bodyMedium?.withColor(
                      Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              )
            else
              ...portfolioService.getRecentTransactions(limit: 10).map((transaction) {
                final isBuy = transaction.isBuy;
                return Card(
                  margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                  child: Padding(
                    padding: AppSpacing.paddingMd,
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: (isBuy ? LightModeColors.profitGreen : LightModeColors.lossRed).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(AppRadius.sm),
                          ),
                          child: Icon(
                            isBuy ? Icons.add : Icons.remove,
                            color: isBuy ? LightModeColors.profitGreen : LightModeColors.lossRed,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${isBuy ? 'Bought' : 'Sold'} ${transaction.quantity} ${transaction.symbol}',
                                style: context.textStyles.titleSmall?.semiBold,
                              ),
                              Text(
                                DateFormat('MMM dd, yyyy • hh:mm a').format(transaction.timestamp),
                                style: context.textStyles.bodySmall?.withColor(
                                  Theme.of(context).colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          '${isBuy ? '-' : '+'}${Formatters.inr(transaction.totalAmount)}',
                          style: context.textStyles.titleSmall?.semiBold.withColor(
                            isBuy ? LightModeColors.lossRed : LightModeColors.profitGreen,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            const SizedBox(height: AppSpacing.xl),
            FilledButton.icon(
              onPressed: () async {
                await showModalBottomSheet(
                  context: context,
                  builder: (ctx) => Padding(
                    padding: AppSpacing.paddingLg,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.logout, color: LightModeColors.lossRed),
                            const SizedBox(width: 8),
                            Text('Logout', style: ctx.textStyles.titleLarge?.bold),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Are you sure you want to logout? You can login again anytime.',
                          style: ctx.textStyles.bodyMedium?.withColor(Theme.of(ctx).colorScheme.onSurfaceVariant),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () => Navigator.of(ctx).pop(),
                                child: const Text('Cancel'),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: FilledButton(
                                style: FilledButton.styleFrom(backgroundColor: LightModeColors.lossRed, foregroundColor: Colors.white),
                                onPressed: () async {
                                  Navigator.of(ctx).pop();
                                  await authService.logout();
                                  if (context.mounted) context.go('/login');
                                },
                                child: const Text('Logout'),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
              style: FilledButton.styleFrom(
                backgroundColor: LightModeColors.lossRed,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
              ),
              icon: const Icon(Icons.power_settings_new),
              label: const Text('Logout'),
            ),
            const SizedBox(height: AppSpacing.lg),
          ],
        ),
      ),
    );
  }

  IconData _getRiskIcon(String riskProfile) {
    switch (riskProfile) {
      case 'conservative':
        return Icons.shield_outlined;
      case 'aggressive':
        return Icons.trending_up;
      default:
        return Icons.balance_outlined;
    }
  }

  Color _getRiskColor(String riskProfile) {
    switch (riskProfile) {
      case 'conservative':
        return Colors.blue;
      case 'aggressive':
        return Colors.red;
      default:
        return Colors.orange;
    }
  }

  String _formatRiskProfile(String riskProfile) {
    return riskProfile[0].toUpperCase() + riskProfile.substring(1);
  }

  String _getRiskDescription(String riskProfile) {
    switch (riskProfile) {
      case 'conservative':
        return 'Prefer stable investments with minimal risk';
      case 'aggressive':
        return 'Seek maximum returns with high risk tolerance';
      default:
        return 'Balanced growth with moderate risk';
    }
  }
}

class ProfileDetailCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final Color color;

  const ProfileDetailCard({
    super.key,
    required this.icon,
    required this.title,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Padding(
        padding: AppSpacing.paddingMd,
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppRadius.sm),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Text(title, style: context.textStyles.bodyLarge),
            ),
            Text(value, style: context.textStyles.titleMedium?.semiBold),
          ],
        ),
      ),
    );
  }
}

class _SettingsCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsService>();
    return Card(
      child: Padding(
        padding: AppSpacing.paddingMd,
        child: Column(
          children: [
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.brightness_6, color: Colors.blue),
              title: const Text('Appearance'),
              subtitle: const Text('Theme mode'),
              trailing: DropdownButton<ThemeMode>(
                value: settings.themeMode,
                onChanged: (mode) {
                  if (mode != null) settings.setThemeMode(mode);
                },
                items: const [
                  DropdownMenuItem(value: ThemeMode.system, child: Text('System')),
                  DropdownMenuItem(value: ThemeMode.light, child: Text('Light')),
                  DropdownMenuItem(value: ThemeMode.dark, child: Text('Dark')),
                ],
              ),
            ),
            const Divider(height: 0),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Price Alerts'),
              subtitle: const Text('Get notified on big moves'),
              value: settings.notificationsEnabled,
              onChanged: (v) => settings.setNotifications(v),
              secondary: const Icon(Icons.notifications_active_outlined, color: Colors.blue),
            ),
            const Divider(height: 0),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Weekly Summary'),
              subtitle: const Text('Email weekly P&L and tips'),
              value: settings.weeklySummaryEnabled,
              onChanged: (v) => settings.setWeeklySummary(v),
              secondary: const Icon(Icons.calendar_month_outlined, color: Colors.blue),
            ),
          ],
        ),
      ),
    );
  }
}
