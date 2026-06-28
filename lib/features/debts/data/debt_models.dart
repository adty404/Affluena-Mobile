import '../../../core/api/api_json.dart';
import '../../../core/api/pagination.dart';

enum DebtType {
  payable,
  receivable;

  String get apiValue => name;

  static DebtType fromApiValue(String value) {
    return switch (value) {
      'payable' => DebtType.payable,
      'receivable' => DebtType.receivable,
      _ => throw FormatException('Unknown debt type "$value".'),
    };
  }
}

enum DebtStatus {
  open,
  partial,
  paidOff,
  cancelled;

  String get apiValue {
    return switch (this) {
      DebtStatus.paidOff => 'paid_off',
      _ => name,
    };
  }

  String get label {
    return switch (this) {
      DebtStatus.open => 'Terbuka',
      DebtStatus.partial => 'Sebagian',
      DebtStatus.paidOff => 'Lunas',
      DebtStatus.cancelled => 'Dibatalkan',
    };
  }

  static DebtStatus fromApiValue(String value) {
    return switch (value) {
      'open' => DebtStatus.open,
      'partial' => DebtStatus.partial,
      'paid_off' || 'paid' => DebtStatus.paidOff,
      'cancelled' => DebtStatus.cancelled,
      _ => throw FormatException('Unknown debt status "$value".'),
    };
  }
}

class Debt {
  const Debt({
    required this.id,
    required this.userId,
    required this.type,
    required this.counterpartyName,
    required this.walletId,
    required this.disbursementCategoryId,
    required this.paymentCategoryId,
    required this.originationTransactionId,
    required this.principalAmountMinor,
    required this.paidAmountMinor,
    required this.remainingAmountMinor,
    required this.openedAt,
    required this.status,
    required this.note,
    required this.createdAt,
    required this.updatedAt,
    this.dueDate,
    this.payments = const [],
  });

  factory Debt.fromJson(JsonMap json) {
    return Debt(
      id: ApiJson.readString(json, 'id'),
      userId: ApiJson.readString(json, 'user_id'),
      type: DebtType.fromApiValue(ApiJson.readString(json, 'type')),
      counterpartyName: ApiJson.readString(json, 'counterparty_name'),
      walletId: ApiJson.readString(json, 'wallet_id'),
      disbursementCategoryId: ApiJson.readString(
        json,
        'disbursement_category_id',
      ),
      paymentCategoryId: ApiJson.readString(json, 'payment_category_id'),
      originationTransactionId: ApiJson.readString(
        json,
        'origination_transaction_id',
      ),
      principalAmountMinor: ApiJson.readInt(json, 'principal_amount_minor'),
      paidAmountMinor: ApiJson.readInt(json, 'paid_amount_minor'),
      remainingAmountMinor: ApiJson.readInt(json, 'remaining_amount_minor'),
      openedAt: ApiJson.readString(json, 'opened_at'),
      dueDate: ApiJson.nullableString(json, 'due_date'),
      status: DebtStatus.fromApiValue(ApiJson.readString(json, 'status')),
      note: ApiJson.optionalString(json, 'note'),
      createdAt: ApiJson.readString(json, 'created_at'),
      updatedAt: ApiJson.readString(json, 'updated_at'),
      payments: ApiJson.readObjectList({
        'payments': json['payments'] ?? const [],
      }, 'payments').map(DebtPayment.fromJson).toList(growable: false),
    );
  }

  final String id;
  final String userId;
  final DebtType type;
  final String counterpartyName;
  final String walletId;
  final String disbursementCategoryId;
  final String paymentCategoryId;
  final String originationTransactionId;
  final int principalAmountMinor;
  final int paidAmountMinor;
  final int remainingAmountMinor;
  final String openedAt;
  final String? dueDate;
  final DebtStatus status;
  final String note;
  final String createdAt;
  final String updatedAt;
  final List<DebtPayment> payments;

  bool get canPay =>
      status != DebtStatus.paidOff &&
      status != DebtStatus.cancelled &&
      remainingAmountMinor > 0;

  double get paidPercent {
    if (principalAmountMinor <= 0) return 0;
    return (paidAmountMinor / principalAmountMinor * 100).clamp(0, 100);
  }
}

class DebtPayment {
  const DebtPayment({
    required this.id,
    required this.userId,
    required this.debtId,
    required this.transactionId,
    required this.amountMinor,
    required this.paidAt,
    required this.note,
    required this.createdAt,
  });

  factory DebtPayment.fromJson(JsonMap json) {
    return DebtPayment(
      id: ApiJson.readString(json, 'id'),
      userId: ApiJson.readString(json, 'user_id'),
      debtId: ApiJson.readString(json, 'debt_id'),
      transactionId: ApiJson.readString(json, 'transaction_id'),
      amountMinor: ApiJson.readInt(json, 'amount_minor'),
      paidAt: ApiJson.readString(json, 'paid_at'),
      note: ApiJson.optionalString(json, 'note'),
      createdAt: ApiJson.readString(json, 'created_at'),
    );
  }

  final String id;
  final String userId;
  final String debtId;
  final String transactionId;
  final int amountMinor;
  final String paidAt;
  final String note;
  final String createdAt;
}

class DebtListResponse {
  const DebtListResponse({required this.debts, required this.pagination});

  factory DebtListResponse.fromJson(JsonMap json) {
    return DebtListResponse(
      debts: ApiJson.readObjectList(
        json,
        'debts',
      ).map(Debt.fromJson).toList(growable: false),
      pagination: Pagination.fromJson(ApiJson.readMap(json, 'pagination')),
    );
  }

  final List<Debt> debts;
  final Pagination pagination;
}

class DebtRequest {
  const DebtRequest({
    required this.type,
    required this.counterpartyName,
    required this.walletId,
    required this.disbursementCategoryId,
    required this.paymentCategoryId,
    required this.principalAmountMinor,
    this.openedAt,
    this.dueDate,
    this.note,
  });

  final DebtType type;
  final String counterpartyName;
  final String walletId;
  final String disbursementCategoryId;
  final String paymentCategoryId;
  final int principalAmountMinor;
  final String? openedAt;
  final String? dueDate;
  final String? note;

  JsonMap toJson() => {
    'type': type.apiValue,
    'counterparty_name': counterpartyName,
    'wallet_id': walletId,
    'disbursement_category_id': disbursementCategoryId,
    'payment_category_id': paymentCategoryId,
    'principal_amount_minor': principalAmountMinor,
    if (openedAt != null && openedAt!.isNotEmpty) 'opened_at': openedAt,
    if (dueDate != null && dueDate!.isNotEmpty) 'due_date': dueDate,
    if (note != null) 'note': note,
  };
}

class DebtUpdateRequest {
  const DebtUpdateRequest({
    required this.counterpartyName,
    this.dueDate,
    this.status,
    this.note,
  });

  final String counterpartyName;
  final String? dueDate;
  final DebtStatus? status;
  final String? note;

  JsonMap toJson() => {
    'counterparty_name': counterpartyName,
    if (dueDate != null && dueDate!.isNotEmpty) 'due_date': dueDate,
    if (status != null) 'status': status!.apiValue,
    if (note != null) 'note': note,
  };
}

class DebtPaymentRequest {
  const DebtPaymentRequest({required this.amountMinor, this.paidAt, this.note});

  final int amountMinor;
  final String? paidAt;
  final String? note;

  JsonMap toJson() => {
    'amount_minor': amountMinor,
    if (paidAt != null && paidAt!.isNotEmpty) 'paid_at': paidAt,
    if (note != null) 'note': note,
  };
}
