import 'package:affluena_mobile/app/provider_retry.dart';
import 'package:affluena_mobile/app/theme/affluena_theme.dart';
import 'package:affluena_mobile/core/api/pagination.dart';
import 'package:affluena_mobile/features/insights/application/csv_share_service.dart';
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

  testWidgets('renders reports from the mobile surface', (tester) async {
    final repository = TestInsightsRepository();

    await tester.pumpWidget(insightsTestApp(repository));
    await tester.pumpInsightsState();

    expect(find.text('Insights'), findsOneWidget);
    expect(find.text('Overview balance'), findsOneWidget);
    expect(find.text('Rp 4.000.000'), findsOneWidget);
    expect(find.text('79%'), findsOneWidget);
    expect(find.text('Rp 79'), findsNothing);

    // CSV export is hidden from the UI for now, so its tab chip is not offered.
    expect(find.byKey(const Key('insights-tab-exports')), findsNothing);
  });

  testWidgets('opens alert and activity detail cards', (tester) async {
    await tester.pumpWidget(insightsTestApp(TestInsightsRepository()));
    await tester.pumpInsightsState();

    await tester.tap(find.byKey(const Key('insights-tab-alerts')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Food limit reached'));
    await tester.pumpAndSettle();
    // The detail sheet now surfaces humanized Type/Module/Raised metadata and
    // the description, not the raw actionPath ("/budgets").
    expect(find.text('Food spending reached 100%.'), findsWidgets);
    expect(find.text('Type'), findsOneWidget);
    expect(find.text('Module'), findsOneWidget);
    expect(find.text('Raised'), findsOneWidget);
    expect(find.text('Budget'), findsWidgets);
    expect(find.text('/budgets'), findsNothing);

    // Dismiss the modal sheet by tapping the scrim before switching tabs.
    await tester.tapAt(const Offset(20, 20));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('insights-tab-activity')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Created transaction Lunch'));
    await tester.pumpAndSettle();
    // The activity detail sheet de-emphasizes the raw entity id as a
    // "Reference ID (debug)" technical row.
    expect(find.text('Reference ID (debug)'), findsOneWidget);
    expect(find.text('transaction-1'), findsOneWidget);
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

  test('update rule refreshes backend-derived insight sections', () async {
    final repository = TestInsightsRepository();
    repository.onRuleUpdated = () {
      repository.report = refreshedReport;
      repository.alerts = const [refreshedAlert];
    };
    final container = ProviderContainer(
      retry: noProviderRetry,
      overrides: [insightsRepositoryProvider.overrideWithValue(repository)],
    );
    addTearDown(container.dispose);

    container.read(insightsControllerProvider);
    await Future<void>.delayed(Duration.zero);
    await Future<void>.delayed(Duration.zero);

    await container
        .read(insightsControllerProvider.notifier)
        .updateRule(seededRule, const NotificationRuleUpdate(enabled: false));

    final state = container.read(insightsControllerProvider);
    expect(repository.ruleUpdates.single.enabled, false);
    expect(state.rules.single.enabled, false);
    expect(state.report.metrics.first.label, 'Rules refreshed balance');
    expect(state.alerts.single.title, 'Budget alerts paused');
    expect(state.actionMessage, 'Notification rule updated.');
  });

  test(
    'update rule keeps updated state when post-update refresh fails',
    () async {
      final repository = TestInsightsRepository();
      repository.onRuleUpdated = () {
        repository.failAlertsReload = true;
      };
      final container = ProviderContainer(
        retry: noProviderRetry,
        overrides: [insightsRepositoryProvider.overrideWithValue(repository)],
      );
      addTearDown(container.dispose);

      container.read(insightsControllerProvider);
      await Future<void>.delayed(Duration.zero);
      await Future<void>.delayed(Duration.zero);

      await container
          .read(insightsControllerProvider.notifier)
          .updateRule(seededRule, const NotificationRuleUpdate(enabled: false));

      final state = container.read(insightsControllerProvider);
      expect(repository.ruleUpdates.single.enabled, false);
      expect(repository.alertReloadAttempts, 2);
      expect(state.rules.single.enabled, false);
      expect(
        state.actionError,
        'Notification rule updated, but insights could not be refreshed.',
      );
      expect(
        state.actionError,
        isNot('Notification rule could not be updated.'),
      );
    },
  );
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
    overrides: [
      insightsRepositoryProvider.overrideWithValue(repository),
      // CSV export now routes through the platform share sheet via
      // csvShareServiceProvider. Override it so the test exercises the success
      // path ("CSV export shared.") without touching the SharePlus platform
      // channel.
      csvShareServiceProvider.overrideWithValue(
        const FakeCsvShareService(CsvShareOutcome.shared),
      ),
    ],
    child: MaterialApp(
      theme: AffluenaTheme.light,
      darkTheme: AffluenaTheme.dark,
      themeMode: ThemeMode.dark,
      home: const Scaffold(body: InsightsScreen()),
    ),
  );
}

class FakeCsvShareService implements CsvShareService {
  const FakeCsvShareService(this.outcome);

  final CsvShareOutcome outcome;

  @override
  Future<CsvShareOutcome> share(CsvExportResult export) async => outcome;
}

class TestInsightsRepository implements InsightsRepository {
  final exportRequests = <ExportCsvRequest>[];
  final ruleUpdates = <NotificationRuleUpdate>[];
  ReportResponse report = seededReport;
  List<ExportJob> exportJobs = const [seededExportJob];
  List<ActivityItem> activities = const [seededActivity];
  List<SystemLog> systemLogs = const [seededSystemLog];
  List<InsightAlert> alerts = const [seededAlert];
  List<NotificationRule> rules = const [seededRule];
  bool failAlertsReload = false;
  int alertReloadAttempts = 0;
  VoidCallback? onRuleUpdated;

  @override
  Future<ReportResponse> getReport({
    required ReportKind kind,
    String? month,
  }) async {
    return report;
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
    return ExportJobsResponse(
      jobs: exportJobs,
      pagination: Pagination(total: exportJobs.length, limit: 20, offset: 0),
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
    return ActivityListResponse(
      activities: activities,
      pagination: Pagination(total: activities.length, limit: 20, offset: 0),
    );
  }

  @override
  Future<ActivityItem> getActivity(String id) async => seededActivity;

  @override
  Future<SystemLogsResponse> listSystemLogs({int? limit}) async {
    return SystemLogsResponse(logs: systemLogs);
  }

  @override
  Future<SystemLog> getSystemLog(String id) async => seededSystemLog;

  @override
  Future<AlertsResponse> listAlerts({String? month}) async {
    alertReloadAttempts += 1;
    if (failAlertsReload) {
      await Future<void>.delayed(Duration.zero);
      throw StateError('alerts reload failed');
    }
    return AlertsResponse(alerts: alerts);
  }

  @override
  Future<InsightAlert> getAlert(String id) async => seededAlert;

  @override
  Future<NotificationRulesResponse> listNotificationRules() async {
    return NotificationRulesResponse(rules: rules);
  }

  @override
  Future<NotificationRule> updateNotificationRule(
    String id,
    NotificationRuleUpdate update,
  ) async {
    ruleUpdates.add(update);
    final updated = seededRule.copyWith(
      enabled: update.enabled ?? seededRule.enabled,
      channel: update.channel ?? seededRule.channel,
    );
    rules = [
      for (final rule in rules)
        if (rule.id == updated.id) updated else rule,
    ];
    onRuleUpdated?.call();
    return updated;
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
      id: 'saving_rate',
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

const refreshedReport = ReportResponse(
  metrics: [
    ReportMetric(
      id: 'metric-balance',
      label: 'Rules refreshed balance',
      valueMinor: 4100000,
      helper: 'Current month',
      tone: 'success',
    ),
  ],
  rows: [
    ReportRow(
      id: 'row-food-refreshed',
      name: 'Food spending',
      category: 'Food & Dining',
      amountMinor: 1150000,
      previousAmountMinor: 900000,
      changePercent: 27.7,
      wallet: 'GoPay',
      status: ReportRowStatus.healthy,
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

const seededSystemLog = SystemLog(
  id: 'log-1',
  method: 'GET',
  path: '/api/v1/wallets',
  statusCode: 200,
  latencyMs: 12,
  clientIp: '127.0.0.1',
  userAgent: 'Flutter test',
  userId: 'user-1',
  responsePayload: '{"ok":true}',
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

const refreshedAlert = InsightAlert(
  id: 'alert-2',
  type: 'budget',
  title: 'Budget alerts paused',
  module: 'budget',
  description: 'Budget notifications are now paused.',
  severity: InsightSeverity.info,
  createdAt: '2026-06-22T08:05:00Z',
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
