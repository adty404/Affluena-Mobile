import 'package:flutter/material.dart';

import '../../../../app/theme/affluena_theme.dart';

class TransactionTile extends StatelessWidget {
  const TransactionTile({
    required this.title,
    required this.metadata,
    required this.amount,
    required this.icon,
    this.isIncome = false,
    this.iconColor,
    super.key,
  });

  final String title;
  final String metadata;
  final String amount;
  final IconData icon;
  final bool isIncome;

  /// The category's chosen accent: tints the leading icon and its soft
  /// background. Null keeps the default theming.
  final Color? iconColor;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colors = context.affluenaColors;
    final amountColor = isIncome ? colors.success : colors.ink;
    final iconBackground = iconColor != null
        ? iconColor!.withValues(alpha: 0.14)
        : (isIncome ? colors.forestSoft : colors.surfaceTintSoft);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AffluenaSpacing.space3),
      child: Row(
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              color: iconBackground,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(AffluenaSpacing.space3),
              child: Icon(icon, color: iconColor ?? colors.forest, size: 20),
            ),
          ),
          const SizedBox(width: AffluenaSpacing.space3),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: textTheme.bodyLarge),
                const SizedBox(height: AffluenaSpacing.space1),
                Text(metadata, style: textTheme.bodySmall),
              ],
            ),
          ),
          const SizedBox(width: AffluenaSpacing.space3),
          Text(
            amount,
            style: textTheme.bodyLarge?.copyWith(
              color: amountColor,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
