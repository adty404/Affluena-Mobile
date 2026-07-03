import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/formatters/date_formatter.dart';
import '../../categories/data/category_models.dart';
import '../../categories/data/category_repository.dart';
import '../../shared/application/financial_refresh.dart';
import '../data/budget_models.dart';
import '../data/budget_repository.dart';

const budgetPageSize = 20;

final budgetControllerProvider =
    NotifierProvider<BudgetController, BudgetState>(BudgetController.new);

class BudgetController extends Notifier<BudgetState> {
  @override
  BudgetState build() {
    final month = AffluenaDateFormatter.monthKey(DateTime.now());
    Future<void>.microtask(() => load(month: month));
    return BudgetState(month: month);
  }

  Future<void> load({String? month}) async {
    final targetMonth = month ?? state.month;
    state = state.copyWith(
      month: targetMonth,
      isLoading: true,
      loadError: null,
      actionError: null,
    );

    try {
      final budgetsFuture = ref
          .read(budgetRepositoryProvider)
          .listBudgets(month: targetMonth, limit: budgetPageSize, offset: 0);
      final reportFuture = ref
          .read(budgetRepositoryProvider)
          .getReport(month: targetMonth);
      final alertsFuture = ref
          .read(budgetRepositoryProvider)
          .getAlerts(month: targetMonth);
      final categoriesFuture = ref
          .read(categoryRepositoryProvider)
          .listCategories(type: CategoryType.expense, limit: 100, offset: 0);

      final budgetResponse = await budgetsFuture;
      final reportResponse = await reportFuture;
      final alertResponse = await alertsFuture;
      final categoryResponse = await categoriesFuture;

      state = state.copyWith(
        isLoading: false,
        budgets: budgetResponse.budgets,
        total: budgetResponse.pagination.total,
        report: reportResponse.report,
        reportSummary: reportResponse.summary,
        alerts: alertResponse.alerts,
        categories: categoryResponse.categories,
        categoryNames: {
          for (final category in categoryResponse.categories)
            category.id: category.name,
        },
      );
    } catch (_) {
      state = state.copyWith(
        isLoading: false,
        loadError: 'Anggaran gagal dimuat.',
      );
    }
  }

  void setMonth(String month) {
    if (month == state.month) return;
    unawaited(load(month: month));
  }

  Future<void> loadMore() async {
    if (state.isLoading || state.isLoadingMore || !state.hasMore) return;

    state = state.copyWith(isLoadingMore: true, actionError: null);
    try {
      final response = await ref
          .read(budgetRepositoryProvider)
          .listBudgets(
            month: state.month,
            limit: budgetPageSize,
            offset: state.budgets.length,
          );
      state = state.copyWith(
        isLoadingMore: false,
        budgets: [...state.budgets, ...response.budgets],
        total: response.pagination.total,
      );
    } catch (_) {
      state = state.copyWith(
        isLoadingMore: false,
        actionError: 'Anggaran lainnya gagal dimuat.',
      );
    }
  }

  Future<void> createBudget({
    required String categoryId,
    required int limitMinor,
    String? color,
    String? icon,
  }) async {
    await _saveBudget(
      BudgetRequest(
        categoryId: categoryId,
        month: state.month,
        limitMinor: limitMinor,
        color: color,
        icon: icon,
      ),
    );
  }

  Future<void> updateBudget(
    BudgetSummary budget, {
    required int limitMinor,
    String? color,
    String? icon,
  }) {
    return _saveBudget(
      BudgetRequest(
        categoryId: budget.categoryId,
        month: state.month,
        limitMinor: limitMinor,
        // Default to the stored appearance so an unrelated edit preserves it.
        color: color ?? budget.color,
        icon: icon ?? budget.icon,
      ),
      id: budget.id,
    );
  }

  Future<void> _saveBudget(BudgetRequest request, {String? id}) async {
    state = state.copyWith(isSaving: true, actionError: null);
    try {
      if (id == null) {
        await ref.read(budgetRepositoryProvider).createBudget(request);
      } else {
        await ref.read(budgetRepositoryProvider).updateBudget(id, request);
      }
      state = state.copyWith(isSaving: false);
      await load();
      // Budget limits feed the dashboard and budget report, so refresh the
      // shared financial providers (wallets/dashboard) after a successful save.
      ref.invalidateFinancialData();
    } catch (_) {
      state = state.copyWith(
        isSaving: false,
        actionError: id == null
            ? 'Anggaran gagal dibuat.'
            : 'Anggaran gagal diperbarui.',
      );
    }
  }

  Future<void> deleteBudget(BudgetSummary budget) async {
    state = state.copyWith(actionError: null);
    try {
      await ref.read(budgetRepositoryProvider).deleteBudget(budget.id);
      state = state.copyWith(
        budgets: state.budgets
            .where((item) => item.id != budget.id)
            .toList(growable: false),
        total: state.total > 0 ? state.total - 1 : 0,
      );
      await load();
      ref.invalidateFinancialData();
    } catch (_) {
      state = state.copyWith(actionError: 'Anggaran gagal dihapus.');
    }
  }
}

class BudgetState {
  const BudgetState({
    required this.month,
    this.budgets = const [],
    this.total = 0,
    this.report = const [],
    this.alerts = const [],
    this.categories = const [],
    this.categoryNames = const {},
    this.reportSummary,
    this.isLoading = false,
    this.isLoadingMore = false,
    this.isSaving = false,
    this.loadError,
    this.actionError,
  });

  final String month;
  final List<BudgetSummary> budgets;
  final int total;
  final List<BudgetReportItem> report;
  final List<BudgetAlert> alerts;
  final List<Category> categories;
  final Map<String, String> categoryNames;
  final BudgetReportSummary? reportSummary;
  final bool isLoading;
  final bool isLoadingMore;
  final bool isSaving;
  final String? loadError;
  final String? actionError;

  bool get hasMore => budgets.length < total;

  /// Expense categories the user can still budget against. Used to decide
  /// between an actionable "create budget" affordance and a CTA to first add a
  /// category.
  bool get hasExpenseCategories => categories.isNotEmpty;

  String categoryName(String id) =>
      categoryNames[id] ?? 'Kategori tidak dikenal';

  BudgetReportItem? reportFor(BudgetSummary budget) {
    for (final item in report) {
      if (item.id == budget.id) return item;
    }
    return null;
  }

  BudgetState copyWith({
    String? month,
    List<BudgetSummary>? budgets,
    int? total,
    List<BudgetReportItem>? report,
    List<BudgetAlert>? alerts,
    List<Category>? categories,
    Map<String, String>? categoryNames,
    Object? reportSummary = _unchanged,
    bool? isLoading,
    bool? isLoadingMore,
    bool? isSaving,
    Object? loadError = _unchanged,
    Object? actionError = _unchanged,
  }) {
    return BudgetState(
      month: month ?? this.month,
      budgets: budgets ?? this.budgets,
      total: total ?? this.total,
      report: report ?? this.report,
      alerts: alerts ?? this.alerts,
      categories: categories ?? this.categories,
      categoryNames: categoryNames ?? this.categoryNames,
      reportSummary: identical(reportSummary, _unchanged)
          ? this.reportSummary
          : reportSummary as BudgetReportSummary?,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      isSaving: isSaving ?? this.isSaving,
      loadError: identical(loadError, _unchanged)
          ? this.loadError
          : loadError as String?,
      actionError: identical(actionError, _unchanged)
          ? this.actionError
          : actionError as String?,
    );
  }
}

const _unchanged = Object();
