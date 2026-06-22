import 'package:flutter/material.dart';

import '../../shared/presentation/parity_surface_screen.dart';

class QuickEntryTemplatesScreen extends StatelessWidget {
  const QuickEntryTemplatesScreen({super.key});

  static const path = '/quick-entry/templates';

  @override
  Widget build(BuildContext context) {
    return const ParitySurfaceScreen(
      title: 'Quick-entry templates',
      subtitle: 'Saved transaction shortcuts and execution defaults.',
      icon: Icons.bolt_outlined,
      items: [
        ParitySurfaceItem(icon: Icons.playlist_add_check, title: 'Templates'),
        ParitySurfaceItem(icon: Icons.payments_outlined, title: 'Amounts'),
        ParitySurfaceItem(icon: Icons.sell_outlined, title: 'Tags'),
      ],
    );
  }
}
