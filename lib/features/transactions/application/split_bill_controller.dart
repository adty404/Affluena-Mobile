import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/formatters/tag_formatter.dart';
import '../../../core/state/copy_with_sentinel.dart';
import '../../categories/data/category_models.dart';
import '../../categories/data/category_repository.dart';
import '../../debts/application/debt_controller.dart';
import '../../shared/application/financial_refresh.dart';
import '../../tags/data/tag_models.dart';
import '../../tags/data/tag_repository.dart';
import '../../wallets/data/wallet_models.dart';
import '../../wallets/data/wallet_repository.dart';
import '../data/transaction_models.dart';
import '../data/transaction_repository.dart';

const splitBillLookupPageSize = 100;

final splitBillControllerProvider =
    NotifierProvider<SplitBillController, SplitBillState>(
      SplitBillController.new,
    );

class SplitBillController extends Notifier<SplitBillState> {
  @override
  SplitBillState build() {
    Future<void>.microtask(load);
    return const SplitBillState();
  }

  Future<void> load() async {
    state = state.copyWith(isLoading: true, loadError: null, actionError: null);

    try {
      final walletFuture = ref
          .read(walletRepositoryProvider)
          .listWallets(
            limit: splitBillLookupPageSize,
            offset: 0,
            sort: 'name_asc',
          );
      final expenseCategoryFuture = ref
          .read(categoryRepositoryProvider)
          .listCategories(
            type: CategoryType.expense,
            limit: splitBillLookupPageSize,
            offset: 0,
          );
      final incomeCategoryFuture = ref
          .read(categoryRepositoryProvider)
          .listCategories(
            type: CategoryType.income,
            limit: splitBillLookupPageSize,
            offset: 0,
          );
      final tagFuture = ref
          .read(tagRepositoryProvider)
          .listTags(
            limit: splitBillLookupPageSize,
            offset: 0,
            sort: 'name_asc',
          );

      final wallets = await walletFuture;
      final expenseCategories = await expenseCategoryFuture;
      final incomeCategories = await incomeCategoryFuture;
      final tags = await tagFuture;

      state = state.copyWith(
        isLoading: false,
        // Only wallets the user can write to are selectable as a target.
        wallets: wallets.wallets
            .where((w) => w.canWrite)
            .toList(growable: false),
        expenseCategories: expenseCategories.categories,
        incomeCategories: incomeCategories.categories,
        tags: tags.tags,
      );
    } catch (_) {
      state = state.copyWith(
        isLoading: false,
        loadError: 'Data bagi tagihan gagal dimuat.',
      );
    }
  }

  /// Clears the transient "created" result/error so it does not linger when the
  /// create form is re-opened.
  void clearResult() {
    state = state.copyWith(result: null, actionError: null);
  }

  Future<bool> createSplitBill(SplitTransactionRequest request) async {
    state = state.copyWith(isSaving: true, actionError: null, result: null);

    try {
      final result = await ref
          .read(transactionRepositoryProvider)
          .splitBill(request);
      ref.invalidateFinancialData();
      ref.invalidate(debtControllerProvider);
      state = state.copyWith(isSaving: false, result: result);
      return true;
    } catch (_) {
      state = state.copyWith(
        isSaving: false,
        actionError: 'Bagi tagihan gagal dibuat.',
      );
      return false;
    }
  }
}

class SplitBillState {
  const SplitBillState({
    this.wallets = const [],
    this.expenseCategories = const [],
    this.incomeCategories = const [],
    this.tags = const [],
    this.isLoading = false,
    this.isSaving = false,
    this.loadError,
    this.actionError,
    this.result,
  });

  final List<Wallet> wallets;
  final List<Category> expenseCategories;
  final List<Category> incomeCategories;
  final List<Tag> tags;
  final bool isLoading;
  final bool isSaving;
  final String? loadError;
  final String? actionError;
  final SplitTransactionResponse? result;

  Wallet? walletById(String? id) => _findById(wallets, id);

  Category? expenseCategoryById(String? id) => _findById(expenseCategories, id);

  Category? incomeCategoryById(String? id) => _findById(incomeCategories, id);

  Tag? tagById(String? id) => _findById(tags, id);

  String walletName(String? id) => walletById(id)?.name ?? 'Pilih dompet';

  String expenseCategoryName(String? id) {
    return expenseCategoryById(id)?.name ?? 'Pilih kategori';
  }

  String incomeCategoryName(String? id) {
    return incomeCategoryById(id)?.name ?? 'Pilih kategori';
  }

  String tagName(String? id) {
    final tag = tagById(id);
    return tag == null ? 'Opsional' : tagLabel(tag.name);
  }

  SplitBillState copyWith({
    List<Wallet>? wallets,
    List<Category>? expenseCategories,
    List<Category>? incomeCategories,
    List<Tag>? tags,
    bool? isLoading,
    bool? isSaving,
    Object? loadError = kUnchanged,
    Object? actionError = kUnchanged,
    Object? result = kUnchanged,
  }) {
    return SplitBillState(
      wallets: wallets ?? this.wallets,
      expenseCategories: expenseCategories ?? this.expenseCategories,
      incomeCategories: incomeCategories ?? this.incomeCategories,
      tags: tags ?? this.tags,
      isLoading: isLoading ?? this.isLoading,
      isSaving: isSaving ?? this.isSaving,
      loadError: identical(loadError, kUnchanged)
          ? this.loadError
          : loadError as String?,
      actionError: identical(actionError, kUnchanged)
          ? this.actionError
          : actionError as String?,
      result: identical(result, kUnchanged)
          ? this.result
          : result as SplitTransactionResponse?,
    );
  }
}

T? _findById<T>(Iterable<T> items, String? id) {
  if (id == null) return null;
  for (final item in items) {
    final itemId = switch (item) {
      Wallet(:final id) => id,
      Category(:final id) => id,
      Tag(:final id) => id,
      _ => null,
    };
    if (itemId == id) return item;
  }
  return null;
}
