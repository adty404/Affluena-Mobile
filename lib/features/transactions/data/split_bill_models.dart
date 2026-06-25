import '../../../core/api/api_json.dart';

/// Summary of one split bill (an origination expense transaction plus its
/// receivable debts), as returned by GET /split-bills.
class SplitBillSummary {
  const SplitBillSummary({
    required this.transactionId,
    required this.note,
    required this.totalAmountMinor,
    required this.transactionAt,
    required this.participantCount,
    required this.settledCount,
    required this.totalOwedMinor,
    required this.totalRemainingMinor,
    required this.status,
  });

  factory SplitBillSummary.fromJson(JsonMap json) {
    return SplitBillSummary(
      transactionId: ApiJson.readString(json, 'transaction_id'),
      note: ApiJson.optionalString(json, 'note'),
      totalAmountMinor: ApiJson.readInt(json, 'total_amount_minor'),
      transactionAt: ApiJson.readString(json, 'transaction_at'),
      participantCount: ApiJson.readInt(json, 'participant_count'),
      settledCount: ApiJson.readInt(json, 'settled_count'),
      totalOwedMinor: ApiJson.readInt(json, 'total_owed_minor'),
      totalRemainingMinor: ApiJson.readInt(json, 'total_remaining_minor'),
      status: ApiJson.readString(json, 'status'),
    );
  }

  final String transactionId;
  final String note;
  final int totalAmountMinor;
  final String transactionAt;
  final int participantCount;
  final int settledCount;
  final int totalOwedMinor;
  final int totalRemainingMinor;
  final String status;

  bool get isOngoing => status == 'ongoing';
}

class SplitBillListResponse {
  const SplitBillListResponse({required this.splitBills});

  factory SplitBillListResponse.fromJson(JsonMap json) {
    return SplitBillListResponse(
      splitBills: ApiJson.readObjectList(
        json,
        'split_bills',
      ).map(SplitBillSummary.fromJson).toList(growable: false),
    );
  }

  final List<SplitBillSummary> splitBills;
}

class SplitBillParticipant {
  const SplitBillParticipant({
    required this.debtId,
    required this.counterpartyName,
    required this.principalAmountMinor,
    required this.paidAmountMinor,
    required this.remainingAmountMinor,
    required this.status,
    this.dueDate,
  });

  factory SplitBillParticipant.fromJson(JsonMap json) {
    return SplitBillParticipant(
      debtId: ApiJson.readString(json, 'debt_id'),
      counterpartyName: ApiJson.readString(json, 'counterparty_name'),
      principalAmountMinor: ApiJson.readInt(json, 'principal_amount_minor'),
      paidAmountMinor: ApiJson.readInt(json, 'paid_amount_minor'),
      remainingAmountMinor: ApiJson.readInt(json, 'remaining_amount_minor'),
      status: ApiJson.readString(json, 'status'),
      dueDate: ApiJson.nullableString(json, 'due_date'),
    );
  }

  final String debtId;
  final String counterpartyName;
  final int principalAmountMinor;
  final int paidAmountMinor;
  final int remainingAmountMinor;
  final String status;
  final String? dueDate;
}

class SplitBillDetail {
  const SplitBillDetail({
    required this.transactionId,
    required this.note,
    required this.totalAmountMinor,
    required this.transactionAt,
    required this.participantCount,
    required this.settledCount,
    required this.totalOwedMinor,
    required this.totalRemainingMinor,
    required this.status,
    required this.participants,
  });

  factory SplitBillDetail.fromJson(JsonMap json) {
    return SplitBillDetail(
      transactionId: ApiJson.readString(json, 'transaction_id'),
      note: ApiJson.optionalString(json, 'note'),
      totalAmountMinor: ApiJson.readInt(json, 'total_amount_minor'),
      transactionAt: ApiJson.readString(json, 'transaction_at'),
      participantCount: ApiJson.readInt(json, 'participant_count'),
      settledCount: ApiJson.readInt(json, 'settled_count'),
      totalOwedMinor: ApiJson.readInt(json, 'total_owed_minor'),
      totalRemainingMinor: ApiJson.readInt(json, 'total_remaining_minor'),
      status: ApiJson.readString(json, 'status'),
      participants: ApiJson.readObjectList(
        json,
        'participants',
      ).map(SplitBillParticipant.fromJson).toList(growable: false),
    );
  }

  final String transactionId;
  final String note;
  final int totalAmountMinor;
  final String transactionAt;
  final int participantCount;
  final int settledCount;
  final int totalOwedMinor;
  final int totalRemainingMinor;
  final String status;
  final List<SplitBillParticipant> participants;

  bool get isOngoing => status == 'ongoing';
}
