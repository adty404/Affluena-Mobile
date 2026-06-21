import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/formatters/date_formatter.dart';
import '../data/insight_models.dart';
import '../data/insights_repository.dart';

const insightsPageSize = 20;

final insightsControllerProvider =
    NotifierProvider<InsightsController, InsightsState>(InsightsController.new);

enum InsightTab {
  reports('Reports'),
  exports('Exports'),
  alerts('Alerts'),
  activity('Activity'),
  rules('Rules');

  const InsightTab(this.label);

  final String label;
}

class InsightsController extends Notifier<InsightsState> {
  @override
  InsightsState build() {
    Future<void>.microtask(load);
    return InsightsState(month: _currentMonth());
  }

  Future<void> load() async {
    state = state.copyWith(
      isLoading: true,
      loadError: null,
      actionMessage: null,
    );
    try {
      final repository = ref.read(insightsRepositoryProvider);
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

      final report = await reportFuture;
      final exportJobs = await exportJobsFuture;
      final activities = await activitiesFuture;
      final alerts = await alertsFuture;
      final rules = await rulesFuture;

      state = state.copyWith(
        isLoading: false,
        report: report,
        exportJobs: exportJobs.jobs,
        exportJobTotal: exportJobs.pagination.total,
        activities: activities.activities,
        activityTotal: activities.pagination.total,
        alerts: alerts.alerts,
        rules: rules.rules,
      );
    } catch (_) {
      state = state.copyWith(
        isLoading: false,
        loadError: 'Insights could not be loaded.',
      );
    }
  }

  Future<void> setReportKind(ReportKind kind) async {
    if (kind == state.reportKind) return;
    state = state.copyWith(
      reportKind: kind,
      isReportLoading: true,
      actionMessage: null,
    );
    try {
      final report = await ref
          .read(insightsRepositoryProvider)
          .getReport(kind: kind, month: state.month);
      state = state.copyWith(isReportLoading: false, report: report);
    } catch (_) {
      state = state.copyWith(
        isReportLoading: false,
        actionError: 'Report could not be loaded.',
      );
    }
  }

  void setTab(InsightTab tab) {
    state = state.copyWith(selectedTab: tab, actionMessage: null);
  }

  Future<void> exportCsv() async {
    state = state.copyWith(
      isSaving: true,
      actionError: null,
      actionMessage: null,
    );
    try {
      final repository = ref.read(insightsRepositoryProvider);
      final request = _monthExportRequest(state.month);
      final result = await repository.exportCsv(request);
      final jobs = await repository.listExportJobs(
        limit: insightsPageSize,
        offset: 0,
      );
      state = state.copyWith(
        isSaving: false,
        selectedTab: InsightTab.exports,
        exportJobs: jobs.jobs,
        exportJobTotal: jobs.pagination.total,
        actionMessage: result.bytes.isEmpty
            ? 'CSV export generated'
            : 'CSV export generated',
      );
    } catch (_) {
      state = state.copyWith(
        isSaving: false,
        actionError: 'CSV export could not be generated.',
      );
    }
  }

  Future<void> updateRule(
    NotificationRule rule,
    NotificationRuleUpdate update,
  ) async {
    state = state.copyWith(
      isSaving: true,
      actionError: null,
      actionMessage: null,
    );
    try {
      final updated = await ref
          .read(insightsRepositoryProvider)
          .updateNotificationRule(rule.id, update);
      state = state.copyWith(
        isSaving: false,
        rules: [
          for (final current in state.rules)
            if (current.id == updated.id) updated else current,
        ],
        actionMessage: 'Notification rule updated.',
      );
    } catch (_) {
      state = state.copyWith(
        isSaving: false,
        actionError: 'Notification rule could not be updated.',
      );
    }
  }
}

class InsightsState {
  const InsightsState({
    required this.month,
    this.selectedTab = InsightTab.reports,
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
  final InsightTab selectedTab;
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
    InsightTab? selectedTab,
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
    Object? loadError = _unchanged,
    Object? actionError = _unchanged,
    Object? actionMessage = _unchanged,
  }) {
    return InsightsState(
      month: month ?? this.month,
      selectedTab: selectedTab ?? this.selectedTab,
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
      loadError: identical(loadError, _unchanged)
          ? this.loadError
          : loadError as String?,
      actionError: identical(actionError, _unchanged)
          ? this.actionError
          : actionError as String?,
      actionMessage: identical(actionMessage, _unchanged)
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
  final from = DateTime.utc(year, monthNumber);
  final to = DateTime.utc(
    year,
    monthNumber + 1,
  ).subtract(const Duration(milliseconds: 1));
  return ExportCsvRequest(
    from: from.toIso8601String(),
    to: to.toIso8601String(),
  );
}

const _unchanged = Object();
