import 'package:affluena_mobile/app/provider_retry.dart';
import 'package:affluena_mobile/app/theme/affluena_theme.dart';
import 'package:affluena_mobile/core/api/pagination.dart';
import 'package:affluena_mobile/features/insights/data/insight_models.dart';
import 'package:affluena_mobile/features/insights/data/insights_repository.dart';
import 'package:affluena_mobile/features/insights/presentation/audit_log_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('renders activity and system logs from repository data', (
    tester,
  ) async {
    await tester.pumpWidget(auditLogTestApp(TestAuditLogRepository()));
    await tester.pumpAuditState();

    expect(find.text('Audit logs'), findsOneWidget);
    expect(find.text('1 activity'), findsOneWidget);
    expect(find.text('1 system request'), findsOneWidget);
    expect(find.text('Created transaction Lunch'), findsOneWidget);
    expect(find.text('create · transaction'), findsOneWidget);
    expect(find.text('Activity'), findsWidgets);

    await tester.tap(find.byKey(const Key('audit-log-tab-system')));
    await tester.pumpAndSettle();

    expect(find.text('System logs'), findsWidgets);
    expect(find.text('GET /api/v1/wallets'), findsOneWidget);
    expect(find.text('200 · 12 ms'), findsOneWidget);
    expect(find.text('Flutter test'), findsOneWidget);
  });

  testWidgets(
    'opens activity and system log details through detail endpoints',
    (tester) async {
      final repository = TestAuditLogRepository();

      await tester.pumpWidget(auditLogTestApp(repository));
      await tester.pumpAuditState();

      await tester.tap(find.text('Created transaction Lunch'));
      await tester.pumpAndSettle();

      expect(repository.activityDetailRequests, ['activity-1']);
      expect(find.text('Entity ID'), findsOneWidget);
      expect(find.text('transaction-1'), findsOneWidget);

      await tester.tap(find.byIcon(Icons.close));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('audit-log-tab-system')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('GET /api/v1/wallets'));
      await tester.pumpAndSettle();

      expect(repository.systemLogDetailRequests, ['log-1']);
      expect(find.text('Request payload'), findsOneWidget);
      expect(find.text('Response payload'), findsOneWidget);
      expect(find.text('{"ok":true}'), findsOneWidget);
    },
  );

  testWidgets('shows retryable error state when audit logs fail to load', (
    tester,
  ) async {
    final repository = TestAuditLogRepository()..failInitialLoad = true;

    await tester.pumpWidget(auditLogTestApp(repository));
    await tester.pumpAuditState();

    expect(find.text('Audit logs unavailable'), findsOneWidget);

    repository.failInitialLoad = false;
    await tester.tap(find.byKey(const Key('audit-log-retry-button')));
    await tester.pumpAuditState();

    expect(find.text('Created transaction Lunch'), findsOneWidget);
    expect(repository.activityListAttempts, 2);
  });
}

extension on WidgetTester {
  Future<void> pumpAuditState() async {
    await pump();
    await pump();
    await pumpAndSettle();
  }
}

Widget auditLogTestApp(TestAuditLogRepository repository) {
  return ProviderScope(
    retry: noProviderRetry,
    overrides: [insightsRepositoryProvider.overrideWithValue(repository)],
    child: MaterialApp(
      theme: AffluenaTheme.light,
      darkTheme: AffluenaTheme.dark,
      themeMode: ThemeMode.dark,
      home: const Scaffold(body: AuditLogScreen()),
    ),
  );
}

class TestAuditLogRepository implements InsightsRepository {
  bool failInitialLoad = false;
  int activityListAttempts = 0;
  final activityDetailRequests = <String>[];
  final systemLogDetailRequests = <String>[];

  @override
  Future<ActivityListResponse> listActivities({
    int? limit,
    int? offset,
    String? sort,
  }) async {
    activityListAttempts += 1;
    if (failInitialLoad) {
      throw StateError('offline');
    }
    return const ActivityListResponse(
      activities: [seededActivity],
      pagination: Pagination(total: 1, limit: 20, offset: 0),
    );
  }

  @override
  Future<SystemLogsResponse> listSystemLogs({int? limit}) async {
    if (failInitialLoad) {
      throw StateError('offline');
    }
    return const SystemLogsResponse(logs: [seededSystemLog]);
  }

  @override
  Future<ActivityItem> getActivity(String id) async {
    activityDetailRequests.add(id);
    return seededActivity;
  }

  @override
  Future<SystemLog> getSystemLog(String id) async {
    systemLogDetailRequests.add(id);
    return seededSystemLog;
  }

  @override
  Future<ReportResponse> getReport({required ReportKind kind, String? month}) {
    throw UnimplementedError();
  }

  @override
  Future<CsvExportResult> exportCsv(ExportCsvRequest request) {
    throw UnimplementedError();
  }

  @override
  Future<ExportJobsResponse> listExportJobs({int? limit, int? offset}) {
    throw UnimplementedError();
  }

  @override
  Future<ExportJob> getExportJob(String id) {
    throw UnimplementedError();
  }

  @override
  Future<AlertsResponse> listAlerts({String? month}) {
    throw UnimplementedError();
  }

  @override
  Future<InsightAlert> getAlert(String id) {
    throw UnimplementedError();
  }

  @override
  Future<NotificationRulesResponse> listNotificationRules() {
    throw UnimplementedError();
  }

  @override
  Future<NotificationRule> updateNotificationRule(
    String id,
    NotificationRuleUpdate update,
  ) {
    throw UnimplementedError();
  }
}

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
  requestPayload: '{"limit":20}',
  responsePayload: '{"ok":true}',
  createdAt: '2026-06-22T08:00:00Z',
);
