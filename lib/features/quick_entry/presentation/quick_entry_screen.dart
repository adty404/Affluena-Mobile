import 'package:flutter/material.dart';

import '../../../app/theme/affluena_theme.dart';
import '../../shared/presentation/widgets/affluena_card.dart';
import '../../shared/presentation/widgets/selector_row.dart';

class QuickEntryScreen extends StatelessWidget {
  const QuickEntryScreen({super.key});

  static const path = '/quick-entry';

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
          Text('Quick entry', style: textTheme.headlineMedium),
          const SizedBox(height: AffluenaSpacing.space2),
          Text(
            'Record daily money movement without turning it into paperwork.',
            style: textTheme.bodySmall,
          ),
          const SizedBox(height: AffluenaSpacing.space6),
          SegmentedButton<String>(
            segments: const [
              ButtonSegment(value: 'expense', label: Text('Expense')),
              ButtonSegment(value: 'income', label: Text('Income')),
              ButtonSegment(value: 'transfer', label: Text('Transfer')),
            ],
            selected: const {'expense'},
            onSelectionChanged: (_) {},
          ),
          const SizedBox(height: AffluenaSpacing.space5),
          AffluenaCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Amount', style: textTheme.bodySmall),
                const SizedBox(height: AffluenaSpacing.space2),
                Text('Rp 125.000', style: textTheme.displaySmall),
                const SizedBox(height: AffluenaSpacing.space4),
                const Divider(height: 1),
                const SelectorRow(
                  label: 'Wallet',
                  value: 'GoPay',
                  icon: Icons.account_balance_wallet_outlined,
                ),
                const Divider(height: 1),
                const SelectorRow(
                  label: 'Category',
                  value: 'Food & Dining',
                  icon: Icons.restaurant_outlined,
                ),
                const Divider(height: 1),
                const SelectorRow(
                  label: 'Tags',
                  value: '#MonthlyBill',
                  icon: Icons.sell_outlined,
                ),
                const Divider(height: 1),
                const SelectorRow(
                  label: 'Date',
                  value: 'Today',
                  icon: Icons.calendar_today_outlined,
                ),
                const Divider(height: 1),
                const SelectorRow(
                  label: 'Note',
                  value: 'Lunch meeting',
                  icon: Icons.notes_outlined,
                ),
              ],
            ),
          ),
          const SizedBox(height: AffluenaSpacing.space6),
          Text('Saved templates', style: textTheme.titleMedium),
          const SizedBox(height: AffluenaSpacing.space3),
          Wrap(
            spacing: AffluenaSpacing.space3,
            runSpacing: AffluenaSpacing.space3,
            children: const [
              _TemplateChip(label: 'Coffee', amount: 'Rp 35.000'),
              _TemplateChip(label: 'Lunch', amount: 'Rp 125.000'),
              _TemplateChip(label: 'Top up', amount: 'Rp 500.000'),
            ],
          ),
          const SizedBox(height: AffluenaSpacing.space6),
          FilledButton(onPressed: () {}, child: const Text('Save transaction')),
        ],
      ),
    );
  }
}

class _TemplateChip extends StatelessWidget {
  const _TemplateChip({required this.label, required this.amount});

  final String label;
  final String amount;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return AffluenaCard(
      padding: const EdgeInsets.symmetric(
        horizontal: AffluenaSpacing.space4,
        vertical: AffluenaSpacing.space3,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label, style: textTheme.bodyLarge),
          const SizedBox(height: AffluenaSpacing.space1),
          Text(amount, style: textTheme.bodySmall),
        ],
      ),
    );
  }
}
