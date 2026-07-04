import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/affluena_theme.dart';
import '../../../app/theme/sky_palette.dart';
import '../../../core/formatters/date_formatter.dart';
import '../../auth/application/auth_controller.dart';
import '../../shared/presentation/widgets/affluena_chip_bar.dart';
import '../../shared/presentation/widgets/affluena_choice_chip.dart';
import '../../shared/presentation/widgets/empty_state.dart';
import '../../shared/presentation/widgets/error_state.dart';
import '../../transactions/application/transactions_controller.dart';
import '../../transactions/data/transaction_models.dart';
import '../../transactions/data/transaction_repository.dart';
import '../../transactions/presentation/transaction_activity_row.dart';
import '../../transactions/presentation/transaction_detail_sheet.dart';
import '../../transactions/presentation/transaction_filter_sheet.dart';
import '../../wallets/application/wallets_controller.dart';
import '../../wallets/data/wallet_models.dart';

/// The server-side filter key for the Aktivitas feed: an optional wallet,
/// category, and inclusive date range. All-null = today's unfiltered feed.
///
/// A record compares by value (field-equal), so the family key is stable across
/// rebuilds — the same `(walletId, categoryId, from, to)` never respawns a
/// fetch. The [DateTime]s are the raw pickers; the provider date-truncates them
/// to ISO before the request.
typedef ActivityQuery = ({
  String? walletId,
  String? categoryId,
  DateTime? from,
  DateTime? to,
});

/// Recent transactions across MY wallets, newest first — the source for the
/// Aktivitas feed. A standalone provider so the redesign Activity never clobbers
/// the legacy Transactions tab filter.
///
/// Keyed by an [ActivityQuery] so the feed's own date/category/wallet filters
/// apply SERVER-side (mirroring the ledger's [TransactionsController.load]); the
/// all-null query is the default unfiltered feed. The client-side search
/// (note/wallet/category) is layered on top in [ActivityFeedView].
///
/// Wallets shared TO me (role 'viewer') are excluded, mirroring the main
/// ledger's [TransactionsState.visibleTransactions]: those rows are read-only
/// and belong to someone else, so surfacing them here would leak another
/// person's activity into my feed.
final recentActivityProvider = FutureProvider.autoDispose
    .family<List<Transaction>, ActivityQuery>((ref, q) async {
      final response = await ref
          .watch(transactionRepositoryProvider)
          .listTransactions(
            walletId: q.walletId,
            categoryId: q.categoryId,
            from: _iso(q.from),
            to: _iso(q.to),
            limit: 100,
            offset: 0,
            sort: 'transaction_at_desc',
          );
      final wallets = await ref.watch(walletListProvider.future);
      final viewerWalletIds = {
        for (final w in wallets)
          if (w.isViewer) w.id,
      };
      return response.transactions
          .where((t) => !viewerWalletIds.contains(t.walletId))
          .toList();
    });

/// Date-only ISO for the transactions API (`YYYY-MM-DDT00:00:00Z`), null-safe.
/// Matches [TransactionsController]'s private `_isoDate` so the feed's filter
/// maps to the same server window as the ledger.
String? _iso(DateTime? date) {
  if (date == null) return null;
  final month = date.month.toString().padLeft(2, '0');
  final day = date.day.toString().padLeft(2, '0');
  return '${date.year}-$month-${day}T00:00:00Z';
}

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
/// as a tab in the redesign nav shell. Stateful for the client-side search query
/// and the server-side filters (both local to this surface).
class ActivityFeedView extends ConsumerStatefulWidget {
  const ActivityFeedView({super.key});

  @override
  ConsumerState<ActivityFeedView> createState() => _ActivityFeedViewState();
}

class _ActivityFeedViewState extends ConsumerState<ActivityFeedView> {
  final _searchController = TextEditingController();
  String _searchQuery = '';

  /// Server-side filters (date/category/wallet). `type`/`tagId` stay null — the
  /// Aktivitas filter is date/category/wallet only (the sheet hides Tag).
  TransactionFilters _filters = const TransactionFilters();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  /// The family key the current filters map to.
  ActivityQuery get _query => (
    walletId: _filters.walletId,
    categoryId: _filters.categoryId,
    from: _filters.from,
    to: _filters.to,
  );

  @override
  Widget build(BuildContext context) {
    final txAsync = ref.watch(recentActivityProvider(_query));
    final wallets =
        ref.watch(walletListProvider).asData?.value ?? const <Wallet>[];
    final walletNames = {for (final w in wallets) w.id: w.name};
    final meId = ref.watch(authControllerProvider).user?.id;
    // Row taps open the shared transaction detail sheet — the same surface
    // TransactionsScreen uses. It needs the transactions controller's lookup
    // maps (wallet/category names) and powers the sheet's edit/delete flows.
    // It also backs the filter sheet's wallet/category selectors.
    final txState = ref.watch(transactionsControllerProvider);
    final isSearching = _searchQuery.trim().isNotEmpty;

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
          TextField(
            key: const Key('activity-search-field'),
            controller: _searchController,
            autocorrect: false,
            textInputAction: TextInputAction.search,
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.search),
              hintText: 'Cari catatan, dompet, atau kategori',
              suffixIcon: isSearching
                  ? IconButton(
                      key: const Key('activity-search-clear'),
                      tooltip: 'Hapus pencarian',
                      icon: const Icon(Icons.close),
                      onPressed: () {
                        _searchController.clear();
                        setState(() => _searchQuery = '');
                      },
                    )
                  : null,
            ),
            onChanged: (value) => setState(() => _searchQuery = value),
          ),
          const SizedBox(height: AffluenaSpacing.space3),
          Row(
            children: [
              Expanded(
                child: Text(
                  'Transaksi terbaru dari semua dompetmu',
                  style: TextStyle(fontSize: 12.5, color: context.sky.muted),
                ),
              ),
              const SizedBox(width: AffluenaSpacing.space2),
              _FilterButton(
                activeCount: _filters.activeCount,
                onTap: () => _openFilters(context, txState),
              ),
            ],
          ),
          if (_filters.hasActiveFilters) ...[
            const SizedBox(height: AffluenaSpacing.space3),
            _ActiveFilterChips(
              filters: _filters,
              txState: txState,
              onClear: _clearFilters,
            ),
          ],
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
              onRetry: () => ref.invalidate(recentActivityProvider(_query)),
            ),
            data: (txns) {
              final visible = _applySearch(txns, walletNames, txState);
              if (visible.isEmpty) {
                // Distinguish a genuinely empty feed from one narrowed to
                // nothing by the active search/filter.
                if (isSearching || _filters.hasActiveFilters) {
                  return EmptyState(
                    icon: Icons.search_off_outlined,
                    title: 'Tidak ada transaksi yang cocok',
                    subtitle:
                        'Coba ubah pencarian atau hapus filter untuk '
                        'melihat lebih banyak.',
                    actionLabel: 'Hapus filter & pencarian',
                    actionIcon: Icons.filter_alt_off_outlined,
                    onAction: _clearAll,
                  );
                }
                return EmptyState(
                  icon: Icons.receipt_long_outlined,
                  title: 'Belum ada transaksi',
                  subtitle:
                      'Catat transaksi pertamamu lewat tombol + di bawah.',
                );
              }
              return _Feed(
                txns: visible,
                walletNames: walletNames,
                meId: meId,
                txState: txState,
                onOpen: (tx) =>
                    showTransactionDetail(context, ref, txState, tx),
              );
            },
          ),
        ],
      ),
    );
  }

  /// The client-side search, matching [TransactionsState.visibleTransactions]:
  /// case-insensitive `contains` over the note, wallet name, and category name.
  /// (Viewer-wallet exclusion already happened in the provider.)
  List<Transaction> _applySearch(
    List<Transaction> txns,
    Map<String, String> walletNames,
    TransactionsState txState,
  ) {
    final query = _searchQuery.trim().toLowerCase();
    if (query.isEmpty) return txns;
    return txns.where((tx) {
      final note = tx.note.toLowerCase();
      final wallet = (walletNames[tx.walletId] ?? '').toLowerCase();
      final category = txState.categoryName(tx).toLowerCase();
      return note.contains(query) ||
          wallet.contains(query) ||
          category.contains(query);
    }).toList(growable: false);
  }

  Future<void> _openFilters(
    BuildContext context,
    TransactionsState txState,
  ) async {
    final result = await showTransactionFilterSheet(
      context: context,
      state: txState,
      initialFilters: _filters,
      includeTag: false,
    );
    if (result == null) return;
    setState(() => _filters = result);
  }

  void _clearFilters() {
    setState(() => _filters = const TransactionFilters());
  }

  void _clearAll() {
    _searchController.clear();
    setState(() {
      _searchQuery = '';
      _filters = const TransactionFilters();
    });
  }

  /// Pull-to-refresh: reload the merged feed (and the wallet names shown on
  /// each row). Errors surface through the provider's error state, not here.
  Future<void> _refresh(WidgetRef ref) async {
    ref.invalidate(recentActivityProvider(_query));
    ref.invalidate(walletListProvider);
    try {
      await ref.read(recentActivityProvider(_query).future);
    } catch (_) {
      // The feed renders its own error + retry.
    }
  }
}

/// The `Icons.tune` filter affordance — a filled tonal button badged with the
/// active-filter count, mirroring the ledger's filter button.
class _FilterButton extends StatelessWidget {
  const _FilterButton({required this.activeCount, required this.onTap});

  final int activeCount;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final hasActive = activeCount > 0;
    return Badge(
      isLabelVisible: hasActive,
      label: Text('$activeCount'),
      backgroundColor: context.sky.danger,
      child: IconButton.filledTonal(
        key: const Key('activity-filter-button'),
        tooltip: 'Saring aktivitas',
        onPressed: onTap,
        icon: const Icon(Icons.tune),
      ),
    );
  }
}

/// A scrollable chip strip summarising the active server-side filters (wallet /
/// category / date range) with an "Atur ulang" chip to clear them all.
class _ActiveFilterChips extends StatelessWidget {
  const _ActiveFilterChips({
    required this.filters,
    required this.txState,
    required this.onClear,
  });

  final TransactionFilters filters;
  final TransactionsState txState;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final labels = <String>[
      if (filters.walletId != null) txState.walletName(filters.walletId!),
      if (filters.categoryId != null)
        (txState.categoryNames[filters.categoryId] ?? 'Kategori'),
      if (filters.from != null) 'Dari ${txState.filterDateLabel(filters.from!)}',
      if (filters.to != null) 'Sampai ${txState.filterDateLabel(filters.to!)}',
    ];

    return AffluenaChipBar(
      chips: [
        for (final label in labels)
          AffluenaChoiceChip(label: label, selected: true, onSelected: () {}),
        AffluenaChoiceChip(
          key: const Key('activity-clear-filters'),
          label: 'Atur ulang',
          selected: false,
          onSelected: onClear,
        ),
      ],
    );
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
        TransactionActivityRow(
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
