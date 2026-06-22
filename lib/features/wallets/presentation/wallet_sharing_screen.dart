import 'package:flutter/material.dart';

import '../../shared/presentation/parity_surface_screen.dart';

class WalletSharingScreen extends StatelessWidget {
  const WalletSharingScreen({required this.walletId, super.key});

  static const path = '/wallets/:walletId/sharing';

  static String location(String walletId) => '/wallets/$walletId/sharing';

  final String walletId;

  @override
  Widget build(BuildContext context) {
    return const ParitySurfaceScreen(
      title: 'Wallet sharing',
      subtitle: 'Invites, member status, and shared wallet access.',
      icon: Icons.group_add_outlined,
      items: [
        ParitySurfaceItem(icon: Icons.mail_outline, title: 'Invites'),
        ParitySurfaceItem(icon: Icons.verified_user_outlined, title: 'Access'),
        ParitySurfaceItem(icon: Icons.people_alt_outlined, title: 'Members'),
      ],
    );
  }
}
