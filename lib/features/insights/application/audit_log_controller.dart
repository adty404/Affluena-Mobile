import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/insight_models.dart';
import '../data/insights_repository.dart';

const auditLogPageSize = 20;

final auditLogControllerProvider =
    NotifierProvider<AuditLogController, AuditLogState>(AuditLogController.new);

enum AuditLogTab {
  activity('Aktivitas'),
  system('Log sistem');

  const AuditLogTab(this.label);

  final String label;
}

class AuditLogController extends Notifier<AuditLogState> {
  @override
  AuditLogState build() {
    Future<void>.microtask(load);
    return const AuditLogState();
  }

  Future<void> load() async {
    state = state.copyWith(isLoading: true, loadError: null);
    try {
      final repository = ref.read(insightsRepositoryProvider);
      final sections = await Future.wait<Object>([
        repository.listActivities(
          limit: auditLogPageSize,
          offset: 0,
          sort: 'created_at_desc',
        ),
        repository.listSystemLogs(limit: auditLogPageSize),
      ]);
      final activities = sections[0] as ActivityListResponse;
      final systemLogs = sections[1] as SystemLogsResponse;

      state = state.copyWith(
        isLoading: false,
        activities: activities.activities,
        activityTotal: activities.pagination.total,
        systemLogs: systemLogs.logs,
      );
    } catch (_) {
      state = state.copyWith(
        isLoading: false,
        loadError: 'Log audit tidak dapat dimuat.',
      );
    }
  }

  void setTab(AuditLogTab tab) {
    if (state.selectedTab == tab) return;
    state = state.copyWith(selectedTab: tab);
  }
}

class AuditLogState {
  const AuditLogState({
    this.selectedTab = AuditLogTab.activity,
    this.activities = const [],
    this.activityTotal = 0,
    this.systemLogs = const [],
    this.isLoading = false,
    this.loadError,
  });

  final AuditLogTab selectedTab;
  final List<ActivityItem> activities;
  final int activityTotal;
  final List<SystemLog> systemLogs;
  final bool isLoading;
  final String? loadError;

  int get systemLogTotal => systemLogs.length;

  AuditLogState copyWith({
    AuditLogTab? selectedTab,
    List<ActivityItem>? activities,
    int? activityTotal,
    List<SystemLog>? systemLogs,
    bool? isLoading,
    Object? loadError = _unchanged,
  }) {
    return AuditLogState(
      selectedTab: selectedTab ?? this.selectedTab,
      activities: activities ?? this.activities,
      activityTotal: activityTotal ?? this.activityTotal,
      systemLogs: systemLogs ?? this.systemLogs,
      isLoading: isLoading ?? this.isLoading,
      loadError: identical(loadError, _unchanged)
          ? this.loadError
          : loadError as String?,
    );
  }
}

const _unchanged = Object();
