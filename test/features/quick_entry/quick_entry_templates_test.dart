import 'package:affluena_mobile/app/provider_retry.dart';
import 'package:affluena_mobile/core/api/pagination.dart';
import 'package:affluena_mobile/features/categories/data/category_models.dart';
import 'package:affluena_mobile/features/categories/data/category_repository.dart';
import 'package:affluena_mobile/features/quick_entry/data/quick_entry_models.dart';
import 'package:affluena_mobile/features/quick_entry/data/quick_entry_repository.dart';
import 'package:affluena_mobile/features/quick_entry/presentation/quick_entry_templates_screen.dart';
import 'package:affluena_mobile/features/shared/presentation/widgets/date_picker_field.dart';
import 'package:affluena_mobile/features/tags/data/tag_models.dart';
import 'package:affluena_mobile/features/tags/data/tag_repository.dart';
import 'package:affluena_mobile/features/transactions/data/transaction_models.dart';
import 'package:affluena_mobile/features/wallets/data/wallet_models.dart';
import 'package:affluena_mobile/features/wallets/data/wallet_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

void main() {
  setUpAll(() async {
    // DatePickerField formats with the 'id_ID' locale, mirroring main().
    await initializeDateFormatting('id_ID');
  });

  testWidgets('renders template detail with wallet category and tag names', (
    tester,
  ) async {
    await tester.pumpWidget(
      quickEntryTemplatesApp(
        quickEntryRepository: TestQuickEntryTemplateRepository(
          templates: [dailyCoffeeTemplate],
        ),
      ),
    );
    await tester.pumpTemplateState();

    expect(find.text('Daily Coffee'), findsOneWidget);
    expect(find.text('GoPay'), findsOneWidget);
    expect(find.text('Food & Dining'), findsOneWidget);
    expect(find.text('#MonthlyBill'), findsOneWidget);
    expect(find.text(gopayWallet.id), findsNothing);
    expect(find.text(foodCategory.id), findsNothing);

    await tester.tap(find.byKey(const Key('template-detail-template-coffee')));
    await tester.pumpAndSettle();

    expect(find.text('Daily Coffee details'), findsOneWidget);
    expect(find.text('Wallet: GoPay'), findsOneWidget);
    expect(find.text('Category: Food & Dining'), findsOneWidget);
    expect(find.text('Tags: #MonthlyBill'), findsOneWidget);
  });

  testWidgets(
    'creates edits and deletes a template from display-name selectors',
    (tester) async {
      final repository = TestQuickEntryTemplateRepository();

      await tester.pumpWidget(
        quickEntryTemplatesApp(quickEntryRepository: repository),
      );
      await tester.pumpTemplateState();

      await tester.tap(find.byKey(const Key('add-template-button')));
      await tester.pumpAndSettle();
      expect(find.text('Create template'), findsOneWidget);

      await tester.enterText(
        find.byKey(const Key('template-name-field')),
        'Weekend Lunch',
      );
      await tester.enterText(
        find.byKey(const Key('template-amount-field')),
        '89000',
      );
      await _tapTemplateSelector(tester, 'template-wallet-selector');
      await tester.tap(find.text('BCA Primary').last);
      await tester.pumpAndSettle();
      await _tapTemplateSelector(tester, 'template-category-selector');
      await tester.tap(find.text('Transportation').last);
      await tester.pumpAndSettle();
      await _tapTemplateSelector(tester, 'template-tag-selector');
      await tester.tap(find.text('#MonthlyBill').last);
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('tag-multi-select-apply')));
      await tester.pumpAndSettle();
      await _scrollToTemplateSave(tester);
      await tester.tap(find.byKey(const Key('template-save-button')));
      await tester.pumpTemplateState();

      expect(repository.createdRequests.single.name, 'Weekend Lunch');
      expect(repository.createdRequests.single.walletId, bcaWallet.id);
      expect(
        repository.createdRequests.single.categoryId,
        transportationCategory.id,
      );
      expect(repository.createdRequests.single.tagIds, [monthlyTag.id]);
      expect(repository.createdRequests.single.amountMinor, 89000);
      expect(find.text('Weekend Lunch'), findsOneWidget);
      expect(find.text('BCA Primary'), findsOneWidget);
      expect(find.text('Transportation'), findsOneWidget);
      expect(find.text(bcaWallet.id), findsNothing);

      await tester.tap(
        find.byKey(const Key('template-menu-template-weekend-lunch')),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Edit'));
      await tester.pumpAndSettle();
      expect(find.text('Edit template'), findsOneWidget);
      expect(find.text('BCA Primary'), findsWidgets);
      expect(find.text('Transportation'), findsWidgets);

      await tester.enterText(
        find.byKey(const Key('template-name-field')),
        'Weekend Brunch',
      );
      await _scrollToTemplateSave(tester);
      await tester.tap(find.byKey(const Key('template-save-button')));
      await tester.pumpTemplateState();

      expect(repository.updatedIds.single, 'template-weekend-lunch');
      expect(repository.updatedRequests.single.name, 'Weekend Brunch');
      expect(repository.updatedRequests.single.walletId, bcaWallet.id);
      expect(
        repository.updatedRequests.single.categoryId,
        transportationCategory.id,
      );
      expect(find.text('Weekend Brunch'), findsOneWidget);

      await tester.tap(
        find.byKey(const Key('template-menu-template-weekend-lunch')),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Delete'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Delete template'));
      await tester.pumpTemplateState();

      expect(repository.deletedIds.single, 'template-weekend-lunch');
      expect(find.text('Weekend Brunch'), findsNothing);
    },
  );

  testWidgets(
    'execute failure keeps template visible and override request intact',
    (tester) async {
      final repository = TestQuickEntryTemplateRepository(
        templates: [dailyCoffeeTemplate],
        executeError: Exception('offline'),
      );

      await tester.pumpWidget(
        quickEntryTemplatesApp(quickEntryRepository: repository),
      );
      await tester.pumpTemplateState();

      await tester.tap(
        find.byKey(const Key('execute-template-template-coffee')),
      );
      await tester.pumpAndSettle();
      expect(find.text('Execute Daily Coffee'), findsOneWidget);

      // The execute date is now a tappable DatePickerField backed by the native
      // date picker (no typed YYYY-MM-DD). Open it and confirm via the picker's
      // OK action.
      final expectedDate = await _confirmExecutionDate(tester);
      await tester.enterText(
        find.byKey(const Key('template-execute-note-field')),
        'Override note',
      );
      await tester.tap(find.byKey(const Key('template-execute-button')));
      await tester.pumpAndSettle();

      expect(repository.executedIds.single, dailyCoffeeTemplate.id);
      expect(
        repository.executeRequests.single.transactionAt,
        contains(expectedDate),
      );
      expect(repository.executeRequests.single.note, 'Override note');
      expect(find.text('Template could not be executed.'), findsWidgets);
      expect(find.text('Execute Daily Coffee'), findsOneWidget);
      expect(find.text('Daily Coffee'), findsWidgets);
    },
  );
}

/// Opens the DatePickerField's native picker and confirms the default date
/// (today). Returns the expected `YYYY-MM-DD` date the screen will send: the
/// screen anchors the chosen day to local noon before converting to UTC, which
/// keeps the calendar day stable across timezones.
Future<String> _confirmExecutionDate(WidgetTester tester) async {
  final now = DateTime.now();
  final field = find.byKey(const Key('template-execute-date-field'));
  await tester.ensureVisible(field);
  await tester.pumpAndSettle();
  await tester.tap(field);
  await tester.pumpAndSettle();
  expect(find.byType(DatePickerField), findsWidgets);
  await tester.tap(find.text('OK'));
  await tester.pumpAndSettle();

  final utc = DateTime(now.year, now.month, now.day, 12).toUtc();
  final month = utc.month.toString().padLeft(2, '0');
  final dayStr = utc.day.toString().padLeft(2, '0');
  return '${utc.year}-$month-$dayStr';
}

Future<void> _scrollToTemplateSave(WidgetTester tester) async {
  await tester.scrollUntilVisible(
    find.byKey(const Key('template-save-button')),
    240,
    scrollable: find.byType(Scrollable).last,
  );
  await Scrollable.ensureVisible(
    tester.element(find.byKey(const Key('template-save-button'))),
    alignment: 0.72,
    duration: Duration.zero,
  );
  await tester.pumpAndSettle();
}

Future<void> _tapTemplateSelector(WidgetTester tester, String key) async {
  final finder = find.byKey(Key(key));
  await Scrollable.ensureVisible(
    tester.element(finder),
    alignment: 0.45,
    duration: Duration.zero,
  );
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

extension on WidgetTester {
  Future<void> pumpTemplateState() async {
    await pump();
    await pump();
    await pumpAndSettle();
  }
}

Widget quickEntryTemplatesApp({
  TestQuickEntryTemplateRepository? quickEntryRepository,
}) {
  return ProviderScope(
    retry: noProviderRetry,
    overrides: [
      walletRepositoryProvider.overrideWithValue(
        const TestTemplateWalletRepository(wallets: [gopayWallet, bcaWallet]),
      ),
      categoryRepositoryProvider.overrideWithValue(
        const TestTemplateCategoryRepository(
          categories: [foodCategory, transportationCategory, salaryCategory],
        ),
      ),
      tagRepositoryProvider.overrideWithValue(
        const TestTemplateTagRepository(tags: [monthlyTag]),
      ),
      quickEntryRepositoryProvider.overrideWithValue(
        quickEntryRepository ?? TestQuickEntryTemplateRepository(),
      ),
    ],
    child: const MaterialApp(home: Scaffold(body: QuickEntryTemplatesScreen())),
  );
}

class TestQuickEntryTemplateRepository implements QuickEntryRepository {
  TestQuickEntryTemplateRepository({
    List<QuickEntryTemplate> templates = const [],
    this.executeError,
  }) : _templates = List<QuickEntryTemplate>.of(templates);

  final List<QuickEntryTemplate> _templates;
  final Object? executeError;
  final createdRequests = <QuickEntryTemplateRequest>[];
  final updatedIds = <String>[];
  final updatedRequests = <QuickEntryTemplateRequest>[];
  final deletedIds = <String>[];
  final executedIds = <String>[];
  final executeRequests = <ExecuteQuickEntryRequest>[];

  @override
  Future<QuickEntryTemplateListResponse> listTemplates({
    int? limit,
    int? offset,
    String? sort,
  }) async {
    return QuickEntryTemplateListResponse(
      templates: _templates,
      pagination: Pagination(
        total: _templates.length,
        limit: limit ?? _templates.length,
        offset: offset ?? 0,
      ),
    );
  }

  @override
  Future<QuickEntryTemplate> getTemplate(String id) async {
    return _templates.firstWhere((template) => template.id == id);
  }

  @override
  Future<QuickEntryTemplate> createTemplate(
    QuickEntryTemplateRequest request,
  ) async {
    createdRequests.add(request);
    final template = QuickEntryTemplate(
      id: 'template-${request.name.toLowerCase().replaceAll(' ', '-')}',
      userId: 'user-1',
      name: request.name,
      type: request.type,
      walletId: request.walletId,
      toWalletId: request.toWalletId,
      categoryId: request.categoryId,
      amountMinor: request.amountMinor,
      note: request.note ?? '',
      tagIds: request.tagIds,
      createdAt: '2026-06-01T00:00:00Z',
      updatedAt: '2026-06-01T00:00:00Z',
    );
    _templates.add(template);
    return template;
  }

  @override
  Future<QuickEntryTemplate> updateTemplate(
    String id,
    QuickEntryTemplateRequest request,
  ) async {
    updatedIds.add(id);
    updatedRequests.add(request);
    final index = _templates.indexWhere((template) => template.id == id);
    final current = _templates[index];
    final template = QuickEntryTemplate(
      id: current.id,
      userId: current.userId,
      name: request.name,
      type: request.type,
      walletId: request.walletId,
      toWalletId: request.toWalletId,
      categoryId: request.categoryId,
      amountMinor: request.amountMinor,
      note: request.note ?? '',
      tagIds: request.tagIds,
      createdAt: current.createdAt,
      updatedAt: '2026-06-02T00:00:00Z',
    );
    _templates[index] = template;
    return template;
  }

  @override
  Future<void> deleteTemplate(String id) async {
    deletedIds.add(id);
    _templates.removeWhere((template) => template.id == id);
  }

  @override
  Future<ExecuteQuickEntryResponse> executeTemplate(
    String id,
    ExecuteQuickEntryRequest request,
  ) async {
    executedIds.add(id);
    executeRequests.add(request);
    if (executeError != null) throw executeError!;
    return const ExecuteQuickEntryResponse(transaction: createdTransaction);
  }
}

class TestTemplateWalletRepository implements WalletRepository {
  const TestTemplateWalletRepository({required this.wallets});

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
    return getWallet(id);
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

class TestTemplateCategoryRepository implements CategoryRepository {
  const TestTemplateCategoryRepository({required this.categories});

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
  Future<Category> createCategory(CategoryRequest request) async =>
      categories.first;

  @override
  Future<Category> getCategory(String id) async {
    return categories.firstWhere((category) => category.id == id);
  }

  @override
  Future<Category> updateCategory(String id, CategoryRequest request) async {
    return getCategory(id);
  }

  @override
  Future<void> deleteCategory(String id) async {}
}

class TestTemplateTagRepository implements TagRepository {
  const TestTemplateTagRepository({required this.tags});

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
  Future<Tag> updateTag(String id, TagRequest request) async {
    return getTag(id);
  }

  @override
  Future<void> deleteTag(String id) async {}
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
  id: 'template-coffee',
  userId: 'user-1',
  name: 'Daily Coffee',
  type: TransactionType.expense,
  walletId: '22222222-2222-2222-2222-222222220003',
  categoryId: '44444444-4444-4444-4444-444444440001',
  amountMinor: 35000,
  note: 'Daily coffee',
  tagIds: ['55555555-5555-5555-5555-555555550002'],
  createdAt: '2026-06-01T00:00:00Z',
  updatedAt: '2026-06-01T00:00:00Z',
);

const createdTransaction = Transaction(
  id: 'created-transaction',
  userId: 'user-1',
  type: TransactionType.expense,
  walletId: '22222222-2222-2222-2222-222222220003',
  categoryId: '44444444-4444-4444-4444-444444440001',
  amountMinor: 35000,
  tagIds: ['55555555-5555-5555-5555-555555550002'],
  transactionAt: '2026-06-21T10:00:00Z',
  note: 'Daily coffee',
  createdAt: '2026-06-21T10:00:00Z',
  updatedAt: '2026-06-21T10:00:00Z',
);
