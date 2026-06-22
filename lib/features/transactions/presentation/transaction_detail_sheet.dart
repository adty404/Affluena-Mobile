import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/affluena_theme.dart';
import '../../../core/formatters/date_formatter.dart';
import '../application/transactions_controller.dart';
import '../data/transaction_models.dart';
import 'transaction_display.dart';
import 'transaction_edit_sheet.dart';

void showTransactionDetail(
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
    builder: (sheetContext) {
      return SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              AffluenaSpacing.space5,
              AffluenaSpacing.space2,
              AffluenaSpacing.space5,
              MediaQuery.viewInsetsOf(sheetContext).bottom +
                  AffluenaSpacing.space6,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Transaction detail', style: textTheme.titleLarge),
                const SizedBox(height: AffluenaSpacing.space4),
                Text(
                  transactionTitle(state, transaction),
                  style: textTheme.headlineMedium,
                ),
                const SizedBox(height: AffluenaSpacing.space2),
                Text(
                  transactionAmount(transaction),
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
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.of(sheetContext).pop();
                      showTransactionEditForm(context, state, transaction);
                    },
                    icon: const Icon(Icons.edit_outlined),
                    label: const Text('Edit transaction'),
                  ),
                ),
                const SizedBox(height: AffluenaSpacing.space3),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: () {
                      Navigator.of(sheetContext).pop();
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
