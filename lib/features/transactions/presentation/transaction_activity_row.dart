import 'package:flutter/material.dart';

import '../../../app/theme/affluena_theme.dart';
import '../../../app/theme/sky_palette.dart';
import '../../../core/formatters/date_formatter.dart';
import '../../../core/formatters/money_formatter.dart';
import '../../categories/data/category_models.dart';
import '../data/transaction_models.dart';
import 'transaction_display.dart';

/// The Bahasa Indonesia label for a transaction type, used as the last-resort
/// row title when a transaction has neither a note nor a category (transfers,
/// balance adjustments).
String transactionTypeLabel(TransactionType type) => switch (type) {
  TransactionType.income => 'Pemasukan',
  TransactionType.expense => 'Pengeluaran',
  TransactionType.transfer => 'Transfer',
  TransactionType.adjustment => 'Penyesuaian',
};

/// A single tappable transaction row in the "Tinta"/sky language, shared by the
/// cross-wallet Aktivitas feed and the Wawasan per-category transactions
/// screen. The leading slot shows the category's chosen icon + color on a soft
/// tinted tile (via [categoryAppearanceFor]); the title falls back to the
/// category name (then the type label) when there's no note; the meta line
/// carries the wallet, time, and a "kamu" ownership signal.
class TransactionActivityRow extends StatelessWidget {
  const TransactionActivityRow({
    required this.tx,
    required this.walletName,
    required this.mine,
    required this.category,
    required this.onTap,
    super.key,
  });

  final Transaction tx;
  final String walletName;
  final bool mine;

  /// The resolved category for [tx] (null when uncategorized/transfer) — drives
  /// the leading tile's chosen icon + color and the note-less title fallback.
  final Category? category;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isIncome = tx.type == TransactionType.income;
    // With a note → the note; no note but a category → the category name (e.g.
    // "Makanan"); neither (transfer/adjustment) → the type label.
    final title = tx.note.isNotEmpty
        ? tx.note
        : (category?.name ?? transactionTypeLabel(tx.type));
    final sign = isIncome
        ? '+'
        : (tx.type == TransactionType.expense ? '-' : '');
    final amount = '$sign${MoneyFormatter.idr(tx.amountMinor.abs())}';
    // Ownership ("kamu") stays in the meta line so the leading slot can show
    // the CATEGORY icon+color instead of an initial avatar.
    final meta =
        '$walletName · ${AffluenaDateFormatter.time(tx.transactionAt)}${mine ? ' · kamu' : ''}';
    final appearance = categoryAppearanceFor(category, type: tx.type);
    final tileColor = appearance.color ?? context.sky.accent;

    // Material + InkWell (the _DashCard pattern) so the tap ripples on the
    // card surface. The 34px tile plus 2×11px vertical padding keeps the
    // touch target at ≥52px, clear of the 48px minimum.
    return Padding(
      padding: const EdgeInsets.only(bottom: AffluenaSpacing.space2),
      child: Material(
        color: context.sky.surface,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Ink(
            padding: const EdgeInsets.symmetric(
              horizontal: AffluenaSpacing.space3,
              vertical: 11,
            ),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: context.sky.line),
            ),
            child: Row(
              children: [
                Container(
                  key: const Key('activity-row-category-icon'),
                  width: 34,
                  height: 34,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: tileColor.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(11),
                  ),
                  child: Icon(appearance.icon, size: 18, color: tileColor),
                ),
                const SizedBox(width: AffluenaSpacing.space3),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w600,
                          color: context.sky.ink,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        meta,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 11,
                          color: context.sky.muted,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AffluenaSpacing.space2),
                Text(
                  amount,
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                    color: isIncome ? context.sky.income : context.sky.ink,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
