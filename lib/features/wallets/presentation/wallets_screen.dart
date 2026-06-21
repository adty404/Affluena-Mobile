import 'package:flutter/material.dart';

import '../../../app/theme/affluena_theme.dart';
import '../../shared/presentation/widgets/affluena_card.dart';
import '../../shared/presentation/widgets/metric_tile.dart';
import '../../shared/presentation/widgets/section_header.dart';

class WalletsScreen extends StatelessWidget {
  const WalletsScreen({super.key});

  static const path = '/wallets';

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
              Expanded(child: Text('Wallets', style: textTheme.headlineMedium)),
              IconButton.filledTonal(
                onPressed: () {},
                icon: const Icon(Icons.add),
              ),
            ],
          ),
          const SizedBox(height: AffluenaSpacing.space5),
          const AffluenaCard(
            child: Row(
              children: [
                MetricTile(
                  label: 'Total balance',
                  value: 'Rp 16.370.000',
                  helper: 'Across 4 wallets',
                ),
                SizedBox(width: AffluenaSpacing.space3),
                MetricTile(
                  label: 'Shared',
                  value: '1 wallet',
                  helper: '2 members',
                  icon: Icons.group_outlined,
                ),
              ],
            ),
          ),
          const SizedBox(height: AffluenaSpacing.space6),
          const SectionHeader(title: 'Your wallets'),
          const SizedBox(height: AffluenaSpacing.space3),
          const _WalletCard(
            name: 'BCA Primary',
            type: 'Bank',
            balance: 'Rp 15.200.000',
            description: 'Main account · Shared with Nadya',
            icon: Icons.account_balance_outlined,
            isShared: true,
          ),
          const SizedBox(height: AffluenaSpacing.space3),
          const _WalletCard(
            name: 'GoPay',
            type: 'E-wallet',
            balance: 'Rp 320.000',
            description: 'Daily meals and transport',
            icon: Icons.phone_iphone_outlined,
          ),
          const SizedBox(height: AffluenaSpacing.space3),
          const _WalletCard(
            name: 'Cash Wallet',
            type: 'Cash',
            balance: 'Rp 850.000',
            description: 'Pocket cash',
            icon: Icons.payments_outlined,
          ),
          const SizedBox(height: AffluenaSpacing.space3),
          const _WalletCard(
            name: 'Europe Trip Fund',
            type: 'Goal',
            balance: 'Rp 8.500.000',
            description: '17% of Rp 50.000.000 target',
            icon: Icons.flag_outlined,
          ),
        ],
      ),
    );
  }
}

class _WalletCard extends StatelessWidget {
  const _WalletCard({
    required this.name,
    required this.type,
    required this.balance,
    required this.description,
    required this.icon,
    this.isShared = false,
  });

  final String name;
  final String type;
  final String balance;
  final String description;
  final IconData icon;
  final bool isShared;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return AffluenaCard(
      child: Row(
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              color: AffluenaColors.forestSoft,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Padding(
              padding: const EdgeInsets.all(AffluenaSpacing.space4),
              child: Icon(icon, color: AffluenaColors.forest),
            ),
          ),
          const SizedBox(width: AffluenaSpacing.space4),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(child: Text(name, style: textTheme.titleMedium)),
                    if (isShared) const Icon(Icons.group, size: 18),
                  ],
                ),
                const SizedBox(height: AffluenaSpacing.space1),
                Text('$type · $description', style: textTheme.bodySmall),
                const SizedBox(height: AffluenaSpacing.space2),
                Text(balance, style: textTheme.bodyLarge),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
