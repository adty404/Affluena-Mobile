import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_client.dart';
import '../../../core/api/api_json.dart';
import 'tag_models.dart';

final tagRepositoryProvider = Provider<TagRepository>((ref) {
  return DioTagRepository(ref.watch(dioProvider));
});

abstract interface class TagRepository {
  Future<TagListResponse> listTags({int? limit, int? offset, String? sort});

  Future<Tag> createTag(TagRequest request);

  Future<Tag> getTag(String id);

  Future<Tag> updateTag(String id, TagRequest request);

  Future<void> deleteTag(String id);
}

class DioTagRepository implements TagRepository {
  const DioTagRepository(this._dio);

  final Dio _dio;

  @override
  Future<TagListResponse> listTags({
    int? limit,
    int? offset,
    String? sort,
  }) async {
    final response = await _dio.get<Map<String, Object?>>(
      '/tags',
      queryParameters: _query({'limit': limit, 'offset': offset, 'sort': sort}),
    );
    return TagListResponse.fromJson(_responseMap(response.data));
  }

  @override
  Future<Tag> createTag(TagRequest request) async {
    final response = await _dio.post<Map<String, Object?>>(
      '/tags',
      data: request.toJson(),
    );
    return Tag.fromJson(_responseMap(response.data));
  }

  @override
  Future<Tag> getTag(String id) async {
    final response = await _dio.get<Map<String, Object?>>('/tags/$id');
    return Tag.fromJson(_responseMap(response.data));
  }

  @override
  Future<Tag> updateTag(String id, TagRequest request) async {
    final response = await _dio.put<Map<String, Object?>>(
      '/tags/$id',
      data: request.toJson(),
    );
    return Tag.fromJson(_responseMap(response.data));
  }

  @override
  Future<void> deleteTag(String id) async {
    await _dio.delete<void>('/tags/$id');
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
