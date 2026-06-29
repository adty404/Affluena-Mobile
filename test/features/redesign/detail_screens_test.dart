import 'package:affluena_mobile/features/auth/application/auth_controller.dart';
import 'package:affluena_mobile/features/budgets/application/budget_controller.dart';
import 'package:affluena_mobile/features/budgets/data/budget_models.dart';
import 'package:affluena_mobile/features/budgets/presentation/budget_detail_screen.dart';
import 'package:affluena_mobile/features/goals/application/goal_controller.dart';
import 'package:affluena_mobile/features/goals/data/goal_models.dart';
import 'package:affluena_mobile/features/goals/presentation/goal_detail_screen.dart';
import 'package:affluena_mobile/features/recurring/application/recurring_controller.dart';
import 'package:affluena_mobile/features/recurring/data/recurring_models.dart';
import 'package:affluena_mobile/features/recurring/presentation/recurring_detail_screen.dart';
import 'package:affluena_mobile/features/trackers/application/tracker_controller.dart';
import 'package:affluena_mobile/features/trackers/data/tracker_models.dart';
import 'package:affluena_mobile/features/trackers/presentation/installment_detail_screen.dart';
import 'package:affluena_mobile/features/trackers/presentation/subscription_detail_screen.dart';
import 'package:affluena_mobile/features/transactions/data/transaction_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

const _budget = BudgetSummary(
  id: 'b1',
  userId: 'u1',
  categoryId: 'cat-food',
  // The API serializes the DATE column to a full RFC3339 timestamp; the detail
  // screen must handle that (not just 'YYYY-MM') or it blanks out.
  month: '2026-06-01T00:00:00Z',
  limitMinor: 1500000,
  createdAt: '2026-06-01T00:00:00Z',
  updatedAt: '2026-06-01T00:00:00Z',
  spentMinor: 1080000,
  remainingMinor: 420000,
  usagePercent: 72,
);

const _goal = Goal(
  id: 'g1',
  userId: 'u1',
  name: 'Liburan Bali',
  targetAmountMinor: 10000000,
  collectedAmountMinor: 6200000,
  deadline: null,
  status: GoalStatus.active,
  createdAt: '2026-06-01T00:00:00Z',
  updatedAt: '2026-06-01T00:00:00Z',
);

const _installment = Installment(
  id: 'i1',
  userId: 'u1',
  name: 'iPhone 15',
  walletId: 'w1',
  categoryId: 'c1',
  totalAmountMinor: 14400000,
  monthlyAmountMinor: 1200000,
  tenorMonths: 12,
  remainingMonths: 8,
  startDate: '2026-03-02T00:00:00Z',
  dueDay: 2,
  status: InstallmentStatus.active,
  note: '',
  createdAt: '2026-03-01T00:00:00Z',
  updatedAt: '2026-03-01T00:00:00Z',
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
  nextDueDate: '2026-07-03T00:00:00Z',
  status: SubscriptionStatus.active,
  note: '',
  createdAt: '2026-06-01T00:00:00Z',
  updatedAt: '2026-06-01T00:00:00Z',
);

const _rule = RecurringRule(
  id: 'r1',
  userId: 'u1',
  name: 'Transfer ke Tabungan',
  type: RecurringType.expense,
  walletId: 'w1',
  toWalletId: '',
  categoryId: 'c1',
  amountMinor: 500000,
  frequency: RecurringFrequency.monthly,
  intervalCount: 1,
  nextRunAt: '2026-07-01T00:00:00Z',
  endAt: '',
  lastRunAt: '',
  status: RecurringStatus.active,
  note: '',
  createdAt: '2026-06-01T00:00:00Z',
  updatedAt: '2026-06-01T00:00:00Z',
);

class _StubBudget extends BudgetController {
  @override
  BudgetState build() => const BudgetState(
    month: '2026-06',
    budgets: [_budget],
    categoryNames: {'cat-food': 'Makan & Minum'},
  );
}

class _StubGoal extends GoalController {
  @override
  GoalState build() => const GoalState(goals: [_goal]);
}

class _StubTracker extends TrackerController {
  @override
  TrackerState build() => const TrackerState(
    installments: [_installment],
    subscriptions: [_subscription],
  );
}

class _StubRecurring extends RecurringController {
  @override
  RecurringState build() => const RecurringState(rules: [_rule]);
}

class _StubAuth extends AuthController {
  @override
  AuthState build() => const AuthState.unauthenticated();
}

Future<void> _pump(
  WidgetTester tester,
  Widget screen,
  List<dynamic> overrides,
) async {
  await tester.binding.setSurfaceSize(const Size(390, 844));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  await tester.pumpWidget(
    ProviderScope(
      overrides: [...overrides],
      child: MaterialApp(home: screen),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  setUpAll(() async {
    await initializeDateFormatting('id_ID');
  });

  testWidgets('budget detail renders the spend + status', (tester) async {
    await _pump(tester, const BudgetDetailScreen(id: 'b1'), [
      budgetControllerProvider.overrideWith(_StubBudget.new),
      categoryTransactionsProvider.overrideWith(
        (ref, id) async => const <Transaction>[],
      ),
    ]);
    expect(find.text('Makan & Minum'), findsOneWidget);
    expect(find.text('Terpakai 72%'), findsOneWidget);
    expect(find.text('Aman'), findsOneWidget);
  });

  testWidgets('goal detail renders progress + Setor action', (tester) async {
    await _pump(tester, const GoalDetailScreen(id: 'g1'), [
      goalControllerProvider.overrideWith(_StubGoal.new),
      authControllerProvider.overrideWith(_StubAuth.new),
    ]);
    expect(find.text('Liburan Bali'), findsOneWidget);
    expect(find.text('Tercapai 62%'), findsOneWidget);
    expect(find.widgetWithText(FilledButton, 'Setor'), findsOneWidget);
  });

  testWidgets('installment detail renders schedule + pay action', (
    tester,
  ) async {
    await _pump(tester, const InstallmentDetailScreen(id: 'i1'), [
      trackerControllerProvider.overrideWith(_StubTracker.new),
    ]);
    expect(find.text('iPhone 15'), findsOneWidget);
    expect(find.text('Terbayar 33%'), findsOneWidget);
    expect(find.widgetWithText(FilledButton, 'Bayar cicilan'), findsOneWidget);
  });

  testWidgets('subscription detail renders pay + pause actions', (
    tester,
  ) async {
    await _pump(tester, const SubscriptionDetailScreen(id: 's1'), [
      trackerControllerProvider.overrideWith(_StubTracker.new),
    ]);
    expect(find.text('Netflix'), findsOneWidget);
    expect(find.widgetWithText(FilledButton, 'Bayar sekarang'), findsOneWidget);
    expect(
      find.widgetWithText(OutlinedButton, 'Jeda langganan'),
      findsOneWidget,
    );
  });

  testWidgets('recurring detail renders run action', (tester) async {
    await _pump(tester, const RecurringDetailScreen(id: 'r1'), [
      recurringControllerProvider.overrideWith(_StubRecurring.new),
    ]);
    expect(find.text('Transfer ke Tabungan'), findsOneWidget);
    expect(
      find.widgetWithText(FilledButton, 'Jalankan sekarang'),
      findsOneWidget,
    );
  });
}
