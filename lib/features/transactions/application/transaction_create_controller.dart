import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/haptics.dart';
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

const _createLookupPageSize = 100;

final transactionCreateControllerProvider =
    NotifierProvider<TransactionCreateController, TransactionCreateState>(
      TransactionCreateController.new,
    );

class TransactionCreateController extends Notifier<TransactionCreateState> {
  @override
  TransactionCreateState build() {
    Future<void>.microtask(load);
    return const TransactionCreateState();
  }

  Future<void> load() async {
    state = state.copyWith(isLoading: true, loadError: null);

    try {
      final walletFuture = ref
          .read(walletRepositoryProvider)
          .listWallets(
            limit: _createLookupPageSize,
            offset: 0,
            sort: 'name_asc',
          );
      final categoryFuture = ref
          .read(categoryRepositoryProvider)
          .listCategories(limit: _createLookupPageSize, offset: 0);
      final tagFuture = ref
          .read(tagRepositoryProvider)
          .listTags(limit: _createLookupPageSize, offset: 0, sort: 'name_asc');

      final wallets = await walletFuture;
      final categories = await categoryFuture;
      final tags = await tagFuture;

      state = state.copyWith(
        isLoading: false,
        // Only wallets the user can write to are selectable as a target.
        wallets: wallets.wallets
            .where((w) => w.canWrite)
            .toList(growable: false),
        categories: categories.categories,
        tags: tags.tags,
      );
    } catch (_) {
      state = state.copyWith(
        isLoading: false,
        loadError: 'Kami tidak bisa memuat dompet dan kategori.',
      );
    }
  }

  Future<bool> create(TransactionRequest request) async {
    state = state.copyWith(isSaving: true, actionError: null);
    try {
      await ref.read(transactionRepositoryProvider).createTransaction(request);
      ref.invalidateFinancialData();
      state = state.copyWith(isSaving: false);
      hapticSuccess();
      return true;
    } catch (_) {
      state = state.copyWith(
        isSaving: false,
        actionError: 'Transaksi gagal dibuat.',
      );
      return false;
    }
  }

  void clearActionError() {
    if (state.actionError == null) return;
    state = state.copyWith(actionError: null);
  }
}

class TransactionCreateState {
  const TransactionCreateState({
    this.wallets = const [],
    this.categories = const [],
    this.tags = const [],
    this.isLoading = false,
    this.isSaving = false,
    this.loadError,
    this.actionError,
  });

  final List<Wallet> wallets;
  final List<Category> categories;
  final List<Tag> tags;
  final bool isLoading;
  final bool isSaving;
  final String? loadError;
  final String? actionError;

  List<Category> categoriesOfType(CategoryType type) {
    return categories
        .where((category) => category.type == type)
        .toList(growable: false);
  }

  Wallet? walletById(String? id) {
    if (id == null) return null;
    for (final wallet in wallets) {
      if (wallet.id == id) return wallet;
    }
    return null;
  }

  Category? categoryById(String? id) {
    if (id == null) return null;
    for (final category in categories) {
      if (category.id == id) return category;
    }
    return null;
  }

  Tag? tagById(String? id) {
    if (id == null) return null;
    for (final tag in tags) {
      if (tag.id == id) return tag;
    }
    return null;
  }

  String walletName(String? id) => walletById(id)?.name ?? 'Pilih dompet';

  String categoryName(String? id) => categoryById(id)?.name ?? 'Pilih kategori';

  TransactionCreateState copyWith({
    List<Wallet>? wallets,
    List<Category>? categories,
    List<Tag>? tags,
    bool? isLoading,
    bool? isSaving,
    Object? loadError = kUnchanged,
    Object? actionError = kUnchanged,
  }) {
    return TransactionCreateState(
      wallets: wallets ?? this.wallets,
      categories: categories ?? this.categories,
      tags: tags ?? this.tags,
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
