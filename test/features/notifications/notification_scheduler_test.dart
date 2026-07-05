import 'dart:async';

import 'package:affluena_mobile/app/provider_retry.dart';
import 'package:affluena_mobile/core/api/pagination.dart';
import 'package:affluena_mobile/core/storage/secure_token_store.dart';
import 'package:affluena_mobile/features/auth/application/auth_controller.dart';
import 'package:affluena_mobile/features/auth/data/auth_repository.dart';
import 'package:affluena_mobile/features/dashboard/data/dashboard_models.dart';
import 'package:affluena_mobile/features/insights/application/insights_controller.dart';
import 'package:affluena_mobile/features/insights/data/insight_models.dart';
import 'package:affluena_mobile/features/insights/data/insights_repository.dart';
import 'package:affluena_mobile/features/notifications/application/device_notifications.dart';
import 'package:affluena_mobile/features/notifications/application/due_reminder_planner.dart';
import 'package:affluena_mobile/features/notifications/application/notification_scheduler.dart';
import 'package:clock/clock.dart';
import 'package:fake_async/fake_async.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../helpers/auth_test_helpers.dart';

/// In-memory [DeviceNotifications] mirroring the device's pending pane, with a
/// chronological call log so tests can assert the arm-vs-prune ordering.
class FakeDeviceNotifications implements DeviceNotifications {
  FakeDeviceNotifications({this.isSupported = true});

  @override
  final bool isSupported;

  /// Armed reminders by id — what the device's notification manager holds.
  final Map<int, PlannedReminder> armed = {};

  /// Chronological call log (`schedule:<id>`, `listPendingIds`,
  /// `cancelIds:<ids>`, `cancelAll`).
  final List<String> log = [];

  int cancelAllCalls = 0;

  @override
  Future<bool> requestPermission() async => true;

  @override
  Future<bool?> areEnabled() async => true;

  @override
  Future<void> cancelAll() async {
    cancelAllCalls += 1;
    log.add('cancelAll');
    armed.clear();
  }

  @override
  Future<List<int>> listPendingIds() async {
    log.add('listPendingIds');
    return armed.keys.toList(growable: false);
  }

  @override
  Future<void> cancelIds(List<int> ids) async {
    log.add('cancelIds:${(ids.toList()..sort()).join(',')}');
    ids.forEach(armed.remove);
  }

  @override
  Future<void> schedule(PlannedReminder reminder) async {
    log.add('schedule:${reminder.id}');
    armed[reminder.id] = reminder;
  }
}

/// Minimal rules-focused [InsightsRepository]: everything the
/// [InsightsController] loads returns empty, while the notification rules are
/// mutable so a test can toggle the due-reminder rule like Pengaturan does.
class _RulesInsightsRepository implements InsightsRepository {
  _RulesInsightsRepository(this.rules);

  List<NotificationRule> rules;

  @override
  Future<NotificationRulesResponse> listNotificationRules() async =>
      NotificationRulesResponse(rules: rules);

  @override
  Future<NotificationRule> updateNotificationRule(
    String id,
    NotificationRuleUpdate update,
  ) async {
    final current = rules.firstWhere((rule) => rule.id == id);
    final updated = current.copyWith(
      enabled: update.enabled ?? current.enabled,
      channel: update.channel ?? current.channel,
    );
    rules = [
      for (final rule in rules)
        if (rule.id == id) updated else rule,
    ];
    return updated;
  }

  @override
  Future<ReportResponse> getReport({
    required ReportKind kind,
    String? month,
  }) async => ReportResponse.empty;

  @override
  Future<ExportJobsResponse> listExportJobs({int? limit, int? offset}) async =>
      const ExportJobsResponse(
        jobs: [],
        pagination: Pagination(total: 0, limit: 20, offset: 0),
      );

  @override
  Future<ActivityListResponse> listActivities({
    int? limit,
    int? offset,
    String? sort,
  }) async => const ActivityListResponse(
    activities: [],
    pagination: Pagination(total: 0, limit: 20, offset: 0),
  );

  @override
  Future<AlertsResponse> listAlerts({String? month}) async =>
      const AlertsResponse(alerts: []);

  @override
  Future<CsvExportResult> exportCsv(ExportCsvRequest request) =>
      throw UnimplementedError();

  @override
  Future<ExportJob> getExportJob(String id) => throw UnimplementedError();

  @override
  Future<ActivityItem> getActivity(String id) => throw UnimplementedError();

  @override
  Future<SystemLogsResponse> listSystemLogs({int? limit}) =>
      throw UnimplementedError();

  @override
  Future<SystemLog> getSystemLog(String id) => throw UnimplementedError();

  @override
  Future<InsightAlert> getAlert(String id) => throw UnimplementedError();
}

NotificationRule _dueRule({required bool enabled}) => NotificationRule(
  id: 'rule-due',
  userId: 'u1',
  ruleKey: kDueReminderRuleKey,
  title: 'Pengingat jatuh tempo',
  description: 'H-3 dan H-1.',
  enabled: enabled,
  channel: NotificationChannel.inApp,
  tone: 'info',
  createdAt: '2026-06-01T00:00:00Z',
  updatedAt: '2026-06-01T00:00:00Z',
);

NotificationRulesResponse _rules({required bool dueEnabled}) =>
    NotificationRulesResponse(rules: [_dueRule(enabled: dueEnabled)]);

DashboardSummary _summaryWith({
  List<UpcomingSubscription> subscriptions = const [],
}) => DashboardSummary(
  month: '2026-07',
  netWorthMinor: 0,
  monthlyIncomeMinor: 0,
  monthlyExpenseMinor: 0,
  monthlyCashflowMinor: 0,
  budget: const BudgetSummary(
    limitMinor: 0,
    spentMinor: 0,
    remainingMinor: 0,
    usagePercent: 0,
  ),
  upcomingSubscriptions: subscriptions,
  upcomingInstallments: const [],
  upcomingDebts: const [],
);

UpcomingSubscription _sub(String id, String dueDate) => UpcomingSubscription(
  id: id,
  name: 'Langganan $id',
  accountDetail: '',
  amountMinor: 54000,
  nextDueDate: dueDate,
);

/// Ids the planner would produce for [summary] with the due rule enabled.
Set<int> _plannedIds(DashboardSummary summary, DateTime now) => {
  for (final reminder in planDueReminders(
    summary: summary,
    enabledRuleKeys: const {kDueReminderRuleKey},
    now: now,
  ))
    reminder.id,
};

final _stale = PlannedReminder(
  id: 999,
  when: DateTime(2026, 7, 1, 9),
  title: 'stale',
  body: 'stale',
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({
      'affluena.device_notif_prompted': true,
    });
  });

  group('NotificationScheduler.resyncNow', () {
    test('arms the plan first, THEN prunes stale ids — never cancel-all', () async {
      final device = FakeDeviceNotifications()..armed[_stale.id] = _stale;
      final scheduler = NotificationScheduler(
        device: device,
        loadRules: () async => _rules(dueEnabled: true),
      );

      final now = DateTime(2026, 7, 5);
      final summary = _summaryWith(subscriptions: [_sub('s1', '2026-07-10')]);
      await withClock(Clock.fixed(now), () => scheduler.resyncNow(summary));

      final expected = _plannedIds(summary, now);
      expect(expected, hasLength(2)); // H-3 + H-1, both still in the future.
      expect(device.armed.keys.toSet(), expected);
      expect(device.cancelAllCalls, 0);

      // Ordering: every arm happens before the prune pass, so a crash
      // mid-resync leaves the old set or a superset — never nothing.
      final lastSchedule = device.log.lastIndexWhere(
        (entry) => entry.startsWith('schedule:'),
      );
      final pruneList = device.log.indexOf('listPendingIds');
      expect(lastSchedule, lessThan(pruneList));
      expect(device.log.last, 'cancelIds:${_stale.id}');
    });

    test('a disabled due-reminder rule cancels all and arms nothing', () async {
      final device = FakeDeviceNotifications()..armed[_stale.id] = _stale;
      final scheduler = NotificationScheduler(
        device: device,
        loadRules: () async => _rules(dueEnabled: false),
      );

      await withClock(
        Clock.fixed(DateTime(2026, 7, 5)),
        () => scheduler.resyncNow(
          _summaryWith(subscriptions: [_sub('s1', '2026-07-10')]),
        ),
      );

      expect(device.cancelAllCalls, 1);
      expect(device.armed, isEmpty);
      expect(device.log.where((e) => e.startsWith('schedule:')), isEmpty);
    });

    test('a rules-fetch failure keeps what is armed and arms nothing', () async {
      final device = FakeDeviceNotifications()..armed[_stale.id] = _stale;
      final scheduler = NotificationScheduler(
        device: device,
        loadRules: () async => throw StateError('rules down'),
      );

      await withClock(
        Clock.fixed(DateTime(2026, 7, 5)),
        () => scheduler.resyncNow(
          _summaryWith(subscriptions: [_sub('s1', '2026-07-10')]),
        ),
      );

      expect(device.armed.keys, [_stale.id]);
      expect(device.cancelAllCalls, 0);
      expect(device.log, isEmpty);
    });

    test('a superseded run can never clobber the fresh plan', () async {
      final device = FakeDeviceNotifications();
      final gates = <Completer<NotificationRulesResponse>>[];
      final scheduler = NotificationScheduler(
        device: device,
        loadRules: () {
          final gate = Completer<NotificationRulesResponse>();
          gates.add(gate);
          return gate.future;
        },
      );

      final now = DateTime(2026, 7, 5);
      final staleSummary = _summaryWith(
        subscriptions: [_sub('old', '2026-07-10')],
      );
      final freshSummary = _summaryWith(
        subscriptions: [_sub('new', '2026-07-20')],
      );

      await withClock(Clock.fixed(now), () async {
        // Run A starts and parks on its rules fetch; run B supersedes it and
        // completes FIRST.
        final runA = scheduler.resyncNow(staleSummary);
        final runB = scheduler.resyncNow(freshSummary);
        gates[1].complete(_rules(dueEnabled: true));
        await runB;
        expect(device.armed.keys.toSet(), _plannedIds(freshSummary, now));

        // The stale run resumes afterwards and must abort at its generation
        // checkpoint without cancelling or re-arming anything.
        gates[0].complete(_rules(dueEnabled: true));
        await runA;
        expect(device.armed.keys.toSet(), _plannedIds(freshSummary, now));
        expect(device.cancelAllCalls, 0);
      });
    });
  });

  group('NotificationScheduler.requestResync', () {
    test('debounced runs are serialized and re-read the latest summary', () {
      fakeAsync((async) {
        final device = FakeDeviceNotifications();
        var rulesCalls = 0;
        final scheduler = NotificationScheduler(
          device: device,
          loadRules: () {
            rulesCalls += 1;
            // Rules answer 5s later so a second request lands mid-flight.
            return Future<NotificationRulesResponse>.delayed(
              const Duration(seconds: 5),
              () => _rules(dueEnabled: true),
            );
          },
        );

        final staleSummary = _summaryWith(
          subscriptions: [_sub('old', '2026-07-10')],
        );
        final freshSummary = _summaryWith(
          subscriptions: [_sub('new', '2026-07-20')],
        );

        scheduler.requestResync(staleSummary);
        async.elapse(const Duration(seconds: 3)); // Debounce → run 1 starts.
        expect(rulesCalls, 1);

        // A newer summary arrives while run 1 is still fetching rules; its
        // debounce fires but the run must CHAIN, not interleave.
        scheduler.requestResync(freshSummary);
        async.elapse(const Duration(seconds: 3));
        expect(rulesCalls, 1);

        async.elapse(const Duration(seconds: 5)); // Run 1 done → run 2 starts.
        expect(rulesCalls, 2);
        async.elapse(const Duration(seconds: 5)); // Run 2 completes.

        expect(
          device.armed.keys.toSet(),
          _plannedIds(freshSummary, clock.now()),
        );
      }, initialTime: DateTime(2026, 7, 5));
    });
  });

  group('NotificationScheduler.clear', () {
    test('cancels armed reminders and a pending debounce cannot re-arm', () {
      fakeAsync((async) {
        final device = FakeDeviceNotifications();
        final scheduler = NotificationScheduler(
          device: device,
          loadRules: () async => _rules(dueEnabled: true),
        );

        // Arm something first.
        scheduler.resyncNow(
          _summaryWith(subscriptions: [_sub('s1', '2026-07-10')]),
        );
        async.flushMicrotasks();
        expect(device.armed, isNotEmpty);

        // A resync request is still inside its debounce window when the user
        // logs out.
        scheduler.requestResync(
          _summaryWith(subscriptions: [_sub('s2', '2026-07-12')]),
        );
        scheduler.clear();
        async.flushMicrotasks();
        expect(device.cancelAllCalls, 1);
        expect(device.armed, isEmpty);

        // The debounce window passing must not re-arm anything.
        async.elapse(const Duration(minutes: 1));
        expect(device.armed, isEmpty);
        expect(device.cancelAllCalls, 1);
      }, initialTime: DateTime(2026, 7, 5));
    });
  });

  group('AuthController + scheduler', () {
    test('logout wipes armed device reminders without touching the network', () async {
      final device = FakeDeviceNotifications()..armed[_stale.id] = _stale;
      final scheduler = NotificationScheduler(
        device: device,
        loadRules: () async => throw StateError('network must not be needed'),
      );
      final container = ProviderContainer(
        retry: noProviderRetry,
        overrides: [
          secureTokenStoreProvider.overrideWithValue(
            authenticatedTokenStore(),
          ),
          authRepositoryProvider.overrideWithValue(FakeAuthRepository()),
          notificationSchedulerProvider.overrideWithValue(scheduler),
        ],
      );
      addTearDown(container.dispose);

      await container.read(authControllerProvider.notifier).logout();
      await scheduler.idle(); // clear() is fire-and-forget.

      expect(device.cancelAllCalls, 1);
      expect(device.armed, isEmpty);
    });

    test('a discarded (failing) restored session clears reminders too', () async {
      final device = FakeDeviceNotifications()..armed[_stale.id] = _stale;
      final scheduler = NotificationScheduler(
        device: device,
        loadRules: () async => _rules(dueEnabled: true),
      );
      final container = ProviderContainer(
        retry: noProviderRetry,
        overrides: [
          secureTokenStoreProvider.overrideWithValue(
            authenticatedTokenStore(),
          ),
          authRepositoryProvider.overrideWithValue(
            FakeAuthRepository(meError: StateError('session dead')),
          ),
          notificationSchedulerProvider.overrideWithValue(scheduler),
        ],
      );
      addTearDown(container.dispose);

      // build() kicks off _restoreSession in a microtask; wait for it to land
      // on unauthenticated.
      container.read(authControllerProvider);
      for (var i = 0; i < 10; i++) {
        await Future<void>.delayed(Duration.zero);
        if (container.read(authControllerProvider).status ==
            AuthStatus.unauthenticated) {
          break;
        }
      }
      await scheduler.idle();

      expect(
        container.read(authControllerProvider).status,
        AuthStatus.unauthenticated,
      );
      expect(device.cancelAllCalls, 1);
      expect(device.armed, isEmpty);
    });
  });

  group('InsightsController.updateRule + scheduler', () {
    // Due dates far in the future so the plan is non-empty for the real
    // clock — the resync triggered by the toggle runs outside any fake clock.
    final summary = _summaryWith(subscriptions: [_sub('s1', '2099-01-10')]);

    (ProviderContainer, FakeDeviceNotifications, NotificationScheduler)
    setUpToggle({required bool dueEnabled}) {
      final device = FakeDeviceNotifications();
      final repository = _RulesInsightsRepository([
        _dueRule(enabled: dueEnabled),
      ]);
      final scheduler = NotificationScheduler(
        device: device,
        loadRules: repository.listNotificationRules,
      );
      final container = ProviderContainer(
        retry: noProviderRetry,
        overrides: [
          insightsRepositoryProvider.overrideWithValue(repository),
          notificationSchedulerProvider.overrideWithValue(scheduler),
        ],
      );
      addTearDown(container.dispose);
      return (container, device, scheduler);
    }

    test('toggling OFF cancels armed reminders with nothing re-armed', () async {
      final (container, device, scheduler) = setUpToggle(dueEnabled: true);

      // Seed: a summary resync armed the H-3/H-1 reminders while enabled.
      await scheduler.resyncNow(summary);
      expect(device.armed, hasLength(2));
      device.log.clear();

      await container
          .read(insightsControllerProvider.notifier)
          .updateRule(
            _dueRule(enabled: true),
            const NotificationRuleUpdate(enabled: false),
          );
      await scheduler.idle();

      expect(device.cancelAllCalls, 1);
      expect(device.armed, isEmpty);
      expect(device.log.where((e) => e.startsWith('schedule:')), isEmpty);
    });

    test('toggling ON arms reminders without needing a money mutation', () async {
      final (container, device, scheduler) = setUpToggle(dueEnabled: false);

      // Seed: the summary resync ran while the rule was off — nothing armed.
      await scheduler.resyncNow(summary);
      expect(device.armed, isEmpty);

      await container
          .read(insightsControllerProvider.notifier)
          .updateRule(
            _dueRule(enabled: false),
            const NotificationRuleUpdate(enabled: true),
          );
      await scheduler.idle();

      expect(
        device.armed.keys.toSet(),
        _plannedIds(summary, DateTime.now()),
      );
      expect(device.armed, hasLength(2));
    });
  });
}
