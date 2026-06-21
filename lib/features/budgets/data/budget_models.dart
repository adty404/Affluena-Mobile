import '../../../core/api/api_json.dart';
import '../../../core/api/pagination.dart';

enum BudgetSeverity {
  warning,
  danger;

  static BudgetSeverity fromApiValue(String value) {
    return switch (value) {
      'warning' => BudgetSeverity.warning,
      'danger' => BudgetSeverity.danger,
      _ => throw FormatException('Unknown budget severity "$value".'),
    };
  }
}

class Budget {
  const Budget({
    required this.id,
    required this.userId,
    required this.categoryId,
    required this.month,
    required this.limitMinor,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Budget.fromJson(JsonMap json) {
    return Budget(
      id: ApiJson.readString(json, 'id'),
      userId: ApiJson.readString(json, 'user_id'),
      categoryId: ApiJson.readString(json, 'category_id'),
      month: ApiJson.readString(json, 'month'),
      limitMinor: ApiJson.readInt(json, 'limit_minor'),
      createdAt: ApiJson.readString(json, 'created_at'),
      updatedAt: ApiJson.readString(json, 'updated_at'),
    );
  }

  final String id;
  final String userId;
  final String categoryId;
  final String month;
  final int limitMinor;
  final String createdAt;
  final String updatedAt;
}

class BudgetSummary extends Budget {
  const BudgetSummary({
    required super.id,
    required super.userId,
    required super.categoryId,
    required super.month,
    required super.limitMinor,
    required super.createdAt,
    required super.updatedAt,
    required this.spentMinor,
    required this.remainingMinor,
    required this.usagePercent,
  });

  factory BudgetSummary.fromJson(JsonMap json) {
    return BudgetSummary(
      id: ApiJson.readString(json, 'id'),
      userId: ApiJson.readString(json, 'user_id'),
      categoryId: ApiJson.readString(json, 'category_id'),
      month: ApiJson.readString(json, 'month'),
      limitMinor: ApiJson.readInt(json, 'limit_minor'),
      spentMinor: ApiJson.readInt(json, 'spent_minor'),
      remainingMinor: ApiJson.readInt(json, 'remaining_minor'),
      usagePercent: ApiJson.readDouble(json, 'usage_percent'),
      createdAt: ApiJson.readString(json, 'created_at'),
      updatedAt: ApiJson.readString(json, 'updated_at'),
    );
  }

  final int spentMinor;
  final int remainingMinor;
  final double usagePercent;
}

class BudgetListResponse {
  const BudgetListResponse({required this.budgets, required this.pagination});

  factory BudgetListResponse.fromJson(JsonMap json) {
    return BudgetListResponse(
      budgets: ApiJson.readObjectList(
        json,
        'budgets',
      ).map(BudgetSummary.fromJson).toList(growable: false),
      pagination: Pagination.fromJson(ApiJson.readMap(json, 'pagination')),
    );
  }

  final List<BudgetSummary> budgets;
  final Pagination pagination;
}

class BudgetRequest {
  const BudgetRequest({
    required this.categoryId,
    required this.month,
    required this.limitMinor,
  });

  final String categoryId;
  final String month;
  final int limitMinor;

  JsonMap toJson() => {
    'category_id': categoryId,
    'month': month,
    'limit_minor': limitMinor,
  };
}

class BudgetAlert {
  const BudgetAlert({
    required this.id,
    required this.budgetId,
    required this.categoryId,
    required this.categoryName,
    required this.title,
    required this.message,
    required this.threshold,
    required this.severity,
    required this.usagePercent,
    required this.spentMinor,
    required this.limitMinor,
    required this.month,
    this.notifiedAt,
  });

  factory BudgetAlert.fromJson(JsonMap json) {
    return BudgetAlert(
      id: ApiJson.readString(json, 'id'),
      budgetId: ApiJson.readString(json, 'budget_id'),
      categoryId: ApiJson.readString(json, 'category_id'),
      categoryName: ApiJson.readString(json, 'category_name'),
      title: ApiJson.readString(json, 'title'),
      message: ApiJson.readString(json, 'message'),
      threshold: ApiJson.readInt(json, 'threshold'),
      severity: BudgetSeverity.fromApiValue(
        ApiJson.readString(json, 'severity'),
      ),
      usagePercent: ApiJson.readDouble(json, 'usage_percent'),
      spentMinor: ApiJson.readInt(json, 'spent_minor'),
      limitMinor: ApiJson.readInt(json, 'limit_minor'),
      notifiedAt: ApiJson.nullableString(json, 'notified_at'),
      month: ApiJson.readString(json, 'month'),
    );
  }

  final String id;
  final String budgetId;
  final String categoryId;
  final String categoryName;
  final String title;
  final String message;
  final int threshold;
  final BudgetSeverity severity;
  final double usagePercent;
  final int spentMinor;
  final int limitMinor;
  final String? notifiedAt;
  final String month;
}

class BudgetAlertsResponse {
  const BudgetAlertsResponse({required this.alerts});

  factory BudgetAlertsResponse.fromJson(JsonMap json) {
    return BudgetAlertsResponse(
      alerts: ApiJson.readObjectList(
        json,
        'alerts',
      ).map(BudgetAlert.fromJson).toList(growable: false),
    );
  }

  final List<BudgetAlert> alerts;
}

class BudgetReportItem extends BudgetSummary {
  const BudgetReportItem({
    required super.id,
    required super.userId,
    required super.categoryId,
    required super.month,
    required super.limitMinor,
    required super.createdAt,
    required super.updatedAt,
    required super.spentMinor,
    required super.remainingMinor,
    required super.usagePercent,
    required this.varianceMinor,
    required this.dailyAllowanceMinor,
    required this.recommendation,
  });

  factory BudgetReportItem.fromJson(JsonMap json) {
    return BudgetReportItem(
      id: ApiJson.readString(json, 'id'),
      userId: ApiJson.readString(json, 'user_id'),
      categoryId: ApiJson.readString(json, 'category_id'),
      month: ApiJson.readString(json, 'month'),
      limitMinor: ApiJson.readInt(json, 'limit_minor'),
      spentMinor: ApiJson.readInt(json, 'spent_minor'),
      remainingMinor: ApiJson.readInt(json, 'remaining_minor'),
      usagePercent: ApiJson.readDouble(json, 'usage_percent'),
      varianceMinor: ApiJson.readInt(json, 'variance_minor'),
      dailyAllowanceMinor: ApiJson.readInt(json, 'daily_allowance_minor'),
      recommendation: ApiJson.readString(json, 'recommendation'),
      createdAt: ApiJson.readString(json, 'created_at'),
      updatedAt: ApiJson.readString(json, 'updated_at'),
    );
  }

  final int varianceMinor;
  final int dailyAllowanceMinor;
  final String recommendation;
}

class BudgetReportSummary {
  const BudgetReportSummary({
    required this.totalLimitMinor,
    required this.totalSpentMinor,
    required this.totalRemainingMinor,
    required this.safeCount,
    required this.warningCount,
    required this.exceededCount,
    required this.dailyAllowanceMinor,
    required this.forecastMinor,
  });

  factory BudgetReportSummary.fromJson(JsonMap json) {
    return BudgetReportSummary(
      totalLimitMinor: ApiJson.readInt(json, 'total_limit_minor'),
      totalSpentMinor: ApiJson.readInt(json, 'total_spent_minor'),
      totalRemainingMinor: ApiJson.readInt(json, 'total_remaining_minor'),
      safeCount: ApiJson.readInt(json, 'safe_count'),
      warningCount: ApiJson.readInt(json, 'warning_count'),
      exceededCount: ApiJson.readInt(json, 'exceeded_count'),
      dailyAllowanceMinor: ApiJson.readInt(json, 'daily_allowance_minor'),
      forecastMinor: ApiJson.readInt(json, 'forecast_minor'),
    );
  }

  final int totalLimitMinor;
  final int totalSpentMinor;
  final int totalRemainingMinor;
  final int safeCount;
  final int warningCount;
  final int exceededCount;
  final int dailyAllowanceMinor;
  final int forecastMinor;
}

class BudgetReportResponse {
  const BudgetReportResponse({required this.report, required this.summary});

  factory BudgetReportResponse.fromJson(JsonMap json) {
    return BudgetReportResponse(
      report: ApiJson.readObjectList(
        json,
        'report',
      ).map(BudgetReportItem.fromJson).toList(growable: false),
      summary: BudgetReportSummary.fromJson(ApiJson.readMap(json, 'summary')),
    );
  }

  final List<BudgetReportItem> report;
  final BudgetReportSummary summary;
}
