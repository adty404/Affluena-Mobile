import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_client.dart';
import '../../../core/api/api_json.dart';
import 'category_models.dart';

final categoryRepositoryProvider = Provider<CategoryRepository>((ref) {
  return DioCategoryRepository(ref.watch(dioProvider));
});

abstract interface class CategoryRepository {
  Future<CategoryListResponse> listCategories({
    CategoryType? type,
    int? limit,
    int? offset,
    String? sort,
  });

  Future<Category> createCategory(CategoryRequest request);

  Future<Category> getCategory(String id);

  Future<Category> updateCategory(String id, CategoryRequest request);

  Future<void> deleteCategory(String id);
}

class DioCategoryRepository implements CategoryRepository {
  const DioCategoryRepository(this._dio);

  final Dio _dio;

  @override
  Future<CategoryListResponse> listCategories({
    CategoryType? type,
    int? limit,
    int? offset,
    String? sort,
  }) async {
    final response = await _dio.get<Map<String, Object?>>(
      '/categories',
      queryParameters: _query({
        'type': type?.apiValue,
        'limit': limit,
        'offset': offset,
        'sort': sort,
      }),
    );
    return CategoryListResponse.fromJson(_responseMap(response.data));
  }

  @override
  Future<Category> createCategory(CategoryRequest request) async {
    final response = await _dio.post<Map<String, Object?>>(
      '/categories',
      data: request.toJson(),
    );
    return Category.fromJson(_responseMap(response.data));
  }

  @override
  Future<Category> getCategory(String id) async {
    final response = await _dio.get<Map<String, Object?>>('/categories/$id');
    return Category.fromJson(_responseMap(response.data));
  }

  @override
  Future<Category> updateCategory(String id, CategoryRequest request) async {
    final response = await _dio.put<Map<String, Object?>>(
      '/categories/$id',
      data: request.toJson(),
    );
    return Category.fromJson(_responseMap(response.data));
  }

  @override
  Future<void> deleteCategory(String id) async {
    await _dio.delete<void>('/categories/$id');
  }
}

Map<String, Object?> _query(Map<String, Object?> values) {
  return Map<String, Object?>.from(values)
    ..removeWhere((key, value) => value == null);
}

JsonMap _responseMap(Object? data) {
  if (data is Map<String, Object?>) return data;
  if (data is Map) return Map<String, Object?>.from(data);
  throw const FormatException('Expected response body to be an object.');
}
