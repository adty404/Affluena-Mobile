import 'package:affluena_mobile/app/provider_retry.dart';
import 'package:affluena_mobile/core/api/pagination.dart';
import 'package:affluena_mobile/features/categories/data/category_models.dart';
import 'package:affluena_mobile/features/categories/data/category_repository.dart';
import 'package:affluena_mobile/features/quick_entry/data/quick_entry_models.dart';
import 'package:affluena_mobile/features/quick_entry/data/quick_entry_repository.dart';
import 'package:affluena_mobile/features/quick_entry/presentation/quick_entry_screen.dart';
import 'package:affluena_mobile/features/tags/data/tag_models.dart';
import 'package:affluena_mobile/features/tags/data/tag_repository.dart';
import 'package:affluena_mobile/features/transactions/data/transaction_models.dart';
import 'package:affluena_mobile/features/transactions/data/transaction_repository.dart';
import 'package:affluena_mobile/features/wallets/data/wallet_models.dart';
import 'package:affluena_mobile/features/wallets/data/wallet_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('amount validity gates save and API failure preserves values', (
    tester,
  ) async {
    final transactionRepository = WriteTransactionRepository(
      createError: Exception('network'),
    );

    await tester.pumpWidget(
      quickEntryWriteApp(transactionRepository: transactionRepository),
    );
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const Key('quick-entry-amount-field')),
      '',
    );
    await tester.pumpAndSettle();
    await _scrollToSave(tester);
    expect(_saveButton(tester).onPressed, isNull);

    await tester.scrollUntilVisible(
      find.byKey(const Key('quick-entry-amount-field')),
      -300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.enterText(
      find.byKey(const Key('quick-entry-amount-field')),
      '35000',
    );
    await tester.pumpAndSettle();
    await _scrollToSave(tester);
    expect(_saveButton(tester).onPressed, isNotNull);

    await tester.tap(find.byKey(const Key('quick-entry-save-button')));
    await tester.pumpAndSettle();

    expect(transactionRepository.createRequests, hasLength(1));
    expect(find.text('Transaction could not be saved.'), findsOneWidget);
    expect(find.text('GoPay'), findsOneWidget);
    expect(find.text('Food & Dining'), findsOneWidget);
    expect(find.text('Rp 35.000'), findsOneWidget);
  });

  testWidgets('transfer requires a destination wallet before save', (
    tester,
  ) async {
    await tester.pumpWidget(quickEntryWriteApp());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Transfer'));
    await tester.pumpAndSettle();

    expect(find.text('Choose destination wallet'), findsOneWidget);
    await _scrollToSave(tester);
    expect(_saveButton(tester).onPressed, isNull);

    await tester.scrollUntilVisible(
      find.byKey(const Key('quick-entry-to-wallet-row')),
      -300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.byKey(const Key('quick-entry-to-wallet-row')));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(ListTile, 'BCA Primary'));
    await tester.pumpAndSettle();

    expect(find.text('BCA Primary'), findsOneWidget);
    await _scrollToSave(tester);
    expect(_saveButton(tester).onPressed, isNotNull);
  });

  testWidgets('selecting wallet and category updates selected names', (
    tester,
  ) async {
    await tester.pumpWidget(quickEntryWriteApp());
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('quick-entry-wallet-row')));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(ListTile, 'BCA Primary'));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('quick-entry-category-row')));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(ListTile, 'Transportation'));
    await tester.pumpAndSettle();

    expect(find.text('BCA Primary'), findsOneWidget);
    expect(find.text('Transportation'), findsOneWidget);
    expect(find.text(gopayWallet.id), findsNothing);
    expect(find.text(foodCategory.id), findsNothing);
  });

  testWidgets('template execute records success without manual create call', (
    tester,
  ) async {
    final quickEntryRepository = WriteQuickEntryRepository(
      templates: [dailyCoffeeTemplate],
    );
    final transactionRepository = WriteTransactionRepository();

    await tester.pumpWidget(
      quickEntryWriteApp(
        quickEntryRepository: quickEntryRepository,
        transactionRepository: transactionRepository,
      ),
    );
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.text('Daily Coffee'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('Daily Coffee'));
    await tester.pumpAndSettle();

    expect(quickEntryRepository.executedTemplateIds, [dailyCoffeeTemplate.id]);
    expect(transactionRepository.createRequests, isEmpty);
    expect(find.text('Daily Coffee recorded.'), findsOneWidget);
  });
}

FilledButton _saveButton(WidgetTester tester) {
  return tester.widget<FilledButton>(
    find.byKey(const Key('quick-entry-save-button')),
  );
}

Future<void> _scrollToSave(WidgetTester tester) async {
  await tester.scrollUntilVisible(
    find.byKey(const Key('quick-entry-save-button')),
    300,
    scrollable: find.byType(Scrollable).first,
  );
}

Widget quickEntryWriteApp({
  WriteTransactionRepository? transactionRepository,
  WriteQuickEntryRepository? quickEntryRepository,
}) {
  return ProviderScope(
    retry: noProviderRetry,
    overrides: [
      walletRepositoryProvider.overrideWithValue(
        const WriteWalletRepository(wallets: [gopayWallet, bcaWallet]),
      ),
      categoryRepositoryProvider.overrideWithValue(
        const WriteCategoryRepository(
          categories: [foodCategory, transportationCategory, salaryCategory],
        ),
      ),
      tagRepositoryProvider.overrideWithValue(
        const WriteTagRepository(tags: [monthlyTag]),
      ),
      transactionRepositoryProvider.overrideWithValue(
        transactionRepository ?? WriteTransactionRepository(),
      ),
      quickEntryRepositoryProvider.overrideWithValue(
        quickEntryRepository ?? WriteQuickEntryRepository(),
      ),
    ],
    child: const MaterialApp(home: Scaffold(body: QuickEntryScreen())),
  );
}

class WriteTransactionRepository implements TransactionRepository {
  WriteTransactionRepository({this.createError});

  final Object? createError;
  final createRequests = <TransactionRequest>[];

  @override
  Future<Transaction> createTransaction(TransactionRequest request) async {
    createRequests.add(request);
    if (createError != null) throw createError!;
    return createdTransaction;
  }

  @override
  Future<void> deleteTransaction(String id) async {}

  @override
  Future<Transaction> getTransaction(String id) async => createdTransaction;

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
    return const TransactionListResponse(
      transactions: [],
      pagination: Pagination(total: 0, limit: 0, offset: 0),
    );
  }
}

class WriteQuickEntryRepository implements QuickEntryRepository {
  WriteQuickEntryRepository({this.templates = const []});

  final List<QuickEntryTemplate> templates;
  final executedTemplateIds = <String>[];

  @override
  Future<ExecuteQuickEntryResponse> executeTemplate(
    String id,
    ExecuteQuickEntryRequest request,
  ) async {
    executedTemplateIds.add(id);
    return const ExecuteQuickEntryResponse(transaction: createdTransaction);
  }

  @override
  Future<QuickEntryTemplateListResponse> listTemplates({
    int? limit,
    int? offset,
    String? sort,
  }) async {
    return QuickEntryTemplateListResponse(
      templates: templates,
      pagination: Pagination(
        total: templates.length,
        limit: limit ?? templates.length,
        offset: offset ?? 0,
      ),
    );
  }
}

class WriteWalletRepository implements WalletRepository {
  const WriteWalletRepository({required this.wallets});

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

class WriteCategoryRepository implements CategoryRepository {
  const WriteCategoryRepository({required this.categories});

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

class WriteTagRepository implements TagRepository {
  const WriteTagRepository({required this.tags});

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
  Future<Tag> updateTag(String id, TagRequest request) async {
    return tags.firstWhere((tag) => tag.id == id);
  }
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

const transportationCategory = Category(
  id: '44444444-4444-4444-4444-444444440002',
  userId: '11111111-1111-1111-1111-111111111111',
  name: 'Transportation',
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

const monthlyTag = Tag(
  id: '55555555-5555-5555-5555-555555550002',
  userId: '11111111-1111-1111-1111-111111111111',
  name: '#MonthlyBill',
  createdAt: '2026-06-01T00:00:00Z',
  updatedAt: '2026-06-01T00:00:00Z',
);

const dailyCoffeeTemplate = QuickEntryTemplate(
  id: '77777777-7777-7777-7777-777777770001',
  userId: '11111111-1111-1111-1111-111111111111',
  name: 'Daily Coffee',
  type: TransactionType.expense,
  walletId: '22222222-2222-2222-2222-222222220003',
  categoryId: '44444444-4444-4444-4444-444444440001',
  amountMinor: 35000,
  note: 'Daily Coffee',
  createdAt: '2026-06-01T00:00:00Z',
  updatedAt: '2026-06-01T00:00:00Z',
);

const createdTransaction = Transaction(
  id: 'created-transaction',
  userId: '11111111-1111-1111-1111-111111111111',
  type: TransactionType.expense,
  walletId: '22222222-2222-2222-2222-222222220003',
  categoryId: '44444444-4444-4444-4444-444444440001',
  amountMinor: 35000,
  tagIds: [],
  transactionAt: '2026-06-21T10:00:00Z',
  note: 'Daily Coffee',
  createdAt: '2026-06-21T10:00:00Z',
  updatedAt: '2026-06-21T10:00:00Z',
);
