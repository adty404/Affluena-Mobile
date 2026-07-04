import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/state/copy_with_sentinel.dart';
import '../../categories/data/category_models.dart';
import '../../categories/data/category_repository.dart';
import '../../shared/application/financial_refresh.dart';
import '../../wallets/data/wallet_models.dart';
import '../../wallets/data/wallet_repository.dart';
import '../data/recurring_models.dart';
import '../data/recurring_repository.dart';

const recurringPageSize = 20;

final recurringControllerProvider =
    NotifierProvider<RecurringController, RecurringState>(
      RecurringController.new,
    );

class RecurringController extends Notifier<RecurringState> {
  @override
  RecurringState build() {
    Future<void>.microtask(load);
    return const RecurringState();
  }

  Future<void> load() async {
    state = state.copyWith(isLoading: true, loadError: null, actionError: null);

    try {
      final rulesFuture = ref
          .read(recurringRepositoryProvider)
          .listRules(
            limit: recurringPageSize,
            offset: 0,
            sort: 'next_run_at_asc',
          );
      final walletsFuture = ref
          .read(walletRepositoryProvider)
          .listWallets(limit: 100, offset: 0, sort: 'name_asc');
      final categoriesFuture = ref
          .read(categoryRepositoryProvider)
          .listCategories(limit: 100, offset: 0);

      final rulesResponse = await rulesFuture;
      final walletsResponse = await walletsFuture;
      final categoriesResponse = await categoriesFuture;
      final selectableWallets = walletsResponse.wallets
          .where((wallet) => !wallet.isGoal && wallet.canWrite)
          .toList(growable: false);

      state = state.copyWith(
        isLoading: false,
        rules: rulesResponse.rules,
        total: rulesResponse.pagination.total,
        wallets: selectableWallets,
        categories: categoriesResponse.categories,
        walletNames: {
          for (final wallet in selectableWallets) wallet.id: wallet.name,
        },
        categoryNames: {
          for (final category in categoriesResponse.categories)
            category.id: category.name,
        },
      );
    } catch (_) {
      state = state.copyWith(
        isLoading: false,
        loadError: 'Transaksi berulang gagal dimuat.',
      );
    }
  }

  Future<void> createRule(RecurringRuleRequest request) async {
    await _save(
      () => ref.read(recurringRepositoryProvider).createRule(request),
    );
  }

  Future<void> updateRule(
    RecurringRule rule,
    RecurringRuleRequest request,
  ) async {
    await _save(
      () => ref.read(recurringRepositoryProvider).updateRule(rule.id, request),
    );
  }

  Future<void> deleteRule(RecurringRule rule) async {
    await _save(
      () => ref.read(recurringRepositoryProvider).deleteRule(rule.id),
      errorMessage: 'Aturan berulang gagal dihapus.',
    );
  }

  Future<void> runRule(RecurringRule rule) async {
    await _save(
      () => ref.read(recurringRepositoryProvider).runRule(rule.id),
      errorMessage: 'Aturan berulang gagal dijalankan.',
    );
  }

  Future<void> setStatus(RecurringRule rule, RecurringStatus status) async {
    await updateRule(rule, requestFromRule(rule, status: status));
  }

  Future<void> _save(
    Future<Object?> Function() action, {
    String errorMessage = 'Aturan berulang gagal disimpan.',
  }) async {
    state = state.copyWith(isSaving: true, actionError: null);
    try {
      await action();
      ref.invalidateFinancialData();
      state = state.copyWith(isSaving: false);
      await load();
    } catch (_) {
      state = state.copyWith(isSaving: false, actionError: errorMessage);
    }
  }
}

RecurringRuleRequest requestFromRule(
  RecurringRule rule, {
  RecurringStatus? status,
}) {
  return RecurringRuleRequest(
    name: rule.name,
    type: rule.type,
    walletId: rule.walletId,
    toWalletId: rule.toWalletId,
    categoryId: rule.categoryId,
    amountMinor: rule.amountMinor,
    frequency: rule.frequency,
    intervalCount: rule.intervalCount,
    nextRunAt: rule.nextRunAt,
    endAt: rule.endAt,
    status: status ?? rule.status,
    note: rule.note,
    // Re-send the stored appearance so a status change preserves it.
    color: rule.color,
    icon: rule.icon,
  );
}

class RecurringState {
  const RecurringState({
    this.rules = const [],
    this.total = 0,
    this.wallets = const [],
    this.categories = const [],
    this.walletNames = const {},
    this.categoryNames = const {},
    this.isLoading = false,
    this.isSaving = false,
    this.loadError,
    this.actionError,
  });

  final List<RecurringRule> rules;
  final int total;
  final List<Wallet> wallets;
  final List<Category> categories;
  final Map<String, String> walletNames;
  final Map<String, String> categoryNames;
  final bool isLoading;
  final bool isSaving;
  final String? loadError;
  final String? actionError;

  int get activeCount =>
      rules.where((rule) => rule.status == RecurringStatus.active).length;

  int get monthlyExpenseMinor => rules
      .where(
        (rule) =>
            rule.status == RecurringStatus.active &&
            rule.frequency == RecurringFrequency.monthly &&
            rule.type == RecurringType.expense,
      )
      .fold(0, (total, rule) => total + rule.amountMinor);

  int get upcomingCount => rules.where(_isUpcoming).length;

  String walletName(String id) => walletNames[id] ?? 'Dompet tidak dikenal';

  String categoryName(String? id) {
    if (id == null || id.isEmpty) return 'Tanpa kategori';
    return categoryNames[id] ?? 'Tanpa kategori';
  }

  RecurringState copyWith({
    List<RecurringRule>? rules,
    int? total,
    List<Wallet>? wallets,
    List<Category>? categories,
    Map<String, String>? walletNames,
    Map<String, String>? categoryNames,
    bool? isLoading,
    bool? isSaving,
    Object? loadError = kUnchanged,
    Object? actionError = kUnchanged,
  }) {
    return RecurringState(
      rules: rules ?? this.rules,
      total: total ?? this.total,
      wallets: wallets ?? this.wallets,
      categories: categories ?? this.categories,
      walletNames: walletNames ?? this.walletNames,
      categoryNames: categoryNames ?? this.categoryNames,
      isLoading: isLoading ?? this.isLoading,
      isSaving: isSaving ?? this.isSaving,
      loadError: identical(loadError, kUnchanged)
          ? this.loadError
          : loadError as String?,
      actionError: identical(actionError, kUnchanged)
          ? this.actionError
          : actionError as String?,
    );
  }
}

bool _isUpcoming(RecurringRule rule) {
  if (rule.status != RecurringStatus.active) return false;
  final nextRun = DateTime.tryParse(rule.nextRunAt);
  if (nextRun == null) return false;
  // nextRunAt is an RFC3339 'Z' instant; normalize to a whole LOCAL day before
  // comparing against local-midnight bounds, or it's off by one in WIB.
  final local = nextRun.toLocal();
  final runDay = DateTime(local.year, local.month, local.day);
  final today = DateTime.now();
  final start = DateTime(today.year, today.month, today.day);
  final end = DateTime(today.year, today.month, today.day + 7);
  return !runDay.isBefore(start) && !runDay.isAfter(end);
}
