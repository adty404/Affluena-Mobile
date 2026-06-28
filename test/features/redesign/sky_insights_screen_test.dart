import 'package:affluena_mobile/features/dashboard/application/dashboard_home_controller.dart';
import 'package:affluena_mobile/features/dashboard/data/dashboard_models.dart';
import 'package:affluena_mobile/features/redesign/presentation/sky_insights_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

const _trend = CashflowTrendResponse(
  trend: [
    CashflowTrendPoint(
      month: '2026-05',
      incomeMinor: 9500000,
      expenseMinor: 3100000,
      cashflowMinor: 6400000,
    ),
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

Future<void> _pump(WidgetTester tester) async {
  await tester.binding.setSurfaceSize(const Size(390, 844));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        dashboardCashflowTrendProvider.overrideWith((ref) async => _trend),
        dashboardExpenseDistributionProvider.overrideWith(
          (ref) async => _distribution,
        ),
        dashboardForecastProvider.overrideWith((ref) async => _forecast),
      ],
      child: const MaterialApp(home: SkyInsightsScreen()),
    ),
  );
  for (var i = 0; i < 6; i++) {
    await tester.pump(const Duration(milliseconds: 10));
  }
}

void main() {
  testWidgets('renders the three analytics sections', (tester) async {
    await _pump(tester);

    expect(find.text('Wawasan'), findsOneWidget);
    expect(find.text('Arus kas'), findsOneWidget);
    expect(find.text('Ke mana uang pergi'), findsOneWidget);
    expect(find.text('Perkiraan bulan ini'), findsOneWidget);
  });

  testWidgets('shows distribution category and forecast status', (
    tester,
  ) async {
    await _pump(tester);

    expect(find.text('Makan & Minum'), findsOneWidget);
    expect(find.text('Rp 1.850.000'), findsOneWidget);
    expect(find.text('Rp 3.200.000'), findsOneWidget); // forecasted expense
    expect(find.text('Aman, di bawah budget'), findsOneWidget); // safe status
  });
}
