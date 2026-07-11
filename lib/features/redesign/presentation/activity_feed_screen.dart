import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
/// category, inclusive date range, and free-text search. All-null = today's
/// unfiltered feed.
///
/// A record compares by value (field-equal), so the family key is stable across
/// rebuilds — the same `(walletId, categoryId, from, to, search)` never
/// respawns a fetch. The [DateTime]s are the raw pickers; the provider
/// date-truncates them to ISO before the request. [search] is the debounced,
/// trimmed query (null when empty) — the API matches it against the note,
/// category name, and wallet name over the FULL history.
typedef ActivityQuery = ({
  String? walletId,
  String? categoryId,
  DateTime? from,
  DateTime? to,
  String? search,
});

/// Recent transactions across MY wallets, newest first — the source for the
/// Aktivitas feed. A standalone provider so the redesign Activity never clobbers
/// the legacy Transactions tab filter.
///
/// Keyed by an [ActivityQuery] so the feed's own date/category/wallet filters
/// AND the search query apply SERVER-side (mirroring the ledger's
/// [TransactionsController.load]); the all-null query is the default
/// unfiltered feed. Search used to be a client-side `contains` over the
/// fetched page — it now rides the API's `search=` param, so it matches the
/// full history instead of just the latest 100 rows.
///
/// Wallets shared TO me (role 'viewer') are excluded, mirroring the main
/// ledger's [TransactionsState.visibleTransactions]: those rows are read-only
/// and belong to someone else, so surfacing them here would leak another
/// person's activity into my feed.
final recentActivityProvider = FutureProvider.autoDispose
    .family<List<Transaction>, ActivityQuery>((ref, q) async {
      final repository = ref.watch(transactionRepositoryProvider);
      final response = await repository.listTransactions(
        walletId: q.walletId,
        categoryId: q.categoryId,
        from: _iso(q.from),
        to: _iso(q.to),
        search: q.search,
        limit: 100,
        offset: 0,
        sort: 'transaction_at_desc',
      );
      var transactions = response.transactions;

      // Parity with the RENDERED row titles: the API's `search=` matches the
      // note, category name, and wallet name — but a note-less UNCATEGORIZED
      // row is titled by its type label ("Transfer", "Pemasukan",
      // "Pengeluaran", "Penyesuaian"; see [TransactionActivityRow]), which
      // the server can't match. When the query could name such a label, also
      // fetch the same window WITHOUT `search=` and union in the rows whose
      // visible title matches — so what the feed shows stays findable, like
      // the ledger's client-side search.
      final query = q.search?.toLowerCase();
      if (query != null && _matchesAnyTypeLabel(query)) {
        final unsearched = await repository.listTransactions(
          walletId: q.walletId,
          categoryId: q.categoryId,
          from: _iso(q.from),
          to: _iso(q.to),
          limit: 100,
          offset: 0,
          sort: 'transaction_at_desc',
        );
        final seen = {for (final t in transactions) t.id};
        final extras = unsearched.transactions.where(
          (t) =>
              !seen.contains(t.id) &&
              t.note.isEmpty &&
              t.categoryId == null &&
              transactionTypeLabel(t.type).toLowerCase().contains(query),
        );
        if (extras.isNotEmpty) {
          transactions = [...transactions, ...extras]
            ..sort((a, b) => b.transactionAt.compareTo(a.transactionAt));
        }
      }

      final wallets = await ref.watch(walletListProvider.future);
      final viewerWalletIds = {
        for (final w in wallets)
          if (w.isViewer) w.id,
      };
      return transactions
          .where((t) => !viewerWalletIds.contains(t.walletId))
          .toList();
    });

/// Whether the (lowercased) query appears in any transaction-type label — the
/// only case where the client-side title-parity pass above can add rows the
/// server search missed, and so the only case worth the second fetch.
bool _matchesAnyTypeLabel(String query) {
  if (query.isEmpty) return false;
  return TransactionType.values.any(
    (type) => transactionTypeLabel(type).toLowerCase().contains(query),
  );
}

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
/// as a tab in the redesign nav shell. Stateful for the debounced search query
/// and the server-side filters (both local to this surface; both applied
/// server-side through [recentActivityProvider]'s [ActivityQuery] key).
class ActivityFeedView extends ConsumerStatefulWidget {
  const ActivityFeedView({super.key});

  @override
  ConsumerState<ActivityFeedView> createState() => _ActivityFeedViewState();
}

class _ActivityFeedViewState extends ConsumerState<ActivityFeedView> {
  /// How long typing must pause before the search query hits the API. Keeps
  /// keystroke-per-request traffic off the server while staying responsive.
  static const _searchDebounce = Duration(milliseconds: 350);

  final _searchController = TextEditingController();

  /// Whether the search field is expanded. Search lives behind a header icon
  /// (mirroring the category picker); collapsing it clears the query.
  bool _searchVisible = false;

  /// What the field currently shows (drives the clear button instantly).
  String _searchQuery = '';

  /// The debounced query the provider fetches with (server-side `search=`).
  String _debouncedQuery = '';
  Timer? _searchTimer;

  /// Server-side filters (date/category/wallet). `type`/`tagId` stay null — the
  /// Aktivitas filter is date/category/wallet only (the sheet hides Tag).
  TransactionFilters _filters = const TransactionFilters();

  @override
  void dispose() {
    _searchTimer?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  /// The family key the current filters + debounced search map to.
  ActivityQuery get _query => (
    walletId: _filters.walletId,
    categoryId: _filters.categoryId,
    from: _filters.from,
    to: _filters.to,
    search: _debouncedQuery.isEmpty ? null : _debouncedQuery,
  );

  /// The API rejects search queries over 100 runes with a 400; mirror the cap
  /// client-side so a pasted wall of text can never error the whole feed.
  /// Runes (code points), not [String.length] or graphemes, to match Go's
  /// `utf8.RuneCountInString`.
  static const _maxSearchRunes = 100;

  void _onSearchChanged(String value) {
    // An emptied field behaves like the clear button: there is no keystroke
    // traffic left to throttle, so skip the debounce. Waiting would render
    // the stale no-match result against an empty live query — briefly showing
    // the wrong "Belum ada transaksi" onboarding state to a user who has
    // transactions.
    if (value.trim().isEmpty) {
      _searchTimer?.cancel();
      setState(() {
        _searchQuery = value;
        _debouncedQuery = '';
      });
      return;
    }
    setState(() => _searchQuery = value);
    _searchTimer?.cancel();
    _searchTimer = Timer(_searchDebounce, () {
      if (!mounted) return;
      final trimmed = value.trim();
      setState(() {
        _debouncedQuery = String.fromCharCodes(
          trimmed.runes.take(_maxSearchRunes),
        );
      });
    });
  }

  /// Clearing is instant (no debounce): the button should restore the
  /// unsearched feed immediately.
  void _clearSearch() {
    _searchTimer?.cancel();
    _searchController.clear();
    setState(() {
      _searchQuery = '';
      _debouncedQuery = '';
    });
  }

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
          Row(
            children: [
              Expanded(
                child: Text(
                  'Aktivitas',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: context.sky.ink,
                  ),
                ),
              ),
              // Search is a header icon (not an always-on field), mirroring the
              // category picker: tapping toggles the input; collapsing clears
              // the query so the feed snaps back to the unsearched state.
              IconButton(
                key: const Key('activity-search-button'),
                tooltip: _searchVisible ? 'Tutup pencarian' : 'Cari transaksi',
                visualDensity: VisualDensity.compact,
                onPressed: () => setState(() {
                  _searchVisible = !_searchVisible;
                  if (!_searchVisible) _clearSearch();
                }),
                icon: Icon(
                  _searchVisible ? Icons.close : Icons.search,
                  color: context.sky.muted,
                ),
              ),
              const SizedBox(width: AffluenaSpacing.space1),
              _FilterButton(
                activeCount: _filters.activeCount,
                onTap: () => _openFilters(context, txState),
              ),
            ],
          ),
          const SizedBox(height: AffluenaSpacing.space3),
          if (_searchVisible) ...[
            TextField(
              key: const Key('activity-search-field'),
              controller: _searchController,
              autofocus: true,
              autocorrect: false,
              textInputAction: TextInputAction.search,
              // Silently cap at the API's 100-rune limit (no counter UI) so a
              // pasted long string can't 400 the feed into the error state.
              maxLength: _maxSearchRunes,
              maxLengthEnforcement: MaxLengthEnforcement.enforced,
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search),
                hintText: 'Cari catatan, dompet, atau kategori',
                counterText: '',
                suffixIcon: isSearching
                    ? IconButton(
                        key: const Key('activity-search-clear'),
                        tooltip: 'Hapus pencarian',
                        icon: const Icon(Icons.close),
                        onPressed: _clearSearch,
                      )
                    : null,
              ),
              onChanged: _onSearchChanged,
            ),
            const SizedBox(height: AffluenaSpacing.space3),
          ],
          Text(
            'Transaksi terbaru dari semua dompetmu',
            style: TextStyle(fontSize: 12.5, color: context.sky.muted),
          ),
          if (_filters.hasActiveFilters) ...[
            const SizedBox(height: AffluenaSpacing.space3),
            _ActiveFilterChips(
              filters: _filters,
              txState: txState,
              onClear: _clearFilters,
              onFiltersChanged: (next) => setState(() => _filters = next),
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
            data: (visible) {
              if (visible.isEmpty) {
                // Distinguish a genuinely empty feed from one narrowed to
                // nothing by the active search/filter. Judged by the DEBOUNCED
                // query — the one that produced THIS data — not the live field
                // text, which can diverge inside the debounce window.
                if (_debouncedQuery.isNotEmpty || _filters.hasActiveFilters) {
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
    _searchTimer?.cancel();
    _searchController.clear();
    setState(() {
      _searchQuery = '';
      _debouncedQuery = '';
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
/// Tapping an individual chip removes exactly that filter.
class _ActiveFilterChips extends StatelessWidget {
  const _ActiveFilterChips({
    required this.filters,
    required this.txState,
    required this.onClear,
    required this.onFiltersChanged,
  });

  final TransactionFilters filters;
  final TransactionsState txState;
  final VoidCallback onClear;

  /// Fired with the filter set minus the tapped chip's own filter
  /// (copyWith's kUnchanged sentinel supports the explicit null).
  final ValueChanged<TransactionFilters> onFiltersChanged;

  @override
  Widget build(BuildContext context) {
    final chips = <({String label, TransactionFilters next})>[
      if (filters.walletId != null)
        (
          label: txState.walletName(filters.walletId!),
          next: filters.copyWith(walletId: null),
        ),
      if (filters.categoryId != null)
        (
          label: txState.categoryNames[filters.categoryId] ?? 'Kategori',
          next: filters.copyWith(categoryId: null),
        ),
      if (filters.from != null)
        (
          label: 'Dari ${txState.filterDateLabel(filters.from!)}',
          next: filters.copyWith(from: null),
        ),
      if (filters.to != null)
        (
          label: 'Sampai ${txState.filterDateLabel(filters.to!)}',
          next: filters.copyWith(to: null),
        ),
    ];

    return AffluenaChipBar(
      chips: [
        for (final chip in chips)
          AffluenaChoiceChip(
            label: chip.label,
            selected: true,
            onSelected: () => onFiltersChanged(chip.next),
          ),
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
