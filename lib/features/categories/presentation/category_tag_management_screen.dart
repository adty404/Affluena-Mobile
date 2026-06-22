import 'package:flutter/material.dart';

import '../../shared/presentation/parity_surface_screen.dart';

class CategoryTagManagementScreen extends StatelessWidget {
  const CategoryTagManagementScreen({super.key});

  static const path = '/categories-tags';

  @override
  Widget build(BuildContext context) {
    return const ParitySurfaceScreen(
      title: 'Categories & Tags',
      subtitle: 'Income, expense hierarchy, and transaction labels.',
      icon: Icons.category_outlined,
      items: [
        ParitySurfaceItem(
          icon: Icons.account_tree_outlined,
          title: 'Hierarchy',
        ),
        ParitySurfaceItem(icon: Icons.label_outline, title: 'Tags'),
        ParitySurfaceItem(icon: Icons.rule_outlined, title: 'Usage checks'),
      ],
    );
  }
}
