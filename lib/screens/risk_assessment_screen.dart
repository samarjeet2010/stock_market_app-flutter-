import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:untitled_5/services/auth_service.dart';
import 'package:untitled_5/theme.dart';

class RiskAssessmentScreen extends StatefulWidget {
  final Map<String, String> userData;

  const RiskAssessmentScreen({super.key, required this.userData});

  @override
  State<RiskAssessmentScreen> createState() => _RiskAssessmentScreenState();
}

class _RiskAssessmentScreenState extends State<RiskAssessmentScreen> {
  String _selectedRisk = 'moderate';
  bool _isLoading = false;

  final List<Map<String, dynamic>> _riskProfiles = [
    {
      'value': 'conservative',
      'title': 'Conservative',
      'icon': Icons.shield_outlined,
      'description': 'I prefer stable investments with minimal risk',
      'color': Colors.blue,
    },
    {
      'value': 'moderate',
      'title': 'Moderate',
      'icon': Icons.balance_outlined,
      'description': 'I seek balanced growth with moderate risk',
      'color': Colors.orange,
    },
    {
      'value': 'aggressive',
      'title': 'Aggressive',
      'icon': Icons.trending_up,
      'description': 'I want maximum returns and can handle high risk',
      'color': Colors.red,
    },
  ];

  Future<void> _createAccount() async {
    setState(() => _isLoading = true);

    final authService = context.read<AuthService>();
    final success = await authService.signup(
      widget.userData['email']!,
      widget.userData['password']!,
      widget.userData['name']!,
      _selectedRisk,
    );

    if (!mounted) return;

    setState(() => _isLoading = false);

    if (success) {
      context.go('/home');
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Account creation failed. Email may already exist.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: AppSpacing.paddingLg,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Choose Your Risk Profile',
                style: context.textStyles.headlineMedium?.bold,
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'This helps our AI provide personalized investment advice',
                style: context.textStyles.bodyLarge?.withColor(
                  Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              ..._riskProfiles.map((profile) => Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.md),
                child: RiskProfileCard(
                  value: profile['value'],
                  title: profile['title'],
                  icon: profile['icon'],
                  description: profile['description'],
                  color: profile['color'],
                  isSelected: _selectedRisk == profile['value'],
                  onTap: () => setState(() => _selectedRisk = profile['value']),
                ),
              )),
              const SizedBox(height: AppSpacing.xl),
              FilledButton(
                onPressed: _isLoading ? null : _createAccount,
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                ),
                child: _isLoading
                    ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
                    : const Text('Create Account'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class RiskProfileCard extends StatelessWidget {
  final String value;
  final String title;
  final IconData icon;
  final String description;
  final Color color;
  final bool isSelected;
  final VoidCallback onTap;

  const RiskProfileCard({
    super.key,
    required this.value,
    required this.title,
    required this.icon,
    required this.description,
    required this.color,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(
            color: isSelected
                ? Theme.of(context).colorScheme.primary
                : Theme.of(context).colorScheme.outline,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(AppRadius.md),
          color: isSelected
              ? Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.3)
              : Theme.of(context).colorScheme.surface,
        ),
        padding: AppSpacing.paddingMd,
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppRadius.sm),
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: context.textStyles.titleMedium?.semiBold),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: context.textStyles.bodySmall?.withColor(
                      Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Icon(
                Icons.check_circle,
                color: Theme.of(context).colorScheme.primary,
              ),
          ],
        ),
      ),
    );
  }
}
