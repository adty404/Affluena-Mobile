import 'package:affluena_mobile/app/provider_retry.dart';
import 'package:affluena_mobile/core/api/pagination.dart';
import 'package:affluena_mobile/features/categories/data/category_models.dart';
import 'package:affluena_mobile/features/categories/data/category_repository.dart';
import 'package:affluena_mobile/features/transactions/data/transaction_models.dart';
import 'package:affluena_mobile/features/transactions/data/transaction_repository.dart';
import 'package:affluena_mobile/features/transactions/presentation/transactions_screen.dart';
import 'package:affluena_mobile/features/wallets/data/wallet_models.dart';
import 'package:affluena_mobile/features/wallets/data/wallet_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('renders transaction list with wallet and category names', (
    tester,
  ) async {
    await tester.pumpWidget(
      transactionsTestApp(
        transactionRepository: RecordingTransactionRepository(
          transactions: [groceriesTransaction, salaryTransaction],
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Groceries at Indomaret'), findsOneWidget);
    expect(find.text('Food & Dining · GoPay · 20 Jun 2026'), findsOneWidget);
    expect(find.text('Monthly Salary'), findsOneWidget);
    expect(find.text('Salary · BCA Primary · 21 Jun 2026'), findsOneWidget);
    expect(find.text(gopayWallet.id), findsNothing);
    expect(find.text(foodCategory.id), findsNothing);
  });

  testWidgets('maps expense filter and load more to API query params', (
    tester,
  ) async {
    final repository = RecordingTransactionRepository(
      transactions: [
        groceriesTransaction,
        fuelTransaction,
        coffeeTransaction,
        lunchTransaction,
        electricityTransaction,
        entertainmentTransaction,
      ],
    );

    await tester.pumpWidget(
      transactionsTestApp(transactionRepository: repository),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Expense'));
    await tester.pumpAndSettle();

    expect(repository.requestedTypes, contains(TransactionType.expense));

    await tester.scrollUntilVisible(
      find.text('Load more'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('Load more'));
    await tester.pumpAndSettle();

    expect(repository.requestedOffsets, contains(5));
  });

  testWidgets('opens mapped detail sheet and deletes after API success', (
    tester,
  ) async {
    final repository = RecordingTransactionRepository(
      transactions: [groceriesTransaction],
    );

    await tester.pumpWidget(
      transactionsTestApp(transactionRepository: repository),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Groceries at Indomaret'));
    await tester.pumpAndSettle();

    expect(find.text('Transaction detail'), findsOneWidget);
    expect(find.text('GoPay'), findsWidgets);
    expect(find.text('Food & Dining'), findsWidgets);

    await tester.tap(find.text('Delete transaction'));
    await tester.pumpAndSettle();

    expect(repository.deletedIds, [groceriesTransaction.id]);
    expect(find.text('Groceries at Indomaret'), findsNothing);
  });

  testWidgets('delete failure preserves row and shows error', (tester) async {
    final repository = RecordingTransactionRepository(
      transactions: [groceriesTransaction],
      deleteError: Exception('forbidden'),
    );

    await tester.pumpWidget(
      transactionsTestApp(transactionRepository: repository),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Groceries at Indomaret'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete transaction'));
    await tester.pumpAndSettle();

    expect(find.text('Groceries at Indomaret'), findsOneWidget);
    expect(find.text('Transaction could not be deleted.'), findsOneWidget);
  });
}

Widget transactionsTestApp({
  required RecordingTransactionRepository transactionRepository,
}) {
  return ProviderScope(
    retry: noProviderRetry,
    overrides: [
      transactionRepositoryProvider.overrideWithValue(transactionRepository),
      walletRepositoryProvider.overrideWithValue(
        const StaticWalletRepository(wallets: [gopayWallet, bcaWallet]),
      ),
      categoryRepositoryProvider.overrideWithValue(
        const StaticCategoryRepository(
          categories: [foodCategory, salaryCategory],
        ),
      ),
    ],
    child: const MaterialApp(home: Scaffold(body: TransactionsScreen())),
  );
}

class RecordingTransactionRepository implements TransactionRepository {
  RecordingTransactionRepository({
    required this.transactions,
    this.deleteError,
  });

  final List<Transaction> transactions;
  final Object? deleteError;
  final requestedTypes = <TransactionType?>[];
  final requestedOffsets = <int?>[];
  final deletedIds = <String>[];

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
        ? transactions
        : transactions
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
    return transactions.firstWhere((transaction) => transaction.id == id);
  }

  @override
  Future<Transaction> createTransaction(TransactionRequest request) async {
    return transactions.first;
  }

  @override
  Future<void> deleteTransaction(String id) async {
    deletedIds.add(id);
    if (deleteError != null) throw deleteError!;
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
  Future<Wallet> updateWallet(String id, WalletRequest request) async {
    return wallets.firstWhere((wallet) => wallet.id == id);
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
  Future<Category> updateCategory(String id, CategoryRequest request) async {
    return categories.firstWhere((category) => category.id == id);
  }
}

Transaction transactionFixture({
  required String id,
  required TransactionType type,
  required String walletId,
  required int amountMinor,
  required String note,
  required String transactionAt,
  String? categoryId,
  String? toWalletId,
}) {
  return Transaction(
    id: id,
    userId: '11111111-1111-1111-1111-111111111111',
    type: type,
    walletId: walletId,
    toWalletId: toWalletId,
    categoryId: categoryId,
    amountMinor: amountMinor,
    tagIds: const [],
    transactionAt: transactionAt,
    note: note,
    createdAt: transactionAt,
    updatedAt: transactionAt,
  );
}

const gopayWallet = Wallet(
  id: '22222222-2222-2222-2222-222222220003',
  userId: '11111111-1111-1111-1111-111111111111',
  name: 'GoPay',
  type: WalletType.eWallet,
  currencyCode: 'IDR',
  balanceMinor: 320000,
  color: 'green',
  description: 'Daily wallet',
  createdAt: '2026-06-01T00:00:00Z',
  updatedAt: '2026-06-01T00:00:00Z',
);

const bcaWallet = Wallet(
  id: '22222222-2222-2222-2222-222222220002',
  userId: '11111111-1111-1111-1111-111111111111',
  name: 'BCA Primary',
  type: WalletType.bank,
  currencyCode: 'IDR',
  balanceMinor: 15200000,
  color: 'blue',
  description: 'Main account',
  createdAt: '2026-06-01T00:00:00Z',
  updatedAt: '2026-06-01T00:00:00Z',
);

const foodCategory = Category(
  id: '44444444-4444-4444-4444-444444440001',
  userId: '11111111-1111-1111-1111-111111111111',
  name: 'Food & Dining',
  type: CategoryType.expense,
  createdAt: '2026-06-01T00:00:00Z',
  updatedAt: '2026-06-01T00:00:00Z',
);

const salaryCategory = Category(
  id: '33333333-3333-3333-3333-333333330001',
  userId: '11111111-1111-1111-1111-111111111111',
  name: 'Salary',
  type: CategoryType.income,
  createdAt: '2026-06-01T00:00:00Z',
  updatedAt: '2026-06-01T00:00:00Z',
);

final groceriesTransaction = transactionFixture(
  id: '66666666-6666-6666-6666-666666660004',
  type: TransactionType.expense,
  walletId: gopayWallet.id,
  categoryId: foodCategory.id,
  amountMinor: 450000,
  note: 'Groceries at Indomaret',
  transactionAt: '2026-06-20T11:00:00Z',
);

final salaryTransaction = transactionFixture(
  id: '66666666-6666-6666-6666-666666660001',
  type: TransactionType.income,
  walletId: bcaWallet.id,
  categoryId: salaryCategory.id,
  amountMinor: 18500000,
  note: 'Monthly Salary',
  transactionAt: '2026-06-21T09:00:00Z',
);

final fuelTransaction = transactionFixture(
  id: 'fuel',
  type: TransactionType.expense,
  walletId: gopayWallet.id,
  categoryId: foodCategory.id,
  amountMinor: 350000,
  note: 'Fuel and Parking',
  transactionAt: '2026-06-18T09:00:00Z',
);

final coffeeTransaction = transactionFixture(
  id: 'coffee',
  type: TransactionType.expense,
  walletId: gopayWallet.id,
  categoryId: foodCategory.id,
  amountMinor: 35000,
  note: 'Coffee',
  transactionAt: '2026-06-17T09:00:00Z',
);

final lunchTransaction = transactionFixture(
  id: 'lunch',
  type: TransactionType.expense,
  walletId: gopayWallet.id,
  categoryId: foodCategory.id,
  amountMinor: 180000,
  note: 'Lunch Meeting',
  transactionAt: '2026-06-16T09:00:00Z',
);

final electricityTransaction = transactionFixture(
  id: 'electricity',
  type: TransactionType.expense,
  walletId: bcaWallet.id,
  categoryId: foodCategory.id,
  amountMinor: 850000,
  note: 'Electricity Bill',
  transactionAt: '2026-06-15T09:00:00Z',
);

final entertainmentTransaction = transactionFixture(
  id: 'entertainment',
  type: TransactionType.expense,
  walletId: gopayWallet.id,
  categoryId: foodCategory.id,
  amountMinor: 250000,
  note: 'Movie Night',
  transactionAt: '2026-06-14T09:00:00Z',
);
