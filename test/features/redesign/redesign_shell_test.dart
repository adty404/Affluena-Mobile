import 'package:affluena_mobile/features/auth/application/auth_controller.dart';
import 'package:affluena_mobile/features/auth/data/auth_models.dart';
import 'package:affluena_mobile/features/dashboard/application/dashboard_home_controller.dart';
import 'package:affluena_mobile/features/dashboard/data/dashboard_models.dart';
import 'package:affluena_mobile/features/goals/application/goal_controller.dart';
import 'package:affluena_mobile/features/goals/data/goal_models.dart';
import 'package:affluena_mobile/features/redesign/presentation/activity_feed_screen.dart';
import 'package:affluena_mobile/features/redesign/presentation/redesign_shell.dart';
import 'package:affluena_mobile/features/transactions/data/transaction_models.dart';
import 'package:affluena_mobile/features/wallets/application/wallets_controller.dart';
import 'package:affluena_mobile/features/wallets/data/wallet_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

const _me = AuthUser(
  id: 'u-me',
  email: 'aditya@example.com',
  name: 'Aditya',
  avatarUrl: '',
  createdAt: '2026-06-01T00:00:00Z',
  updatedAt: '2026-06-01T00:00:00Z',
);

const _gopay = Wallet(
  id: 'w1',
  userId: 'u-me',
  name: 'GoPay',
  type: WalletType.eWallet,
  currencyCode: 'IDR',
  balanceMinor: 1300000,
  color: 'blue',
  description: '',
  createdAt: '2026-06-01T00:00:00Z',
  updatedAt: '2026-06-01T00:00:00Z',
);

const _goal = Goal(
  id: 'g1',
  userId: 'u-me',
  name: 'Liburan Bali',
  targetAmountMinor: 10000000,
  collectedAmountMinor: 6200000,
  deadline: null,
  status: GoalStatus.active,
  createdAt: '2026-06-01T00:00:00Z',
  updatedAt: '2026-06-01T00:00:00Z',
);

const _txn = Transaction(
  id: 't1',
  userId: 'u-me',
  type: TransactionType.expense,
  walletId: 'w1',
  amountMinor: 28000,
  tagIds: [],
  transactionAt: '2026-06-20T08:00:00Z',
  note: 'Kopi Tuku',
  createdAt: '2026-06-20T08:00:00Z',
  updatedAt: '2026-06-20T08:00:00Z',
);

const _trend = CashflowTrendResponse(
  trend: [
    CashflowTrendPoint(
      month: '2026-06',
      incomeMinor: 9500000,
      expenseMinor: 3200000,
      cashflowMinor: 6300000,
    ),
  ],
);

const _distribution = ExpenseDistributionResponse(
  distribution: [
    ExpenseDistribution(
      categoryId: 'c1',
      categoryName: 'Makan & Minum',
      amountMinor: 1850000,
      percentage: 40,
    ),
  ],
);

const _forecast = DashboardForecast(
  currentExpenseMinor: 1800000,
  dailyAverageMinor: 90000,
  forecastedExpenseMinor: 3200000,
  budgetLimitMinor: 4000000,
  status: ForecastStatus.safe,
);

class _StubGoalController extends GoalController {
  @override
  GoalState build() => const GoalState(goals: [_goal]);
}

class _AuthedController extends AuthController {
  @override
  AuthState build() => AuthState.authenticated(_me);
}

Future<void> _pump(WidgetTester tester) async {
  await tester.binding.setSurfaceSize(const Size(390, 844));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        authControllerProvider.overrideWith(_AuthedController.new),
        walletListProvider.overrideWith((ref) async => const [_gopay]),
        goalControllerProvider.overrideWith(_StubGoalController.new),
        recentActivityProvider.overrideWith((ref) async => const [_txn]),
        dashboardCashflowTrendProvider.overrideWith((ref) async => _trend),
        dashboardExpenseDistributionProvider.overrideWith(
          (ref) async => _distribution,
        ),
        dashboardForecastProvider.overrideWith((ref) async => _forecast),
      ],
      child: const MaterialApp(home: RedesignShell()),
    ),
  );
  for (var i = 0; i < 6; i++) {
    await tester.pump(const Duration(milliseconds: 10));
  }
}

void main() {
  testWidgets('shell starts on Home and switches tabs via the bottom nav', (
    tester,
  ) async {
    await _pump(tester);

    // Home tab is the rooms view.
    expect(find.text('Total'), findsOneWidget);
    expect(find.byType(FloatingActionButton), findsOneWidget);
    expect(find.byKey(const Key('nav-lainnya')), findsOneWidget);

    // Switch to Wawasan -> a unique card title appears.
    await tester.tap(find.byKey(const Key('nav-wawasan')));
    for (var i = 0; i < 4; i++) {
      await tester.pump(const Duration(milliseconds: 10));
    }
    expect(find.text('Arus kas'), findsOneWidget);

    // Switch to Aktivitas -> the merged feed shows the transaction.
    await tester.tap(find.byKey(const Key('nav-aktivitas')));
    for (var i = 0; i < 4; i++) {
      await tester.pump(const Duration(milliseconds: 10));
    }
    expect(find.text('Kopi Tuku'), findsOneWidget);
  });
}
