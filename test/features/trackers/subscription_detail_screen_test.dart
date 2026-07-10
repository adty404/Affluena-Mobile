import 'package:affluena_mobile/app/provider_retry.dart';
import 'package:affluena_mobile/core/api/pagination.dart';
import 'package:affluena_mobile/features/categories/data/category_models.dart';
import 'package:affluena_mobile/features/categories/data/category_repository.dart';
import 'package:affluena_mobile/features/trackers/data/tracker_models.dart';
import 'package:affluena_mobile/features/trackers/data/tracker_repository.dart';
import 'package:affluena_mobile/features/trackers/presentation/subscription_detail_screen.dart';
import 'package:affluena_mobile/features/wallets/data/wallet_models.dart';
import 'package:affluena_mobile/features/wallets/data/wallet_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

// The API serializes its DATE columns as full RFC3339 timestamps — this is
// exactly what a freshly listed subscription carries in `nextDueDate`.
const _activeSubscription = Subscription(
  id: 'subscription-netflix',
  userId: 'user-1',
  name: 'Netflix',
  accountDetail: '',
  walletId: 'wallet-main',
  categoryId: 'category-fun',
  amountMinor: 6500000,
  billingCycle: BillingCycle.monthly,
  nextDueDate: '2026-07-19T00:00:00Z',
  status: SubscriptionStatus.active,
  note: '',
  createdAt: '2026-06-01T00:00:00Z',
  updatedAt: '2026-06-01T00:00:00Z',
);

void main() {
  setUpAll(() async {
    await initializeDateFormatting('id_ID');
  });

  testWidgets('pause sends a date-only next_due_date and flips the status', (
    tester,
  ) async {
    final repository = _RecordingTrackerRepository();
    await _pumpDetail(tester, repository);

    expect(find.text('Jeda langganan'), findsOneWidget);
    await tester.tap(find.text('Jeda langganan'));
    await tester.pumpAndSettle();

    final request = repository.updateRequests.single;
    expect(request.status, SubscriptionStatus.paused);
    // Regression guard: the stored RFC3339 timestamp must be normalized to
    // YYYY-MM-DD — the API's next_due_date field rejects a full timestamp
    // with a 400, which made the pause button look dead.
    expect(request.nextDueDate, '2026-07-19');

    // The reloaded state reflects the flip: pause became resume.
    expect(find.text('Lanjutkan langganan'), findsOneWidget);
    expect(find.text('Jeda langganan'), findsNothing);
    expect(find.text('Dijeda'), findsOneWidget);
  });

  testWidgets('a failed pause surfaces the save error in a SnackBar', (
    tester,
  ) async {
    final repository = _RecordingTrackerRepository(
      updateError: Exception('offline'),
    );
    await _pumpDetail(tester, repository);

    await tester.tap(find.text('Jeda langganan'));
    await tester.pumpAndSettle();

    // The controller folds the failure into state.actionError; the detail
    // screen must surface it instead of failing silently.
    expect(find.byType(SnackBar), findsOneWidget);
    expect(find.text('Cicilan & Langganan gagal disimpan.'), findsOneWidget);
    // The subscription stayed active, so the pause action remains available.
    expect(find.text('Jeda langganan'), findsOneWidget);
  });
}

Future<void> _pumpDetail(
  WidgetTester tester,
  _RecordingTrackerRepository repository,
) async {
  await tester.pumpWidget(
    ProviderScope(
      retry: noProviderRetry,
      overrides: [
        trackerRepositoryProvider.overrideWithValue(repository),
        walletRepositoryProvider.overrideWithValue(
          const _StubWalletRepository(),
        ),
        categoryRepositoryProvider.overrideWithValue(
          const _StubCategoryRepository(),
        ),
      ],
      child: const MaterialApp(
        home: SubscriptionDetailScreen(id: 'subscription-netflix'),
      ),
    ),
  );
  await tester.pump();
  await tester.pump();
  await tester.pumpAndSettle();
}

class _RecordingTrackerRepository implements TrackerRepository {
  _RecordingTrackerRepository({this.updateError});

  /// When set, [updateSubscription] throws instead of applying the change.
  final Object? updateError;

  final updateRequests = <SubscriptionRequest>[];
  Subscription _current = _activeSubscription;

  @override
  Future<SubscriptionListResponse> listSubscriptions({
    int? limit,
    int? offset,
    String? sort,
  }) async {
    return SubscriptionListResponse(
      subscriptions: [_current],
      pagination: const Pagination(total: 1, limit: 20, offset: 0),
    );
  }

  @override
  Future<Subscription> updateSubscription(
    String id,
    SubscriptionRequest request,
  ) async {
    updateRequests.add(request);
    final error = updateError;
    if (error != null) throw error;
    _current = Subscription(
      id: _current.id,
      userId: _current.userId,
      name: request.name,
      accountDetail: request.accountDetail ?? '',
      walletId: request.walletId,
      categoryId: request.categoryId,
      amountMinor: request.amountMinor,
      billingCycle: request.billingCycle,
      nextDueDate: request.nextDueDate,
      status: request.status ?? _current.status,
      note: request.note ?? '',
      createdAt: _current.createdAt,
      updatedAt: _current.updatedAt,
    );
    return _current;
  }

  @override
  Future<InstallmentListResponse> listInstallments({
    int? limit,
    int? offset,
    String? sort,
  }) async {
    return const InstallmentListResponse(
      installments: [],
      pagination: Pagination(total: 0, limit: 20, offset: 0),
    );
  }

  @override
  Future<Subscription> getSubscription(String id) async => _current;

  @override
  Future<List<SubscriptionPayment>> listSubscriptionPayments(String id) async {
    return const [];
  }

  @override
  Future<List<InstallmentPayment>> listInstallmentPayments(String id) async {
    return const [];
  }

  @override
  Future<Subscription> createSubscription(SubscriptionRequest request) =>
      throw UnimplementedError();

  @override
  Future<void> deleteSubscription(String id) => throw UnimplementedError();

  @override
  Future<SubscriptionPayment> paySubscription(
    String id,
    TrackerPaymentRequest request,
  ) => throw UnimplementedError();

  @override
  Future<Installment> getInstallment(String id) => throw UnimplementedError();

  @override
  Future<Installment> createInstallment(InstallmentRequest request) =>
      throw UnimplementedError();

  @override
  Future<Installment> updateInstallment(
    String id,
    InstallmentRequest request,
  ) => throw UnimplementedError();

  @override
  Future<void> deleteInstallment(String id) => throw UnimplementedError();

  @override
  Future<InstallmentPayment> payInstallment(
    String id,
    TrackerPaymentRequest request,
  ) => throw UnimplementedError();
}

class _StubWalletRepository implements WalletRepository {
  const _StubWalletRepository();

  @override
  Future<WalletListResponse> listWallets({
    int? limit,
    int? offset,
    String? sort,
  }) async {
    return const WalletListResponse(
      wallets: [
        Wallet(
          id: 'wallet-main',
          userId: 'user-1',
          name: 'Main Wallet',
          type: WalletType.bank,
          currencyCode: 'IDR',
          balanceMinor: 5000000,
          color: 'green',
          description: '',
          createdAt: '2026-06-01T00:00:00Z',
          updatedAt: '2026-06-01T00:00:00Z',
        ),
      ],
      pagination: Pagination(total: 1, limit: 100, offset: 0),
    );
  }

  @override
  Future<Wallet> createWallet(WalletRequest request) =>
      throw UnimplementedError();

  @override
  Future<Wallet> getWallet(String id) => throw UnimplementedError();

  @override
  Future<Wallet> updateWallet(String id, WalletRequest request) =>
      throw UnimplementedError();

  @override
  Future<void> deleteWallet(String id) => throw UnimplementedError();

  @override
  Future<WalletInviteResponse> inviteMember(
    String id,
    WalletInviteRequest request,
  ) => throw UnimplementedError();

  @override
  Future<WalletInviteResponse> respondInvite(
    String id,
    String memberId,
    WalletInviteResponse response,
  ) => throw UnimplementedError();

  @override
  Future<WalletMembersResponse> listMembers(String id) =>
      throw UnimplementedError();

  @override
  Future<WalletAnalytics> getAnalytics(String id, {String? month}) =>
      throw UnimplementedError();
}

class _StubCategoryRepository implements CategoryRepository {
  const _StubCategoryRepository();

  @override
  Future<CategoryListResponse> listCategories({
    CategoryType? type,
    int? limit,
    int? offset,
    String? sort,
  }) async {
    return const CategoryListResponse(
      categories: [
        Category(
          id: 'category-fun',
          userId: 'user-1',
          name: 'Hiburan',
          type: CategoryType.expense,
          createdAt: '2026-06-01T00:00:00Z',
          updatedAt: '2026-06-01T00:00:00Z',
        ),
      ],
      pagination: Pagination(total: 1, limit: 100, offset: 0),
    );
  }

  @override
  Future<Category> createCategory(CategoryRequest request) =>
      throw UnimplementedError();

  @override
  Future<Category> getCategory(String id) => throw UnimplementedError();

  @override
  Future<Category> updateCategory(String id, CategoryRequest request) =>
      throw UnimplementedError();

  @override
  Future<void> deleteCategory(String id) => throw UnimplementedError();

  @override
  Future<void> reorderCategories(List<String> ids) =>
      throw UnimplementedError();
}
