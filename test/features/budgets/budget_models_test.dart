import 'package:affluena_mobile/features/budgets/data/budget_models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('parses budget list, alerts, and report payloads', () {
    final list = BudgetListResponse.fromJson(const {
      'budgets': [
        {
          'id': 'budget-food',
          'user_id': 'user-1',
          'category_id': 'category-food',
          'month': '2026-06',
          'limit_minor': 1500000,
          'spent_minor': 1275000,
          'remaining_minor': 225000,
          'usage_percent': 85.0,
          'created_at': '2026-06-01T00:00:00Z',
          'updated_at': '2026-06-01T00:00:00Z',
        },
      ],
      'pagination': {'total': 1, 'limit': 20, 'offset': 0},
    });

    expect(list.budgets.single.categoryId, 'category-food');
    expect(list.budgets.single.usagePercent, 85);
    // Appearance fields are optional server-side; absent means "no color".
    expect(list.budgets.single.color, '');
    expect(list.budgets.single.icon, '');
    expect(list.pagination.total, 1);

    final alerts = BudgetAlertsResponse.fromJson(const {
      'alerts': [
        {
          'id': 'alert-food',
          'budget_id': 'budget-food',
          'category_id': 'category-food',
          'category_name': 'Food & Dining',
          'title': 'Food near limit',
          'message': 'Food has reached 85% of budget.',
          'threshold': 80,
          'severity': 'warning',
          'usage_percent': 85.0,
          'spent_minor': 1275000,
          'limit_minor': 1500000,
          'notified_at': null,
          'month': '2026-06',
        },
      ],
    });

    expect(alerts.alerts.single.severity, BudgetSeverity.warning);
    expect(alerts.alerts.single.categoryName, 'Food & Dining');

    final report = BudgetReportResponse.fromJson(const {
      'report': [
        {
          'id': 'budget-food',
          'user_id': 'user-1',
          'category_id': 'category-food',
          'month': '2026-06',
          'limit_minor': 1500000,
          'spent_minor': 1275000,
          'remaining_minor': 225000,
          'usage_percent': 85.0,
          'variance_minor': 225000,
          'daily_allowance_minor': 75000,
          'recommendation': 'Keep food spending below Rp 75.000 per day.',
          'created_at': '2026-06-01T00:00:00Z',
          'updated_at': '2026-06-01T00:00:00Z',
        },
      ],
      'summary': {
        'total_limit_minor': 1500000,
        'total_spent_minor': 1275000,
        'total_remaining_minor': 225000,
        'safe_count': 0,
        'warning_count': 1,
        'exceeded_count': 0,
        'daily_allowance_minor': 75000,
        'forecast_minor': 1450000,
      },
    });

    expect(report.summary.warningCount, 1);
    expect(report.report.single.dailyAllowanceMinor, 75000);
  });

  test('parses budget appearance fields and serializes them on requests', () {
    final budget = BudgetSummary.fromJson(const {
      'id': 'budget-food',
      'user_id': 'user-1',
      'category_id': 'category-food',
      'month': '2026-06',
      'limit_minor': 1500000,
      'spent_minor': 1275000,
      'remaining_minor': 225000,
      'usage_percent': 85.0,
      'color': '#2E8B57',
      'icon': 'food',
      'created_at': '2026-06-01T00:00:00Z',
      'updated_at': '2026-06-01T00:00:00Z',
    });

    expect(budget.color, '#2E8B57');
    expect(budget.icon, 'food');

    final json = const BudgetRequest(
      categoryId: 'category-food',
      month: '2026-06',
      limitMinor: 1500000,
      color: '#2E8B57',
      icon: 'food',
    ).toJson();
    expect(json, containsPair('color', '#2E8B57'));
    expect(json, containsPair('icon', 'food'));

    // Omitted appearance fields stay off the wire entirely.
    final bare = const BudgetRequest(
      categoryId: 'category-food',
      month: '2026-06',
      limitMinor: 1500000,
    ).toJson();
    expect(bare.containsKey('color'), isFalse);
    expect(bare.containsKey('icon'), isFalse);
  });
}
