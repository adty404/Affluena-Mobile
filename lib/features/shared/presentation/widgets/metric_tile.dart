import 'package:flutter/material.dart';

import '../../../../app/theme/affluena_theme.dart';

class MetricTile extends StatelessWidget {
  const MetricTile({
    required this.label,
    required this.value,
    this.helper,
    this.icon,
    super.key,
  });

  final String label;
  final String value;
  final String? helper;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Expanded(
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: AffluenaColors.surfaceTintSoft,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Padding(
          padding: const EdgeInsets.all(AffluenaSpacing.space4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (icon != null) ...[
                Icon(icon, color: AffluenaColors.forest, size: 18),
                const SizedBox(height: AffluenaSpacing.space2),
              ],
              Text(label, style: textTheme.labelMedium),
              const SizedBox(height: AffluenaSpacing.space1),
              Text(value, style: textTheme.titleMedium),
              if (helper != null) ...[
                const SizedBox(height: AffluenaSpacing.space1),
                Text(helper!, style: textTheme.bodySmall),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
