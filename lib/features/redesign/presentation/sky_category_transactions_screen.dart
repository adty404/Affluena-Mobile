import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/affluena_theme.dart';
import '../../../app/theme/sky_palette.dart';
import '../../../core/formatters/date_formatter.dart';
import '../../auth/application/auth_controller.dart';
import '../../insights/application/category_breakdown_providers.dart';
import '../../shared/presentation/widgets/drill_in_scaffold.dart';
import '../../shared/presentation/widgets/empty_state.dart';
import '../../shared/presentation/widgets/error_state.dart';
import '../../transactions/application/transactions_controller.dart';
import '../../transactions/data/transaction_models.dart';
import '../../transactions/presentation/transaction_activity_row.dart';
import '../../transactions/presentation/transaction_detail_sheet.dart';
import '../../wallets/application/wallets_controller.dart';
import '../../wallets/data/wallet_models.dart';

/// The full list of one category's transactions within a period, opened by
/// tapping a category row on the Wawasan breakdown. Header shows the category
/// name + the period the user came from; the body day-groups every matching
/// transaction (the full range — no feed-style oldest-day truncation) and each
/// row taps through to the shared detail sheet.
class SkyCategoryTransactionsScreen extends ConsumerWidget {
  const SkyCategoryTransactionsScreen({
    required this.categoryId,
    required this.categoryName,
    required this.range,
    required this.periodLabel,
    super.key,
  });

  final String categoryId;
  final String categoryName;
  final DateRange range;

  /// The human period the user came from (e.g. "Juni 2026"), shown as the
  /// subtitle so they keep their bearings.
  final String periodLabel;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final query = (categoryId: categoryId, range: range);
    final txAsync = ref.watch(categoryTransactionsInRangeProvider(query));
    final wallets =
        ref.watch(walletListProvider).asData?.value ?? const <Wallet>[];
    final walletNames = {for (final w in wallets) w.id: w.name};
    final meId = ref.watch(authControllerProvider).user?.id;
    // Powers the detail sheet's name resolution + edit/delete, matching the
    // ledger and Aktivitas (per CLAUDE.md every tx row is tappable → detail).
    final txState = ref.watch(transactionsControllerProvider);

    return DrillInScaffold(
      title: categoryName,
      body: txAsync.when(
        loading: () => Padding(
          padding: const EdgeInsets.symmetric(vertical: AffluenaSpacing.space6),
          child: Center(
            child: CircularProgressIndicator(color: context.sky.accent),
          ),
        ),
        error: (_, _) => ErrorState(
          message: 'Tidak bisa memuat transaksi. Coba lagi, ya.',
          onRetry: () =>
              ref.invalidate(categoryTransactionsInRangeProvider(query)),
        ),
        data: (txns) => txns.isEmpty
            ? EmptyState(
                icon: Icons.receipt_long_outlined,
                title: 'Belum ada transaksi',
                subtitle: 'Tidak ada transaksi di kategori ini pada '
                    '$periodLabel.',
              )
            : _CategoryTxList(
                txns: txns,
                periodLabel: periodLabel,
                walletNames: walletNames,
                meId: meId,
                txState: txState,
                onOpen: (tx) => showTransactionDetail(context, ref, txState, tx),
              ),
      ),
    );
  }
}

class _CategoryTxList extends StatelessWidget {
  const _CategoryTxList({
    required this.txns,
    required this.periodLabel,
    required this.walletNames,
    required this.meId,
    required this.txState,
    required this.onOpen,
  });

  final List<Transaction> txns;
  final String periodLabel;
  final Map<String, String> walletNames;
  final String? meId;
  final TransactionsState txState;
  final ValueChanged<Transaction> onOpen;

  @override
  Widget build(BuildContext context) {
    // A day-grouped list over the FULL range — no oldest-day truncation (that
    // heuristic only applies to the 100-cap Aktivitas feed).
    final children = <Widget>[
      Padding(
        padding: const EdgeInsets.only(bottom: AffluenaSpacing.space4),
        child: Text(
          periodLabel,
          style: TextStyle(fontSize: 12.5, color: context.sky.muted),
        ),
      ),
    ];
    DateTime? currentDay;
    for (final tx in txns) {
      final day = AffluenaDateFormatter.localDay(tx.transactionAt);
      if (currentDay == null || day != currentDay) {
        currentDay = day;
        children.add(
          Padding(
            padding: const EdgeInsets.only(
              top: AffluenaSpacing.space3,
              bottom: AffluenaSpacing.space2,
            ),
            child: Text(
              AffluenaDateFormatter.dayHeader(day),
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: context.sky.faint,
              ),
            ),
          ),
        );
      }
      children.add(
        TransactionActivityRow(
          tx: tx,
          walletName: walletNames[tx.walletId] ?? 'Dompet',
          mine: meId != null && tx.userId == meId,
          category: txState.categoryOf(tx),
          onTap: () => onOpen(tx),
        ),
      );
    }

    return ListView(
      // Extra bottom padding so the last row clears the floating nav pill.
      padding: AffluenaInsets.screen.copyWith(bottom: 120),
      children: children,
    );
  }
}
