import 'package:flutter/material.dart';

import '../../shared/presentation/parity_surface_screen.dart';

class WalletDetailScreen extends StatelessWidget {
  const WalletDetailScreen({required this.walletId, super.key});

  static const path = '/wallets/:walletId';

  static String location(String walletId) => '/wallets/$walletId';

  final String walletId;

  @override
  Widget build(BuildContext context) {
    return const ParitySurfaceScreen(
      title: 'Wallet detail',
      subtitle: 'Balance, ownership, members, and monthly movement.',
      icon: Icons.account_balance_wallet_outlined,
      items: [
        ParitySurfaceItem(
          icon: Icons.account_balance_outlined,
          title: 'Balance',
        ),
        ParitySurfaceItem(icon: Icons.groups_outlined, title: 'Members'),
        ParitySurfaceItem(icon: Icons.analytics_outlined, title: 'Analytics'),
      ],
    );
  }
}
