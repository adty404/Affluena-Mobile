import 'package:flutter/material.dart';

import '../../shared/presentation/parity_surface_screen.dart';

class AuditLogScreen extends StatelessWidget {
  const AuditLogScreen({super.key});

  static const path = '/audit-logs';

  @override
  Widget build(BuildContext context) {
    return const ParitySurfaceScreen(
      title: 'Audit logs',
      subtitle: 'Account activity and system request history.',
      icon: Icons.manage_search_outlined,
      items: [
        ParitySurfaceItem(icon: Icons.history_outlined, title: 'Activity'),
        ParitySurfaceItem(icon: Icons.http_outlined, title: 'System logs'),
        ParitySurfaceItem(icon: Icons.lock_outline, title: 'Access scope'),
      ],
    );
  }
}
