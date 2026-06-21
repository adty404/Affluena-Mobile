import 'package:affluena_mobile/app/provider_retry.dart';
import 'package:affluena_mobile/app/theme/affluena_theme.dart';
import 'package:affluena_mobile/core/api/pagination.dart';
import 'package:affluena_mobile/features/insights/application/insights_controller.dart';
import 'package:affluena_mobile/features/insights/data/insight_models.dart';
import 'package:affluena_mobile/features/insights/data/insights_repository.dart';
import 'package:affluena_mobile/features/insights/presentation/insights_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('loads insight state from repositories', () async {
    final container = ProviderContainer(
      retry: noProviderRetry,
      overrides: [
        insightsRepositoryProvider.overrideWithValue(TestInsightsRepository()),
      ],
    );
    addTearDown(container.dispose);

    container.read(insightsControllerProvider);
    await Future<void>.delayed(Duration.zero);
    await Future<void>.delayed(Duration.zero);

    final state = container.read(insightsControllerProvider);
    expect(state.report.metrics.first.label, 'Overview balance');
    expect(state.exportJobs.single.id, 'job-1');
    expect(state.alerts.single.title, 'Food limit reached');
    expect(state.rules.single.title, 'Budget alerts');
  });

  testWidgets('renders reports and exports CSV from the mobile surface', (
    tester,
  ) async {
    final repository = TestInsightsRepository();

    await tester.pumpWidget(insightsTestApp(repository));
    await tester.pumpInsightsState();

    expect(find.text('Insights'), findsOneWidget);
    expect(find.text('Overview balance'), findsOneWidget);
    expect(find.text('Rp 4.000.000'), findsOneWidget);
    expect(find.text('79%'), findsOneWidget);
    expect(find.text('Rp 79'), findsNothing);

    await tester.tap(find.byKey(const Key('insights-tab-exports')));
    await tester.pumpAndSettle();
    expect(find.text('Transaction CSV'), findsOneWidget);

    await tester.tap(find.byKey(const Key('insights-export-button')));
    await tester.pumpAndSettle();

    expect(repository.exportRequests, hasLength(1));
    expect(find.text('CSV export generated'), findsOneWidget);
  });

  testWidgets('opens alert and activity detail cards', (tester) async {
    await tester.pumpWidget(insightsTestApp(TestInsightsRepository()));
    await tester.pumpInsightsState();

    await tester.tap(find.byKey(const Key('insights-tab-alerts')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Food limit reached'));
    await tester.pumpAndSettle();
    expect(find.text('Food spending reached 100%.'), findsWidgets);
    expect(find.text('/budgets'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.close));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('insights-tab-activity')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Created transaction Lunch'));
    await tester.pumpAndSettle();
    expect(find.textContaining('transaction'), findsWidgets);
  });

  testWidgets('updates notification rule toggle', (tester) async {
    final repository = TestInsightsRepository();

    await tester.pumpWidget(insightsTestApp(repository));
    await tester.pumpInsightsState();

    await tester.tap(find.byKey(const Key('insights-tab-rules')));
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const Key('notification-rule-budget-alert-switch')),
    );
    await tester.pumpAndSettle();

    expect(repository.ruleUpdates.single.enabled, false);
  });
}

extension on WidgetTester {
  Future<void> pumpInsightsState() async {
    await pump();
    await pump();
    await pumpAndSettle();
  }
}

Widget insightsTestApp(TestInsightsRepository repository) {
  return ProviderScope(
    retry: noProviderRetry,
    overrides: [insightsRepositoryProvider.overrideWithValue(repository)],
    child: MaterialApp(
      theme: AffluenaTheme.light,
      darkTheme: AffluenaTheme.dark,
      themeMode: ThemeMode.dark,
      home: const Scaffold(body: InsightsScreen()),
    ),
  );
}

class TestInsightsRepository implements InsightsRepository {
  final exportRequests = <ExportCsvRequest>[];
  final ruleUpdates = <NotificationRuleUpdate>[];

  @override
  Future<ReportResponse> getReport({
    required ReportKind kind,
    String? month,
  }) async {
    return seededReport;
  }

  @override
  Future<CsvExportResult> exportCsv(ExportCsvRequest request) async {
    exportRequests.add(request);
    return const CsvExportResult(
      bytes: [105, 100, 44, 97, 109, 111, 117, 110, 116],
      filename: 'transactions_export.csv',
    );
  }

  @override
  Future<ExportJobsResponse> listExportJobs({int? limit, int? offset}) async {
    return const ExportJobsResponse(
      jobs: [seededExportJob],
      pagination: Pagination(total: 1, limit: 20, offset: 0),
    );
  }

  @override
  Future<ExportJob> getExportJob(String id) async => seededExportJob;

  @override
  Future<ActivityListResponse> listActivities({
    int? limit,
    int? offset,
    String? sort,
  }) async {
    return const ActivityListResponse(
      activities: [seededActivity],
      pagination: Pagination(total: 1, limit: 20, offset: 0),
    );
  }

  @override
  Future<ActivityItem> getActivity(String id) async => seededActivity;

  @override
  Future<AlertsResponse> listAlerts({String? month}) async {
    return const AlertsResponse(alerts: [seededAlert]);
  }

  @override
  Future<InsightAlert> getAlert(String id) async => seededAlert;

  @override
  Future<NotificationRulesResponse> listNotificationRules() async {
    return const NotificationRulesResponse(rules: [seededRule]);
  }

  @override
  Future<NotificationRule> updateNotificationRule(
    String id,
    NotificationRuleUpdate update,
  ) async {
    ruleUpdates.add(update);
    return seededRule.copyWith(
      enabled: update.enabled ?? seededRule.enabled,
      channel: update.channel ?? seededRule.channel,
    );
  }
}

const seededReport = ReportResponse(
  metrics: [
    ReportMetric(
      id: 'metric-balance',
      label: 'Overview balance',
      valueMinor: 4000000,
      helper: 'Current month',
      tone: 'success',
    ),
    ReportMetric(
      id: 'metric-saving-rate',
      label: 'Saving Rate',
      valueMinor: 79,
      helper: '% of income saved',
      tone: 'positive',
    ),
  ],
  rows: [
    ReportRow(
      id: 'row-food',
      name: 'Food spending',
      category: 'Food & Dining',
      amountMinor: 1250000,
      previousAmountMinor: 900000,
      changePercent: 38.8,
      wallet: 'GoPay',
      status: ReportRowStatus.watch,
    ),
  ],
);

const seededExportJob = ExportJob(
  id: 'job-1',
  userId: 'user-1',
  format: 'CSV',
  fromAt: '2026-06-01T00:00:00Z',
  toAt: '2026-06-30T23:59:59Z',
  rowCount: 42,
  status: ExportJobStatus.completed,
  createdAt: '2026-06-22T08:00:00Z',
);

const seededActivity = ActivityItem(
  id: 'activity-1',
  userId: 'user-1',
  actionType: 'create',
  entityType: 'transaction',
  entityId: 'transaction-1',
  description: 'Created transaction Lunch',
  createdAt: '2026-06-22T08:00:00Z',
);

const seededAlert = InsightAlert(
  id: 'alert-1',
  type: 'budget',
  title: 'Food limit reached',
  module: 'budget',
  description: 'Food spending reached 100%.',
  severity: InsightSeverity.danger,
  createdAt: '2026-06-22T08:00:00Z',
  actionPath: '/budgets',
);

const seededRule = NotificationRule(
  id: 'rule-1',
  userId: 'user-1',
  ruleKey: 'budget-alert',
  title: 'Budget alerts',
  description: 'Notify when budgets cross thresholds.',
  enabled: true,
  channel: NotificationChannel.inApp,
  tone: 'warning',
  createdAt: '2026-06-01T00:00:00Z',
  updatedAt: '2026-06-22T08:00:00Z',
);
