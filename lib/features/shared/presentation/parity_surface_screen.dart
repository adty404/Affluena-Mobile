import 'package:flutter/material.dart';

import '../../../app/theme/affluena_theme.dart';
import 'widgets/affluena_card.dart';
import 'widgets/section_header.dart';

class ParitySurfaceItem {
  const ParitySurfaceItem({required this.icon, required this.title});

  final IconData icon;
  final String title;
}

class ParitySurfaceScreen extends StatelessWidget {
  const ParitySurfaceScreen({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.items,
    super.key,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final List<ParitySurfaceItem> items;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colors = context.affluenaColors;

    return SafeArea(
      child: ListView(
        padding: AffluenaInsets.screen,
        children: [
          Text(title, style: textTheme.headlineMedium),
          const SizedBox(height: AffluenaSpacing.space5),
          AffluenaCard(
            child: Row(
              children: [
                DecoratedBox(
                  decoration: BoxDecoration(
                    color: colors.forestSoft,
                    borderRadius: BorderRadius.circular(AffluenaRadii.lg),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(AffluenaSpacing.space3),
                    child: Icon(icon, color: colors.forest, size: 24),
                  ),
                ),
                const SizedBox(width: AffluenaSpacing.space4),
                Expanded(
                  child: Text(
                    subtitle,
                    style: textTheme.bodyMedium?.copyWith(
                      color: colors.inkMuted,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AffluenaSpacing.space6),
          const SectionHeader(title: 'Surface'),
          const SizedBox(height: AffluenaSpacing.space3),
          AffluenaCard(
            child: Column(
              children: [
                for (final (index, item) in items.indexed) ...[
                  _ParitySurfaceRow(item: item),
                  if (index != items.length - 1) const Divider(height: 1),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ParitySurfaceRow extends StatelessWidget {
  const _ParitySurfaceRow({required this.item});

  final ParitySurfaceItem item;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colors = context.affluenaColors;

    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 60),
      child: Row(
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              color: colors.surfaceTintSoft,
              borderRadius: BorderRadius.circular(AffluenaRadii.md),
            ),
            child: Padding(
              padding: const EdgeInsets.all(AffluenaSpacing.space2),
              child: Icon(item.icon, color: colors.forest, size: 18),
            ),
          ),
          const SizedBox(width: AffluenaSpacing.space3),
          Expanded(
            child: Text(
              item.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: textTheme.bodyLarge,
            ),
          ),
        ],
      ),
    );
  }
}
