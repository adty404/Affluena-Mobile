import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/affluena_theme.dart';
import '../../../core/formatters/date_formatter.dart';
import '../../../core/formatters/money_formatter.dart';
import '../../shared/presentation/widgets/affluena_banner.dart';
import '../../shared/presentation/widgets/transaction_tile.dart';
import '../../transactions/data/transaction_models.dart';
import '../../transactions/data/transaction_repository.dart';

/// Opens a sheet listing the expense transactions that make up one category
/// slice of the "Where money went" breakdown for a given month. Uses the
/// transactions list endpoint whose category filter expands to the subtree, so
/// a root-category slice shows transactions from its subcategories too.
Future<void> showCategoryMonthTransactionsSheet({
  required BuildContext context,
  required String categoryId,
  required String categoryName,
  required DateTime month,
  required Map<String, String> walletNames,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    useSafeArea: true,
    builder: (context) => _CategoryMonthSheet(
      categoryId: categoryId,
      categoryName: categoryName,
      month: month,
      walletNames: walletNames,
    ),
  );
}

class _CategoryMonthSheet extends ConsumerStatefulWidget {
  const _CategoryMonthSheet({
    required this.categoryId,
    required this.categoryName,
    required this.month,
    required this.walletNames,
  });

  final String categoryId;
  final String categoryName;
  final DateTime month;
  final Map<String, String> walletNames;

  @override
  ConsumerState<_CategoryMonthSheet> createState() => _CategoryMonthSheetState();
}

class _CategoryMonthSheetState extends ConsumerState<_CategoryMonthSheet> {
  late Future<TransactionListResponse> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<TransactionListResponse> _load() {
    final from = DateTime(widget.month.year, widget.month.month, 1);
    final to = DateTime(widget.month.year, widget.month.month + 1, 0);
    String fmt(DateTime d) =>
        '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
    return ref
        .read(transactionRepositoryProvider)
        .listTransactions(
          type: TransactionType.expense,
          categoryId: widget.categoryId,
          from: fmt(from),
          to: fmt(to),
          limit: 100,
          offset: 0,
          sort: 'transaction_at_desc',
        );
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colors = context.affluenaColors;
    final screenHeight = MediaQuery.sizeOf(context).height;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AffluenaSpacing.space5,
          0,
          AffluenaSpacing.space5,
          AffluenaSpacing.space5,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.categoryName, style: textTheme.titleLarge),
            const SizedBox(height: AffluenaSpacing.space1),
            Text(
              AffluenaDateFormatter.monthLabel(widget.month),
              style: textTheme.bodySmall?.copyWith(color: colors.inkMuted),
            ),
            const SizedBox(height: AffluenaSpacing.space4),
            ConstrainedBox(
              constraints: BoxConstraints(maxHeight: screenHeight * 0.6),
              child: FutureBuilder<TransactionListResponse>(
                future: _future,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(
                        vertical: AffluenaSpacing.space6,
                      ),
                      child: Center(child: CircularProgressIndicator()),
                    );
                  }
                  if (snapshot.hasError) {
                    return AffluenaBanner.error(
                      'We could not load these transactions.',
                      onRetry: () =>
                          setState(() => _future = _load()),
                    );
                  }
                  final transactions =
                      snapshot.data?.transactions ?? const <Transaction>[];
                  if (transactions.isEmpty) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(
                        vertical: AffluenaSpacing.space6,
                      ),
                      child: Center(
                        child: Text(
                          'No transactions in this category for the month.',
                          style: textTheme.bodyMedium?.copyWith(
                            color: colors.inkMuted,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    );
                  }
                  return ListView.separated(
                    shrinkWrap: true,
                    itemCount: transactions.length,
                    separatorBuilder: (_, _) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final t = transactions[index];
                      final wallet =
                          widget.walletNames[t.walletId] ?? 'Wallet';
                      return TransactionTile(
                        title: t.note.isEmpty ? widget.categoryName : t.note,
                        metadata:
                            '$wallet · ${AffluenaDateFormatter.shortDate(t.transactionAt)}',
                        amount: MoneyFormatter.signedIdr(-t.amountMinor),
                        icon: Icons.receipt_long_outlined,
                        isIncome: false,
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
