import 'package:flutter/material.dart';

import '../../../../app/theme/affluena_theme.dart';

class SelectorRow extends StatelessWidget {
  const SelectorRow({
    required this.label,
    required this.value,
    required this.icon,
    this.onTap,
    this.enabled = true,
    super.key,
  });

  final String label;
  final String value;
  final IconData icon;
  final VoidCallback? onTap;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return InkWell(
      onTap: enabled ? onTap : null,
      borderRadius: BorderRadius.circular(14),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AffluenaSpacing.space3),
        child: Row(
          children: [
            DecoratedBox(
              decoration: BoxDecoration(
                color: AffluenaColors.forestSoft,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Padding(
                padding: const EdgeInsets.all(AffluenaSpacing.space2),
                child: Icon(icon, color: AffluenaColors.forest, size: 18),
              ),
            ),
            const SizedBox(width: AffluenaSpacing.space3),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: textTheme.bodySmall),
                  const SizedBox(height: AffluenaSpacing.space1),
                  Text(
                    value,
                    style: textTheme.bodyLarge?.copyWith(
                      color: enabled ? null : AffluenaColors.inkMuted,
                    ),
                  ),
                ],
              ),
            ),
            if (onTap != null)
              const Icon(Icons.chevron_right, color: AffluenaColors.inkMuted),
          ],
        ),
      ),
    );
  }
}
