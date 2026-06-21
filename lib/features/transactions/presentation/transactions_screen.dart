import 'package:flutter/material.dart';

import '../../../app/theme/affluena_theme.dart';
import '../../shared/presentation/widgets/affluena_card.dart';
import '../../shared/presentation/widgets/transaction_tile.dart';

class TransactionsScreen extends StatelessWidget {
  const TransactionsScreen({super.key});

  static const path = '/transactions';

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
          Text('Transactions', style: textTheme.headlineMedium),
          const SizedBox(height: AffluenaSpacing.space5),
          TextField(
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.search),
              hintText: 'Search note, wallet, or category',
            ),
          ),
          const SizedBox(height: AffluenaSpacing.space3),
          Wrap(
            spacing: AffluenaSpacing.space2,
            runSpacing: AffluenaSpacing.space2,
            children: const [
              _FilterChip(label: 'This month'),
              _FilterChip(label: 'Expense'),
              _FilterChip(label: 'Food'),
            ],
          ),
          const SizedBox(height: AffluenaSpacing.space5),
          const AffluenaCard(
            child: Column(
              children: [
                TransactionTile(
                  title: 'Lunch meeting',
                  metadata: 'Food & Dining · GoPay · Today',
                  amount: '-Rp 125.000',
                  icon: Icons.restaurant_outlined,
                ),
                Divider(height: 1),
                TransactionTile(
                  title: 'Coffee',
                  metadata: 'Food & Dining · GoPay · Today',
                  amount: '-Rp 35.000',
                  icon: Icons.local_cafe_outlined,
                ),
                Divider(height: 1),
                TransactionTile(
                  title: 'Top up GoPay',
                  metadata: 'Transfer · BCA Primary · Yesterday',
                  amount: 'Rp 500.000',
                  icon: Icons.swap_horiz_rounded,
                ),
                Divider(height: 1),
                TransactionTile(
                  title: 'Monthly Salary',
                  metadata: 'Salary · BCA Primary · Jun 21',
                  amount: '+Rp 18.500.000',
                  icon: Icons.work_outline,
                  isIncome: true,
                ),
                Divider(height: 1),
                TransactionTile(
                  title: 'Electricity bill',
                  metadata: 'Bills & Utilities · BCA Primary · Jun 20',
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

class _FilterChip extends StatelessWidget {
  const _FilterChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Chip(label: Text(label), avatar: const Icon(Icons.check, size: 16));
  }
}
