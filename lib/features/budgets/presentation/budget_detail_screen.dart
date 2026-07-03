import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/affluena_theme.dart';
import '../../../app/theme/sky_palette.dart';
import '../../../core/formatters/date_formatter.dart';
import '../../../core/formatters/money_formatter.dart';
import '../../categories/application/category_tag_management_controller.dart';
import '../../categories/data/category_models.dart';
import '../../shared/presentation/appearance/item_appearance.dart';
import '../../shared/presentation/widgets/affluena_card.dart';
import '../../shared/presentation/widgets/drill_in_scaffold.dart';
import '../../shared/presentation/widgets/sky_detail.dart';
import '../../shared/presentation/widgets/sky_progress_bar.dart';
import '../../transactions/application/transactions_controller.dart';
import '../../transactions/data/transaction_models.dart';
import '../../transactions/data/transaction_repository.dart';
import '../../transactions/presentation/transaction_detail_sheet.dart';
import '../../transactions/presentation/transaction_display.dart';
import '../application/budget_controller.dart';
import '../data/budget_models.dart';

/// Transactions in a budget's category (most recent first), for the detail
/// screen's "Transaksi" list.
final categoryTransactionsProvider =
    FutureProvider.family<List<Transaction>, String>((ref, categoryId) async {
      final response = await ref
          .watch(transactionRepositoryProvider)
          .listTransactions(
            categoryId: categoryId,
            limit: 50,
            sort: 'transaction_at_desc',
          );
      return response.transactions;
    });

/// Per-budget detail (Anggaran) in the Sky & Denim language — opened from a
/// Beranda dashboard card. Reads the budget from the already-loaded
/// [budgetControllerProvider]; editing stays in the budget list screen.
class BudgetDetailScreen extends ConsumerWidget {
  const BudgetDetailScreen({required this.id, super.key});

  final String id;

  static const path = '/budgets/:id';
  static String location(String id) => '/budgets/$id';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(budgetControllerProvider);
    BudgetSummary? budget;
    for (final b in state.budgets) {
      if (b.id == id) {
        budget = b;
        break;
      }
    }

    if (budget == null) {
      return DrillInScaffold(
        title: 'Anggaran',
        body: SkyDetailPlaceholder(
          loading: state.isLoading,
          message: 'Anggaran tidak ditemukan.',
        ),
      );
    }

    final current = budget;
    final over = current.usagePercent >= 100;
    final overMinor = current.spentMinor - current.limitMinor;
    // The item's chosen colour accents the hero + progress; over-budget
    // danger still wins on the fill.
    final itemColor = parseItemColor(current.color);
    final accent = over
        ? context.sky.danger
        : (itemColor ?? context.sky.accent);
    // budget.month arrives as a full ISO timestamp (the API serializes a DATE
    // column to RFC3339), or as 'YYYY-MM' in tests. Take the calendar-month
    // prefix and build a local date — never parse the raw string with '-01'
    // appended, which throws on a timestamp and blanks the whole screen.
    final monthIso = current.month.length >= 7
        ? current.month.substring(0, 7)
        : current.month;
    final monthDate = DateTime.tryParse('$monthIso-01');
    final monthLabel = monthDate != null
        ? AffluenaDateFormatter.monthLabel(monthDate)
        : '';
    final transactions = ref.watch(
      categoryTransactionsProvider(current.categoryId),
    );
    // Every transaction here shares the budget's category, so resolve its
    // chosen icon + color once and render it on each row (consistent with the
    // main ledger). Fall back to the budget's own stored color when the
    // category itself has none.
    final category = ref
        .watch(categoryTagManagementControllerProvider)
        .categoryById(current.categoryId);
    final rowColor = parseItemColor(category?.color ?? '') ?? itemColor;
    final txnCount = transactions.asData?.value.length;
    final txnHeader = (txnCount != null && txnCount > 0)
        ? 'Transaksi · $txnCount'
        : 'Transaksi';

    return DrillInScaffold(
      title: state.categoryName(current.categoryId),
      body: ListView(
        padding: AffluenaInsets.screen,
        children: [
          SkyDetailHero(
            label: monthLabel.isEmpty
                ? 'Terpakai bulan ini'
                : 'Terpakai · $monthLabel',
            amount: MoneyFormatter.idr(current.spentMinor),
            sub: 'dari ${MoneyFormatter.idr(current.limitMinor)}',
            amountColor: over ? context.sky.danger : null,
            accent: itemColor,
          ),
          const SizedBox(height: AffluenaSpacing.space5),
          SkyDetailCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Text(
                      'Terpakai ${current.usagePercent.round()}%',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: context.sky.ink,
                      ),
                    ),
                    const Spacer(),
                    SkyStatusPill(
                      label: over ? 'Lewat batas' : 'Aman',
                      color: over ? context.sky.danger : context.sky.income,
                    ),
                  ],
                ),
                const SizedBox(height: AffluenaSpacing.space3),
                SkyProgressBar(
                  value: current.usagePercent / 100,
                  height: 8,
                  fillColor: accent,
                ),
                const SizedBox(height: AffluenaSpacing.space4),
                Divider(height: 1, color: context.sky.line),
                const SizedBox(height: AffluenaSpacing.space4),
                over
                    ? SkyDetailRow(
                        label: 'Lewat batas',
                        value: MoneyFormatter.idr(overMinor),
                        valueColor: context.sky.danger,
                      )
                    : SkyDetailRow(
                        label: 'Sisa',
                        value: MoneyFormatter.idr(current.remainingMinor),
                        valueColor: context.sky.income,
                      ),
              ],
            ),
          ),
          const SizedBox(height: AffluenaSpacing.space6),
          Text(
            txnHeader,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: context.sky.ink,
            ),
          ),
          const SizedBox(height: AffluenaSpacing.space3),
          transactions.when(
            loading: () => const _TxnSkeleton(),
            error: (_, _) => Text(
              'Tidak bisa memuat transaksi.',
              style: TextStyle(fontSize: 12.5, color: context.sky.muted),
            ),
            data: (items) => items.isEmpty
                ? Text(
                    'Belum ada transaksi di kategori ini.',
                    style: TextStyle(fontSize: 12.5, color: context.sky.muted),
                  )
                : _CategoryTxnList(
                    items: items,
                    category: category,
                    rowColor: rowColor,
                  ),
          ),
        ],
      ),
    );
  }
}

class _CategoryTxnList extends StatelessWidget {
  const _CategoryTxnList({
    required this.items,
    required this.category,
    required this.rowColor,
  });

  final List<Transaction> items;

  /// The budget's category (shared by every row), for the chosen icon glyph.
  final Category? category;

  /// The accent for every row's leading tile (category color → budget color).
  final Color? rowColor;

  @override
  Widget build(BuildContext context) {
    final rows = <Widget>[];
    DateTime? currentDay;
    for (final tx in items) {
      final day = AffluenaDateFormatter.localDay(tx.transactionAt);
      if (currentDay == null || day != currentDay) {
        currentDay = day;
        if (rows.isNotEmpty) {
          rows.add(const SizedBox(height: AffluenaSpacing.space3));
        }
        rows.add(
          Padding(
            padding: const EdgeInsets.only(bottom: AffluenaSpacing.space2),
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
      rows.add(_TxnRow(tx: tx, category: category, rowColor: rowColor));
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: rows,
    );
  }
}

class _TxnRow extends ConsumerWidget {
  const _TxnRow({
    required this.tx,
    required this.category,
    required this.rowColor,
  });

  final Transaction tx;
  final Category? category;
  final Color? rowColor;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final income = tx.type == TransactionType.income;
    final amount = '${income ? '+' : '−'}${MoneyFormatter.idr(tx.amountMinor)}';
    final appearance = categoryAppearanceFor(category, type: tx.type);
    // The list is per-category, so lean on the shared row accent; only fall
    // back to theming when neither the category nor the budget has a color.
    final tileColor = appearance.color ?? rowColor ?? context.sky.muted;
    final tinted = appearance.color != null || rowColor != null;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      // Tap opens the shared detail sheet (view/edit/delete), same as the
      // ledger and Aktivitas.
      onTap: () => showTransactionDetail(
        context,
        ref,
        ref.read(transactionsControllerProvider),
        tx,
      ),
      child: Padding(
        padding: const EdgeInsets.only(bottom: AffluenaSpacing.space2),
        child: AffluenaCard(
          padding: const EdgeInsets.all(AffluenaSpacing.space4),
          backgroundColor: context.sky.surface,
          borderColor: context.sky.line,
          child: Row(
            children: [
              Container(
                width: 34,
                height: 34,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: tinted
                      ? tileColor.withValues(alpha: 0.14)
                      : context.sky.sheet,
                  borderRadius: BorderRadius.circular(11),
                  border: Border.all(
                    color: tinted ? Colors.transparent : context.sky.line,
                  ),
                ),
                child: Icon(appearance.icon, size: 18, color: tileColor),
              ),
              const SizedBox(width: AffluenaSpacing.space3),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      tx.note.isEmpty ? 'Transaksi' : tx.note,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w600,
                        color: context.sky.ink,
                      ),
                    ),
                    const SizedBox(height: 1),
                    Text(
                      AffluenaDateFormatter.time(tx.transactionAt),
                      style: TextStyle(fontSize: 11, color: context.sky.faint),
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
                  color: income ? context.sky.income : context.sky.ink,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TxnSkeleton extends StatelessWidget {
  const _TxnSkeleton();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (var i = 0; i < 3; i++)
          Container(
            height: 44,
            margin: const EdgeInsets.only(bottom: AffluenaSpacing.space2),
            decoration: BoxDecoration(
              color: context.sky.sheet,
              borderRadius: BorderRadius.circular(AffluenaRadii.md),
            ),
          ),
      ],
    );
  }
}
