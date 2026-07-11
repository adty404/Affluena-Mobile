import '../../../core/api/api_json.dart';
import '../../../core/api/pagination.dart';

enum TransactionType {
  income,
  expense,
  transfer,
  adjustment;

  String get apiValue => name;

  static TransactionType fromApiValue(String value) {
    return switch (value) {
      'income' => TransactionType.income,
      'expense' => TransactionType.expense,
      'transfer' => TransactionType.transfer,
      'adjustment' => TransactionType.adjustment,
      _ => throw FormatException('Unknown transaction type "$value".'),
    };
  }
}

class Transaction {
  const Transaction({
    required this.id,
    required this.userId,
    required this.type,
    required this.walletId,
    required this.amountMinor,
    required this.tagIds,
    required this.transactionAt,
    required this.note,
    required this.createdAt,
    required this.updatedAt,
    this.toWalletId,
    this.categoryId,
    this.feeMinor = 0,
  });

  factory Transaction.fromJson(JsonMap json) {
    return Transaction(
      id: ApiJson.readString(json, 'id'),
      userId: ApiJson.readString(json, 'user_id'),
      type: TransactionType.fromApiValue(ApiJson.readString(json, 'type')),
      walletId: ApiJson.readString(json, 'wallet_id'),
      toWalletId: ApiJson.nullableString(json, 'to_wallet_id'),
      categoryId: ApiJson.nullableString(json, 'category_id'),
      amountMinor: ApiJson.readInt(json, 'amount_minor'),
      // Optional transfer admin fee. Older rows and list responses may omit it,
      // so default to 0 when absent.
      feeMinor: ApiJson.optionalInt(json, 'fee_minor'),
      tagIds: ApiJson.readStringList(json, 'tag_ids'),
      transactionAt: ApiJson.readString(json, 'transaction_at'),
      note: ApiJson.optionalString(json, 'note'),
      createdAt: ApiJson.readString(json, 'created_at'),
      updatedAt: ApiJson.readString(json, 'updated_at'),
    );
  }

  final String id;
  final String userId;
  final TransactionType type;
  final String walletId;
  final String? toWalletId;
  final String? categoryId;
  final int amountMinor;

  /// Transfer admin fee in minor units (0 when none / not a transfer). The
  /// source wallet is charged `amountMinor + feeMinor`; the destination
  /// receives `amountMinor`, so the fee is a net-worth reduction.
  final int feeMinor;
  final List<String> tagIds;
  final String transactionAt;
  final String note;
  final String createdAt;
  final String updatedAt;
}

class TransactionListResponse {
  const TransactionListResponse({
    required this.transactions,
    required this.pagination,
  });

  factory TransactionListResponse.fromJson(JsonMap json) {
    return TransactionListResponse(
      transactions: ApiJson.readObjectList(
        json,
        'transactions',
      ).map(Transaction.fromJson).toList(growable: false),
      pagination: Pagination.fromJson(ApiJson.readMap(json, 'pagination')),
    );
  }

  final List<Transaction> transactions;
  final Pagination pagination;
}

class TransactionRequest {
  const TransactionRequest({
    required this.type,
    required this.walletId,
    required this.amountMinor,
    required this.transactionAt,
    this.toWalletId,
    this.categoryId,
    this.tagIds = const [],
    this.note,
    this.feeMinor = 0,
  });

  final TransactionType type;
  final String walletId;
  final String? toWalletId;
  final String? categoryId;
  final int amountMinor;
  final List<String> tagIds;
  final String transactionAt;
  final String? note;

  /// Optional transfer admin fee in minor units. Only meaningful for a
  /// transfer (the source wallet is charged `amountMinor + feeMinor`); never
  /// sent for expense/income/adjustment. Defaults to 0 = no fee.
  final int feeMinor;

  JsonMap toJson() => {
    'type': type.apiValue,
    'wallet_id': walletId,
    if (toWalletId != null) 'to_wallet_id': toWalletId,
    if (categoryId != null) 'category_id': categoryId,
    'amount_minor': amountMinor,
    // Only a transfer carries an admin fee, and only when it is > 0.
    if (type == TransactionType.transfer && feeMinor > 0) 'fee_minor': feeMinor,
    'tag_ids': tagIds,
    'transaction_at': transactionAt,
    if (note != null) 'note': note,
  };
}

class SplitTransactionRequest {
  const SplitTransactionRequest({
    required this.walletId,
    required this.totalAmountMinor,
    required this.splits,
    this.categoryId,
    this.transactionAt,
    this.note,
    this.tagIds = const [],
  });

  final String walletId;
  final String? categoryId;
  final int totalAmountMinor;
  final String? transactionAt;
  final String? note;
  final List<String> tagIds;
  final List<TransactionSplit> splits;

  JsonMap toJson() => {
    'wallet_id': walletId,
    if (categoryId != null) 'category_id': categoryId,
    'total_amount_minor': totalAmountMinor,
    if (transactionAt != null) 'transaction_at': transactionAt,
    if (note != null) 'note': note,
    'tag_ids': tagIds,
    'splits': splits.map((split) => split.toJson()).toList(growable: false),
  };
}

class TransactionSplit {
  const TransactionSplit({
    required this.counterpartyName,
    required this.amountMinor,
    required this.disbursementCategoryId,
    required this.paymentCategoryId,
  });

  final String counterpartyName;
  final int amountMinor;
  final String disbursementCategoryId;
  final String paymentCategoryId;

  JsonMap toJson() => {
    'counterparty_name': counterpartyName,
    'amount_minor': amountMinor,
    'disbursement_category_id': disbursementCategoryId,
    'payment_category_id': paymentCategoryId,
  };
}

class SplitTransactionResponse {
  const SplitTransactionResponse({
    required this.transactionId,
    required this.debtIds,
  });

  factory SplitTransactionResponse.fromJson(JsonMap json) {
    return SplitTransactionResponse(
      transactionId: ApiJson.readString(json, 'transaction_id'),
      debtIds: ApiJson.readStringList(json, 'debt_ids'),
    );
  }

  final String transactionId;
  final List<String> debtIds;
}
