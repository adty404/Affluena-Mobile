import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/formatters/date_formatter.dart';
import '../../../core/state/copy_with_sentinel.dart';
import '../../categories/data/category_models.dart';
import '../../categories/data/category_repository.dart';
import '../../shared/application/financial_refresh.dart';
import '../../tags/data/tag_models.dart';
import '../../tags/data/tag_repository.dart';
import '../../wallets/data/wallet_models.dart';
import '../../wallets/data/wallet_repository.dart';
import '../data/transaction_models.dart';
import '../data/transaction_repository.dart';

const transactionsPageSize = 5;
const _transactionsLookupPageSize = 100;

final transactionsControllerProvider =
    NotifierProvider<TransactionsController, TransactionsState>(
      TransactionsController.new,
    );

class TransactionFilters {
  const TransactionFilters({
    this.type,
    this.walletId,
    this.categoryId,
    this.tagId,
    this.from,
    this.to,
  });

  final TransactionType? type;
  final String? walletId;
  final String? categoryId;
  final String? tagId;
  final DateTime? from;
  final DateTime? to;

  bool get hasActiveFilters =>
      walletId != null ||
      categoryId != null ||
      tagId != null ||
      from != null ||
      to != null;

  int get activeCount =>
      (walletId != null ? 1 : 0) +
      (categoryId != null ? 1 : 0) +
      (tagId != null ? 1 : 0) +
      (from != null ? 1 : 0) +
      (to != null ? 1 : 0);

  TransactionFilters copyWith({
    Object? type = kUnchanged,
    Object? walletId = kUnchanged,
    Object? categoryId = kUnchanged,
    Object? tagId = kUnchanged,
    Object? from = kUnchanged,
    Object? to = kUnchanged,
  }) {
    return TransactionFilters(
      type: identical(type, kUnchanged) ? this.type : type as TransactionType?,
      walletId: identical(walletId, kUnchanged)
          ? this.walletId
          : walletId as String?,
      categoryId: identical(categoryId, kUnchanged)
          ? this.categoryId
          : categoryId as String?,
      tagId: identical(tagId, kUnchanged) ? this.tagId : tagId as String?,
      from: identical(from, kUnchanged) ? this.from : from as DateTime?,
      to: identical(to, kUnchanged) ? this.to : to as DateTime?,
    );
  }

  TransactionFilters cleared() => const TransactionFilters();
}

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
      final filters = state.filters;
      final transactionFuture = ref
          .read(transactionRepositoryProvider)
          .listTransactions(
            type: filters.type,
            walletId: filters.walletId,
            categoryId: filters.categoryId,
            tagId: filters.tagId,
            from: _isoDate(filters.from),
            to: _isoDate(filters.to),
            limit: transactionsPageSize,
            offset: offset,
            sort: 'transaction_at_desc',
          );
      final walletsFuture = ref
          .read(walletRepositoryProvider)
          .listWallets(
            limit: _transactionsLookupPageSize,
            offset: 0,
            sort: 'name_asc',
          );
      final categoriesFuture = ref
          .read(categoryRepositoryProvider)
          .listCategories(limit: _transactionsLookupPageSize, offset: 0);
      final tagsFuture = ref
          .read(tagRepositoryProvider)
          .listTags(
            limit: _transactionsLookupPageSize,
            offset: 0,
            sort: 'name_asc',
          );

      final transactionResponse = await transactionFuture;
      final walletResponse = await walletsFuture;
      final categoryResponse = await categoriesFuture;
      final tagResponse = await tagsFuture;

      state = state.copyWith(
        isLoading: false,
        isLoadingMore: false,
        loadError: null,
        transactions: [
          if (!reset) ...state.transactions,
          ...transactionResponse.transactions,
        ],
        total: transactionResponse.pagination.total,
        // Only write-capable wallets are pickable when re-targeting an edit;
        // walletNames stays unfiltered so an existing transaction's wallet name
        // still resolves even if it later became view-only.
        wallets: walletResponse.wallets
            .where((w) => w.canWrite)
            .toList(growable: false),
        viewerWalletIds: {
          for (final wallet in walletResponse.wallets)
            if (wallet.isViewer) wallet.id,
        },
        categories: categoryResponse.categories,
        tags: tagResponse.tags,
        walletNames: {
          for (final wallet in walletResponse.wallets) wallet.id: wallet.name,
        },
        categoryNames: {
          for (final category in categoryResponse.categories)
            category.id: category.name,
        },
        tagNames: {for (final tag in tagResponse.tags) tag.id: tag.name},
      );
    } catch (_) {
      state = state.copyWith(
        isLoading: false,
        isLoadingMore: false,
        loadError: reset ? 'Transaksi gagal dimuat.' : state.loadError,
        actionError: reset ? null : 'Transaksi lainnya gagal dimuat.',
      );
    }
  }

  void setSearchQuery(String query) {
    if (state.searchQuery == query) return;
    state = state.copyWith(searchQuery: query);
  }

  void setTypeFilter(TransactionType? type) {
    if (state.filters.type == type) return;
    state = state.copyWith(
      filters: state.filters.copyWith(type: type),
      transactions: const [],
      total: 0,
    );
    unawaited(load(reset: true));
  }

  void applyFilters(TransactionFilters filters) {
    state = state.copyWith(filters: filters, transactions: const [], total: 0);
    unawaited(load(reset: true));
  }

  void clearFilters() {
    if (!state.filters.hasActiveFilters) return;
    applyFilters(state.filters.cleared());
  }

  Future<bool> createTransaction(TransactionRequest request) async {
    state = state.copyWith(actionError: null);
    try {
      await ref.read(transactionRepositoryProvider).createTransaction(request);
      ref.invalidateBalances();
      await load(reset: true);
      return true;
    } catch (_) {
      state = state.copyWith(actionError: 'Transaksi gagal dibuat.');
      return false;
    }
  }

  Future<bool> updateTransaction(
    Transaction transaction,
    TransactionRequest request,
  ) async {
    state = state.copyWith(actionError: null);
    final repository = ref.read(transactionRepositoryProvider);
    if (repository is! TransactionMutationRepository) {
      state = state.copyWith(actionError: 'Transaksi gagal diperbarui.');
      return false;
    }

    try {
      await repository.updateTransaction(transaction.id, request);
      ref.invalidateBalances();
      await load(reset: true);
      return true;
    } catch (_) {
      state = state.copyWith(actionError: 'Transaksi gagal diperbarui.');
      return false;
    }
  }

  Future<bool> deleteTransaction(Transaction transaction) async {
    state = state.copyWith(actionError: null);
    try {
      await ref
          .read(transactionRepositoryProvider)
          .deleteTransaction(transaction.id);
      ref.invalidateBalances();
      await load(reset: true);
      return true;
    } catch (_) {
      state = state.copyWith(actionError: 'Transaksi gagal dihapus.');
      return false;
    }
  }

  void clearActionFeedback() {
    if (state.actionError == null) return;
    state = state.copyWith(actionError: null);
  }

  static String? _isoDate(DateTime? date) {
    if (date == null) return null;
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '${date.year}-$month-${day}T00:00:00Z';
  }
}

class TransactionsState {
  const TransactionsState({
    this.transactions = const [],
    this.total = 0,
    this.wallets = const [],
    this.viewerWalletIds = const {},
    this.categories = const [],
    this.tags = const [],
    this.walletNames = const {},
    this.categoryNames = const {},
    this.tagNames = const {},
    this.filters = const TransactionFilters(),
    this.searchQuery = '',
    this.isLoading = false,
    this.isLoadingMore = false,
    this.loadError,
    this.actionError,
  });

  final List<Transaction> transactions;
  final int total;
  final List<Wallet> wallets;

  /// Wallets shared TO me (role 'viewer'). Their transactions are hidden from
  /// the main history so it shows only my own wallets' activity.
  final Set<String> viewerWalletIds;
  final List<Category> categories;
  final List<Tag> tags;
  final Map<String, String> walletNames;
  final Map<String, String> categoryNames;
  final Map<String, String> tagNames;
  final TransactionFilters filters;
  final String searchQuery;
  final bool isLoading;
  final bool isLoadingMore;
  final String? loadError;
  final String? actionError;

  TransactionType? get typeFilter => filters.type;

  bool get hasMore => transactions.length < total;

  /// Transactions narrowed by the in-memory search query. Server-side filters
  /// are applied during [TransactionsController.load]; the query refines the
  /// already-loaded page by note, wallet, or category name.
  List<Transaction> get visibleTransactions {
    Iterable<Transaction> base = transactions;
    if (viewerWalletIds.isNotEmpty) {
      base = base.where((t) => !viewerWalletIds.contains(t.walletId));
    }
    final query = searchQuery.trim().toLowerCase();
    if (query.isEmpty) return base.toList(growable: false);
    return base
        .where((transaction) {
          final note = transaction.note.toLowerCase();
          final wallet = walletName(transaction.walletId).toLowerCase();
          final category = categoryName(transaction).toLowerCase();
          return note.contains(query) ||
              wallet.contains(query) ||
              category.contains(query);
        })
        .toList(growable: false);
  }

  String walletName(String id) => walletNames[id] ?? 'Dompet tidak dikenal';

  String tagName(String id) => tagNames[id] ?? 'Tag';

  String categoryName(Transaction transaction) {
    if (transaction.categoryId == null) {
      return switch (transaction.type) {
        TransactionType.transfer => 'Transfer',
        TransactionType.income => 'Pemasukan',
        TransactionType.expense => 'Tanpa kategori',
        TransactionType.adjustment => 'Penyesuaian',
      };
    }
    return categoryNames[transaction.categoryId] ?? 'Tanpa kategori';
  }

  /// The full category object behind [transaction], when loaded — used to
  /// render the user's chosen category icon/color on tiles.
  Category? categoryOf(Transaction transaction) {
    final id = transaction.categoryId;
    if (id == null) return null;
    for (final category in categories) {
      if (category.id == id) return category;
    }
    return null;
  }

  String filterDateLabel(DateTime date) => AffluenaDateFormatter.shortDate(
    '${date.year.toString().padLeft(4, '0')}-'
    '${date.month.toString().padLeft(2, '0')}-'
    '${date.day.toString().padLeft(2, '0')}T00:00:00Z',
  );

  TransactionsState copyWith({
    List<Transaction>? transactions,
    int? total,
    List<Wallet>? wallets,
    Set<String>? viewerWalletIds,
    List<Category>? categories,
    List<Tag>? tags,
    Map<String, String>? walletNames,
    Map<String, String>? categoryNames,
    Map<String, String>? tagNames,
    TransactionFilters? filters,
    String? searchQuery,
    bool? isLoading,
    bool? isLoadingMore,
    Object? loadError = kUnchanged,
    Object? actionError = kUnchanged,
  }) {
    return TransactionsState(
      transactions: transactions ?? this.transactions,
      total: total ?? this.total,
      wallets: wallets ?? this.wallets,
      viewerWalletIds: viewerWalletIds ?? this.viewerWalletIds,
      categories: categories ?? this.categories,
      tags: tags ?? this.tags,
      walletNames: walletNames ?? this.walletNames,
      categoryNames: categoryNames ?? this.categoryNames,
      tagNames: tagNames ?? this.tagNames,
      filters: filters ?? this.filters,
      searchQuery: searchQuery ?? this.searchQuery,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      loadError: identical(loadError, kUnchanged)
          ? this.loadError
          : loadError as String?,
      actionError: identical(actionError, kUnchanged)
          ? this.actionError
          : actionError as String?,
    );
  }
}
