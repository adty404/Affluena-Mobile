import 'package:affluena_mobile/app/provider_retry.dart';
import 'package:affluena_mobile/core/api/pagination.dart';
import 'package:affluena_mobile/features/auth/application/auth_controller.dart';
import 'package:affluena_mobile/features/auth/data/auth_models.dart';
import 'package:affluena_mobile/features/categories/data/category_models.dart';
import 'package:affluena_mobile/features/categories/data/category_repository.dart';
import 'package:affluena_mobile/features/tags/data/tag_models.dart';
import 'package:affluena_mobile/features/tags/data/tag_repository.dart';
import 'package:affluena_mobile/features/transactions/data/split_bill_models.dart';
import 'package:affluena_mobile/features/transactions/data/transaction_models.dart';
import 'package:affluena_mobile/features/transactions/data/transaction_repository.dart';
import 'package:affluena_mobile/features/transactions/presentation/transactions_screen.dart';
import 'package:affluena_mobile/features/wallets/data/wallet_models.dart';
import 'package:affluena_mobile/features/wallets/data/wallet_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'transactions_test_data.dart';

export 'transactions_test_data.dart';

/// The user id used by every transaction fixture. Edit/delete are gated to the
/// transaction creator, so the signed-in test user must match this id.
const transactionsTestUserId = '11111111-1111-1111-1111-111111111111';

const _transactionsTestUser = AuthUser(
  id: transactionsTestUserId,
  email: 'demo@affluena.com',
  name: 'Demo User',
  avatarUrl: '',
  createdAt: '2026-06-01T00:00:00Z',
  updatedAt: '2026-06-01T00:00:00Z',
);

/// A signed-in [AuthController] override so the detail sheet treats the test
/// user as the transaction creator (and exposes edit/delete actions) without
/// hitting the auth repository or token store.
class _AuthenticatedAuthController extends AuthController {
  _AuthenticatedAuthController(this.user);

  final AuthUser user;

  @override
  AuthState build() => AuthState.authenticated(user);
}

Widget transactionsTestApp({
  required RecordingTransactionRepository transactionRepository,
  AuthUser currentUser = _transactionsTestUser,
  List<Category> categories = const [foodCategory, salaryCategory],
}) {
  return ProviderScope(
    retry: noProviderRetry,
    overrides: [
      authControllerProvider.overrideWith(
        () => _AuthenticatedAuthController(currentUser),
      ),
      transactionRepositoryProvider.overrideWithValue(transactionRepository),
      walletRepositoryProvider.overrideWithValue(
        const StaticWalletRepository(wallets: [gopayWallet, bcaWallet]),
      ),
      categoryRepositoryProvider.overrideWithValue(
        StaticCategoryRepository(categories: categories),
      ),
      tagRepositoryProvider.overrideWithValue(
        const StaticTransactionsTagRepository(tags: []),
      ),
    ],
    child: const MaterialApp(home: Scaffold(body: TransactionsScreen())),
  );
}

class StaticTransactionsTagRepository implements TagRepository {
  const StaticTransactionsTagRepository({required this.tags});

  final List<Tag> tags;

  @override
  Future<TagListResponse> listTags({
    int? limit,
    int? offset,
    String? sort,
  }) async {
    return TagListResponse(
      tags: tags,
      pagination: Pagination(
        total: tags.length,
        limit: limit ?? tags.length,
        offset: offset ?? 0,
      ),
    );
  }

  @override
  Future<Tag> createTag(TagRequest request) async => tags.first;

  @override
  Future<Tag> getTag(String id) async {
    return tags.firstWhere((tag) => tag.id == id);
  }

  @override
  Future<Tag> updateTag(String id, TagRequest request) async => getTag(id);

  @override
  Future<void> deleteTag(String id) async {}
}

class RecordingTransactionRepository implements TransactionMutationRepository {
  RecordingTransactionRepository({
    required List<Transaction> transactions,
    this.deleteError,
    this.updateError,
  }) : _transactions = List<Transaction>.of(transactions);

  final List<Transaction> _transactions;
  final Object? deleteError;
  final Object? updateError;
  final requestedTypes = <TransactionType?>[];
  final requestedOffsets = <int?>[];
  final deletedIds = <String>[];
  final updatedIds = <String>[];
  final updatedRequests = <TransactionRequest>[];

  @override
  Future<TransactionListResponse> listTransactions({
    TransactionType? type,
    String? walletId,
    String? categoryId,
    String? tagId,
    String? from,
    String? to,
    int? limit,
    int? offset,
    String? sort,
  }) async {
    requestedTypes.add(type);
    requestedOffsets.add(offset);
    final filtered = type == null
        ? _transactions
        : _transactions
              .where((transaction) => transaction.type == type)
              .toList(growable: false);
    final start = offset ?? 0;
    final end = (start + (limit ?? filtered.length)).clamp(0, filtered.length);
    final page = filtered.sublist(start.clamp(0, filtered.length), end);
    return TransactionListResponse(
      transactions: page,
      pagination: Pagination(
        total: filtered.length,
        limit: limit ?? filtered.length,
        offset: offset ?? 0,
      ),
    );
  }

  @override
  Future<Transaction> getTransaction(String id) async {
    return _transactions.firstWhere((transaction) => transaction.id == id);
  }

  @override
  Future<Transaction> createTransaction(TransactionRequest request) async {
    return _transactions.first;
  }

  @override
  Future<SplitTransactionResponse> splitBill(
    SplitTransactionRequest request,
  ) async {
    return const SplitTransactionResponse(
      transactionId: 'transaction-split',
      debtIds: [],
    );
  }

  @override
  Future<Transaction> updateTransaction(
    String id,
    TransactionRequest request,
  ) async {
    updatedIds.add(id);
    updatedRequests.add(request);
    if (updateError != null) throw updateError!;

    final index = _transactions.indexWhere(
      (transaction) => transaction.id == id,
    );
    final updated = transactionFixture(
      id: id,
      type: request.type,
      walletId: request.walletId,
      toWalletId: request.toWalletId,
      categoryId: request.categoryId,
      amountMinor: request.amountMinor,
      note: request.note ?? '',
      transactionAt: request.transactionAt,
    );
    _transactions[index] = updated;
    return updated;
  }

  @override
  Future<SplitBillListResponse> listSplitBills({String? status}) async {
    return const SplitBillListResponse(splitBills: []);
  }

  @override
  Future<SplitBillDetail> getSplitBill(String transactionId) async {
    throw UnimplementedError();
  }

  @override
  Future<void> deleteTransaction(String id) async {
    deletedIds.add(id);
    if (deleteError != null) throw deleteError!;
    _transactions.removeWhere((transaction) => transaction.id == id);
  }
}

class StaticWalletRepository implements WalletRepository {
  const StaticWalletRepository({required this.wallets});

  final List<Wallet> wallets;

  @override
  Future<WalletListResponse> listWallets({
    int? limit,
    int? offset,
    String? sort,
  }) async {
    return WalletListResponse(
      wallets: wallets,
      pagination: Pagination(
        total: wallets.length,
        limit: limit ?? wallets.length,
        offset: offset ?? 0,
      ),
    );
  }

  @override
  Future<Wallet> createWallet(WalletRequest request) async => wallets.first;

  @override
  Future<Wallet> getWallet(String id) async {
    return wallets.firstWhere((wallet) => wallet.id == id);
  }

  @override
  Future<Wallet> updateWallet(String id, WalletRequest request) async {
    return wallets.firstWhere((wallet) => wallet.id == id);
  }

  @override
  Future<void> deleteWallet(String id) async {}

  @override
  Future<WalletInviteResponse> inviteMember(
    String id,
    WalletInviteRequest request,
  ) async {
    return const WalletInviteResponse(status: WalletShareStatus.pending);
  }

  @override
  Future<WalletInviteResponse> respondInvite(
    String id,
    String memberId,
    WalletInviteResponse response,
  ) async {
    return response;
  }

  @override
  Future<WalletMembersResponse> listMembers(String id) async {
    final wallet = await getWallet(id);
    return WalletMembersResponse(members: wallet.members);
  }

  @override
  Future<WalletAnalytics> getAnalytics(String id, {String? month}) async {
    return WalletAnalytics(
      walletId: id,
      month: month ?? '2026-06',
      inflowMinor: 0,
      outflowMinor: 0,
      transactionCount: 0,
    );
  }
}

class StaticCategoryRepository implements CategoryRepository {
  const StaticCategoryRepository({required this.categories});

  final List<Category> categories;

  @override
  Future<CategoryListResponse> listCategories({
    CategoryType? type,
    int? limit,
    int? offset,
    String? sort,
  }) async {
    final filtered = type == null
        ? categories
        : categories.where((category) => category.type == type).toList();
    return CategoryListResponse(
      categories: filtered,
      pagination: Pagination(
        total: filtered.length,
        limit: limit ?? filtered.length,
        offset: offset ?? 0,
      ),
    );
  }

  @override
  Future<Category> createCategory(CategoryRequest request) async {
    return categories.first;
  }

  @override
  Future<Category> getCategory(String id) async {
    return categories.firstWhere((category) => category.id == id);
  }

  @override
  Future<Category> updateCategory(String id, CategoryRequest request) async {
    return categories.firstWhere((category) => category.id == id);
  }

  @override
  Future<void> deleteCategory(String id) async {}
}
