import 'package:affluena_mobile/app/provider_retry.dart';
import 'package:affluena_mobile/features/categories/data/category_repository.dart';
import 'package:affluena_mobile/features/tags/data/tag_repository.dart';
import 'package:affluena_mobile/features/trackers/application/tracker_controller.dart';
import 'package:affluena_mobile/features/trackers/data/tracker_models.dart';
import 'package:affluena_mobile/features/trackers/data/tracker_repository.dart';
import 'package:affluena_mobile/features/trackers/presentation/installment_detail_screen.dart';
import 'package:affluena_mobile/features/trackers/presentation/subscription_detail_screen.dart';
import 'package:affluena_mobile/features/transactions/data/transaction_models.dart';
import 'package:affluena_mobile/features/transactions/data/transaction_repository.dart';
import 'package:affluena_mobile/features/wallets/data/wallet_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

import '../../helpers/auth_test_helpers.dart';

const _installment = Installment(
  id: 'i1',
  userId: 'u1',
  name: 'iPhone 15',
  walletId: 'w1',
  categoryId: 'c1',
  totalAmountMinor: 14400000,
  monthlyAmountMinor: 1200000,
  tenorMonths: 12,
  remainingMonths: 10,
  startDate: '2026-05-02T00:00:00Z',
  dueDay: 2,
  status: InstallmentStatus.active,
  note: '',
  createdAt: '2026-05-01T00:00:00Z',
  updatedAt: '2026-05-01T00:00:00Z',
);

const _subscription = Subscription(
  id: 's1',
  userId: 'u1',
  name: 'Netflix',
  accountDetail: '',
  walletId: 'w1',
  categoryId: 'c1',
  amountMinor: 65000,
  billingCycle: BillingCycle.monthly,
  nextDueDate: '2026-08-03T00:00:00Z',
  status: SubscriptionStatus.active,
  note: '',
  createdAt: '2026-06-01T00:00:00Z',
  updatedAt: '2026-06-01T00:00:00Z',
);

// Deliberately OLDEST-first from the fake API: the provider must still render
// newest-first. The older payment carries a note; the newer has none
// (nullable note parses defensively).
const _installmentPayments = [
  InstallmentPayment(
    id: 'pay-old',
    userId: '',
    installmentId: 'i1',
    transactionId: 'tx-old',
    amountMinor: 1200000,
    paidAt: '2026-06-02T09:00:00Z',
    note: 'Transfer BCA',
    createdAt: '',
  ),
  InstallmentPayment(
    id: 'pay-new',
    userId: '',
    installmentId: 'i1',
    transactionId: 'tx-new',
    amountMinor: 1150000,
    paidAt: '2026-07-02T09:00:00Z',
    note: '',
    createdAt: '',
  ),
];

const _subscriptionPayments = [
  SubscriptionPayment(
    id: 'spay-old',
    userId: '',
    subscriptionId: 's1',
    transactionId: 'tx-old',
    amountMinor: 65000,
    paidAt: '2026-06-03T09:00:00Z',
    note: 'Bulan Juni',
    createdAt: '',
  ),
  SubscriptionPayment(
    id: 'spay-new',
    userId: '',
    subscriptionId: 's1',
    transactionId: 'tx-new',
    amountMinor: 66000,
    paidAt: '2026-07-03T09:00:00Z',
    note: '',
    createdAt: '',
  ),
];

const _newTransaction = Transaction(
  id: 'tx-new',
  userId: 'u1',
  type: TransactionType.expense,
  walletId: 'w1',
  categoryId: null,
  amountMinor: 1150000,
  tagIds: [],
  transactionAt: '2026-07-02T09:00:00Z',
  note: 'Cicilan Juli',
  createdAt: '2026-07-02T09:00:00Z',
  updatedAt: '2026-07-02T09:00:00Z',
);

void main() {
  setUpAll(() async {
    await initializeDateFormatting('id_ID');
  });

  testWidgets('installment detail lists payments newest-first and opens the '
      'backing transaction', (tester) async {
    final txRepository = _RecordingTransactionRepository();
    await _pump(
      tester,
      const InstallmentDetailScreen(id: 'i1'),
      txRepository: txRepository,
    );

    await tester.scrollUntilVisible(
      find.text('Riwayat pembayaran'),
      240,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();

    // Newest first even though the fake API returned oldest-first.
    expect(find.byKey(const Key('payment-row-pay-new')), findsOneWidget);
    await tester.scrollUntilVisible(
      find.byKey(const Key('payment-row-pay-old')),
      120,
      scrollable: find.byType(Scrollable).first,
    );
    final newTop = tester
        .getTopLeft(find.byKey(const Key('payment-row-pay-new')))
        .dy;
    final oldTop = tester
        .getTopLeft(find.byKey(const Key('payment-row-pay-old')))
        .dy;
    expect(newTop, lessThan(oldTop));
    expect(find.text('Rp 1.150.000'), findsOneWidget);
    expect(find.text('Transfer BCA'), findsOneWidget);

    // Tapping a row fetches the payment's transaction and opens the
    // shared detail sheet.
    await tester.tap(find.byKey(const Key('payment-row-pay-new')));
    await tester.pumpAndSettle();
    expect(txRepository.fetchedIds, ['tx-new']);
    expect(find.text('Detail transaksi'), findsOneWidget);
    expect(find.text('Cicilan Juli'), findsWidgets);
  });

  testWidgets('subscription detail lists payments newest-first and opens the '
      'backing transaction', (tester) async {
    final txRepository = _RecordingTransactionRepository();
    await _pump(
      tester,
      const SubscriptionDetailScreen(id: 's1'),
      txRepository: txRepository,
    );

    await tester.scrollUntilVisible(
      find.text('Riwayat pembayaran'),
      240,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('payment-row-spay-new')), findsOneWidget);
    await tester.scrollUntilVisible(
      find.byKey(const Key('payment-row-spay-old')),
      120,
      scrollable: find.byType(Scrollable).first,
    );
    final newTop = tester
        .getTopLeft(find.byKey(const Key('payment-row-spay-new')))
        .dy;
    final oldTop = tester
        .getTopLeft(find.byKey(const Key('payment-row-spay-old')))
        .dy;
    expect(newTop, lessThan(oldTop));
    expect(find.text('Rp 66.000'), findsOneWidget);
    expect(find.text('Bulan Juni'), findsOneWidget);

    await tester.tap(find.byKey(const Key('payment-row-spay-new')));
    await tester.pumpAndSettle();
    expect(txRepository.fetchedIds, ['tx-new']);
    expect(find.text('Detail transaksi'), findsOneWidget);
  });
}

Future<void> _pump(
  WidgetTester tester,
  Widget screen, {
  required _RecordingTransactionRepository txRepository,
}) async {
  await tester.binding.setSurfaceSize(const Size(390, 844));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  await tester.pumpWidget(
    ProviderScope(
      retry: noProviderRetry,
      overrides: [
        trackerControllerProvider.overrideWith(_StubTracker.new),
        trackerRepositoryProvider.overrideWithValue(
          const _PaymentsTrackerRepository(),
        ),
        transactionRepositoryProvider.overrideWithValue(txRepository),
        // showTransactionDetail reads the global ledger controller, which
        // loads wallets/categories/tags on first read — keep it hermetic.
        walletRepositoryProvider.overrideWithValue(
          const FakeWalletRepository(),
        ),
        categoryRepositoryProvider.overrideWithValue(
          const FakeCategoryRepository(),
        ),
        tagRepositoryProvider.overrideWithValue(const FakeTagRepository()),
      ],
      child: MaterialApp(home: screen),
    ),
  );
  await tester.pump();
  await tester.pump();
  await tester.pumpAndSettle();
}

class _StubTracker extends TrackerController {
  @override
  TrackerState build() => const TrackerState(
    installments: [_installment],
    subscriptions: [_subscription],
  );
}

/// Serves the two seeded payment lists; everything else is unreachable in
/// these tests.
class _PaymentsTrackerRepository implements TrackerRepository {
  const _PaymentsTrackerRepository();

  @override
  Future<List<InstallmentPayment>> listInstallmentPayments(String id) async {
    return _installmentPayments;
  }

  @override
  Future<List<SubscriptionPayment>> listSubscriptionPayments(String id) async {
    return _subscriptionPayments;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _RecordingTransactionRepository extends FakeTransactionRepository {
  _RecordingTransactionRepository()
    : super(transactions: const [_newTransaction]);

  final fetchedIds = <String>[];

  @override
  Future<Transaction> getTransaction(String id) {
    fetchedIds.add(id);
    return super.getTransaction(id);
  }
}
