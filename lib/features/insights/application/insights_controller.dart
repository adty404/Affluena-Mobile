import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/formatters/date_formatter.dart';
import '../../../core/state/copy_with_sentinel.dart';
import '../../dashboard/application/dashboard_home_controller.dart';
import '../../notifications/application/due_reminder_planner.dart';
import '../../notifications/application/notification_scheduler.dart';
import '../data/insight_models.dart';
import '../data/insights_repository.dart';
import 'csv_share_service.dart';

const insightsPageSize = 20;

final insightsControllerProvider =
    NotifierProvider<InsightsController, InsightsState>(InsightsController.new);

class InsightsController extends Notifier<InsightsState> {
  @override
  InsightsState build() {
    Future<void>.microtask(load);
    return InsightsState(month: _currentMonth());
  }

  Future<void> load() async {
    state = state.copyWith(
      // Recompute the current month at load time — the controller isn't
      // autoDispose, so a process that survives midnight would otherwise keep
      // reporting/exporting the month captured at build().
      month: _currentMonth(),
      isLoading: true,
      loadError: null,
      actionMessage: null,
    );
    try {
      final repository = ref.read(insightsRepositoryProvider);
      final sections = await _fetchSections(repository);

      state = state.copyWith(
        isLoading: false,
        report: sections.report,
        exportJobs: sections.exportJobs.jobs,
        exportJobTotal: sections.exportJobs.pagination.total,
        activities: sections.activities.activities,
        activityTotal: sections.activities.pagination.total,
        alerts: sections.alerts.alerts,
        rules: sections.rules.rules,
      );
    } catch (_) {
      state = state.copyWith(
        isLoading: false,
        loadError: 'Wawasan tidak dapat dimuat.',
      );
    }
  }

  Future<void> setReportKind(ReportKind kind) async {
    if (kind == state.reportKind) return;
    final month = _currentMonth();
    state = state.copyWith(
      month: month,
      reportKind: kind,
      isReportLoading: true,
      actionMessage: null,
    );
    try {
      final report = await ref
          .read(insightsRepositoryProvider)
          .getReport(kind: kind, month: month);
      state = state.copyWith(isReportLoading: false, report: report);
    } catch (_) {
      state = state.copyWith(
        isReportLoading: false,
        actionError: 'Laporan tidak dapat dimuat.',
      );
    }
  }

  void clearActionMessage() {
    if (state.actionMessage == null) return;
    state = state.copyWith(actionMessage: null);
  }

  /// Generates the month CSV, hands the bytes to the platform share sheet, and
  /// only reports success once the user has actually shared/saved the file. The
  /// export-job history is refreshed regardless (the job is created server-side
  /// the moment the export runs).
  Future<void> exportCsv() async {
    final month = _currentMonth();
    state = state.copyWith(
      month: month,
      isSaving: true,
      actionError: null,
      actionMessage: null,
    );

    final repository = ref.read(insightsRepositoryProvider);
    late final CsvExportResult result;
    try {
      result = await repository.exportCsv(_monthExportRequest(month));
    } catch (_) {
      state = state.copyWith(
        isSaving: false,
        actionError: 'Ekspor CSV tidak dapat dibuat.',
      );
      return;
    }

    if (result.bytes.isEmpty) {
      state = state.copyWith(
        isSaving: false,
        actionError: 'Tidak ada transaksi yang bisa diekspor untuk bulan ini.',
      );
      return;
    }

    CsvShareOutcome outcome;
    try {
      outcome = await ref.read(csvShareServiceProvider).share(result);
    } catch (_) {
      await _refreshExportJobs(repository);
      state = state.copyWith(
        isSaving: false,
        actionError: 'Ekspor CSV berhasil dibuat tetapi tidak dapat dibagikan.',
      );
      return;
    }

    await _refreshExportJobs(repository);

    state = state.copyWith(
      isSaving: false,
      actionMessage: outcome == CsvShareOutcome.shared
          ? 'Ekspor CSV dibagikan.'
          : null,
      actionError: switch (outcome) {
        CsvShareOutcome.unavailable =>
          'Berbagi tidak tersedia di perangkat ini.',
        _ => null,
      },
    );
  }

  /// Reloads the export-job list and total after a CSV export completes.
  Future<void> _refreshExportJobs(InsightsRepository repository) async {
    try {
      final jobs = await repository.listExportJobs(
        limit: insightsPageSize,
        offset: 0,
      );
      state = state.copyWith(
        exportJobs: jobs.jobs,
        exportJobTotal: jobs.pagination.total,
      );
    } catch (_) {
      // Non-fatal: the export itself succeeded; the list refresh can be retried
      // by reloading the screen.
    }
  }

  /// Re-generates and shares the CSV for an already-completed export job using
  /// its stored date range. Returns the outcome so the detail sheet can show an
  /// inline error and stay open on failure. Does not mutate global insights
  /// state (the sheet owns its own busy/error UI).
  Future<CsvShareOutcome> shareExportJob(ExportJob job) async {
    final repository = ref.read(insightsRepositoryProvider);
    final result = await repository.exportCsv(
      ExportCsvRequest(from: job.fromAt, to: job.toAt),
    );
    if (result.bytes.isEmpty) {
      return CsvShareOutcome.empty;
    }
    return ref.read(csvShareServiceProvider).share(result);
  }

  /// Retries a FAILED export by re-running it with the same date range — the
  /// backend records a fresh job the moment the export runs, so this is a
  /// pure client-side re-create. The job list is refreshed either way so the
  /// new attempt (and its status) shows up immediately.
  Future<CsvShareOutcome> retryExportJob(ExportJob job) async {
    final repository = ref.read(insightsRepositoryProvider);
    try {
      final result = await repository.exportCsv(
        ExportCsvRequest(from: job.fromAt, to: job.toAt),
      );
      if (result.bytes.isEmpty) {
        return CsvShareOutcome.empty;
      }
      return await ref.read(csvShareServiceProvider).share(result);
    } finally {
      await _refreshExportJobs(repository);
    }
  }

  Future<void> updateRule(
    NotificationRule rule,
    NotificationRuleUpdate update,
  ) async {
    state = state.copyWith(
      // _fetchSections below reads state.month; keep it current across midnight.
      month: _currentMonth(),
      isSaving: true,
      actionError: null,
      actionMessage: null,
    );
    final repository = ref.read(insightsRepositoryProvider);
    late final NotificationRule updated;
    try {
      updated = await repository.updateNotificationRule(rule.id, update);
    } catch (_) {
      state = state.copyWith(
        isSaving: false,
        actionError: 'Aturan notifikasi tidak dapat diperbarui.',
      );
      return;
    }

    // A due-reminder toggle must reach the DEVICE scheduler too — otherwise
    // already-armed H-3/H-1 notifications keep firing after turning the rule
    // off (and turning it on arms nothing) until the next money mutation or
    // cold start. The scheduler re-plans from its last summary; when it has
    // none yet, refetching the summary triggers the same resync on success.
    if (updated.ruleKey == kDueReminderRuleKey) {
      if (!ref.read(notificationSchedulerProvider).resyncLatest()) {
        ref.invalidate(dashboardSummaryProvider);
      }
    }

    try {
      final sections = await _fetchSections(repository);
      state = state.copyWith(
        isSaving: false,
        report: sections.report,
        exportJobs: sections.exportJobs.jobs,
        exportJobTotal: sections.exportJobs.pagination.total,
        activities: sections.activities.activities,
        activityTotal: sections.activities.pagination.total,
        alerts: sections.alerts.alerts,
        rules: sections.rules.rules,
        actionMessage: 'Aturan notifikasi diperbarui.',
      );
    } catch (_) {
      state = state.copyWith(
        isSaving: false,
        rules: _replaceNotificationRule(state.rules, updated),
        actionError:
            'Aturan notifikasi diperbarui, tetapi wawasan tidak dapat disegarkan.',
      );
    }
  }

  Future<_InsightSections> _fetchSections(InsightsRepository repository) async {
    final reportFuture = repository.getReport(
      kind: state.reportKind,
      month: state.month,
    );
    final exportJobsFuture = repository.listExportJobs(
      limit: insightsPageSize,
      offset: 0,
    );
    final activitiesFuture = repository.listActivities(
      limit: insightsPageSize,
      offset: 0,
      sort: 'created_at_desc',
    );
    final alertsFuture = repository.listAlerts(month: state.month);
    final rulesFuture = repository.listNotificationRules();

    return _InsightSections(
      report: await reportFuture,
      exportJobs: await exportJobsFuture,
      activities: await activitiesFuture,
      alerts: await alertsFuture,
      rules: await rulesFuture,
    );
  }
}

class _InsightSections {
  const _InsightSections({
    required this.report,
    required this.exportJobs,
    required this.activities,
    required this.alerts,
    required this.rules,
  });

  final ReportResponse report;
  final ExportJobsResponse exportJobs;
  final ActivityListResponse activities;
  final AlertsResponse alerts;
  final NotificationRulesResponse rules;
}

List<NotificationRule> _replaceNotificationRule(
  List<NotificationRule> rules,
  NotificationRule updated,
) {
  var replaced = false;
  final nextRules = <NotificationRule>[];
  for (final current in rules) {
    if (current.id == updated.id) {
      nextRules.add(updated);
      replaced = true;
    } else {
      nextRules.add(current);
    }
  }
  if (!replaced) {
    nextRules.add(updated);
  }
  return nextRules;
}

class InsightsState {
  const InsightsState({
    required this.month,
    this.reportKind = ReportKind.overview,
    this.report = ReportResponse.empty,
    this.exportJobs = const [],
    this.exportJobTotal = 0,
    this.activities = const [],
    this.activityTotal = 0,
    this.alerts = const [],
    this.rules = const [],
    this.isLoading = false,
    this.isReportLoading = false,
    this.isSaving = false,
    this.loadError,
    this.actionError,
    this.actionMessage,
  });

  final String month;
  final ReportKind reportKind;
  final ReportResponse report;
  final List<ExportJob> exportJobs;
  final int exportJobTotal;
  final List<ActivityItem> activities;
  final int activityTotal;
  final List<InsightAlert> alerts;
  final List<NotificationRule> rules;
  final bool isLoading;
  final bool isReportLoading;
  final bool isSaving;
  final String? loadError;
  final String? actionError;
  final String? actionMessage;

  int get completedExportCount =>
      exportJobs.where((job) => job.status == ExportJobStatus.completed).length;

  int get enabledRuleCount => rules.where((rule) => rule.enabled).length;

  int get warningAlertCount => alerts
      .where(
        (alert) =>
            alert.severity == InsightSeverity.warning ||
            alert.severity == InsightSeverity.danger,
      )
      .length;

  InsightsState copyWith({
    String? month,
    ReportKind? reportKind,
    ReportResponse? report,
    List<ExportJob>? exportJobs,
    int? exportJobTotal,
    List<ActivityItem>? activities,
    int? activityTotal,
    List<InsightAlert>? alerts,
    List<NotificationRule>? rules,
    bool? isLoading,
    bool? isReportLoading,
    bool? isSaving,
    Object? loadError = kUnchanged,
    Object? actionError = kUnchanged,
    Object? actionMessage = kUnchanged,
  }) {
    return InsightsState(
      month: month ?? this.month,
      reportKind: reportKind ?? this.reportKind,
      report: report ?? this.report,
      exportJobs: exportJobs ?? this.exportJobs,
      exportJobTotal: exportJobTotal ?? this.exportJobTotal,
      activities: activities ?? this.activities,
      activityTotal: activityTotal ?? this.activityTotal,
      alerts: alerts ?? this.alerts,
      rules: rules ?? this.rules,
      isLoading: isLoading ?? this.isLoading,
      isReportLoading: isReportLoading ?? this.isReportLoading,
      isSaving: isSaving ?? this.isSaving,
      loadError: identical(loadError, kUnchanged)
          ? this.loadError
          : loadError as String?,
      actionError: identical(actionError, kUnchanged)
          ? this.actionError
          : actionError as String?,
      actionMessage: identical(actionMessage, kUnchanged)
          ? this.actionMessage
          : actionMessage as String?,
    );
  }
}

String _currentMonth() {
  return AffluenaDateFormatter.monthKey(DateTime.now());
}

ExportCsvRequest _monthExportRequest(String month) {
  final parts = month.split('-');
  final year = int.parse(parts[0]);
  final monthNumber = int.parse(parts[1]);
  // LOCAL month edges: the user exports their calendar month, so UTC edges
  // would drop 00:00–06:59 local transactions on the 1st (WIB) and leak the
  // next month's in. `.toUtc()` BEFORE `toIso8601String()` is load-bearing —
  // a local DateTime's ISO string carries no offset suffix and the API 400s
  // on it. The server's `to` bound is exclusive (`transaction_at < to`), so
  // the next month's first instant is the correct upper edge.
  final from = DateTime(year, monthNumber);
  final toExclusive = DateTime(year, monthNumber + 1);
  return ExportCsvRequest(
    from: from.toUtc().toIso8601String(),
    to: toExclusive.toUtc().toIso8601String(),
  );
}
