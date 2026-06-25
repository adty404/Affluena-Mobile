import 'package:affluena_mobile/app/provider_retry.dart';
import 'package:affluena_mobile/core/api/pagination.dart';
import 'package:affluena_mobile/features/categories/data/category_models.dart';
import 'package:affluena_mobile/features/categories/data/category_repository.dart';
import 'package:affluena_mobile/features/recurring/application/recurring_controller.dart';
import 'package:affluena_mobile/features/recurring/data/recurring_models.dart';
import 'package:affluena_mobile/features/recurring/data/recurring_repository.dart';
import 'package:affluena_mobile/features/recurring/presentation/recurring_screen.dart';
import 'package:affluena_mobile/features/shared/presentation/widgets/date_picker_field.dart';
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

  test('loads recurring state from repositories', () async {
    final container = ProviderContainer(
      retry: noProviderRetry,
      overrides: [
        recurringRepositoryProvider.overrideWithValue(
          TestRecurringRepository(),
        ),
        walletRepositoryProvider.overrideWithValue(
          const TestWalletRepository(),
        ),
        categoryRepositoryProvider.overrideWithValue(
          const TestCategoryRepository(),
        ),
      ],
    );
    addTearDown(container.dispose);

    container.read(recurringControllerProvider);
    await Future<void>.delayed(Duration.zero);
    await Future<void>.delayed(Duration.zero);

    final state = container.read(recurringControllerProvider);
    expect(state.rules.single.name, 'Monthly rent');
    expect(state.walletName('wallet-main'), 'Main Wallet');
    expect(state.categoryName('category-rent'), 'Rent');
  });

  testWidgets('renders recurring card and runs it manually', (tester) async {
    final repository = TestRecurringRepository();

    await tester.pumpWidget(recurringTestApp(repository));
    await tester.pumpRecurringState();

    expect(find.text('Recurring'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Monthly rent'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Monthly rent'), findsOneWidget);
    expect(find.textContaining('wallet-main'), findsNothing);

    await tester.ensureVisible(find.text('Run now'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Run now'));
    await tester.pumpAndSettle();

    expect(repository.runRequests, ['rule-1']);
  });

  testWidgets('creates a recurring expense from selectors', (tester) async {
    final repository = TestRecurringRepository(rules: const []);

    await tester.pumpWidget(recurringTestApp(repository));
    await tester.pumpRecurringState();

    await tester.tap(find.byIcon(Icons.add));
    await tester.pumpAndSettle();
    expect(find.text('Create recurring'), findsOneWidget);

    await tester.enterText(
      find.byKey(const Key('recurring-name-field')),
      'Gym',
    );
    await tester.tap(find.text('Choose wallet'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Main Wallet'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Choose category'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Rent'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('recurring-amount-field')),
      '300000',
    );
    // The next-run input is now a tappable DatePickerField backed by the native
    // date picker rather than a hand-typed RFC3339 TextField. Open it and
    // confirm a date so the rule has a non-null next run.
    await tester.ensureVisible(
      find.byKey(const Key('recurring-next-run-field')),
    );
    await tester.tap(find.byKey(const Key('recurring-next-run-field')));
    await tester.pumpAndSettle();
    expect(find.byType(DatePickerField), findsWidgets);
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();

    expect(
      tester
          .widget<FilledButton>(find.byKey(const Key('recurring-save-button')))
          .onPressed,
      isNotNull,
    );
    await tester.ensureVisible(find.byKey(const Key('recurring-save-button')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('recurring-save-button')));
    await tester.pumpAndSettle();

    expect(repository.createdRequests.single.name, 'Gym');
    expect(repository.createdRequests.single.categoryId, 'category-rent');
  });
}

extension on WidgetTester {
  Future<void> pumpRecurringState() async {
    await pump();
    await pump();
    await pumpAndSettle();
  }
}

Widget recurringTestApp(TestRecurringRepository repository) {
  return ProviderScope(
    retry: noProviderRetry,
    overrides: [
      recurringRepositoryProvider.overrideWithValue(repository),
      walletRepositoryProvider.overrideWithValue(const TestWalletRepository()),
      categoryRepositoryProvider.overrideWithValue(
        const TestCategoryRepository(),
      ),
    ],
    child: const MaterialApp(home: Scaffold(body: RecurringScreen())),
  );
}

class TestRecurringRepository implements RecurringRepository {
  TestRecurringRepository({List<RecurringRule> rules = const [seedRule]})
    : _rules = List<RecurringRule>.of(rules);

  final List<RecurringRule> _rules;
  final createdRequests = <RecurringRuleRequest>[];
  final runRequests = <String>[];

  @override
  Future<RecurringRuleListResponse> listRules({
    int? limit,
    int? offset,
    String? sort,
  }) async {
    return RecurringRuleListResponse(
      rules: _rules,
      pagination: Pagination(
        total: _rules.length,
        limit: limit ?? _rules.length,
        offset: offset ?? 0,
      ),
    );
  }

  @override
  Future<RecurringRule> getRule(String id) async {
    return _rules.firstWhere((rule) => rule.id == id);
  }

  @override
  Future<RecurringRule> createRule(RecurringRuleRequest request) async {
    createdRequests.add(request);
    final rule = seedRule.copyForRequest(
      id: 'rule-${request.name}',
      name: request.name,
      categoryId: request.categoryId,
      amountMinor: request.amountMinor,
    );
    _rules.add(rule);
    return rule;
  }

  @override
  Future<RecurringRule> updateRule(
    String id,
    RecurringRuleRequest request,
  ) async {
    return _rules.firstWhere((rule) => rule.id == id);
  }

  @override
  Future<void> deleteRule(String id) async {
    _rules.removeWhere((rule) => rule.id == id);
  }

  @override
  Future<RecurringRun> runRule(String id) async {
    runRequests.add(id);
    return RecurringRun(
      id: 'run-1',
      ruleId: id,
      userId: 'user-1',
      scheduledFor: '2026-07-01T00:00:00Z',
      transactionId: 'transaction-1',
      runType: RecurringRunType.manual,
      createdAt: '2026-06-22T00:00:00Z',
    );
  }
}

class TestWalletRepository implements WalletRepository {
  const TestWalletRepository();

  @override
  Future<WalletListResponse> listWallets({
    int? limit,
    int? offset,
    String? sort,
  }) async {
    return const WalletListResponse(
      wallets: [mainWallet, savingsWallet, goalWallet],
      pagination: Pagination(total: 3, limit: 100, offset: 0),
    );
  }

  @override
  Future<Wallet> createWallet(WalletRequest request) async => mainWallet;

  @override
  Future<Wallet> getWallet(String id) async {
    return [
      mainWallet,
      savingsWallet,
      goalWallet,
    ].firstWhere((wallet) => wallet.id == id);
  }

  @override
  Future<Wallet> updateWallet(String id, WalletRequest request) async {
    return mainWallet;
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

class TestCategoryRepository implements CategoryRepository {
  const TestCategoryRepository();

  @override
  Future<CategoryListResponse> listCategories({
    CategoryType? type,
    int? limit,
    int? offset,
    String? sort,
  }) async {
    return const CategoryListResponse(
      categories: [rentCategory],
      pagination: Pagination(total: 1, limit: 100, offset: 0),
    );
  }

  @override
  Future<Category> createCategory(CategoryRequest request) async =>
      rentCategory;

  @override
  Future<Category> getCategory(String id) async => rentCategory;

  @override
  Future<Category> updateCategory(String id, CategoryRequest request) async {
    return rentCategory;
  }

  @override
  Future<void> deleteCategory(String id) async {}
}

const mainWallet = Wallet(
  id: 'wallet-main',
  userId: 'user-1',
  name: 'Main Wallet',
  type: WalletType.bank,
  currencyCode: 'IDR',
  balanceMinor: 5000000,
  color: '',
  description: '',
  createdAt: '2026-06-01T00:00:00Z',
  updatedAt: '2026-06-01T00:00:00Z',
);

const savingsWallet = Wallet(
  id: 'wallet-save',
  userId: 'user-1',
  name: 'Savings',
  type: WalletType.bank,
  currencyCode: 'IDR',
  balanceMinor: 2500000,
  color: '',
  description: '',
  createdAt: '2026-06-01T00:00:00Z',
  updatedAt: '2026-06-01T00:00:00Z',
);

const goalWallet = Wallet(
  id: 'wallet-goal',
  userId: 'user-1',
  name: 'Emergency fund',
  type: WalletType.goal,
  currencyCode: 'IDR',
  balanceMinor: 1000000,
  color: '',
  description: '',
  goalId: 'goal-1',
  createdAt: '2026-06-01T00:00:00Z',
  updatedAt: '2026-06-01T00:00:00Z',
);

const rentCategory = Category(
  id: 'category-rent',
  userId: 'user-1',
  name: 'Rent',
  type: CategoryType.expense,
  createdAt: '2026-06-01T00:00:00Z',
  updatedAt: '2026-06-01T00:00:00Z',
);

const seedRule = RecurringRule(
  id: 'rule-1',
  userId: 'user-1',
  name: 'Monthly rent',
  type: RecurringType.expense,
  walletId: 'wallet-main',
  toWalletId: null,
  categoryId: 'category-rent',
  amountMinor: 2500000,
  frequency: RecurringFrequency.monthly,
  intervalCount: 1,
  nextRunAt: '2026-07-01T00:00:00Z',
  endAt: null,
  lastRunAt: null,
  status: RecurringStatus.active,
  note: 'Apartment',
  createdAt: '2026-06-01T00:00:00Z',
  updatedAt: '2026-06-01T00:00:00Z',
);
