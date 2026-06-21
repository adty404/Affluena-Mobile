import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../categories/data/category_repository.dart';
import '../../wallets/data/wallet_repository.dart';
import '../data/transaction_models.dart';
import '../data/transaction_repository.dart';

const transactionsPageSize = 5;

final transactionsControllerProvider =
    NotifierProvider<TransactionsController, TransactionsState>(
      TransactionsController.new,
    );

class TransactionsController extends Notifier<TransactionsState> {
  @override
  TransactionsState build() {
    Future<void>.microtask(() => load(reset: true));
    return const TransactionsState();
  }

  Future<void> load({required bool reset}) async {
    if (state.isLoading || state.isLoadingMore) return;

    final offset = reset ? 0 : state.transactions.length;
    state = state.copyWith(
      isLoading: reset,
      isLoadingMore: !reset,
      loadError: reset ? null : state.loadError,
      actionError: null,
      transactions: reset ? const [] : state.transactions,
      total: reset ? 0 : state.total,
    );

    try {
      final transactionFuture = ref
          .read(transactionRepositoryProvider)
          .listTransactions(
            type: state.typeFilter,
            limit: transactionsPageSize,
            offset: offset,
            sort: 'transaction_at_desc',
          );
      final walletsFuture = ref
          .read(walletRepositoryProvider)
          .listWallets(limit: 100, offset: 0, sort: 'name_asc');
      final categoriesFuture = ref
          .read(categoryRepositoryProvider)
          .listCategories(limit: 100, offset: 0, sort: 'name_asc');

      final transactionResponse = await transactionFuture;
      final walletResponse = await walletsFuture;
      final categoryResponse = await categoriesFuture;

      state = state.copyWith(
        isLoading: false,
        isLoadingMore: false,
        loadError: null,
        transactions: [
          if (!reset) ...state.transactions,
          ...transactionResponse.transactions,
        ],
        total: transactionResponse.pagination.total,
        walletNames: {
          for (final wallet in walletResponse.wallets) wallet.id: wallet.name,
        },
        categoryNames: {
          for (final category in categoryResponse.categories)
            category.id: category.name,
        },
      );
    } catch (_) {
      state = state.copyWith(
        isLoading: false,
        isLoadingMore: false,
        loadError: reset
            ? 'Transactions could not be loaded.'
            : state.loadError,
        actionError: reset ? null : 'Could not load more transactions.',
      );
    }
  }

  void setTypeFilter(TransactionType? type) {
    if (state.typeFilter == type) return;
    state = state.copyWith(typeFilter: type, transactions: const [], total: 0);
    unawaited(load(reset: true));
  }

  Future<void> deleteTransaction(Transaction transaction) async {
    state = state.copyWith(actionError: null);
    try {
      await ref
          .read(transactionRepositoryProvider)
          .deleteTransaction(transaction.id);
      await load(reset: true);
    } catch (_) {
      state = state.copyWith(actionError: 'Transaction could not be deleted.');
    }
  }
}

class TransactionsState {
  const TransactionsState({
    this.transactions = const [],
    this.total = 0,
    this.walletNames = const {},
    this.categoryNames = const {},
    this.typeFilter,
    this.isLoading = false,
    this.isLoadingMore = false,
    this.loadError,
    this.actionError,
  });

  final List<Transaction> transactions;
  final int total;
  final Map<String, String> walletNames;
  final Map<String, String> categoryNames;
  final TransactionType? typeFilter;
  final bool isLoading;
  final bool isLoadingMore;
  final String? loadError;
  final String? actionError;

  bool get hasMore => transactions.length < total;

  String walletName(String id) => walletNames[id] ?? 'Unknown wallet';

  String categoryName(Transaction transaction) {
    if (transaction.categoryId == null) {
      return switch (transaction.type) {
        TransactionType.transfer => 'Transfer',
        TransactionType.income => 'Income',
        TransactionType.expense => 'Uncategorized',
        TransactionType.adjustment => 'Adjustment',
      };
    }
    return categoryNames[transaction.categoryId] ?? 'Uncategorized';
  }

  TransactionsState copyWith({
    List<Transaction>? transactions,
    int? total,
    Map<String, String>? walletNames,
    Map<String, String>? categoryNames,
    Object? typeFilter = _unchanged,
    bool? isLoading,
    bool? isLoadingMore,
    Object? loadError = _unchanged,
    Object? actionError = _unchanged,
  }) {
    return TransactionsState(
      transactions: transactions ?? this.transactions,
      total: total ?? this.total,
      walletNames: walletNames ?? this.walletNames,
      categoryNames: categoryNames ?? this.categoryNames,
      typeFilter: identical(typeFilter, _unchanged)
          ? this.typeFilter
          : typeFilter as TransactionType?,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
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
