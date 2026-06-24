import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/affluena_theme.dart';
import '../../shared/presentation/widgets/affluena_banner.dart';
import '../../shared/presentation/widgets/affluena_card.dart';
import '../../shared/presentation/widgets/affluena_skeleton.dart';
import '../../shared/presentation/widgets/transaction_tile.dart';
import '../application/transactions_controller.dart';
import '../data/transaction_models.dart';
import 'split_bill_screen.dart';
import 'transaction_create_screen.dart';
import 'transaction_detail_sheet.dart';
import 'transaction_display.dart';
import 'transaction_filter_sheet.dart';

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

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(transactionsControllerProvider);
    final controller = ref.read(transactionsControllerProvider.notifier);
    final textTheme = Theme.of(context).textTheme;

    if (state.isLoading && state.transactions.isEmpty) {
      return const _TransactionsLoading();
    }

    if (state.loadError != null && state.transactions.isEmpty) {
      return _TransactionsError(onRetry: () => controller.load(reset: true));
    }

    final visible = state.visibleTransactions;
    final isSearching = state.searchQuery.trim().isNotEmpty;

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(
          AffluenaSpacing.space5,
          AffluenaSpacing.space4,
          AffluenaSpacing.space5,
          AffluenaSpacing.space8,
        ),
        children: [
          Text('Transactions', style: textTheme.headlineMedium),
          const SizedBox(height: AffluenaSpacing.space5),
          TextField(
            key: const Key('transactions-search-field'),
            controller: _searchController,
            autocorrect: false,
            textInputAction: TextInputAction.search,
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.search),
              hintText: 'Search note, wallet, or category',
              suffixIcon: isSearching
                  ? IconButton(
                      key: const Key('transactions-search-clear'),
                      tooltip: 'Clear search',
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
                  label: const Text('New transaction'),
                ),
              ),
              const SizedBox(width: AffluenaSpacing.space3),
              Expanded(
                child: FilledButton.tonalIcon(
                  key: const Key('split-bill-entry-button'),
                  onPressed: () => context.push(SplitBillScreen.path),
                  icon: const Icon(Icons.call_split_outlined),
                  label: const Text('Split'),
                ),
              ),
            ],
          ),
          const SizedBox(height: AffluenaSpacing.space3),
          Row(
            children: [
              Expanded(
                child: Wrap(
                  spacing: AffluenaSpacing.space2,
                  runSpacing: AffluenaSpacing.space2,
                  children: [
                    _TypeFilterChip(
                      label: 'All',
                      selected: state.typeFilter == null,
                      onSelected: () => controller.setTypeFilter(null),
                    ),
                    _TypeFilterChip(
                      label: 'Income',
                      selected: state.typeFilter == TransactionType.income,
                      onSelected: () =>
                          controller.setTypeFilter(TransactionType.income),
                    ),
                    _TypeFilterChip(
                      label: 'Expense',
                      selected: state.typeFilter == TransactionType.expense,
                      onSelected: () =>
                          controller.setTypeFilter(TransactionType.expense),
                    ),
                    _TypeFilterChip(
                      label: 'Transfer',
                      selected: state.typeFilter == TransactionType.transfer,
                      onSelected: () =>
                          controller.setTypeFilter(TransactionType.transfer),
                    ),
                    _TypeFilterChip(
                      label: 'Adjustment',
                      selected: state.typeFilter == TransactionType.adjustment,
                      onSelected: () =>
                          controller.setTypeFilter(TransactionType.adjustment),
                    ),
                  ],
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
            _ActiveFilterSummary(
              state: state,
              onClear: controller.clearFilters,
            ),
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
            AffluenaCard(
              child: Column(
                children: [
                  for (final entry in visible.indexed) ...[
                    InkWell(
                      onTap: () =>
                          showTransactionDetail(context, ref, state, entry.$2),
                      child: TransactionTile(
                        title: transactionTitle(state, entry.$2),
                        metadata: transactionMetadata(state, entry.$2),
                        amount: transactionAmount(entry.$2),
                        icon: transactionIcon(state, entry.$2),
                        isIncome: entry.$2.type == TransactionType.income,
                      ),
                    ),
                    if (entry.$1 < visible.length - 1)
                      const Divider(height: 1),
                  ],
                ],
              ),
            ),
          if (state.hasMore && !isSearching) ...[
            const SizedBox(height: AffluenaSpacing.space4),
            OutlinedButton(
              onPressed: state.isLoadingMore
                  ? null
                  : () => controller.load(reset: false),
              child: Text(state.isLoadingMore ? 'Loading...' : 'Load more'),
            ),
          ],
          const SizedBox(height: AffluenaSpacing.space6),
        ],
      ),
    );
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

class _TransactionsLoading extends StatelessWidget {
  const _TransactionsLoading();

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(
          AffluenaSpacing.space5,
          AffluenaSpacing.space4,
          AffluenaSpacing.space5,
          AffluenaSpacing.space8,
        ),
        children: [
          Text('Transactions', style: textTheme.headlineMedium),
          const SizedBox(height: AffluenaSpacing.space5),
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
      ),
    );
  }
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

class _TypeFilterChip extends StatelessWidget {
  const _TypeFilterChip({
    required this.label,
    required this.selected,
    required this.onSelected,
  });

  final String label;
  final bool selected;
  final VoidCallback onSelected;

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onSelected(),
      avatar: selected ? const Icon(Icons.check, size: 16) : null,
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
        tooltip: 'Filter transactions',
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
        (state.categoryNames[filters.categoryId] ?? 'Category'),
      if (filters.tagId != null) _tagLabel(state.tagName(filters.tagId!)),
      if (filters.from != null) 'From ${state.filterDateLabel(filters.from!)}',
      if (filters.to != null) 'To ${state.filterDateLabel(filters.to!)}',
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
                'Clear',
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

class _TransactionsError extends StatelessWidget {
  const _TransactionsError({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(
          AffluenaSpacing.space5,
          AffluenaSpacing.space4,
          AffluenaSpacing.space5,
          AffluenaSpacing.space8,
        ),
        children: [
          Text('Transactions unavailable', style: textTheme.headlineMedium),
          const SizedBox(height: AffluenaSpacing.space5),
          AffluenaBanner.error(
            'We could not load your transactions.',
            onRetry: onRetry,
          ),
        ],
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
            hasFilters ? 'No matches for these filters' : 'No transactions yet',
            style: textTheme.titleMedium,
          ),
          const SizedBox(height: AffluenaSpacing.space1),
          Text(
            hasFilters
                ? 'Adjust or clear your filters to see more activity.'
                : 'Track income, expenses, and transfers to watch your money move.',
            style: textTheme.bodySmall,
          ),
          const SizedBox(height: AffluenaSpacing.space4),
          if (hasFilters)
            OutlinedButton.icon(
              key: const Key('transactions-empty-clear-filters'),
              onPressed: onClearFilters,
              icon: const Icon(Icons.filter_alt_off_outlined),
              label: const Text('Clear filters'),
            )
          else
            FilledButton.icon(
              key: const Key('transactions-empty-create'),
              onPressed: onCreate,
              icon: const Icon(Icons.add),
              label: const Text('Add a transaction'),
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
          Text('No results for "$query"', style: textTheme.titleMedium),
          const SizedBox(height: AffluenaSpacing.space1),
          Text(
            'Search runs over the loaded transactions by note, wallet, or '
            'category.',
            style: textTheme.bodySmall,
          ),
          const SizedBox(height: AffluenaSpacing.space4),
          OutlinedButton.icon(
            key: const Key('transactions-clear-search'),
            onPressed: onClear,
            icon: const Icon(Icons.close),
            label: const Text('Clear search'),
          ),
        ],
      ),
    );
  }
}

String _tagLabel(String name) {
  final normalized = name.trim().replaceFirst(RegExp(r'^#+'), '');
  return normalized.isEmpty ? '#' : '#$normalized';
}
