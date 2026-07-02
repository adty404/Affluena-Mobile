import '../../../core/api/api_json.dart';
import '../../../core/api/pagination.dart';

enum RecurringType {
  income,
  expense,
  transfer,
  adjustment;

  String get apiValue => name;

  String get label => switch (this) {
    RecurringType.income => 'Pemasukan',
    RecurringType.expense => 'Pengeluaran',
    RecurringType.transfer => 'Transfer',
    RecurringType.adjustment => 'Penyesuaian',
  };

  static RecurringType fromApiValue(String value) {
    return switch (value) {
      'income' => RecurringType.income,
      'expense' => RecurringType.expense,
      'transfer' => RecurringType.transfer,
      'adjustment' => RecurringType.adjustment,
      _ => throw FormatException('Unknown recurring type "$value".'),
    };
  }
}

enum RecurringFrequency {
  weekly,
  monthly;

  String get apiValue => name;

  String get label => switch (this) {
    RecurringFrequency.weekly => 'Mingguan',
    RecurringFrequency.monthly => 'Bulanan',
  };

  static RecurringFrequency fromApiValue(String value) {
    return switch (value) {
      'weekly' => RecurringFrequency.weekly,
      'monthly' => RecurringFrequency.monthly,
      _ => throw FormatException('Unknown recurring frequency "$value".'),
    };
  }
}

enum RecurringStatus {
  active,
  paused,
  cancelled;

  String get apiValue => name;

  String get label => switch (this) {
    RecurringStatus.active => 'Aktif',
    RecurringStatus.paused => 'Dijeda',
    RecurringStatus.cancelled => 'Dibatalkan',
  };

  static RecurringStatus fromApiValue(String value) {
    return switch (value) {
      'active' => RecurringStatus.active,
      'paused' => RecurringStatus.paused,
      'cancelled' => RecurringStatus.cancelled,
      _ => throw FormatException('Unknown recurring status "$value".'),
    };
  }
}

enum RecurringRunType {
  manual,
  scheduled;

  String get apiValue => name;

  static RecurringRunType fromApiValue(String value) {
    return switch (value) {
      'manual' => RecurringRunType.manual,
      'scheduled' => RecurringRunType.scheduled,
      _ => throw FormatException('Unknown recurring run type "$value".'),
    };
  }
}

class RecurringRule {
  const RecurringRule({
    required this.id,
    required this.userId,
    required this.name,
    required this.type,
    required this.walletId,
    required this.toWalletId,
    required this.categoryId,
    required this.amountMinor,
    required this.frequency,
    required this.intervalCount,
    required this.nextRunAt,
    required this.endAt,
    required this.lastRunAt,
    required this.status,
    required this.note,
    required this.createdAt,
    required this.updatedAt,
    this.color = '',
    this.icon = '',
  });

  factory RecurringRule.fromJson(JsonMap json) {
    return RecurringRule(
      id: ApiJson.readString(json, 'id'),
      userId: ApiJson.readString(json, 'user_id'),
      name: ApiJson.readString(json, 'name'),
      type: RecurringType.fromApiValue(ApiJson.readString(json, 'type')),
      walletId: ApiJson.readString(json, 'wallet_id'),
      toWalletId: ApiJson.nullableString(json, 'to_wallet_id'),
      categoryId: ApiJson.nullableString(json, 'category_id'),
      amountMinor: ApiJson.readInt(json, 'amount_minor'),
      frequency: RecurringFrequency.fromApiValue(
        ApiJson.readString(json, 'frequency'),
      ),
      intervalCount: ApiJson.readInt(json, 'interval_count'),
      nextRunAt: ApiJson.readString(json, 'next_run_at'),
      endAt: ApiJson.nullableString(json, 'end_at'),
      lastRunAt: ApiJson.nullableString(json, 'last_run_at'),
      status: RecurringStatus.fromApiValue(ApiJson.readString(json, 'status')),
      note: ApiJson.optionalString(json, 'note'),
      // Appearance fields are a recent API addition; parse defensively so a
      // backend without them (or with nulls) still yields "no color".
      color: ApiJson.optionalString(json, 'color'),
      icon: ApiJson.optionalString(json, 'icon'),
      createdAt: ApiJson.readString(json, 'created_at'),
      updatedAt: ApiJson.readString(json, 'updated_at'),
    );
  }

  final String id;
  final String userId;
  final String name;
  final RecurringType type;
  final String walletId;
  final String? toWalletId;
  final String? categoryId;
  final int amountMinor;
  final RecurringFrequency frequency;
  final int intervalCount;
  final String nextRunAt;
  final String? endAt;
  final String? lastRunAt;
  final RecurringStatus status;
  final String note;
  final String color;
  final String icon;
  final String createdAt;
  final String updatedAt;

  bool get canRun => status == RecurringStatus.active;

  /// Natural-language cadence, e.g. "Monthly", "Every 2 weeks", "Every 3
  /// months" — never the machine-ish "Monthly every 1".
  String get frequencyLabel {
    final unit = switch (frequency) {
      RecurringFrequency.weekly => 'week',
      RecurringFrequency.monthly => 'month',
    };
    if (intervalCount <= 1) {
      return frequency.label; // "Weekly" / "Monthly"
    }
    return 'Every $intervalCount ${unit}s'; // "Every 2 weeks"
  }

  RecurringRule copyForRequest({
    required String id,
    required String name,
    required String? categoryId,
    required int amountMinor,
  }) {
    return RecurringRule(
      id: id,
      userId: userId,
      name: name,
      type: type,
      walletId: walletId,
      toWalletId: toWalletId,
      categoryId: categoryId,
      amountMinor: amountMinor,
      frequency: frequency,
      intervalCount: intervalCount,
      nextRunAt: nextRunAt,
      endAt: endAt,
      lastRunAt: lastRunAt,
      status: status,
      note: note,
      color: color,
      icon: icon,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }
}

class RecurringRun {
  const RecurringRun({
    required this.id,
    required this.ruleId,
    required this.userId,
    required this.scheduledFor,
    required this.transactionId,
    required this.runType,
    required this.createdAt,
  });

  factory RecurringRun.fromJson(JsonMap json) {
    return RecurringRun(
      id: ApiJson.readString(json, 'id'),
      ruleId: ApiJson.readString(json, 'rule_id'),
      userId: ApiJson.readString(json, 'user_id'),
      scheduledFor: ApiJson.readString(json, 'scheduled_for'),
      transactionId: ApiJson.nullableString(json, 'transaction_id'),
      runType: RecurringRunType.fromApiValue(
        ApiJson.readString(json, 'run_type'),
      ),
      createdAt: ApiJson.readString(json, 'created_at'),
    );
  }

  final String id;
  final String ruleId;
  final String userId;
  final String scheduledFor;
  final String? transactionId;
  final RecurringRunType runType;
  final String createdAt;
}

class RecurringRuleListResponse {
  const RecurringRuleListResponse({
    required this.rules,
    required this.pagination,
  });

  factory RecurringRuleListResponse.fromJson(JsonMap json) {
    return RecurringRuleListResponse(
      rules: ApiJson.readObjectList(
        json,
        'recurring_transactions',
      ).map(RecurringRule.fromJson).toList(growable: false),
      pagination: Pagination.fromJson(ApiJson.readMap(json, 'pagination')),
    );
  }

  final List<RecurringRule> rules;
  final Pagination pagination;
}

class RecurringRuleRequest {
  const RecurringRuleRequest({
    required this.name,
    required this.type,
    required this.walletId,
    required this.amountMinor,
    required this.frequency,
    required this.intervalCount,
    required this.nextRunAt,
    this.toWalletId,
    this.categoryId,
    this.endAt,
    this.status,
    this.note,
    this.color,
    this.icon,
  });

  final String name;
  final RecurringType type;
  final String walletId;
  final String? toWalletId;
  final String? categoryId;
  final int amountMinor;
  final RecurringFrequency frequency;
  final int intervalCount;
  final String nextRunAt;
  final String? endAt;
  final RecurringStatus? status;
  final String? note;
  final String? color;
  final String? icon;

  JsonMap toJson() => {
    'name': name,
    'type': type.apiValue,
    'wallet_id': walletId,
    if (toWalletId != null && toWalletId!.isNotEmpty)
      'to_wallet_id': toWalletId,
    if (categoryId != null && categoryId!.isNotEmpty) 'category_id': categoryId,
    'amount_minor': amountMinor,
    'frequency': frequency.apiValue,
    'interval_count': intervalCount,
    'next_run_at': nextRunAt,
    if (endAt != null && endAt!.isNotEmpty) 'end_at': endAt,
    if (status != null) 'status': status!.apiValue,
    if (note != null) 'note': note,
    if (color != null) 'color': color,
    if (icon != null) 'icon': icon,
  };
}
