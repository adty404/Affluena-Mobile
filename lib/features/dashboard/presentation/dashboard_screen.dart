import 'package:flutter/material.dart';

import '../../../app/theme/affluena_theme.dart';
import '../../shared/presentation/widgets/affluena_card.dart';
import '../../shared/presentation/widgets/metric_tile.dart';
import '../../shared/presentation/widgets/section_header.dart';
import '../../shared/presentation/widgets/transaction_tile.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  static const path = '/';

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(
          AffluenaSpacing.space5,
          AffluenaSpacing.space4,
          AffluenaSpacing.space5,
          AffluenaSpacing.space8,
        ),
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Affluena', style: textTheme.labelMedium),
                    const SizedBox(height: AffluenaSpacing.space1),
                    Text('Good morning', style: textTheme.headlineMedium),
                  ],
                ),
              ),
              IconButton.filledTonal(
                onPressed: () {},
                icon: const Icon(Icons.notifications_none),
              ),
              const SizedBox(width: AffluenaSpacing.space2),
              CircleAvatar(
                backgroundColor: AffluenaColors.forest,
                child: Text(
                  'A',
                  style: textTheme.bodyLarge?.copyWith(
                    color: AffluenaColors.surfaceElevated,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AffluenaSpacing.space6),
          AffluenaCard(
            backgroundColor: AffluenaColors.surfaceSoft,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Total balance', style: textTheme.bodySmall),
                const SizedBox(height: AffluenaSpacing.space2),
                Text('Rp 16.370.000', style: textTheme.displaySmall),
                const SizedBox(height: AffluenaSpacing.space4),
                Row(
                  children: const [
                    MetricTile(
                      label: 'Income',
                      value: 'Rp 21M',
                      helper: 'This month',
                      icon: Icons.arrow_downward_rounded,
                    ),
                    SizedBox(width: AffluenaSpacing.space3),
                    MetricTile(
                      label: 'Expense',
                      value: 'Rp 3.3M',
                      helper: '72% planned',
                      icon: Icons.arrow_upward_rounded,
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: AffluenaSpacing.space5),
          Row(
            children: const [
              _QuickAction(icon: Icons.add_rounded, label: 'Add'),
              SizedBox(width: AffluenaSpacing.space3),
              _QuickAction(icon: Icons.swap_horiz_rounded, label: 'Transfer'),
              SizedBox(width: AffluenaSpacing.space3),
              _QuickAction(icon: Icons.pie_chart_outline, label: 'Budget'),
              SizedBox(width: AffluenaSpacing.space3),
              _QuickAction(icon: Icons.wallet_outlined, label: 'Wallets'),
            ],
          ),
          const SizedBox(height: AffluenaSpacing.space6),
          AffluenaCard(
            backgroundColor: AffluenaColors.forestSoft,
            borderColor: AffluenaColors.forestSoft,
            child: Row(
              children: [
                const Icon(
                  Icons.restaurant_outlined,
                  color: AffluenaColors.amber,
                ),
                const SizedBox(width: AffluenaSpacing.space3),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Food budget 72% used', style: textTheme.bodyLarge),
                      Text(
                        'Rp 560.000 left for this month',
                        style: textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AffluenaSpacing.space6),
          const SectionHeader(
            title: 'Recent transactions',
            actionLabel: 'See all',
          ),
          const SizedBox(height: AffluenaSpacing.space2),
          const AffluenaCard(
            child: Column(
              children: [
                TransactionTile(
                  title: 'Monthly Salary',
                  metadata: 'Salary · BCA Primary · Today',
                  amount: '+Rp 18.500.000',
                  icon: Icons.work_outline,
                  isIncome: true,
                ),
                Divider(height: 1),
                TransactionTile(
                  title: 'Lunch meeting',
                  metadata: 'Food & Dining · GoPay · Today',
                  amount: '-Rp 125.000',
                  icon: Icons.restaurant_outlined,
                ),
                Divider(height: 1),
                TransactionTile(
                  title: 'Electricity bill',
                  metadata: 'Bills & Utilities · BCA Primary · Yesterday',
                  amount: '-Rp 850.000',
                  icon: Icons.bolt_outlined,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickAction extends StatelessWidget {
  const _QuickAction({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Expanded(
      child: AffluenaCard(
        padding: const EdgeInsets.symmetric(
          horizontal: AffluenaSpacing.space2,
          vertical: AffluenaSpacing.space3,
        ),
        child: Column(
          children: [
            Icon(icon, color: AffluenaColors.forest),
            const SizedBox(height: AffluenaSpacing.space2),
            Text(label, style: textTheme.labelMedium),
          ],
        ),
      ),
    );
  }
}
