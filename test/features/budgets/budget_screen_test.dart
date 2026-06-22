import 'package:affluena_mobile/app/provider_retry.dart';
import 'package:affluena_mobile/core/api/pagination.dart';
import 'package:affluena_mobile/features/budgets/application/budget_controller.dart';
import 'package:affluena_mobile/features/budgets/data/budget_models.dart';
import 'package:affluena_mobile/features/budgets/data/budget_repository.dart';
import 'package:affluena_mobile/features/budgets/presentation/budget_screen.dart';
import 'package:affluena_mobile/features/categories/data/category_models.dart';
import 'package:affluena_mobile/features/categories/data/category_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('loads initial budget state from repositories', () async {
    final container = ProviderContainer(
      retry: noProviderRetry,
      overrides: [
        budgetRepositoryProvider.overrideWithValue(TestBudgetRepository()),
        categoryRepositoryProvider.overrideWithValue(
          const TestCategoryRepository(),
        ),
      ],
    );
    addTearDown(container.dispose);

    container.read(budgetControllerProvider);
    await Future<void>.delayed(Duration.zero);
    await Future<void>.delayed(Duration.zero);

    final state = container.read(budgetControllerProvider);
    expect(state.budgets.single.categoryId, 'category-food');
    expect(state.categoryName('category-food'), 'Food & Dining');
    expect(state.alerts.single.title, 'Food near limit');
  });

  testWidgets('renders budget cards with category names and alerts', (
    tester,
  ) async {
    await tester.pumpWidget(budgetTestApp());
    await tester.pumpBudgetState();

    expect(find.text('Budgets'), findsOneWidget);
    expect(find.text('Food near limit'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Food & Dining'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Food & Dining'), findsOneWidget);
    expect(find.text('85% used'), findsOneWidget);
    expect(find.textContaining('category-food'), findsNothing);
  });

  testWidgets('creates a budget from category selector and limit input', (
    tester,
  ) async {
    final repository = TestBudgetRepository();

    await tester.pumpWidget(budgetTestApp(budgetRepository: repository));
    await tester.pumpBudgetState();

    await tester.tap(find.byIcon(Icons.add));
    await tester.pumpAndSettle();
    expect(find.text('Create budget'), findsOneWidget);

    await tester.tap(find.text('Choose expense category'));
    await tester.pumpAndSettle();
    expect(find.text('Budget category'), findsOneWidget);

    await tester.tap(find.text('Transportation'));
    await tester.pumpAndSettle();
    expect(find.text('Transportation'), findsOneWidget);

    await tester.enterText(
      find.byKey(const Key('budget-limit-field')),
      '900000',
    );
    await tester.pump();
    final saveButton = tester.widget<FilledButton>(
      find.byKey(const Key('budget-save-button')),
    );
    expect(saveButton.onPressed, isNotNull);

    await tester.tap(find.byKey(const Key('budget-save-button')));
    await tester.pumpAndSettle();

    expect(repository.createdRequests.single.categoryId, 'category-transport');
    expect(repository.createdRequests.single.limitMinor, 900000);
  });
}

extension on WidgetTester {
  Future<void> pumpBudgetState() async {
    await pump();
    await pump();
    await pumpAndSettle();
  }
}

Widget budgetTestApp({
  TestBudgetRepository? budgetRepository,
  TestCategoryRepository? categoryRepository,
}) {
  return ProviderScope(
    retry: noProviderRetry,
    overrides: [
      budgetRepositoryProvider.overrideWithValue(
        budgetRepository ?? TestBudgetRepository(),
      ),
      categoryRepositoryProvider.overrideWithValue(
        categoryRepository ?? const TestCategoryRepository(),
      ),
    ],
    child: const MaterialApp(home: Scaffold(body: BudgetScreen())),
  );
}

class TestBudgetRepository implements BudgetRepository {
  TestBudgetRepository({
    List<BudgetSummary> budgets = const [foodBudget],
    this._alerts = const [foodAlert],
    this._reportSummary = seededReportSummary,
  }) : _budgets = List<BudgetSummary>.of(budgets);

  final List<BudgetSummary> _budgets;
  final List<BudgetAlert> _alerts;
  final BudgetReportSummary _reportSummary;
  final createdRequests = <BudgetRequest>[];

  @override
  Future<BudgetListResponse> listBudgets({
    String? month,
    int? limit,
    int? offset,
    String? sort,
  }) async {
    return BudgetListResponse(
      budgets: _budgets,
      pagination: Pagination(
        total: _budgets.length,
        limit: limit ?? _budgets.length,
        offset: offset ?? 0,
      ),
    );
  }

  @override
  Future<Budget> getBudget(String id) async {
    return _budgets.firstWhere((budget) => budget.id == id);
  }

  @override
  Future<Budget> createBudget(BudgetRequest request) async {
    createdRequests.add(request);
    final budget = BudgetSummary(
      id: 'budget-${request.categoryId}',
      userId: 'user-1',
      categoryId: request.categoryId,
      month: request.month,
      limitMinor: request.limitMinor,
      spentMinor: 0,
      remainingMinor: request.limitMinor,
      usagePercent: 0,
      createdAt: '2026-06-01T00:00:00Z',
      updatedAt: '2026-06-01T00:00:00Z',
    );
    _budgets.add(budget);
    return budget;
  }

  @override
  Future<Budget> updateBudget(String id, BudgetRequest request) async {
    return _budgets.firstWhere((budget) => budget.id == id);
  }

  @override
  Future<void> deleteBudget(String id) async {
    _budgets.removeWhere((budget) => budget.id == id);
  }

  @override
  Future<BudgetAlertsResponse> getAlerts({String? month}) async {
    return BudgetAlertsResponse(alerts: _alerts);
  }

  @override
  Future<BudgetReportResponse> getReport({String? month}) async {
    return BudgetReportResponse(
      report: const [foodReport],
      summary: _reportSummary,
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
      categories: [foodCategory, transportCategory],
      pagination: Pagination(total: 2, limit: 100, offset: 0),
    );
  }

  @override
  Future<Category> createCategory(CategoryRequest request) async =>
      foodCategory;

  @override
  Future<Category> getCategory(String id) async {
    return [
      foodCategory,
      transportCategory,
    ].firstWhere((category) => category.id == id);
  }

  @override
  Future<Category> updateCategory(String id, CategoryRequest request) async {
    return foodCategory;
  }

  @override
  Future<void> deleteCategory(String id) async {}
}

const foodCategory = Category(
  id: 'category-food',
  userId: 'user-1',
  name: 'Food & Dining',
  type: CategoryType.expense,
  createdAt: '2026-06-01T00:00:00Z',
  updatedAt: '2026-06-01T00:00:00Z',
);

const transportCategory = Category(
  id: 'category-transport',
  userId: 'user-1',
  name: 'Transportation',
  type: CategoryType.expense,
  createdAt: '2026-06-01T00:00:00Z',
  updatedAt: '2026-06-01T00:00:00Z',
);

const foodBudget = BudgetSummary(
  id: 'budget-food',
  userId: 'user-1',
  categoryId: 'category-food',
  month: '2026-06',
  limitMinor: 1500000,
  spentMinor: 1275000,
  remainingMinor: 225000,
  usagePercent: 85,
  createdAt: '2026-06-01T00:00:00Z',
  updatedAt: '2026-06-01T00:00:00Z',
);

const foodAlert = BudgetAlert(
  id: 'alert-food',
  budgetId: 'budget-food',
  categoryId: 'category-food',
  categoryName: 'Food & Dining',
  title: 'Food near limit',
  message: 'Food has reached 85% of budget.',
  threshold: 80,
  severity: BudgetSeverity.warning,
  usagePercent: 85,
  spentMinor: 1275000,
  limitMinor: 1500000,
  month: '2026-06',
);

const foodReport = BudgetReportItem(
  id: 'budget-food',
  userId: 'user-1',
  categoryId: 'category-food',
  month: '2026-06',
  limitMinor: 1500000,
  spentMinor: 1275000,
  remainingMinor: 225000,
  usagePercent: 85,
  varianceMinor: 225000,
  dailyAllowanceMinor: 75000,
  recommendation: 'Keep food spending below Rp 75.000 per day.',
  createdAt: '2026-06-01T00:00:00Z',
  updatedAt: '2026-06-01T00:00:00Z',
);

const seededReportSummary = BudgetReportSummary(
  totalLimitMinor: 1500000,
  totalSpentMinor: 1275000,
  totalRemainingMinor: 225000,
  safeCount: 0,
  warningCount: 1,
  exceededCount: 0,
  dailyAllowanceMinor: 75000,
  forecastMinor: 1450000,
);
