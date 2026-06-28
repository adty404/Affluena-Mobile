import '../../../core/api/api_json.dart';
import '../../../core/api/pagination.dart';

enum CategoryType {
  income,
  expense;

  String get apiValue => name;

  /// Human-readable label for UI surfaces. Never leak the raw lowercase enum
  /// value ('income'/'expense') as user-facing copy.
  String get label => switch (this) {
    CategoryType.income => 'Pemasukan',
    CategoryType.expense => 'Pengeluaran',
  };

  static CategoryType fromApiValue(String value) {
    return switch (value) {
      'income' => CategoryType.income,
      'expense' => CategoryType.expense,
      _ => throw FormatException('Unknown category type "$value".'),
    };
  }
}

class Category {
  const Category({
    required this.id,
    required this.userId,
    required this.name,
    required this.type,
    required this.createdAt,
    required this.updatedAt,
    this.parentId,
  });

  factory Category.fromJson(JsonMap json) {
    return Category(
      id: ApiJson.readString(json, 'id'),
      userId: ApiJson.readString(json, 'user_id'),
      parentId: ApiJson.nullableString(json, 'parent_id'),
      name: ApiJson.readString(json, 'name'),
      type: CategoryType.fromApiValue(ApiJson.readString(json, 'type')),
      createdAt: ApiJson.readString(json, 'created_at'),
      updatedAt: ApiJson.readString(json, 'updated_at'),
    );
  }

  final String id;
  final String userId;
  final String? parentId;
  final String name;
  final CategoryType type;
  final String createdAt;
  final String updatedAt;
}

class CategoryListResponse {
  const CategoryListResponse({
    required this.categories,
    required this.pagination,
  });

  factory CategoryListResponse.fromJson(JsonMap json) {
    return CategoryListResponse(
      categories: ApiJson.readObjectList(
        json,
        'categories',
      ).map(Category.fromJson).toList(growable: false),
      pagination: Pagination.fromJson(ApiJson.readMap(json, 'pagination')),
    );
  }

  final List<Category> categories;
  final Pagination pagination;
}

class CategoryRequest {
  const CategoryRequest({
    required this.name,
    required this.type,
    this.parentId,
  });

  final String name;
  final CategoryType type;
  final String? parentId;

  JsonMap toJson() => {
    'name': name,
    'type': type.apiValue,
    if (parentId != null) 'parent_id': parentId,
  };
}
