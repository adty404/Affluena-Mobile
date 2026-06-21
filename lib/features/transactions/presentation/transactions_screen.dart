import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/affluena_theme.dart';
import '../../../core/formatters/date_formatter.dart';
import '../../../core/formatters/money_formatter.dart';
import '../../shared/presentation/widgets/affluena_card.dart';
import '../../shared/presentation/widgets/transaction_tile.dart';
import '../application/transactions_controller.dart';
import '../data/transaction_models.dart';

class TransactionsScreen extends ConsumerWidget {
  const TransactionsScreen({super.key});

  static const path = '/transactions';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(transactionsControllerProvider);
    final controller = ref.read(transactionsControllerProvider.notifier);
    final textTheme = Theme.of(context).textTheme;
    final colors = context.affluenaColors;

    if (state.isLoading && state.transactions.isEmpty) {
      return const _TransactionsLoading();
    }

    if (state.loadError != null && state.transactions.isEmpty) {
      return _TransactionsError(onRetry: () => controller.load(reset: true));
    }

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
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.search),
              hintText: 'Search note, wallet, or category',
            ),
          ),
          const SizedBox(height: AffluenaSpacing.space3),
          Wrap(
            spacing: AffluenaSpacing.space2,
            runSpacing: AffluenaSpacing.space2,
            children: [
              _FilterChip(
                label: 'All',
                selected: state.typeFilter == null,
                onSelected: () => controller.setTypeFilter(null),
              ),
              _FilterChip(
                label: 'Income',
                selected: state.typeFilter == TransactionType.income,
                onSelected: () =>
                    controller.setTypeFilter(TransactionType.income),
              ),
              _FilterChip(
                label: 'Expense',
                selected: state.typeFilter == TransactionType.expense,
                onSelected: () =>
                    controller.setTypeFilter(TransactionType.expense),
              ),
              _FilterChip(
                label: 'Transfer',
                selected: state.typeFilter == TransactionType.transfer,
                onSelected: () =>
                    controller.setTypeFilter(TransactionType.transfer),
              ),
            ],
          ),
          const SizedBox(height: AffluenaSpacing.space5),
          if (state.actionError != null) ...[
            AffluenaCard(
              backgroundColor: colors.surfaceTintSoft,
              child: Text(state.actionError!),
            ),
            const SizedBox(height: AffluenaSpacing.space3),
          ],
          if (state.transactions.isEmpty)
            const _EmptyTransactionsState()
          else
            AffluenaCard(
              child: Column(
                children: [
                  for (final entry in state.transactions.indexed) ...[
                    InkWell(
                      onTap: () =>
                          _showTransactionDetail(context, ref, state, entry.$2),
                      child: TransactionTile(
                        title: _transactionTitle(state, entry.$2),
                        metadata: _transactionMetadata(state, entry.$2),
                        amount: _transactionAmount(entry.$2),
                        icon: _transactionIcon(state, entry.$2),
                        isIncome: entry.$2.type == TransactionType.income,
                      ),
                    ),
                    if (entry.$1 < state.transactions.length - 1)
                      const Divider(height: 1),
                  ],
                ],
              ),
            ),
          if (state.hasMore) ...[
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
          const AffluenaCard(
            child: SizedBox(
              height: 160,
              child: Center(child: Text('Loading transactions')),
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
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
          AffluenaCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('We could not load your transactions.'),
                const SizedBox(height: AffluenaSpacing.space4),
                FilledButton.icon(
                  onPressed: onRetry,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Retry'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyTransactionsState extends StatelessWidget {
  const _EmptyTransactionsState();

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
          const Icon(Icons.receipt_long_outlined),
          const SizedBox(height: AffluenaSpacing.space3),
          Text('No transactions found', style: textTheme.titleMedium),
          const SizedBox(height: AffluenaSpacing.space1),
          Text(
            'Try another filter or add a transaction.',
            style: textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}

void _showTransactionDetail(
  BuildContext context,
  WidgetRef ref,
  TransactionsState state,
  Transaction transaction,
) {
  final textTheme = Theme.of(context).textTheme;
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (context) {
      return SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              AffluenaSpacing.space5,
              AffluenaSpacing.space2,
              AffluenaSpacing.space5,
              MediaQuery.viewInsetsOf(context).bottom + AffluenaSpacing.space6,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Transaction detail', style: textTheme.titleLarge),
                const SizedBox(height: AffluenaSpacing.space4),
                Text(
                  _transactionTitle(state, transaction),
                  style: textTheme.headlineMedium,
                ),
                const SizedBox(height: AffluenaSpacing.space2),
                Text(
                  _transactionAmount(transaction),
                  style: textTheme.titleLarge,
                ),
                const SizedBox(height: AffluenaSpacing.space4),
                _DetailLine(
                  label: 'Wallet',
                  value: state.walletName(transaction.walletId),
                ),
                _DetailLine(
                  label: 'Category',
                  value: state.categoryName(transaction),
                ),
                _DetailLine(
                  label: 'Date',
                  value: AffluenaDateFormatter.shortDate(
                    transaction.transactionAt,
                  ),
                ),
                const SizedBox(height: AffluenaSpacing.space5),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: () {
                      Navigator.of(context).pop();
                      ref
                          .read(transactionsControllerProvider.notifier)
                          .deleteTransaction(transaction);
                    },
                    icon: const Icon(Icons.delete_outline),
                    label: const Text('Delete transaction'),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
}

class _DetailLine extends StatelessWidget {
  const _DetailLine({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: AffluenaSpacing.space2),
      child: Row(
        children: [
          SizedBox(width: 88, child: Text(label, style: textTheme.bodySmall)),
          Expanded(child: Text(value, style: textTheme.bodyLarge)),
        ],
      ),
    );
  }
}

String _transactionTitle(TransactionsState state, Transaction transaction) {
  return transaction.note.isEmpty
      ? state.categoryName(transaction)
      : transaction.note;
}

String _transactionMetadata(TransactionsState state, Transaction transaction) {
  final date = AffluenaDateFormatter.shortDate(transaction.transactionAt);
  final walletName = state.walletName(transaction.walletId);
  if (transaction.type == TransactionType.transfer) {
    final toWalletName = transaction.toWalletId == null
        ? 'Unknown wallet'
        : state.walletName(transaction.toWalletId!);
    return 'Transfer · $walletName to $toWalletName · $date';
  }
  return '${state.categoryName(transaction)} · $walletName · $date';
}

String _transactionAmount(Transaction transaction) {
  return switch (transaction.type) {
    TransactionType.income => MoneyFormatter.signedIdr(transaction.amountMinor),
    TransactionType.expense => MoneyFormatter.signedIdr(
      -transaction.amountMinor.abs(),
    ),
    TransactionType.transfer => MoneyFormatter.idr(transaction.amountMinor),
    TransactionType.adjustment => MoneyFormatter.idr(transaction.amountMinor),
  };
}

IconData _transactionIcon(TransactionsState state, Transaction transaction) {
  if (transaction.type == TransactionType.transfer) {
    return Icons.swap_horiz_rounded;
  }
  if (transaction.type == TransactionType.income) return Icons.work_outline;
  final category = state.categoryName(transaction).toLowerCase();
  if (category.contains('food')) return Icons.restaurant_outlined;
  if (category.contains('transport')) return Icons.local_gas_station_outlined;
  if (category.contains('bill')) return Icons.bolt_outlined;
  return Icons.receipt_long_outlined;
}
