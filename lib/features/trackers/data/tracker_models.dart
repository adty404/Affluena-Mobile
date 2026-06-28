import '../../../core/api/api_json.dart';
import '../../../core/api/pagination.dart';

enum InstallmentStatus {
  active,
  paidOff,
  cancelled;

  String get apiValue => switch (this) {
    InstallmentStatus.paidOff => 'paid_off',
    _ => name,
  };

  String get label => switch (this) {
    InstallmentStatus.active => 'Aktif',
    InstallmentStatus.paidOff => 'Lunas',
    InstallmentStatus.cancelled => 'Dibatalkan',
  };

  static InstallmentStatus fromApiValue(String value) {
    return switch (value) {
      'active' => InstallmentStatus.active,
      'paid_off' || 'paid' => InstallmentStatus.paidOff,
      'cancelled' => InstallmentStatus.cancelled,
      _ => throw FormatException('Unknown installment status "$value".'),
    };
  }
}

enum SubscriptionStatus {
  active,
  paused,
  cancelled;

  String get apiValue => name;

  String get label => switch (this) {
    SubscriptionStatus.active => 'Aktif',
    SubscriptionStatus.paused => 'Dijeda',
    SubscriptionStatus.cancelled => 'Dibatalkan',
  };

  static SubscriptionStatus fromApiValue(String value) {
    return switch (value) {
      'active' => SubscriptionStatus.active,
      'paused' => SubscriptionStatus.paused,
      'cancelled' => SubscriptionStatus.cancelled,
      _ => throw FormatException('Unknown subscription status "$value".'),
    };
  }
}

enum BillingCycle {
  weekly,
  monthly;

  String get apiValue => name;

  String get label => switch (this) {
    BillingCycle.weekly => 'Mingguan',
    BillingCycle.monthly => 'Bulanan',
  };

  static BillingCycle fromApiValue(String value) {
    return switch (value) {
      'weekly' => BillingCycle.weekly,
      'monthly' => BillingCycle.monthly,
      _ => throw FormatException('Unknown billing cycle "$value".'),
    };
  }
}

class Installment {
  const Installment({
    required this.id,
    required this.userId,
    required this.name,
    required this.walletId,
    required this.categoryId,
    required this.totalAmountMinor,
    required this.monthlyAmountMinor,
    required this.tenorMonths,
    required this.remainingMonths,
    required this.startDate,
    required this.dueDay,
    required this.status,
    required this.note,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Installment.fromJson(JsonMap json) {
    return Installment(
      id: ApiJson.readString(json, 'id'),
      userId: ApiJson.readString(json, 'user_id'),
      name: ApiJson.readString(json, 'name'),
      walletId: ApiJson.readString(json, 'wallet_id'),
      categoryId: ApiJson.readString(json, 'category_id'),
      totalAmountMinor: ApiJson.readInt(json, 'total_amount_minor'),
      monthlyAmountMinor: ApiJson.readInt(json, 'monthly_amount_minor'),
      tenorMonths: ApiJson.readInt(json, 'tenor_months'),
      remainingMonths: ApiJson.readInt(json, 'remaining_months'),
      startDate: ApiJson.readString(json, 'start_date'),
      dueDay: ApiJson.readInt(json, 'due_day'),
      status: InstallmentStatus.fromApiValue(
        ApiJson.readString(json, 'status'),
      ),
      note: ApiJson.optionalString(json, 'note'),
      createdAt: ApiJson.readString(json, 'created_at'),
      updatedAt: ApiJson.readString(json, 'updated_at'),
    );
  }

  final String id;
  final String userId;
  final String name;
  final String walletId;
  final String categoryId;
  final int totalAmountMinor;
  final int monthlyAmountMinor;
  final int tenorMonths;
  final int remainingMonths;
  final String startDate;
  final int dueDay;
  final InstallmentStatus status;
  final String note;
  final String createdAt;
  final String updatedAt;

  bool get canPay => status == InstallmentStatus.active && remainingMonths > 0;

  double get paidPercent {
    if (tenorMonths <= 0) return 0;
    final paid = tenorMonths - remainingMonths;
    return (paid / tenorMonths * 100).clamp(0, 100);
  }
}

class InstallmentPayment {
  const InstallmentPayment({
    required this.id,
    required this.userId,
    required this.installmentId,
    required this.transactionId,
    required this.amountMinor,
    required this.paidAt,
    required this.note,
    required this.createdAt,
  });

  factory InstallmentPayment.fromJson(JsonMap json) {
    return InstallmentPayment(
      id: ApiJson.readString(json, 'id'),
      userId: ApiJson.readString(json, 'user_id'),
      installmentId: ApiJson.readString(json, 'installment_id'),
      transactionId: ApiJson.readString(json, 'transaction_id'),
      amountMinor: ApiJson.readInt(json, 'amount_minor'),
      paidAt: ApiJson.readString(json, 'paid_at'),
      note: ApiJson.optionalString(json, 'note'),
      createdAt: ApiJson.readString(json, 'created_at'),
    );
  }

  final String id;
  final String userId;
  final String installmentId;
  final String transactionId;
  final int amountMinor;
  final String paidAt;
  final String note;
  final String createdAt;
}

class Subscription {
  const Subscription({
    required this.id,
    required this.userId,
    required this.name,
    required this.accountDetail,
    required this.walletId,
    required this.categoryId,
    required this.amountMinor,
    required this.billingCycle,
    required this.nextDueDate,
    required this.status,
    required this.note,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Subscription.fromJson(JsonMap json) {
    return Subscription(
      id: ApiJson.readString(json, 'id'),
      userId: ApiJson.readString(json, 'user_id'),
      name: ApiJson.readString(json, 'name'),
      accountDetail: ApiJson.optionalString(json, 'account_detail'),
      walletId: ApiJson.readString(json, 'wallet_id'),
      categoryId: ApiJson.readString(json, 'category_id'),
      amountMinor: ApiJson.readInt(json, 'amount_minor'),
      billingCycle: BillingCycle.fromApiValue(
        ApiJson.readString(json, 'billing_cycle'),
      ),
      nextDueDate: ApiJson.readString(json, 'next_due_date'),
      status: SubscriptionStatus.fromApiValue(
        ApiJson.readString(json, 'status'),
      ),
      note: ApiJson.optionalString(json, 'note'),
      createdAt: ApiJson.readString(json, 'created_at'),
      updatedAt: ApiJson.readString(json, 'updated_at'),
    );
  }

  final String id;
  final String userId;
  final String name;
  final String accountDetail;
  final String walletId;
  final String categoryId;
  final int amountMinor;
  final BillingCycle billingCycle;
  final String nextDueDate;
  final SubscriptionStatus status;
  final String note;
  final String createdAt;
  final String updatedAt;

  bool get canPay => status == SubscriptionStatus.active;
}

class SubscriptionPayment {
  const SubscriptionPayment({
    required this.id,
    required this.userId,
    required this.subscriptionId,
    required this.transactionId,
    required this.amountMinor,
    required this.paidAt,
    required this.note,
    required this.createdAt,
  });

  factory SubscriptionPayment.fromJson(JsonMap json) {
    return SubscriptionPayment(
      id: ApiJson.readString(json, 'id'),
      userId: ApiJson.readString(json, 'user_id'),
      subscriptionId: ApiJson.readString(json, 'subscription_id'),
      transactionId: ApiJson.readString(json, 'transaction_id'),
      amountMinor: ApiJson.readInt(json, 'amount_minor'),
      paidAt: ApiJson.readString(json, 'paid_at'),
      note: ApiJson.optionalString(json, 'note'),
      createdAt: ApiJson.readString(json, 'created_at'),
    );
  }

  final String id;
  final String userId;
  final String subscriptionId;
  final String transactionId;
  final int amountMinor;
  final String paidAt;
  final String note;
  final String createdAt;
}

class InstallmentListResponse {
  const InstallmentListResponse({
    required this.installments,
    required this.pagination,
  });

  factory InstallmentListResponse.fromJson(JsonMap json) {
    return InstallmentListResponse(
      installments: ApiJson.readObjectList(
        json,
        'installments',
      ).map(Installment.fromJson).toList(growable: false),
      pagination: Pagination.fromJson(ApiJson.readMap(json, 'pagination')),
    );
  }

  final List<Installment> installments;
  final Pagination pagination;
}

class SubscriptionListResponse {
  const SubscriptionListResponse({
    required this.subscriptions,
    required this.pagination,
  });

  factory SubscriptionListResponse.fromJson(JsonMap json) {
    return SubscriptionListResponse(
      subscriptions: ApiJson.readObjectList(
        json,
        'subscriptions',
      ).map(Subscription.fromJson).toList(growable: false),
      pagination: Pagination.fromJson(ApiJson.readMap(json, 'pagination')),
    );
  }

  final List<Subscription> subscriptions;
  final Pagination pagination;
}

class InstallmentRequest {
  const InstallmentRequest({
    required this.name,
    required this.walletId,
    required this.categoryId,
    required this.totalAmountMinor,
    required this.monthlyAmountMinor,
    required this.tenorMonths,
    required this.startDate,
    required this.dueDay,
    this.remainingMonths,
    this.status,
    this.note,
  });

  final String name;
  final String walletId;
  final String categoryId;
  final int totalAmountMinor;
  final int monthlyAmountMinor;
  final int tenorMonths;
  final int? remainingMonths;
  final String startDate;
  final int dueDay;
  final InstallmentStatus? status;
  final String? note;

  JsonMap toJson() => {
    'name': name,
    'wallet_id': walletId,
    'category_id': categoryId,
    'total_amount_minor': totalAmountMinor,
    'monthly_amount_minor': monthlyAmountMinor,
    'tenor_months': tenorMonths,
    if (remainingMonths != null) 'remaining_months': remainingMonths,
    'start_date': startDate,
    'due_day': dueDay,
    if (status != null) 'status': status!.apiValue,
    if (note != null) 'note': note,
  };
}

class SubscriptionRequest {
  const SubscriptionRequest({
    required this.name,
    required this.walletId,
    required this.categoryId,
    required this.amountMinor,
    required this.billingCycle,
    required this.nextDueDate,
    this.accountDetail,
    this.status,
    this.note,
  });

  final String name;
  final String? accountDetail;
  final String walletId;
  final String categoryId;
  final int amountMinor;
  final BillingCycle billingCycle;
  final String nextDueDate;
  final SubscriptionStatus? status;
  final String? note;

  JsonMap toJson() => {
    'name': name,
    if (accountDetail != null) 'account_detail': accountDetail,
    'wallet_id': walletId,
    'category_id': categoryId,
    'amount_minor': amountMinor,
    'billing_cycle': billingCycle.apiValue,
    'next_due_date': nextDueDate,
    if (status != null) 'status': status!.apiValue,
    if (note != null) 'note': note,
  };
}

class TrackerPaymentRequest {
  const TrackerPaymentRequest({this.paidAt, this.note});

  final String? paidAt;
  final String? note;

  JsonMap toJson() => {
    if (paidAt != null && paidAt!.isNotEmpty) 'paid_at': paidAt,
    if (note != null) 'note': note,
  };
}
