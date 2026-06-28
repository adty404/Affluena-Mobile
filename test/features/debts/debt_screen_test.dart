import 'package:affluena_mobile/app/provider_retry.dart';
import 'package:affluena_mobile/core/api/pagination.dart';
import 'package:affluena_mobile/features/categories/data/category_models.dart';
import 'package:affluena_mobile/features/categories/data/category_repository.dart';
import 'package:affluena_mobile/features/debts/application/debt_controller.dart';
import 'package:affluena_mobile/features/debts/data/debt_models.dart';
import 'package:affluena_mobile/features/debts/data/debt_repository.dart';
import 'package:affluena_mobile/features/debts/presentation/debt_screen.dart';
import 'package:affluena_mobile/features/wallets/data/wallet_models.dart';
import 'package:affluena_mobile/features/wallets/data/wallet_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('loads initial debt state from repositories', () async {
    final container = ProviderContainer(
      retry: noProviderRetry,
      overrides: [
        debtRepositoryProvider.overrideWithValue(TestDebtRepository()),
        walletRepositoryProvider.overrideWithValue(
          const TestWalletRepository(),
        ),
        categoryRepositoryProvider.overrideWithValue(
          const TestCategoryRepository(),
        ),
      ],
    );
    addTearDown(container.dispose);

    container.read(debtControllerProvider);
    await Future<void>.delayed(Duration.zero);
    await Future<void>.delayed(Duration.zero);

    final state = container.read(debtControllerProvider);
    expect(state.debts.single.counterpartyName, 'Alya');
    expect(state.walletName('wallet-main'), 'Main Wallet');
    expect(state.categoryName('category-food'), 'Food & Dining');
  });

  testWidgets('renders debt cards with names and status', (tester) async {
    await tester.pumpWidget(debtTestApp());
    await tester.pumpDebtState();

    expect(find.text('Utang'), findsWidgets);
    await tester.scrollUntilVisible(
      find.text('Alya'),
      300,
      scrollable: find.byType(Scrollable).first,
    );

    expect(find.text('Alya'), findsOneWidget);
    expect(find.text('Sebagian'), findsOneWidget);
    expect(find.textContaining('wallet-main'), findsNothing);
    expect(find.textContaining('category-food'), findsNothing);
  });

  testWidgets('creates a payable debt from selectors', (tester) async {
    final repository = TestDebtRepository(debts: const []);

    await tester.pumpWidget(debtTestApp(debtRepository: repository));
    await tester.pumpDebtState();

    await tester.tap(find.byIcon(Icons.add));
    await tester.pumpAndSettle();
    expect(find.text('Buat utang'), findsOneWidget);

    await tester.enterText(find.byType(TextField).first, 'Bima');
    await tester.tap(find.text('Pilih dompet'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Main Wallet'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Pilih kategori').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Salary'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Pilih kategori').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Food & Dining'));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const Key('debt-amount-field')),
      '750000',
    );
    await tester.pump();
    expect(
      tester
          .widget<FilledButton>(find.byKey(const Key('debt-save-button')))
          .onPressed,
      isNotNull,
    );

    await tester.ensureVisible(find.byKey(const Key('debt-save-button')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('debt-save-button')));
    await tester.pumpAndSettle();

    expect(repository.createdRequests.single.counterpartyName, 'Bima');
    expect(
      repository.createdRequests.single.disbursementCategoryId,
      'category-salary',
    );
    expect(
      repository.createdRequests.single.paymentCategoryId,
      'category-food',
    );
  });

  testWidgets('records a debt payment', (tester) async {
    final repository = TestDebtRepository();

    await tester.pumpWidget(debtTestApp(debtRepository: repository));
    await tester.pumpDebtState();
    await tester.scrollUntilVisible(
      find.text('Catat pembayaran'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.ensureVisible(find.text('Catat pembayaran'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Catat pembayaran'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('debt-payment-amount-field')),
      '250000',
    );
    await tester.pump();
    await tester.tap(find.byKey(const Key('debt-payment-save-button')));
    await tester.pumpAndSettle();

    expect(repository.paymentRequests.single.amountMinor, 250000);
  });
}

extension on WidgetTester {
  Future<void> pumpDebtState() async {
    await pump();
    await pump();
    await pumpAndSettle();
  }
}

Widget debtTestApp({TestDebtRepository? debtRepository}) {
  return ProviderScope(
    retry: noProviderRetry,
    overrides: [
      debtRepositoryProvider.overrideWithValue(
        debtRepository ?? TestDebtRepository(),
      ),
      walletRepositoryProvider.overrideWithValue(const TestWalletRepository()),
      categoryRepositoryProvider.overrideWithValue(
        const TestCategoryRepository(),
      ),
    ],
    child: const MaterialApp(home: Scaffold(body: DebtScreen())),
  );
}

class TestDebtRepository implements DebtRepository {
  TestDebtRepository({List<Debt> debts = const [seedDebt]})
    : _debts = List<Debt>.of(debts);

  final List<Debt> _debts;
  final createdRequests = <DebtRequest>[];
  final paymentRequests = <DebtPaymentRequest>[];

  @override
  Future<DebtListResponse> listDebts({
    int? limit,
    int? offset,
    String? sort,
  }) async {
    return DebtListResponse(
      debts: _debts,
      pagination: Pagination(
        total: _debts.length,
        limit: limit ?? _debts.length,
        offset: offset ?? 0,
      ),
    );
  }

  @override
  Future<Debt> getDebt(String id) async {
    return _debts.firstWhere((debt) => debt.id == id);
  }

  @override
  Future<Debt> createDebt(DebtRequest request) async {
    createdRequests.add(request);
    final debt = seedDebt.copyForCreate(
      id: 'debt-${request.counterpartyName}',
      counterpartyName: request.counterpartyName,
      principalAmountMinor: request.principalAmountMinor,
      remainingAmountMinor: request.principalAmountMinor,
    );
    _debts.add(debt);
    return debt;
  }

  @override
  Future<Debt> updateDebt(String id, DebtUpdateRequest request) async {
    return _debts.firstWhere((debt) => debt.id == id);
  }

  @override
  Future<void> deleteDebt(String id) async {
    _debts.removeWhere((debt) => debt.id == id);
  }

  @override
  Future<DebtPayment> payDebt(String id, DebtPaymentRequest request) async {
    paymentRequests.add(request);
    return DebtPayment(
      id: 'payment-1',
      userId: 'user-1',
      debtId: id,
      transactionId: 'transaction-payment',
      amountMinor: request.amountMinor,
      paidAt: request.paidAt ?? '2026-06-22T00:00:00Z',
      note: request.note ?? '',
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
      wallets: [mainWallet, goalWallet],
      pagination: Pagination(total: 2, limit: 100, offset: 0),
    );
  }

  @override
  Future<Wallet> createWallet(WalletRequest request) async => mainWallet;

  @override
  Future<Wallet> getWallet(String id) async {
    return [mainWallet, goalWallet].firstWhere((wallet) => wallet.id == id);
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
    final categories = [
      salaryCategory,
      foodCategory,
    ].where((category) => type == null || category.type == type).toList();
    return CategoryListResponse(
      categories: categories,
      pagination: Pagination(
        total: categories.length,
        limit: limit ?? categories.length,
        offset: offset ?? 0,
      ),
    );
  }

  @override
  Future<Category> createCategory(CategoryRequest request) async =>
      salaryCategory;

  @override
  Future<Category> getCategory(String id) async {
    return [
      salaryCategory,
      foodCategory,
    ].firstWhere((category) => category.id == id);
  }

  @override
  Future<Category> updateCategory(String id, CategoryRequest request) async {
    return salaryCategory;
  }

  @override
  Future<void> deleteCategory(String id) async {}
}

extension on Debt {
  Debt copyForCreate({
    required String id,
    required String counterpartyName,
    required int principalAmountMinor,
    required int remainingAmountMinor,
  }) {
    return Debt(
      id: id,
      userId: userId,
      type: type,
      counterpartyName: counterpartyName,
      walletId: walletId,
      disbursementCategoryId: disbursementCategoryId,
      paymentCategoryId: paymentCategoryId,
      originationTransactionId: originationTransactionId,
      principalAmountMinor: principalAmountMinor,
      paidAmountMinor: 0,
      remainingAmountMinor: remainingAmountMinor,
      openedAt: openedAt,
      dueDate: dueDate,
      status: DebtStatus.open,
      note: note,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }
}

const mainWallet = Wallet(
  id: 'wallet-main',
  userId: 'user-1',
  name: 'Main Wallet',
  type: WalletType.bank,
  currencyCode: 'IDR',
  balanceMinor: 5000000,
  color: 'green',
  description: 'Primary',
  createdAt: '2026-06-01T00:00:00Z',
  updatedAt: '2026-06-01T00:00:00Z',
);

const goalWallet = Wallet(
  id: 'wallet-goal',
  userId: 'user-1',
  name: 'Goal Wallet',
  type: WalletType.goal,
  currencyCode: 'IDR',
  balanceMinor: 500000,
  color: 'blue',
  description: 'Goal',
  createdAt: '2026-06-01T00:00:00Z',
  updatedAt: '2026-06-01T00:00:00Z',
);

const salaryCategory = Category(
  id: 'category-salary',
  userId: 'user-1',
  name: 'Salary',
  type: CategoryType.income,
  createdAt: '2026-06-01T00:00:00Z',
  updatedAt: '2026-06-01T00:00:00Z',
);

const foodCategory = Category(
  id: 'category-food',
  userId: 'user-1',
  name: 'Food & Dining',
  type: CategoryType.expense,
  createdAt: '2026-06-01T00:00:00Z',
  updatedAt: '2026-06-01T00:00:00Z',
);

const seedDebt = Debt(
  id: 'debt-alya',
  userId: 'user-1',
  type: DebtType.payable,
  counterpartyName: 'Alya',
  walletId: 'wallet-main',
  disbursementCategoryId: 'category-salary',
  paymentCategoryId: 'category-food',
  originationTransactionId: 'transaction-origin',
  principalAmountMinor: 1500000,
  paidAmountMinor: 500000,
  remainingAmountMinor: 1000000,
  openedAt: '2026-06-01T00:00:00Z',
  dueDate: '2026-06-30',
  status: DebtStatus.partial,
  note: 'Laptop advance',
  createdAt: '2026-06-01T00:00:00Z',
  updatedAt: '2026-06-02T00:00:00Z',
);
