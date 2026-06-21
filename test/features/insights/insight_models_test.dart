import 'package:affluena_mobile/features/insights/data/insight_models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('parses report, export, activity, alert, and notification payloads', () {
    final report = ReportResponse.fromJson(const {
      'metrics': [
        {
          'id': 'metric-balance',
          'label': 'Overview balance',
          'value_minor': 4000000,
          'helper': 'Current month',
          'tone': 'success',
        },
      ],
      'rows': [
        {
          'id': 'row-food',
          'name': 'Food spending',
          'category': 'Food & Dining',
          'amount_minor': 1250000,
          'previous_amount_minor': 900000,
          'change_percent': 38.8,
          'wallet': 'GoPay',
          'status': 'watch',
        },
      ],
    });
    expect(report.metrics.single.label, 'Overview balance');
    expect(report.rows.single.status, ReportRowStatus.watch);

    final jobs = ExportJobsResponse.fromJson(const {
      'jobs': [
        {
          'id': 'job-1',
          'user_id': 'user-1',
          'format': 'CSV',
          'from_at': '2026-06-01T00:00:00Z',
          'to_at': '2026-06-30T23:59:59Z',
          'row_count': 42,
          'status': 'completed',
          'created_at': '2026-06-22T08:00:00Z',
        },
      ],
      'pagination': {'limit': 20, 'offset': 0, 'total': 1},
    });
    expect(jobs.jobs.single.rowCount, 42);
    expect(jobs.jobs.single.status, ExportJobStatus.completed);

    final activities = ActivityListResponse.fromJson(const {
      'data': [
        {
          'id': 'activity-1',
          'user_id': 'user-1',
          'action_type': 'create',
          'entity_type': 'transaction',
          'entity_id': null,
          'description': 'Created transaction Lunch',
          'created_at': '2026-06-22T08:00:00Z',
        },
      ],
      'pagination': {'limit': 20, 'offset': 0, 'total': 1},
    });
    expect(activities.activities.single.entityType, 'transaction');
    expect(activities.activities.single.entityId, '');

    final alerts = AlertsResponse.fromJson(const {
      'alerts': [
        {
          'id': 'alert-1',
          'type': 'budget',
          'title': 'Food limit reached',
          'module': 'budget',
          'description': 'Food spending reached 100%.',
          'severity': 'danger',
          'created_at': '2026-06-22T08:00:00Z',
          'action_path': '/budgets',
        },
      ],
    });
    expect(alerts.alerts.single.severity, InsightSeverity.danger);

    final rules = NotificationRulesResponse.fromJson(const {
      'rules': [
        {
          'id': 'rule-1',
          'user_id': 'user-1',
          'rule_key': 'budget-alert',
          'title': 'Budget alerts',
          'description': 'Notify when budgets cross thresholds.',
          'enabled': true,
          'channel': 'in-app',
          'tone': 'warning',
          'created_at': '2026-06-01T00:00:00Z',
          'updated_at': '2026-06-22T08:00:00Z',
        },
      ],
    });
    expect(rules.rules.single.channel, NotificationChannel.inApp);
    expect(
      const NotificationRuleUpdate(
        enabled: false,
        channel: NotificationChannel.email,
      ).toJson(),
      {'enabled': false, 'channel': 'email'},
    );
  });
}
