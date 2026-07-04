import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/affluena_theme.dart';
import '../../../app/theme/sky_palette.dart';
import '../../../core/formatters/date_formatter.dart';
import '../../../core/formatters/money_formatter.dart';
import '../../auth/application/auth_controller.dart';
import '../../categories/data/category_models.dart';
import '../../shared/presentation/widgets/empty_state.dart';
import '../../shared/presentation/widgets/error_state.dart';
import '../../transactions/application/transactions_controller.dart';
import '../../transactions/data/transaction_models.dart';
import '../../transactions/data/transaction_repository.dart';
import '../../transactions/presentation/transaction_detail_sheet.dart';
import '../../transactions/presentation/transaction_display.dart';
import '../../wallets/application/wallets_controller.dart';
import '../../wallets/data/wallet_models.dart';

/// Recent transactions across MY wallets, newest first. A standalone provider
/// so the redesign Activity never clobbers the legacy Transactions tab filter.
///
/// Wallets shared TO me (role 'viewer') are excluded, mirroring the main
/// ledger's [TransactionsState.visibleTransactions]: those rows are read-only
/// and belong to someone else, so surfacing them here would leak another
/// person's activity into my feed.
final recentActivityProvider = FutureProvider<List<Transaction>>((ref) async {
  final response = await ref
      .watch(transactionRepositoryProvider)
      .listTransactions(limit: 100, offset: 0, sort: 'transaction_at_desc');
  final wallets = await ref.watch(walletListProvider.future);
  final viewerWalletIds = {
    for (final w in wallets)
      if (w.isViewer) w.id,
  };
  return response.transactions
      .where((t) => !viewerWalletIds.contains(t.walletId))
      .toList();
});

/// Redesign Tahap 5 — the cross-wallet merged Activity timeline: day-grouped,
/// each row showing the wallet, time, amount, and a "kamu" tag for the current
/// user's own entries (the couple-transparency signal). Additive route.
class ActivityFeedScreen extends StatelessWidget {
  const ActivityFeedScreen({super.key});

  static const path = '/rooms-activity';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.sky.ground,
      body: const SafeArea(child: ActivityFeedView()),
    );
  }
}

/// The merged Activity timeline body (no Scaffold/back) — hosted standalone or
/// as a tab in the redesign nav shell.
class ActivityFeedView extends ConsumerWidget {
  const ActivityFeedView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final txAsync = ref.watch(recentActivityProvider);
    final wallets =
        ref.watch(walletListProvider).asData?.value ?? const <Wallet>[];
    final walletNames = {for (final w in wallets) w.id: w.name};
    final meId = ref.watch(authControllerProvider).user?.id;
    // Row taps open the shared transaction detail sheet — the same surface
    // TransactionsScreen uses. It needs the transactions controller's lookup
    // maps (wallet/category names) and powers the sheet's edit/delete flows.
    final txState = ref.watch(transactionsControllerProvider);

    return RefreshIndicator(
      onRefresh: () => _refresh(ref),
      child: ListView(
        // Always scrollable so pull-to-refresh works even on a short feed.
        physics: const AlwaysScrollableScrollPhysics(),
        // Extra bottom padding so the last row clears the floating nav pill.
        padding: AffluenaInsets.screen.copyWith(bottom: 120),
        children: [
          Text(
            'Aktivitas',
            style: TextStyle(
              fontSize: 21,
              fontWeight: FontWeight.w700,
              color: context.sky.ink,
            ),
          ),
          const SizedBox(height: AffluenaSpacing.space4),
          txAsync.when(
            loading: () => Padding(
              padding: const EdgeInsets.symmetric(
                vertical: AffluenaSpacing.space6,
              ),
              child: Center(
                child: CircularProgressIndicator(color: context.sky.accent),
              ),
            ),
            error: (_, _) => ErrorState(
              message: 'Tidak bisa memuat aktivitas. Coba lagi, ya.',
              onRetry: () => ref.invalidate(recentActivityProvider),
            ),
            data: (txns) => txns.isEmpty
                ? EmptyState(
                    icon: Icons.receipt_long_outlined,
                    title: 'Belum ada transaksi',
                    subtitle:
                        'Catat transaksi pertamamu lewat tombol + di bawah.',
                  )
                : _Feed(
                    txns: txns,
                    walletNames: walletNames,
                    meId: meId,
                    txState: txState,
                    onOpen: (tx) =>
                        showTransactionDetail(context, ref, txState, tx),
                  ),
          ),
        ],
      ),
    );
  }

  /// Pull-to-refresh: reload the merged feed (and the wallet names shown on
  /// each row). Errors surface through the provider's error state, not here.
  Future<void> _refresh(WidgetRef ref) async {
    ref.invalidate(recentActivityProvider);
    ref.invalidate(walletListProvider);
    try {
      await ref.read(recentActivityProvider.future);
    } catch (_) {
      // The feed renders its own error + retry.
    }
  }
}

class _Feed extends StatelessWidget {
  const _Feed({
    required this.txns,
    required this.walletNames,
    required this.meId,
    required this.txState,
    required this.onOpen,
  });

  final List<Transaction> txns;
  final Map<String, String> walletNames;
  final String? meId;

  /// The transactions controller state, used to resolve each row's category
  /// (its chosen icon + color) — the same source the main ledger reads.
  final TransactionsState txState;
  final ValueChanged<Transaction> onOpen;

  /// The page cap the feed fetches; a full page means older rows exist.
  static const _fetchLimit = 100;

  /// When [txns] fills the fetch cap, its oldest day-group may be incomplete
  /// (rows spilled onto the next, unfetched page). Return the list without that
  /// last (oldest) day so a partial day never shows as complete. Below the cap
  /// the list is whole and returned unchanged.
  static List<Transaction> _dropTruncatedOldestDay(List<Transaction> txns) {
    if (txns.length < _fetchLimit) return txns;
    final oldestDay = AffluenaDateFormatter.localDay(txns.last.transactionAt);
    final trimmed = txns
        .where(
          (tx) => AffluenaDateFormatter.localDay(tx.transactionAt) != oldestDay,
        )
        .toList(growable: false);
    // Guard: if EVERY row falls on the same day, keep the list rather than
    // render nothing.
    return trimmed.isEmpty ? txns : trimmed;
  }

  @override
  Widget build(BuildContext context) {
    // The feed fetches at most 100 rows with no pagination. When it comes back
    // full the oldest day is likely incomplete, so drop that final day-group
    // (and its header) rather than render a truncated day as if it were whole.
    final visible = _dropTruncatedOldestDay(txns);

    final rows = <Widget>[];
    DateTime? currentDay;
    for (final tx in visible) {
      final day = AffluenaDateFormatter.localDay(tx.transactionAt);
      if (currentDay == null || day != currentDay) {
        currentDay = day;
        rows.add(
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
      rows.add(
        _ActivityRow(
          tx: tx,
          walletName: walletNames[tx.walletId] ?? 'Dompet',
          mine: meId != null && tx.userId == meId,
          category: txState.categoryOf(tx),
          onTap: () => onOpen(tx),
        ),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: rows,
    );
  }
}

class _ActivityRow extends StatelessWidget {
  const _ActivityRow({
    required this.tx,
    required this.walletName,
    required this.mine,
    required this.category,
    required this.onTap,
  });

  final Transaction tx;
  final String walletName;
  final bool mine;

  /// The resolved category for [tx] (null when uncategorized/transfer) — drives
  /// the leading tile's chosen icon + color.
  final Category? category;
  final VoidCallback onTap;

  static String _typeLabel(TransactionType type) => switch (type) {
    TransactionType.income => 'Pemasukan',
    TransactionType.expense => 'Pengeluaran',
    TransactionType.transfer => 'Transfer',
    TransactionType.adjustment => 'Penyesuaian',
  };

  @override
  Widget build(BuildContext context) {
    final isIncome = tx.type == TransactionType.income;
    final title = tx.note.isNotEmpty ? tx.note : _typeLabel(tx.type);
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
