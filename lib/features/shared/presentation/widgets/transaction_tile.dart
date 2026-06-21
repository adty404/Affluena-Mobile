import 'package:flutter/material.dart';

import '../../../../app/theme/affluena_theme.dart';

class TransactionTile extends StatelessWidget {
  const TransactionTile({
    required this.title,
    required this.metadata,
    required this.amount,
    required this.icon,
    this.isIncome = false,
    super.key,
  });

  final String title;
  final String metadata;
  final String amount;
  final IconData icon;
  final bool isIncome;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colors = context.affluenaColors;
    final amountColor = isIncome ? colors.success : colors.ink;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AffluenaSpacing.space3),
      child: Row(
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              color: isIncome ? colors.forestSoft : colors.surfaceTintSoft,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(AffluenaSpacing.space3),
              child: Icon(icon, color: colors.forest, size: 20),
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
