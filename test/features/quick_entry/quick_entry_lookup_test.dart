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
  testWidgets('resolves quick entry selectors by name without raw ids', (
    tester,
  ) async {
    final categoryRepository = RecordingCategoryRepository(
      categories: const [lookupExpenseCategory, lookupIncomeCategory],
    );

    await tester.pumpWidget(
      lookupTestApp(
        walletRepository: const LookupWalletRepository(
          wallets: [lookupBankWallet],
        ),
        categoryRepository: categoryRepository,
        tagRepository: const LookupTagRepository(tags: [lookupMonthlyTag]),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('BCA Primary'), findsOneWidget);
    expect(find.text('Food & Dining'), findsOneWidget);
    expect(find.text('#MonthlyBill'), findsOneWidget);
    expect(find.text(lookupBankWalletId), findsNothing);
    expect(find.text(lookupExpenseCategoryId), findsNothing);
    expect(
      RecordingCategoryRepository.requestedTypes,
      contains(CategoryType.expense),
    );
  });

  testWidgets('wallet selector search filters lookup options', (tester) async {
    await tester.pumpWidget(
      lookupTestApp(
        walletRepository: const LookupWalletRepository(
          wallets: [lookupBankWallet, lookupGoPayWallet],
        ),
        categoryRepository: const RecordingCategoryRepository(
          categories: [lookupExpenseCategory],
        ),
        tagRepository: const LookupTagRepository(tags: [lookupMonthlyTag]),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('quick-entry-wallet-row')));
    await tester.pumpAndSettle();

    await tester.enterText(find.byKey(const Key('lookup-search-field')), 'go');
    await tester.pumpAndSettle();

    final sheet = find.byType(BottomSheet);
    expect(
      find.descendant(of: sheet, matching: find.text('GoPay')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: sheet, matching: find.text('BCA Primary')),
      findsNothing,
    );
  });

  testWidgets('empty lookup data explains the blocker and disables save', (
    tester,
  ) async {
    await tester.pumpWidget(
      lookupTestApp(
        walletRepository: const LookupWalletRepository(wallets: []),
        categoryRepository: const RecordingCategoryRepository(categories: []),
        tagRepository: const LookupTagRepository(tags: []),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Finish setup first'), findsOneWidget);
    expect(
      find.text(
        'Add at least one wallet and an expense category before saving.',
      ),
      findsOneWidget,
    );

    await tester.scrollUntilVisible(
      find.byKey(const Key('quick-entry-save-button')),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    final saveButton = tester.widget<FilledButton>(
      find.byKey(const Key('quick-entry-save-button')),
    );
    expect(saveButton.onPressed, isNull);
  });
}

Widget lookupTestApp({
  required WalletRepository walletRepository,
  required CategoryRepository categoryRepository,
  required TagRepository tagRepository,
}) {
  return ProviderScope(
    retry: noProviderRetry,
    overrides: [
      walletRepositoryProvider.overrideWithValue(walletRepository),
      categoryRepositoryProvider.overrideWithValue(categoryRepository),
      tagRepositoryProvider.overrideWithValue(tagRepository),
      transactionRepositoryProvider.overrideWithValue(
        const LookupTransactionRepository(),
      ),
      quickEntryRepositoryProvider.overrideWithValue(
        const LookupQuickEntryRepository(),
      ),
    ],
    child: const MaterialApp(home: Scaffold(body: QuickEntryScreen())),
  );
}

class LookupTransactionRepository implements TransactionRepository {
  const LookupTransactionRepository();

  @override
  Future<Transaction> createTransaction(TransactionRequest request) async {
    return lookupTransaction;
  }

  @override
  Future<void> deleteTransaction(String id) async {}

  @override
  Future<Transaction> getTransaction(String id) async => lookupTransaction;

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

class LookupQuickEntryRepository implements QuickEntryRepository {
  const LookupQuickEntryRepository();

  @override
  Future<ExecuteQuickEntryResponse> executeTemplate(
    String id,
    ExecuteQuickEntryRequest request,
  ) async {
    return const ExecuteQuickEntryResponse(transaction: lookupTransaction);
  }

  @override
  Future<QuickEntryTemplateListResponse> listTemplates({
    int? limit,
    int? offset,
    String? sort,
  }) async {
    return const QuickEntryTemplateListResponse(
      templates: [],
      pagination: Pagination(total: 0, limit: 0, offset: 0),
    );
  }
}

class LookupWalletRepository implements WalletRepository {
  const LookupWalletRepository({required this.wallets});

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

class RecordingCategoryRepository implements CategoryRepository {
  const RecordingCategoryRepository({required this.categories});

  final List<Category> categories;
  static final requestedTypes = <CategoryType?>[];

  @override
  Future<CategoryListResponse> listCategories({
    CategoryType? type,
    int? limit,
    int? offset,
    String? sort,
  }) async {
    requestedTypes.add(type);
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

class LookupTagRepository implements TagRepository {
  const LookupTagRepository({required this.tags});

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

const lookupBankWalletId = '22222222-2222-2222-2222-222222220002';
const lookupGoPayWalletId = '22222222-2222-2222-2222-222222220003';
const lookupExpenseCategoryId = '44444444-4444-4444-4444-444444440001';

const lookupBankWallet = Wallet(
  id: lookupBankWalletId,
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

const lookupGoPayWallet = Wallet(
  id: lookupGoPayWalletId,
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

const lookupExpenseCategory = Category(
  id: lookupExpenseCategoryId,
  userId: '11111111-1111-1111-1111-111111111111',
  name: 'Food & Dining',
  type: CategoryType.expense,
  createdAt: '2026-06-01T00:00:00Z',
  updatedAt: '2026-06-01T00:00:00Z',
);

const lookupIncomeCategory = Category(
  id: '33333333-3333-3333-3333-333333330001',
  userId: '11111111-1111-1111-1111-111111111111',
  name: 'Salary',
  type: CategoryType.income,
  createdAt: '2026-06-01T00:00:00Z',
  updatedAt: '2026-06-01T00:00:00Z',
);

const lookupMonthlyTag = Tag(
  id: '55555555-5555-5555-5555-555555550002',
  userId: '11111111-1111-1111-1111-111111111111',
  name: '#MonthlyBill',
  createdAt: '2026-06-01T00:00:00Z',
  updatedAt: '2026-06-01T00:00:00Z',
);

const lookupTransaction = Transaction(
  id: 'created-lookup-transaction',
  userId: '11111111-1111-1111-1111-111111111111',
  type: TransactionType.expense,
  walletId: lookupGoPayWalletId,
  categoryId: lookupExpenseCategoryId,
  amountMinor: 35000,
  tagIds: [],
  transactionAt: '2026-06-21T10:00:00Z',
  note: 'Lookup transaction',
  createdAt: '2026-06-21T10:00:00Z',
  updatedAt: '2026-06-21T10:00:00Z',
);
