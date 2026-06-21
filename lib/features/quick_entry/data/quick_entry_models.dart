import '../../../core/api/api_json.dart';
import '../../../core/api/pagination.dart';
import '../../transactions/data/transaction_models.dart';

class QuickEntryTemplate {
  const QuickEntryTemplate({
    required this.id,
    required this.userId,
    required this.name,
    required this.type,
    required this.walletId,
    required this.amountMinor,
    required this.note,
    required this.createdAt,
    required this.updatedAt,
    this.toWalletId,
    this.categoryId,
    this.tagIds = const [],
  });

  factory QuickEntryTemplate.fromJson(JsonMap json) {
    return QuickEntryTemplate(
      id: ApiJson.readString(json, 'id'),
      userId: ApiJson.readString(json, 'user_id'),
      name: ApiJson.readString(json, 'name'),
      type: TransactionType.fromApiValue(ApiJson.readString(json, 'type')),
      walletId: ApiJson.readString(json, 'wallet_id'),
      toWalletId: ApiJson.nullableString(json, 'to_wallet_id'),
      categoryId: ApiJson.nullableString(json, 'category_id'),
      amountMinor: ApiJson.readInt(json, 'amount_minor'),
      note: ApiJson.optionalString(json, 'note'),
      tagIds: ApiJson.readStringList(json, 'tag_ids'),
      createdAt: ApiJson.readString(json, 'created_at'),
      updatedAt: ApiJson.readString(json, 'updated_at'),
    );
  }

  final String id;
  final String userId;
  final String name;
  final TransactionType type;
  final String walletId;
  final String? toWalletId;
  final String? categoryId;
  final int amountMinor;
  final String note;
  final List<String> tagIds;
  final String createdAt;
  final String updatedAt;
}

class QuickEntryTemplateListResponse {
  const QuickEntryTemplateListResponse({
    required this.templates,
    required this.pagination,
  });

  factory QuickEntryTemplateListResponse.fromJson(JsonMap json) {
    return QuickEntryTemplateListResponse(
      templates: ApiJson.readObjectList(
        json,
        'templates',
      ).map(QuickEntryTemplate.fromJson).toList(growable: false),
      pagination: Pagination.fromJson(ApiJson.readMap(json, 'pagination')),
    );
  }

  final List<QuickEntryTemplate> templates;
  final Pagination pagination;
}

class QuickEntryTemplateRequest {
  const QuickEntryTemplateRequest({
    required this.name,
    required this.type,
    required this.walletId,
    required this.amountMinor,
    this.toWalletId,
    this.categoryId,
    this.note,
    this.tagIds = const [],
  });

  final String name;
  final TransactionType type;
  final String walletId;
  final String? toWalletId;
  final String? categoryId;
  final int amountMinor;
  final String? note;
  final List<String> tagIds;

  JsonMap toJson() => {
    'name': name,
    'type': type.apiValue,
    'wallet_id': walletId,
    if (toWalletId != null) 'to_wallet_id': toWalletId,
    if (categoryId != null) 'category_id': categoryId,
    'amount_minor': amountMinor,
    if (note != null) 'note': note,
    'tag_ids': tagIds,
  };
}

class ExecuteQuickEntryRequest {
  const ExecuteQuickEntryRequest({this.transactionAt, this.note});

  final String? transactionAt;
  final String? note;

  JsonMap toJson() => {
    if (transactionAt != null) 'transaction_at': transactionAt,
    if (note != null) 'note': note,
  };
}

class ExecuteQuickEntryResponse {
  const ExecuteQuickEntryResponse({required this.transaction});

  factory ExecuteQuickEntryResponse.fromJson(JsonMap json) {
    return ExecuteQuickEntryResponse(
      transaction: Transaction.fromJson(ApiJson.readMap(json, 'transaction')),
    );
  }

  final Transaction transaction;
}
