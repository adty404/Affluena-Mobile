import '../../../core/api/api_json.dart';
import '../../../core/api/pagination.dart';

enum ReportKind {
  overview('overview', 'Overview'),
  income('income', 'Income'),
  expense('expense', 'Expense'),
  cashflow('cashflow', 'Cashflow'),
  debt('debt', 'Debt'),
  goal('goal', 'Goal');

  const ReportKind(this.apiValue, this.label);

  final String apiValue;
  final String label;
}

enum ReportRowStatus {
  healthy,
  watch,
  critical,
  growth;

  static ReportRowStatus fromApiValue(String value) {
    return switch (value) {
      'healthy' => ReportRowStatus.healthy,
      'watch' => ReportRowStatus.watch,
      'critical' => ReportRowStatus.critical,
      'growth' => ReportRowStatus.growth,
      _ => throw FormatException('Unknown report status "$value".'),
    };
  }

  String get label {
    return switch (this) {
      ReportRowStatus.healthy => 'Healthy',
      ReportRowStatus.watch => 'Watch',
      ReportRowStatus.critical => 'Critical',
      ReportRowStatus.growth => 'Growth',
    };
  }
}

enum ExportJobStatus {
  completed,
  failed;

  static ExportJobStatus fromApiValue(String value) {
    return switch (value) {
      'completed' => ExportJobStatus.completed,
      'failed' => ExportJobStatus.failed,
      _ => throw FormatException('Unknown export status "$value".'),
    };
  }

  String get label {
    return switch (this) {
      ExportJobStatus.completed => 'Completed',
      ExportJobStatus.failed => 'Failed',
    };
  }
}

enum InsightSeverity {
  info,
  success,
  warning,
  danger;

  static InsightSeverity fromApiValue(String value) {
    return switch (value) {
      'info' => InsightSeverity.info,
      'success' => InsightSeverity.success,
      'warning' => InsightSeverity.warning,
      'danger' => InsightSeverity.danger,
      _ => throw FormatException('Unknown insight severity "$value".'),
    };
  }

  String get label {
    return switch (this) {
      InsightSeverity.info => 'Info',
      InsightSeverity.success => 'Success',
      InsightSeverity.warning => 'Warning',
      InsightSeverity.danger => 'Danger',
    };
  }
}

enum NotificationChannel {
  email('email', 'Email'),
  inApp('in-app', 'In-app'),
  both('both', 'Both');

  const NotificationChannel(this.apiValue, this.label);

  final String apiValue;
  final String label;

  static NotificationChannel fromApiValue(String value) {
    return switch (value) {
      'email' => NotificationChannel.email,
      'in-app' => NotificationChannel.inApp,
      'both' => NotificationChannel.both,
      _ => throw FormatException('Unknown notification channel "$value".'),
    };
  }
}

class ReportMetric {
  const ReportMetric({
    required this.id,
    required this.label,
    required this.valueMinor,
    required this.helper,
    required this.tone,
  });

  factory ReportMetric.fromJson(JsonMap json) {
    return ReportMetric(
      id: ApiJson.readString(json, 'id'),
      label: ApiJson.readString(json, 'label'),
      valueMinor: ApiJson.readInt(json, 'value_minor'),
      helper: ApiJson.readString(json, 'helper'),
      tone: ApiJson.readString(json, 'tone'),
    );
  }

  final String id;
  final String label;
  final int valueMinor;
  final String helper;
  final String tone;
}

class ReportRow {
  const ReportRow({
    required this.id,
    required this.name,
    required this.category,
    required this.amountMinor,
    required this.previousAmountMinor,
    required this.changePercent,
    required this.wallet,
    required this.status,
  });

  factory ReportRow.fromJson(JsonMap json) {
    return ReportRow(
      id: ApiJson.readString(json, 'id'),
      name: ApiJson.readString(json, 'name'),
      category: ApiJson.readString(json, 'category'),
      amountMinor: ApiJson.readInt(json, 'amount_minor'),
      previousAmountMinor: ApiJson.readInt(json, 'previous_amount_minor'),
      changePercent: ApiJson.readDouble(json, 'change_percent'),
      wallet: ApiJson.readString(json, 'wallet'),
      status: ReportRowStatus.fromApiValue(ApiJson.readString(json, 'status')),
    );
  }

  final String id;
  final String name;
  final String category;
  final int amountMinor;
  final int previousAmountMinor;
  final double changePercent;
  final String wallet;
  final ReportRowStatus status;
}

class ReportResponse {
  const ReportResponse({required this.metrics, required this.rows});

  factory ReportResponse.fromJson(JsonMap json) {
    return ReportResponse(
      metrics: ApiJson.readObjectList(
        json,
        'metrics',
      ).map(ReportMetric.fromJson).toList(growable: false),
      rows: ApiJson.readObjectList(
        json,
        'rows',
      ).map(ReportRow.fromJson).toList(growable: false),
    );
  }

  static const empty = ReportResponse(metrics: [], rows: []);

  final List<ReportMetric> metrics;
  final List<ReportRow> rows;
}

class ExportCsvRequest {
  const ExportCsvRequest({this.from, this.to});

  final String? from;
  final String? to;

  JsonMap toQuery() =>
      {'from': from, 'to': to}
        ..removeWhere((key, value) => value == null || value == '');
}

class CsvExportResult {
  const CsvExportResult({required this.bytes, required this.filename});

  final List<int> bytes;
  final String filename;
}

class ExportJob {
  const ExportJob({
    required this.id,
    required this.userId,
    required this.format,
    required this.fromAt,
    required this.toAt,
    required this.rowCount,
    required this.status,
    required this.createdAt,
  });

  factory ExportJob.fromJson(JsonMap json) {
    return ExportJob(
      id: ApiJson.readString(json, 'id'),
      userId: ApiJson.readString(json, 'user_id'),
      format: ApiJson.readString(json, 'format'),
      fromAt: ApiJson.nullableString(json, 'from_at'),
      toAt: ApiJson.nullableString(json, 'to_at'),
      rowCount: ApiJson.readInt(json, 'row_count'),
      status: ExportJobStatus.fromApiValue(ApiJson.readString(json, 'status')),
      createdAt: ApiJson.readString(json, 'created_at'),
    );
  }

  final String id;
  final String userId;
  final String format;
  final String? fromAt;
  final String? toAt;
  final int rowCount;
  final ExportJobStatus status;
  final String createdAt;
}

class ExportJobsResponse {
  const ExportJobsResponse({required this.jobs, required this.pagination});

  factory ExportJobsResponse.fromJson(JsonMap json) {
    return ExportJobsResponse(
      jobs: ApiJson.readObjectList(
        json,
        'jobs',
      ).map(ExportJob.fromJson).toList(growable: false),
      pagination: Pagination.fromJson(ApiJson.readMap(json, 'pagination')),
    );
  }

  final List<ExportJob> jobs;
  final Pagination pagination;
}

class ActivityItem {
  const ActivityItem({
    required this.id,
    required this.userId,
    required this.actionType,
    required this.entityType,
    required this.entityId,
    required this.description,
    required this.createdAt,
  });

  factory ActivityItem.fromJson(JsonMap json) {
    return ActivityItem(
      id: ApiJson.readString(json, 'id'),
      userId: ApiJson.readString(json, 'user_id'),
      actionType: ApiJson.readString(json, 'action_type'),
      entityType: ApiJson.readString(json, 'entity_type'),
      entityId: ApiJson.optionalString(json, 'entity_id'),
      description: ApiJson.readString(json, 'description'),
      createdAt: ApiJson.readString(json, 'created_at'),
    );
  }

  final String id;
  final String userId;
  final String actionType;
  final String entityType;
  final String entityId;
  final String description;
  final String createdAt;
}

class ActivityListResponse {
  const ActivityListResponse({
    required this.activities,
    required this.pagination,
  });

  factory ActivityListResponse.fromJson(JsonMap json) {
    return ActivityListResponse(
      activities: ApiJson.readObjectList(
        json,
        'data',
      ).map(ActivityItem.fromJson).toList(growable: false),
      pagination: Pagination.fromJson(ApiJson.readMap(json, 'pagination')),
    );
  }

  final List<ActivityItem> activities;
  final Pagination pagination;
}

class InsightAlert {
  const InsightAlert({
    required this.id,
    required this.type,
    required this.title,
    required this.module,
    required this.description,
    required this.severity,
    required this.createdAt,
    required this.actionPath,
  });

  factory InsightAlert.fromJson(JsonMap json) {
    return InsightAlert(
      id: ApiJson.readString(json, 'id'),
      type: ApiJson.readString(json, 'type'),
      title: ApiJson.readString(json, 'title'),
      module: ApiJson.readString(json, 'module'),
      description: ApiJson.readString(json, 'description'),
      severity: InsightSeverity.fromApiValue(
        ApiJson.readString(json, 'severity'),
      ),
      createdAt: ApiJson.readString(json, 'created_at'),
      actionPath: ApiJson.readString(json, 'action_path'),
    );
  }

  final String id;
  final String type;
  final String title;
  final String module;
  final String description;
  final InsightSeverity severity;
  final String createdAt;
  final String actionPath;
}

class AlertsResponse {
  const AlertsResponse({required this.alerts});

  factory AlertsResponse.fromJson(JsonMap json) {
    return AlertsResponse(
      alerts: ApiJson.readObjectList(
        json,
        'alerts',
      ).map(InsightAlert.fromJson).toList(growable: false),
    );
  }

  final List<InsightAlert> alerts;
}

class NotificationRule {
  const NotificationRule({
    required this.id,
    required this.userId,
    required this.ruleKey,
    required this.title,
    required this.description,
    required this.enabled,
    required this.channel,
    required this.tone,
    required this.createdAt,
    required this.updatedAt,
  });

  factory NotificationRule.fromJson(JsonMap json) {
    return NotificationRule(
      id: ApiJson.readString(json, 'id'),
      userId: ApiJson.readString(json, 'user_id'),
      ruleKey: ApiJson.readString(json, 'rule_key'),
      title: ApiJson.readString(json, 'title'),
      description: ApiJson.readString(json, 'description'),
      enabled: json['enabled'] == true,
      channel: NotificationChannel.fromApiValue(
        ApiJson.readString(json, 'channel'),
      ),
      tone: ApiJson.readString(json, 'tone'),
      createdAt: ApiJson.readString(json, 'created_at'),
      updatedAt: ApiJson.readString(json, 'updated_at'),
    );
  }

  final String id;
  final String userId;
  final String ruleKey;
  final String title;
  final String description;
  final bool enabled;
  final NotificationChannel channel;
  final String tone;
  final String createdAt;
  final String updatedAt;

  NotificationRule copyWith({bool? enabled, NotificationChannel? channel}) {
    return NotificationRule(
      id: id,
      userId: userId,
      ruleKey: ruleKey,
      title: title,
      description: description,
      enabled: enabled ?? this.enabled,
      channel: channel ?? this.channel,
      tone: tone,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }
}

class NotificationRulesResponse {
  const NotificationRulesResponse({required this.rules});

  factory NotificationRulesResponse.fromJson(JsonMap json) {
    return NotificationRulesResponse(
      rules: ApiJson.readObjectList(
        json,
        'rules',
      ).map(NotificationRule.fromJson).toList(growable: false),
    );
  }

  final List<NotificationRule> rules;
}

class NotificationRuleUpdate {
  const NotificationRuleUpdate({this.enabled, this.channel});

  final bool? enabled;
  final NotificationChannel? channel;

  JsonMap toJson() =>
      {'enabled': enabled, 'channel': channel?.apiValue}
        ..removeWhere((key, value) => value == null);
}
