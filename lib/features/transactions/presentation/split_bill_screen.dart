import 'package:flutter/material.dart';

import '../../shared/presentation/parity_surface_screen.dart';

class SplitBillScreen extends StatelessWidget {
  const SplitBillScreen({super.key});

  static const path = '/transactions/split';

  @override
  Widget build(BuildContext context) {
    return const ParitySurfaceScreen(
      title: 'Split bill',
      subtitle: 'Participants, shares, and linked debt records.',
      icon: Icons.call_split_outlined,
      items: [
        ParitySurfaceItem(icon: Icons.group_outlined, title: 'Participants'),
        ParitySurfaceItem(icon: Icons.summarize_outlined, title: 'Shares'),
        ParitySurfaceItem(
          icon: Icons.handshake_outlined,
          title: 'Debt records',
        ),
      ],
    );
  }
}
