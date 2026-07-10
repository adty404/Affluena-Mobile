import 'package:affluena_mobile/app/provider_retry.dart';
import 'package:affluena_mobile/app/theme/affluena_theme.dart';
import 'package:affluena_mobile/core/api/pagination.dart';
import 'package:affluena_mobile/features/insights/application/csv_share_service.dart';
import 'package:affluena_mobile/features/insights/application/insights_controller.dart';
import 'package:affluena_mobile/features/insights/data/insight_models.dart';
import 'package:affluena_mobile/features/insights/data/insights_repository.dart';
import 'package:affluena_mobile/features/insights/presentation/aturan_notifikasi_screen.dart';
import 'package:affluena_mobile/features/insights/presentation/ekspor_screen.dart';
import 'package:affluena_mobile/features/insights/presentation/laporan_screen.dart';
import 'package:affluena_mobile/features/insights/presentation/peringatan_aktivitas_screen.dart';
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

  testWidgets('LaporanScreen renders the monthly report', (tester) async {
    final repository = TestInsightsRepository();

    await tester.pumpWidget(insightsTestApp(repository, const LaporanScreen()));
    await tester.pumpInsightsState();

    // Its own routed screen now — no cross-section chip bar; the report-kind
    // chips remain as this screen's sub-views.
    expect(find.text('Laporan'), findsWidgets);
    expect(find.text('Overview balance'), findsOneWidget);
    expect(find.text('Rp 4.000.000'), findsOneWidget);
    expect(find.text('79%'), findsOneWidget);
    expect(find.text('Rp 79'), findsNothing);
    expect(find.byKey(const Key('report-kind-overview')), findsOneWidget);
    // Cross-section content (export jobs, alerts, rules) no longer leaks in.
    expect(find.text('42 baris'), findsNothing);
    expect(find.text('Food limit reached'), findsNothing);
  });

  testWidgets('EksporScreen lists export jobs and exports a CSV', (
    tester,
  ) async {
    final repository = TestInsightsRepository();

    await tester.pumpWidget(insightsTestApp(repository, const EksporScreen()));
    await tester.pumpInsightsState();

    // The seeded export job renders in the "Tugas ekspor" list.
    expect(find.text('42 baris'), findsOneWidget);

    // Tapping "Ekspor CSV" generates + shares the month CSV via the fake share
    // service, then shows a success banner on this screen.
    await tester.tap(find.byKey(const Key('insights-export-button')));
    await tester.pumpAndSettle();

    expect(repository.exportRequests, hasLength(1));
    // The window is the user's LOCAL calendar month converted to UTC on the
    // wire (an offset-less local ISO string would 400), with an exclusive
    // upper edge at the next month's first instant — computed the same way
    // here so the assertion holds in any machine timezone.
    final now = DateTime.now();
    expect(
      repository.exportRequests.single.from,
      DateTime(now.year, now.month).toUtc().toIso8601String(),
    );
    expect(
      repository.exportRequests.single.to,
      DateTime(now.year, now.month + 1).toUtc().toIso8601String(),
    );
    expect(find.text('Ekspor CSV dibagikan.'), findsOneWidget);
  });

  testWidgets(
    'PeringatanAktivitasScreen opens alert and activity detail cards',
    (tester) async {
      await tester.pumpWidget(
        insightsTestApp(
          TestInsightsRepository(),
          const PeringatanAktivitasScreen(),
        ),
      );
      await tester.pumpInsightsState();

      // Alerts and the audit-trail activity feed live together as stacked
      // sections on ONE screen (they shared a single Pengaturan entry).
      await tester.tap(find.text('Food limit reached'));
      await tester.pumpAndSettle();
      // The detail sheet surfaces humanized Type/Module/Raised metadata and
      // the description, not the raw actionPath ("/budgets").
      expect(find.text('Food spending reached 100%.'), findsWidgets);
      expect(find.text('Jenis'), findsOneWidget);
      expect(find.text('Modul'), findsOneWidget);
      expect(find.text('Dibuat'), findsOneWidget);
      expect(find.text('Budget'), findsWidgets);
      expect(find.text('/budgets'), findsNothing);

      // Dismiss the modal sheet by tapping the scrim, then open the activity.
      await tester.tapAt(const Offset(20, 20));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Created transaction Lunch'));
      await tester.pumpAndSettle();
      // The activity detail sheet de-emphasizes the raw entity id as a
      // "Reference ID (debug)" technical row.
      expect(find.text('ID referensi (debug)'), findsOneWidget);
      expect(find.text('transaction-1'), findsOneWidget);
    },
  );

  testWidgets('AturanNotifikasiScreen updates a notification rule toggle', (
    tester,
  ) async {
    final repository = TestInsightsRepository();

    await tester.pumpWidget(
      insightsTestApp(repository, const AturanNotifikasiScreen()),
    );
    await tester.pumpInsightsState();

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
    expect(state.actionMessage, 'Aturan notifikasi diperbarui.');
  });

  test('retrying a failed export re-creates it with the same range', () async {
    final repository = TestInsightsRepository();
    const failedJob = ExportJob(
      id: 'job-failed',
      userId: 'user-1',
      format: 'CSV',
      fromAt: '2026-05-01T00:00:00Z',
      toAt: '2026-05-31T23:59:59Z',
      rowCount: 0,
      status: ExportJobStatus.failed,
      createdAt: '2026-06-01T08:00:00Z',
    );
    repository.exportJobs = const [failedJob];
    final container = ProviderContainer(
      retry: noProviderRetry,
      overrides: [
        insightsRepositoryProvider.overrideWithValue(repository),
        csvShareServiceProvider.overrideWithValue(
          const FakeCsvShareService(CsvShareOutcome.shared),
        ),
      ],
    );
    addTearDown(container.dispose);

    container.read(insightsControllerProvider);
    await Future<void>.delayed(Duration.zero);
    await Future<void>.delayed(Duration.zero);

    // The backend records a fresh job the moment the export re-runs.
    repository.exportJobs = const [seededExportJob, failedJob];
    final outcome = await container
        .read(insightsControllerProvider.notifier)
        .retryExportJob(failedJob);

    expect(outcome, CsvShareOutcome.shared);
    // Re-submitted with the failed job's own date range.
    expect(repository.exportRequests.single.from, failedJob.fromAt);
    expect(repository.exportRequests.single.to, failedJob.toAt);
    // The job list was refreshed so the new attempt shows up immediately.
    final state = container.read(insightsControllerProvider);
    expect(state.exportJobs.first.status, ExportJobStatus.completed);
    expect(state.exportJobs, hasLength(2));
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
        'Aturan notifikasi diperbarui, tetapi wawasan tidak dapat disegarkan.',
      );
      expect(
        state.actionError,
        isNot('Aturan notifikasi tidak dapat diperbarui.'),
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

Widget insightsTestApp(TestInsightsRepository repository, Widget screen) {
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
      home: Scaffold(body: screen),
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
