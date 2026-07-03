import 'package:affluena_mobile/app/provider_retry.dart';
import 'package:affluena_mobile/core/api/pagination.dart';
import 'package:affluena_mobile/features/categories/data/category_models.dart';
import 'package:affluena_mobile/features/categories/data/category_repository.dart';
import 'package:affluena_mobile/features/trackers/application/tracker_controller.dart';
import 'package:affluena_mobile/features/trackers/data/tracker_models.dart';
import 'package:affluena_mobile/features/trackers/data/tracker_repository.dart';
import 'package:affluena_mobile/features/trackers/presentation/tracker_screen.dart';
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

  test('loads tracker state from repositories', () async {
    final container = ProviderContainer(
      retry: noProviderRetry,
      overrides: [
        trackerRepositoryProvider.overrideWithValue(TestTrackerRepository()),
        walletRepositoryProvider.overrideWithValue(
          const TestWalletRepository(),
        ),
        categoryRepositoryProvider.overrideWithValue(
          const TestCategoryRepository(),
        ),
      ],
    );
    addTearDown(container.dispose);

    container.read(trackerControllerProvider);
    await Future<void>.delayed(Duration.zero);
    await Future<void>.delayed(Duration.zero);

    final state = container.read(trackerControllerProvider);
    expect(state.installments.single.name, 'Laptop');
    expect(state.subscriptions.single.name, 'Spotify');
    expect(state.walletName('wallet-main'), 'Main Wallet');
  });

  testWidgets('renders installment and records payment', (tester) async {
    final repository = TestTrackerRepository();

    await tester.pumpWidget(trackerTestApp(repository));
    await tester.pumpTrackerState();

    expect(find.text('Cicilan & Langganan'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Laptop'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Laptop'), findsOneWidget);
    expect(find.textContaining('wallet-main'), findsNothing);

    await tester.ensureVisible(find.text('Bayar cicilan'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Bayar cicilan'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('tracker-payment-save-button')));
    await tester.pumpAndSettle();

    expect(repository.installmentPaymentRequests, hasLength(1));
  });

  testWidgets('switches to subscriptions and records payment', (tester) async {
    final repository = TestTrackerRepository();

    await tester.pumpWidget(trackerTestApp(repository));
    await tester.pumpTrackerState();

    await tester.tap(find.byKey(const Key('tracker-subscriptions-tab')));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('Spotify'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Spotify'), findsOneWidget);

    await tester.ensureVisible(find.text('Bayar langganan'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Bayar langganan'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('tracker-payment-save-button')));
    await tester.pumpAndSettle();

    expect(repository.subscriptionPaymentRequests, hasLength(1));
  });

  testWidgets('creates a subscription with a chosen color', (tester) async {
    final repository = TestTrackerRepository();

    await tester.pumpWidget(trackerTestApp(repository));
    await tester.pumpTrackerState();

    // Open the form from the subscriptions tab so it starts on that flow.
    await tester.tap(find.byKey(const Key('tracker-subscriptions-tab')));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.add));
    await tester.pumpAndSettle();
    expect(find.text('Buat langganan'), findsOneWidget);

    await tester.enterText(
      find.widgetWithText(TextField, 'Nama').first,
      'Disney+',
    );
    await tester.tap(find.text('Pilih dompet'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Main Wallet'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Pilih kategori'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Food & Dining'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('tracker-amount-field')),
      '65000',
    );
    await tester.pump();
    await tester.ensureVisible(find.byKey(const Key('tracker-date-field')));
    await tester.tap(find.byKey(const Key('tracker-date-field')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();

    // The form exposes the shared color swatches; the chosen color rides
    // along on the create request.
    await tester.ensureVisible(
      find.byKey(const Key('subscription-color-#2E8B57')),
    );
    await tester.tap(find.byKey(const Key('subscription-color-#2E8B57')));
    await tester.pump();

    await tester.ensureVisible(find.byKey(const Key('tracker-save-button')));
    await tester.tap(find.byKey(const Key('tracker-save-button')));
    await tester.pumpAndSettle();

    expect(repository.createdSubscriptionRequests.single.name, 'Disney+');
    expect(repository.createdSubscriptionRequests.single.color, '#2E8B57');
  });
}

extension on WidgetTester {
  Future<void> pumpTrackerState() async {
    await pump();
    await pump();
    await pumpAndSettle();
  }
}

Widget trackerTestApp(TestTrackerRepository repository) {
  return ProviderScope(
    retry: noProviderRetry,
    overrides: [
      trackerRepositoryProvider.overrideWithValue(repository),
      walletRepositoryProvider.overrideWithValue(const TestWalletRepository()),
      categoryRepositoryProvider.overrideWithValue(
        const TestCategoryRepository(),
      ),
    ],
    child: const MaterialApp(home: Scaffold(body: TrackerScreen())),
  );
}

class TestTrackerRepository implements TrackerRepository {
  final installmentPaymentRequests = <TrackerPaymentRequest>[];
  final subscriptionPaymentRequests = <TrackerPaymentRequest>[];
  final createdInstallmentRequests = <InstallmentRequest>[];
  final createdSubscriptionRequests = <SubscriptionRequest>[];

  @override
  Future<InstallmentListResponse> listInstallments({
    int? limit,
    int? offset,
    String? sort,
  }) async {
    return InstallmentListResponse(
      installments: const [seedInstallment],
      pagination: Pagination(total: 1, limit: limit ?? 1, offset: offset ?? 0),
    );
  }

  @override
  Future<Installment> getInstallment(String id) async => seedInstallment;

  @override
  Future<Installment> createInstallment(InstallmentRequest request) async {
    createdInstallmentRequests.add(request);
    return seedInstallment;
  }

  @override
  Future<Installment> updateInstallment(
    String id,
    InstallmentRequest request,
  ) async {
    return seedInstallment;
  }

  @override
  Future<void> deleteInstallment(String id) async {}

  @override
  Future<InstallmentPayment> payInstallment(
    String id,
    TrackerPaymentRequest request,
  ) async {
    installmentPaymentRequests.add(request);
    return InstallmentPayment(
      id: 'payment-installment',
      userId: 'user-1',
      installmentId: id,
      transactionId: 'transaction-1',
      amountMinor: seedInstallment.monthlyAmountMinor,
      paidAt: request.paidAt ?? '2026-06-22T00:00:00Z',
      note: request.note ?? '',
      createdAt: '2026-06-22T00:00:00Z',
    );
  }

  @override
  Future<SubscriptionListResponse> listSubscriptions({
    int? limit,
    int? offset,
    String? sort,
  }) async {
    return SubscriptionListResponse(
      subscriptions: const [seedSubscription],
      pagination: Pagination(total: 1, limit: limit ?? 1, offset: offset ?? 0),
    );
  }

  @override
  Future<Subscription> getSubscription(String id) async => seedSubscription;

  @override
  Future<Subscription> createSubscription(SubscriptionRequest request) async {
    createdSubscriptionRequests.add(request);
    return seedSubscription;
  }

  @override
  Future<Subscription> updateSubscription(
    String id,
    SubscriptionRequest request,
  ) async {
    return seedSubscription;
  }

  @override
  Future<void> deleteSubscription(String id) async {}

  @override
  Future<SubscriptionPayment> paySubscription(
    String id,
    TrackerPaymentRequest request,
  ) async {
    subscriptionPaymentRequests.add(request);
    return SubscriptionPayment(
      id: 'payment-subscription',
      userId: 'user-1',
      subscriptionId: id,
      transactionId: 'transaction-2',
      amountMinor: seedSubscription.amountMinor,
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
      wallets: [mainWallet],
      pagination: Pagination(total: 1, limit: 100, offset: 0),
    );
  }

  @override
  Future<Wallet> createWallet(WalletRequest request) async => mainWallet;

  @override
  Future<Wallet> getWallet(String id) async => mainWallet;

  @override
  Future<Wallet> updateWallet(String id, WalletRequest request) async =>
      mainWallet;

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
    return const WalletMembersResponse(members: []);
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
      categories: [foodCategory],
      pagination: Pagination(total: 1, limit: 100, offset: 0),
    );
  }

  @override
  Future<Category> createCategory(CategoryRequest request) async =>
      foodCategory;

  @override
  Future<Category> getCategory(String id) async => foodCategory;

  @override
  Future<Category> updateCategory(String id, CategoryRequest request) async =>
      foodCategory;

  @override
  Future<void> deleteCategory(String id) async {}

  @override
  Future<void> reorderCategories(List<String> ids) async {}
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

const foodCategory = Category(
  id: 'category-food',
  userId: 'user-1',
  name: 'Food & Dining',
  type: CategoryType.expense,
  createdAt: '2026-06-01T00:00:00Z',
  updatedAt: '2026-06-01T00:00:00Z',
);

const seedInstallment = Installment(
  id: 'installment-laptop',
  userId: 'user-1',
  name: 'Laptop',
  walletId: 'wallet-main',
  categoryId: 'category-food',
  totalAmountMinor: 12000000,
  monthlyAmountMinor: 1000000,
  tenorMonths: 12,
  remainingMonths: 8,
  startDate: '2026-01-01',
  dueDay: 5,
  status: InstallmentStatus.active,
  note: 'Office laptop',
  createdAt: '2026-01-01T00:00:00Z',
  updatedAt: '2026-01-01T00:00:00Z',
);

const seedSubscription = Subscription(
  id: 'subscription-spotify',
  userId: 'user-1',
  name: 'Spotify',
  accountDetail: 'Family plan',
  walletId: 'wallet-main',
  categoryId: 'category-food',
  amountMinor: 65000,
  billingCycle: BillingCycle.monthly,
  nextDueDate: '2026-07-01',
  status: SubscriptionStatus.active,
  note: '',
  createdAt: '2026-01-01T00:00:00Z',
  updatedAt: '2026-01-01T00:00:00Z',
);
