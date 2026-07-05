import 'package:affluena_mobile/features/budgets/application/budget_controller.dart';
import 'package:affluena_mobile/features/budgets/data/budget_models.dart';
import 'package:affluena_mobile/features/dashboard/application/dashboard_home_controller.dart';
import 'package:affluena_mobile/features/dashboard/data/dashboard_models.dart'
    as dashboard;
import 'package:affluena_mobile/features/goals/application/goal_controller.dart';
import 'package:affluena_mobile/features/goals/data/goal_models.dart';
import 'package:affluena_mobile/features/partner/application/partner_controller.dart';
import 'package:affluena_mobile/features/recurring/application/recurring_controller.dart';
import 'package:affluena_mobile/features/recurring/data/recurring_models.dart';
import 'package:affluena_mobile/features/redesign/presentation/beranda_dashboard_screen.dart';
import 'package:affluena_mobile/features/trackers/application/tracker_controller.dart';
import 'package:affluena_mobile/features/trackers/data/tracker_models.dart';
import 'package:affluena_mobile/features/wallets/application/wallets_controller.dart';
import 'package:affluena_mobile/features/wallets/data/wallet_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// One colored item per entity: a user-chosen `color` must render the Beranda
/// card in the wallet-style solid treatment (bg = the color, white title)
/// instead of the per-section tint.

const _wallet = Wallet(
  id: 'w1',
  userId: 'u-me',
  name: 'GoPay',
  type: WalletType.eWallet,
  currencyCode: 'IDR',
  balanceMinor: 1300000,
  color: '',
  description: '',
  createdAt: '2026-06-01T00:00:00Z',
  updatedAt: '2026-06-01T00:00:00Z',
);

const _budget = BudgetSummary(
  id: 'b1',
  userId: 'u-me',
  categoryId: 'cat-food',
  month: '2026-06-01T00:00:00Z',
  limitMinor: 1500000,
  createdAt: '2026-06-01T00:00:00Z',
  updatedAt: '2026-06-01T00:00:00Z',
  spentMinor: 1080000,
  remainingMinor: 420000,
  usagePercent: 72,
  color: '#E0A23B',
);

const _goal = Goal(
  id: 'g1',
  userId: 'u-me',
  name: 'Liburan Bali',
  targetAmountMinor: 10000000,
  collectedAmountMinor: 6200000,
  deadline: null,
  status: GoalStatus.active,
  color: '#2E8B57',
  createdAt: '2026-06-01T00:00:00Z',
  updatedAt: '2026-06-01T00:00:00Z',
);

const _installment = Installment(
  id: 'i1',
  userId: 'u-me',
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
  color: '#4256B8',
  createdAt: '2026-03-01T00:00:00Z',
  updatedAt: '2026-03-01T00:00:00Z',
);

const _subscription = Subscription(
  id: 's1',
  userId: 'u-me',
  name: 'Netflix',
  accountDetail: '',
  walletId: 'w1',
  categoryId: 'c1',
  amountMinor: 65000,
  billingCycle: BillingCycle.monthly,
  nextDueDate: '2026-07-03T00:00:00Z',
  status: SubscriptionStatus.active,
  note: '',
  color: '#7C5BC2',
  createdAt: '2026-06-01T00:00:00Z',
  updatedAt: '2026-06-01T00:00:00Z',
);

const _rule = RecurringRule(
  id: 'r1',
  userId: 'u-me',
  name: 'Sewa Apartemen',
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
  color: '#2BB3A3',
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

class _StubPartner extends PartnerController {
  @override
  PartnerState build() => const PartnerState();
}

// Beranda's Ringkasan + due-list sources; overriding the providers directly
// keeps the test hermetic (and skips the notification-scheduler side hook).
const _summary = dashboard.DashboardSummary(
  month: '2026-06',
  netWorthMinor: 16370000,
  monthlyIncomeMinor: 9500000,
  monthlyExpenseMinor: 3200000,
  monthlyCashflowMinor: 6300000,
  budget: dashboard.BudgetSummary(
    limitMinor: 4000000,
    spentMinor: 1800000,
    remainingMinor: 2200000,
    usagePercent: 45,
  ),
  upcomingSubscriptions: [],
  upcomingInstallments: [],
  upcomingDebts: [],
);

final _summaryOverrides = [
  dashboardSummaryProvider.overrideWith((ref) async => _summary),
  berandaCashflowTrendProvider.overrideWith(
    (ref) async => const dashboard.CashflowTrendResponse(trend: []),
  ),
];

Future<void> _pump(WidgetTester tester) async {
  await tester.binding.setSurfaceSize(const Size(390, 2200));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        walletListProvider.overrideWith((ref) async => const [_wallet]),
        budgetControllerProvider.overrideWith(_StubBudget.new),
        goalControllerProvider.overrideWith(_StubGoal.new),
        trackerControllerProvider.overrideWith(_StubTracker.new),
        recurringControllerProvider.overrideWith(_StubRecurring.new),
        partnerControllerProvider.overrideWith(_StubPartner.new),
        ..._summaryOverrides,
      ],
      child: const MaterialApp(home: Scaffold(body: BerandaDashboardView())),
    ),
  );
  for (var i = 0; i < 6; i++) {
    await tester.pump(const Duration(milliseconds: 10));
  }
}

Finder _cardWithBackground(Color color) {
  return find.byWidgetPredicate(
    (widget) => widget is Material && widget.color == color,
  );
}

void main() {
  testWidgets('colored items render solid cards per entity on Beranda', (
    tester,
  ) async {
    await _pump(tester);

    // Each entity card uses its item color as the solid background.
    expect(_cardWithBackground(const Color(0xFFE0A23B)), findsOneWidget);
    expect(_cardWithBackground(const Color(0xFF2E8B57)), findsOneWidget);
    expect(_cardWithBackground(const Color(0xFF4256B8)), findsOneWidget);
    expect(_cardWithBackground(const Color(0xFF7C5BC2)), findsOneWidget);
    expect(_cardWithBackground(const Color(0xFF2BB3A3)), findsOneWidget);

    // Text on a solid colored card is always white, like wallet cards.
    final budgetTitle = tester.widget<Text>(find.text('Makan & Minum'));
    expect(budgetTitle.style?.color, Colors.white);
    final goalTitle = tester.widget<Text>(find.text('Liburan Bali'));
    expect(goalTitle.style?.color, Colors.white);
  });

  testWidgets('items without a color keep the section tint', (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 2200));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          walletListProvider.overrideWith((ref) async => const [_wallet]),
          budgetControllerProvider.overrideWith(_StubColorlessBudget.new),
          goalControllerProvider.overrideWith(_StubGoal.new),
          trackerControllerProvider.overrideWith(_StubTracker.new),
          recurringControllerProvider.overrideWith(_StubRecurring.new),
          partnerControllerProvider.overrideWith(_StubPartner.new),
          ..._summaryOverrides,
        ],
        child: const MaterialApp(home: Scaffold(body: BerandaDashboardView())),
      ),
    );
    for (var i = 0; i < 6; i++) {
      await tester.pump(const Duration(milliseconds: 10));
    }

    // No amber solid card; the title falls back to ink (non-white).
    expect(_cardWithBackground(const Color(0xFFE0A23B)), findsNothing);
    final budgetTitle = tester.widget<Text>(find.text('Makan & Minum'));
    expect(budgetTitle.style?.color, isNot(Colors.white));
  });
}

const _colorlessBudget = BudgetSummary(
  id: 'b1',
  userId: 'u-me',
  categoryId: 'cat-food',
  month: '2026-06-01T00:00:00Z',
  limitMinor: 1500000,
  createdAt: '2026-06-01T00:00:00Z',
  updatedAt: '2026-06-01T00:00:00Z',
  spentMinor: 1080000,
  remainingMinor: 420000,
  usagePercent: 72,
);

class _StubColorlessBudget extends BudgetController {
  @override
  BudgetState build() => const BudgetState(
    month: '2026-06',
    budgets: [_colorlessBudget],
    categoryNames: {'cat-food': 'Makan & Minum'},
  );
}
