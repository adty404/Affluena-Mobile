import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/affluena_theme.dart';
import '../../../core/formatters/date_formatter.dart';
import '../../../core/formatters/tag_formatter.dart';
import '../../insights/application/audit_log_controller.dart';
import '../../insights/data/insight_models.dart';
import '../../shared/presentation/widgets/affluena_banner.dart';
import '../../shared/presentation/widgets/affluena_card.dart';
import '../../shared/presentation/widgets/affluena_choice_chip.dart';
import '../../shared/presentation/widgets/affluena_skeleton.dart';
import '../../shared/presentation/widgets/drill_in_scaffold.dart';
import '../../shared/presentation/widgets/transaction_tile.dart';
import '../application/transactions_controller.dart';
import '../data/transaction_models.dart';
import 'transaction_create_screen.dart';
import 'transaction_detail_sheet.dart';
import 'transaction_display.dart';
import 'transaction_filter_sheet.dart';

/// The two views of the Activity tab: the raw transactions ledger, and the
/// broader user-action feed (split bill, debt/installment/subscription payments,
/// etc.) sourced from the audit log.
enum _ActivityView { transactions, activity }

class TransactionsScreen extends ConsumerStatefulWidget {
  const TransactionsScreen({super.key});

  static const path = '/transactions';

  @override
  ConsumerState<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends ConsumerState<TransactionsScreen> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  _ActivityView _view = _ActivityView.transactions;

  @override
  Widget build(BuildContext context) {
    return DrillInScaffold(
      title: 'Transaksi',
      body: SafeArea(
        child: ListView(
          padding: AffluenaInsets.screen,
          children: [
            SegmentedButton<_ActivityView>(
              showSelectedIcon: false,
              segments: const [
                ButtonSegment(
                  value: _ActivityView.transactions,
                  label: Text('Transaksi'),
                ),
                ButtonSegment(
                  value: _ActivityView.activity,
                  label: Text('Aktivitas'),
                ),
              ],
              selected: {_view},
              onSelectionChanged: (selection) =>
                  setState(() => _view = selection.first),
            ),
            const SizedBox(height: AffluenaSpacing.space5),
            if (_view == _ActivityView.transactions)
              ..._buildTransactionsChildren(context)
            else
              ..._buildActivityChildren(context),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildTransactionsChildren(BuildContext context) {
    final state = ref.watch(transactionsControllerProvider);
    final controller = ref.read(transactionsControllerProvider.notifier);

    if (state.isLoading && state.transactions.isEmpty) {
      return const [_TransactionsLoadingBody()];
    }
    if (state.loadError != null && state.transactions.isEmpty) {
      return [
        AffluenaBanner.error(
          state.loadError!,
          onRetry: () => controller.load(reset: true),
        ),
      ];
    }

    final visible = state.visibleTransactions;
    final isSearching = state.searchQuery.trim().isNotEmpty;

    return [
      TextField(
        key: const Key('transactions-search-field'),
        controller: _searchController,
        autocorrect: false,
        textInputAction: TextInputAction.search,
        decoration: InputDecoration(
          prefixIcon: const Icon(Icons.search),
          hintText: 'Cari catatan, dompet, atau kategori',
          suffixIcon: isSearching
              ? IconButton(
                  key: const Key('transactions-search-clear'),
                  tooltip: 'Hapus pencarian',
                  icon: const Icon(Icons.close),
                  onPressed: () {
                    _searchController.clear();
                    controller.setSearchQuery('');
                  },
                )
              : null,
        ),
        onChanged: controller.setSearchQuery,
      ),
      const SizedBox(height: AffluenaSpacing.space3),
      Row(
        children: [
          Expanded(
            child: FilledButton.icon(
              key: const Key('transaction-create-entry-button'),
              onPressed: () => context.push(TransactionCreateScreen.path),
              icon: const Icon(Icons.add),
              label: const Text('Transaksi baru'),
            ),
          ),
        ],
      ),
      const SizedBox(height: AffluenaSpacing.space3),
      Row(
        children: [
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  for (final (label, type)
                      in const <(String, TransactionType?)>[
                        ('Semua', null),
                        ('Pemasukan', TransactionType.income),
                        ('Pengeluaran', TransactionType.expense),
                        ('Transfer', TransactionType.transfer),
                        ('Penyesuaian', TransactionType.adjustment),
                      ])
                    Padding(
                      padding: const EdgeInsets.only(
                        right: AffluenaSpacing.space2,
                      ),
                      child: AffluenaChoiceChip(
                        label: label,
                        selected: state.typeFilter == type,
                        onSelected: () => controller.setTypeFilter(type),
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(width: AffluenaSpacing.space2),
          _FilterButton(
            activeCount: state.filters.activeCount,
            onTap: () => _openFilters(context, state, controller),
          ),
        ],
      ),
      if (state.filters.hasActiveFilters) ...[
        const SizedBox(height: AffluenaSpacing.space3),
        _ActiveFilterSummary(state: state, onClear: controller.clearFilters),
      ],
      const SizedBox(height: AffluenaSpacing.space5),
      if (state.actionError != null) ...[
        AffluenaBanner.error(
          state.actionError!,
          onRetry: () => controller.load(reset: true),
        ),
        const SizedBox(height: AffluenaSpacing.space3),
      ],
      if (state.transactions.isEmpty)
        _EmptyTransactionsState(
          hasFilters: state.filters.hasActiveFilters,
          onClearFilters: controller.clearFilters,
          onCreate: () => context.push(TransactionCreateScreen.path),
        )
      else if (visible.isEmpty)
        _NoSearchMatchesState(
          query: state.searchQuery.trim(),
          onClear: () {
            _searchController.clear();
            controller.setSearchQuery('');
          },
        )
      else
        ..._dayGroupedSections(context, state, visible),
      if (state.hasMore && !isSearching) ...[
        const SizedBox(height: AffluenaSpacing.space4),
        OutlinedButton(
          onPressed: state.isLoadingMore
              ? null
              : () => controller.load(reset: false),
          child: Text(state.isLoadingMore ? 'Memuat...' : 'Muat lebih banyak'),
        ),
      ],
      const SizedBox(height: AffluenaSpacing.space6),
    ];
  }

  List<Widget> _buildActivityChildren(BuildContext context) {
    final state = ref.watch(auditLogControllerProvider);
    final controller = ref.read(auditLogControllerProvider.notifier);

    if (state.isLoading && state.activities.isEmpty) {
      return const [_TransactionsLoadingBody()];
    }
    if (state.loadError != null && state.activities.isEmpty) {
      return [AffluenaBanner.error(state.loadError!, onRetry: controller.load)];
    }
    if (state.activities.isEmpty) {
      return const [
        AffluenaCard(
          child: Text(
            'Belum ada aktivitas. Tindakan seperti menambah transaksi, '
            'membayar utang, atau melunasi bagi tagihan akan muncul di sini.',
          ),
        ),
      ];
    }

    return [
      Text(
        '${state.activityTotal} tindakan tercatat',
        style: Theme.of(
          context,
        ).textTheme.bodySmall?.copyWith(color: context.affluenaColors.inkMuted),
      ),
      const SizedBox(height: AffluenaSpacing.space3),
      AffluenaCard(
        child: Column(
          children: [
            for (final entry in state.activities.indexed) ...[
              _ActivityFeedRow(activity: entry.$2),
              if (entry.$1 < state.activities.length - 1)
                const Divider(height: 1),
            ],
          ],
        ),
      ),
    ];
  }

  /// Renders the (date-desc) transactions as day groups: a "Today / Yesterday /
  /// date" header followed by a card of that day's rows. Scrolling down walks
  /// back through the days.
  List<Widget> _dayGroupedSections(
    BuildContext context,
    TransactionsState state,
    List<Transaction> visible,
  ) {
    final textTheme = Theme.of(context).textTheme;
    final colors = context.affluenaColors;
    final sections = <Widget>[];
    DateTime? currentDay;
    var dayTxns = <Transaction>[];

    void flush() {
      if (dayTxns.isEmpty || currentDay == null) return;
      final group = List<Transaction>.from(dayTxns);
      sections.add(
        Padding(
          padding: const EdgeInsets.only(
            top: AffluenaSpacing.space4,
            bottom: AffluenaSpacing.space2,
          ),
          child: Text(
            AffluenaDateFormatter.dayHeader(currentDay),
            style: textTheme.labelLarge?.copyWith(color: colors.inkMuted),
          ),
        ),
      );
      sections.add(
        AffluenaCard(
          child: Column(
            children: [
              for (final entry in group.indexed) ...[
                InkWell(
                  onTap: () =>
                      showTransactionDetail(context, ref, state, entry.$2),
                  child: TransactionTile(
                    title: transactionTitle(state, entry.$2),
                    metadata: transactionGroupedMetadata(state, entry.$2),
                    amount: transactionAmount(entry.$2),
                    icon: transactionIcon(state, entry.$2),
                    isIncome: entry.$2.type == TransactionType.income,
                  ),
                ),
                if (entry.$1 < group.length - 1) const Divider(height: 1),
              ],
            ],
          ),
        ),
      );
      dayTxns = [];
    }

    for (final transaction in visible) {
      final day = AffluenaDateFormatter.localDay(transaction.transactionAt);
      if (currentDay == null || day != currentDay) {
        flush();
        currentDay = day;
      }
      dayTxns.add(transaction);
    }
    flush();
    return sections;
  }

  Future<void> _openFilters(
    BuildContext context,
    TransactionsState state,
    TransactionsController controller,
  ) async {
    final result = await showTransactionFilterSheet(
      context: context,
      state: state,
    );
    if (result == null) return;
    controller.applyFilters(result);
  }
}

class _TransactionsLoadingBody extends StatelessWidget {
  const _TransactionsLoadingBody();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const AffluenaSkeleton(height: 56),
        const SizedBox(height: AffluenaSpacing.space3),
        const AffluenaSkeleton(height: 44),
        const SizedBox(height: AffluenaSpacing.space5),
        AffluenaCard(
          child: Column(
            children: [
              for (var i = 0; i < 4; i++) ...[
                const _TransactionTileSkeleton(),
                if (i < 3) const Divider(height: 1),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _ActivityFeedRow extends StatelessWidget {
  const _ActivityFeedRow({required this.activity});

  final ActivityItem activity;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colors = context.affluenaColors;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AffluenaSpacing.space3),
      child: Row(
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              color: colors.surfaceTintSoft,
              borderRadius: BorderRadius.circular(AffluenaRadii.md),
            ),
            child: Padding(
              padding: const EdgeInsets.all(AffluenaSpacing.space2),
              child: Icon(
                _activityIcon(activity.entityType),
                color: colors.forest,
                size: 20,
              ),
            ),
          ),
          const SizedBox(width: AffluenaSpacing.space3),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  activity.description,
                  style: textTheme.bodyLarge,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: AffluenaSpacing.space1),
                Text(
                  AffluenaDateFormatter.shortDate(activity.createdAt),
                  style: textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

IconData _activityIcon(String entityType) {
  return switch (entityType.toUpperCase()) {
    'TRANSACTION' => Icons.receipt_long_outlined,
    'SPLIT_BILL' => Icons.call_split_outlined,
    'DEBT' || 'DEBT_PAYMENT' => Icons.handshake_outlined,
    'INSTALLMENT' || 'INSTALLMENT_PAYMENT' => Icons.calendar_month_rounded,
    'SUBSCRIPTION' || 'SUBSCRIPTION_PAYMENT' => Icons.autorenew_rounded,
    'WALLET' => Icons.account_balance_wallet_outlined,
    'CATEGORY' => Icons.category_outlined,
    'TAG' => Icons.sell_outlined,
    'BUDGET' => Icons.pie_chart_outline,
    'GOAL' => Icons.flag_outlined,
    _ => Icons.bolt_outlined,
  };
}

class _TransactionTileSkeleton extends StatelessWidget {
  const _TransactionTileSkeleton();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AffluenaSpacing.space3),
      child: Row(
        children: [
          const AffluenaSkeleton.circle(size: 40),
          const SizedBox(width: AffluenaSpacing.space3),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                AffluenaSkeleton.line(width: 140),
                SizedBox(height: AffluenaSpacing.space2),
                AffluenaSkeleton.line(width: 200, height: 10),
              ],
            ),
          ),
          const SizedBox(width: AffluenaSpacing.space3),
          const AffluenaSkeleton.line(width: 72, height: 14),
        ],
      ),
    );
  }
}

class _FilterButton extends StatelessWidget {
  const _FilterButton({required this.activeCount, required this.onTap});

  final int activeCount;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.affluenaColors;
    final hasActive = activeCount > 0;

    return Badge(
      isLabelVisible: hasActive,
      label: Text('$activeCount'),
      backgroundColor: colors.coral,
      child: IconButton.filledTonal(
        key: const Key('transactions-filter-button'),
        tooltip: 'Saring transaksi',
        onPressed: onTap,
        icon: const Icon(Icons.tune),
      ),
    );
  }
}

class _ActiveFilterSummary extends StatelessWidget {
  const _ActiveFilterSummary({required this.state, required this.onClear});

  final TransactionsState state;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final colors = context.affluenaColors;
    final textTheme = Theme.of(context).textTheme;
    final filters = state.filters;
    final labels = <String>[
      if (filters.walletId != null) state.walletName(filters.walletId!),
      if (filters.categoryId != null)
        (state.categoryNames[filters.categoryId] ?? 'Kategori'),
      if (filters.tagId != null) tagLabel(state.tagName(filters.tagId!)),
      if (filters.from != null) 'Dari ${state.filterDateLabel(filters.from!)}',
      if (filters.to != null) 'Sampai ${state.filterDateLabel(filters.to!)}',
    ];

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.surfaceSoft,
        borderRadius: BorderRadius.circular(AffluenaRadii.lg),
        border: Border.all(color: colors.borderSubtle),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AffluenaSpacing.space3),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.tune, size: 18, color: colors.forest),
            const SizedBox(width: AffluenaSpacing.space3),
            Expanded(
              child: Text(
                labels.join(' · '),
                style: textTheme.bodySmall?.copyWith(color: colors.inkMuted),
              ),
            ),
            const SizedBox(width: AffluenaSpacing.space2),
            GestureDetector(
              key: const Key('transactions-clear-filters'),
              behavior: HitTestBehavior.opaque,
              onTap: onClear,
              child: Text(
                'Hapus',
                style: textTheme.labelMedium?.copyWith(
                  color: colors.forest,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyTransactionsState extends StatelessWidget {
  const _EmptyTransactionsState({
    required this.hasFilters,
    required this.onClearFilters,
    required this.onCreate,
  });

  final bool hasFilters;
  final VoidCallback onClearFilters;
  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colors = context.affluenaColors;

    return AffluenaCard(
      backgroundColor: colors.forestSoft,
      borderColor: colors.forestSoft,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.receipt_long_outlined, color: colors.forest),
          const SizedBox(height: AffluenaSpacing.space3),
          Text(
            hasFilters
                ? 'Tidak ada yang cocok dengan filter ini'
                : 'Belum ada transaksi',
            style: textTheme.titleMedium,
          ),
          const SizedBox(height: AffluenaSpacing.space1),
          Text(
            hasFilters
                ? 'Sesuaikan atau hapus filter untuk melihat lebih banyak aktivitas.'
                : 'Catat pemasukan, pengeluaran, dan transfer untuk memantau uangmu.',
            style: textTheme.bodySmall,
          ),
          const SizedBox(height: AffluenaSpacing.space4),
          if (hasFilters)
            OutlinedButton.icon(
              key: const Key('transactions-empty-clear-filters'),
              onPressed: onClearFilters,
              icon: const Icon(Icons.filter_alt_off_outlined),
              label: const Text('Hapus filter'),
            )
          else
            FilledButton.icon(
              key: const Key('transactions-empty-create'),
              onPressed: onCreate,
              icon: const Icon(Icons.add),
              label: const Text('Tambah transaksi'),
            ),
        ],
      ),
    );
  }
}

class _NoSearchMatchesState extends StatelessWidget {
  const _NoSearchMatchesState({required this.query, required this.onClear});

  final String query;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colors = context.affluenaColors;

    return AffluenaCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.search_off_outlined, color: colors.inkMuted),
          const SizedBox(height: AffluenaSpacing.space3),
          Text('Tidak ada hasil untuk "$query"', style: textTheme.titleMedium),
          const SizedBox(height: AffluenaSpacing.space1),
          Text(
            'Pencarian menjelajahi transaksi yang sudah dimuat berdasarkan '
            'catatan, dompet, atau kategori.',
            style: textTheme.bodySmall,
          ),
          const SizedBox(height: AffluenaSpacing.space4),
          OutlinedButton.icon(
            key: const Key('transactions-clear-search'),
            onPressed: onClear,
            icon: const Icon(Icons.close),
            label: const Text('Hapus pencarian'),
          ),
        ],
      ),
    );
  }
}
