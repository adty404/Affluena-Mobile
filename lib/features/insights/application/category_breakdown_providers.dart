import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/formatters/date_formatter.dart';
import '../../categories/application/category_tag_management_controller.dart';
import '../../categories/data/category_models.dart';
import '../../shared/presentation/appearance/item_appearance.dart';
import '../../transactions/data/transaction_models.dart';
import '../../transactions/data/transaction_repository.dart';

/// The neutral bucket for transactions with no (or an unknown) category.
const kUncategorizedName = 'Tanpa kategori';
const kUncategorizedIcon = Icons.help_outline;

/// One category's slice of a breakdown: the category (null = uncategorized),
/// its display name, chosen icon + color (resolved from the catalog), the
/// summed minor-unit amount, and its share of the type's total (0–100).
class CategorySlice {
  const CategorySlice({
    required this.categoryId,
    required this.name,
    required this.icon,
    required this.color,
    required this.amountMinor,
    required this.percentOfTotal,
  });

  /// The category id, or null for the "Tanpa kategori" bucket.
  final String? categoryId;
  final String name;
  final IconData icon;

  /// The category's chosen accent color, or null (uncategorized / no color) so
  /// the UI falls back to a neutral tint.
  final Color? color;
  final int amountMinor;

  /// Share of this type's month total, 0–100.
  final double percentOfTotal;
}

/// The current month's transactions grouped by category, split into expense and
/// income breakdowns (each sorted desc by amount) plus the per-type totals.
class CategoryBreakdown {
  const CategoryBreakdown({
    required this.expenseByCategory,
    required this.incomeByCategory,
    required this.expenseTotalMinor,
    required this.incomeTotalMinor,
    this.truncated = false,
  });

  final List<CategorySlice> expenseByCategory;
  final List<CategorySlice> incomeByCategory;
  final int expenseTotalMinor;
  final int incomeTotalMinor;

  /// True when the range held more transactions than the per-fetch cap, so the
  /// oldest rows were dropped and the totals under-report. The UI surfaces a
  /// notice so a large-range total isn't silently wrong.
  final bool truncated;
}

/// An inclusive local date range for a category breakdown. Both ends are
/// whole LOCAL days (time-of-day ignored). Value-equal so it can key a
/// `FutureProvider.family` without spawning a fresh fetch on every rebuild.
@immutable
class DateRange {
  DateRange({required DateTime from, required DateTime to})
    : from = DateTime(from.year, from.month, from.day),
      to = DateTime(to.year, to.month, to.day);

  /// Inclusive first local day.
  final DateTime from;

  /// Inclusive last local day.
  final DateTime to;

  @override
  bool operator ==(Object other) =>
      other is DateRange && other.from == from && other.to == to;

  @override
  int get hashCode => Object.hash(from, to);
}

/// Category breakdown for an arbitrary [DateRange], for the Wawasan chart.
///
/// The API has no income-distribution endpoint, so BOTH breakdowns are computed
/// client-side, mirroring [calendarMonthProvider]: fetch the range's
/// transactions (window widened a day on each edge because the `from`/`to`
/// params are date-typed while bucketing is by LOCAL day), drop days outside the
/// range, then group by `categoryId` — summing `amountMinor` separately for
/// income vs expense and ignoring transfers/adjustments. Each bucket is joined
/// to the category catalog for its name/icon/color; a missing or unknown
/// category falls into a neutral "Tanpa kategori" bucket.
///
/// Hermetic-test-friendly: reads only [transactionRepositoryProvider] and
/// [categoryTagManagementControllerProvider], both overridable.
final categoryBreakdownProvider = FutureProvider.autoDispose
    .family<CategoryBreakdown, DateRange>((ref, range) async {
      final repo = ref.watch(transactionRepositoryProvider);
      // Ensure the category catalog is loaded so buckets resolve their
      // name/icon/color; the controller auto-loads on build.
      final categoryState = ref.watch(categoryTagManagementControllerProvider);

      String isoDate(DateTime d) {
        final m = d.month.toString().padLeft(2, '0');
        final day = d.day.toString().padLeft(2, '0');
        return '${d.year}-$m-${day}T00:00:00Z';
      }

      final windowFrom = range.from.subtract(const Duration(days: 1));
      final windowTo = range.to.add(const Duration(days: 2));

      const pageSize = 200;
      const maxTransactions = 5000;
      final all = <Transaction>[];
      var offset = 0;
      var truncated = false;
      while (true) {
        final page = await repo.listTransactions(
          from: isoDate(windowFrom),
          to: isoDate(windowTo),
          limit: pageSize,
          offset: offset,
          sort: 'transaction_at_desc',
        );
        all.addAll(page.transactions);
        offset += page.transactions.length;
        if (page.transactions.isEmpty || offset >= page.pagination.total) {
          break;
        }
        if (offset >= maxTransactions) {
          // We hit the cap with more rows still on the server — the totals below
          // will under-report. Flag it so the UI can warn the user.
          truncated = offset < page.pagination.total;
          break;
        }
      }

      // Sum per category id, keyed separately per type. A null/empty category id
      // collapses into the shared uncategorized key.
      const uncategorizedKey = '';
      final expenseByKey = <String, int>{};
      final incomeByKey = <String, int>{};
      var expenseTotal = 0;
      var incomeTotal = 0;

      for (final tx in all) {
        final day = AffluenaDateFormatter.localDay(tx.transactionAt);
        // Inclusive [from, to] on whole local days.
        if (day.isBefore(range.from) || day.isAfter(range.to)) continue;
        final key = (tx.categoryId == null || tx.categoryId!.isEmpty)
            ? uncategorizedKey
            : tx.categoryId!;
        switch (tx.type) {
          case TransactionType.income:
            incomeByKey.update(
              key,
              (value) => value + tx.amountMinor,
              ifAbsent: () => tx.amountMinor,
            );
            incomeTotal += tx.amountMinor;
          case TransactionType.expense:
            expenseByKey.update(
              key,
              (value) => value + tx.amountMinor,
              ifAbsent: () => tx.amountMinor,
            );
            expenseTotal += tx.amountMinor;
          case TransactionType.transfer:
          case TransactionType.adjustment:
            break;
        }
      }

      List<CategorySlice> slices(Map<String, int> byKey, int total) {
        final result = <CategorySlice>[
          for (final entry in byKey.entries)
            _sliceFor(
              key: entry.key,
              amountMinor: entry.value,
              total: total,
              categoryFor: categoryState.categoryById,
            ),
        ]..sort((a, b) => b.amountMinor.compareTo(a.amountMinor));
        return result;
      }

      return CategoryBreakdown(
        expenseByCategory: slices(expenseByKey, expenseTotal),
        incomeByCategory: slices(incomeByKey, incomeTotal),
        expenseTotalMinor: expenseTotal,
        incomeTotalMinor: incomeTotal,
        truncated: truncated,
      );
    });

/// The current calendar month's breakdown — the default Wawasan view and the
/// shape the provider test pins. Delegates to [categoryBreakdownProvider].
final currentMonthCategoryBreakdownProvider =
    FutureProvider.autoDispose<CategoryBreakdown>((ref) {
      final now = DateTime.now();
      final range = DateRange(
        from: DateTime(now.year, now.month, 1),
        to: DateTime(now.year, now.month + 1, 0),
      );
      return ref.watch(categoryBreakdownProvider(range).future);
    });

/// Builds a [CategorySlice] for one aggregated bucket, resolving the category
/// catalog for its name/icon/color (or the neutral uncategorized fallback).
CategorySlice _sliceFor({
  required String key,
  required int amountMinor,
  required int total,
  required Category? Function(String) categoryFor,
}) {
  final percent = total <= 0 ? 0.0 : (amountMinor / total) * 100;
  if (key.isEmpty) {
    return CategorySlice(
      categoryId: null,
      name: kUncategorizedName,
      icon: kUncategorizedIcon,
      color: null,
      amountMinor: amountMinor,
      percentOfTotal: percent,
    );
  }
  final category = categoryFor(key);
  if (category == null) {
    // Category referenced by a transaction but absent from the loaded catalog.
    return CategorySlice(
      categoryId: key,
      name: kUncategorizedName,
      icon: kUncategorizedIcon,
      color: null,
      amountMinor: amountMinor,
      percentOfTotal: percent,
    );
  }
  return CategorySlice(
    categoryId: category.id,
    name: category.name,
    icon: resolveCategoryIcon(category),
    color: parseItemColor(category.color),
    amountMinor: amountMinor,
    percentOfTotal: percent,
  );
}
