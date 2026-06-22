import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_client.dart';
import '../../../core/api/api_json.dart';
import 'quick_entry_models.dart';

final quickEntryRepositoryProvider = Provider<QuickEntryRepository>((ref) {
  return DioQuickEntryRepository(ref.watch(dioProvider));
});

abstract interface class QuickEntryRepository {
  Future<QuickEntryTemplateListResponse> listTemplates({
    int? limit,
    int? offset,
    String? sort,
  });

  Future<QuickEntryTemplate> getTemplate(String id);

  Future<QuickEntryTemplate> createTemplate(QuickEntryTemplateRequest request);

  Future<QuickEntryTemplate> updateTemplate(
    String id,
    QuickEntryTemplateRequest request,
  );

  Future<void> deleteTemplate(String id);

  Future<ExecuteQuickEntryResponse> executeTemplate(
    String id,
    ExecuteQuickEntryRequest request,
  );
}

class DioQuickEntryRepository implements QuickEntryRepository {
  const DioQuickEntryRepository(this._dio);

  final Dio _dio;

  @override
  Future<QuickEntryTemplateListResponse> listTemplates({
    int? limit,
    int? offset,
    String? sort,
  }) async {
    final response = await _dio.get<Map<String, Object?>>(
      '/quick-entry-templates',
      queryParameters: _query({'limit': limit, 'offset': offset, 'sort': sort}),
    );
    return QuickEntryTemplateListResponse.fromJson(_responseMap(response.data));
  }

  @override
  Future<QuickEntryTemplate> getTemplate(String id) async {
    final response = await _dio.get<Map<String, Object?>>(
      '/quick-entry-templates/$id',
    );
    return QuickEntryTemplate.fromJson(_responseMap(response.data));
  }

  @override
  Future<QuickEntryTemplate> createTemplate(
    QuickEntryTemplateRequest request,
  ) async {
    final response = await _dio.post<Map<String, Object?>>(
      '/quick-entry-templates',
      data: request.toJson(),
    );
    return QuickEntryTemplate.fromJson(_responseMap(response.data));
  }

  @override
  Future<QuickEntryTemplate> updateTemplate(
    String id,
    QuickEntryTemplateRequest request,
  ) async {
    final response = await _dio.put<Map<String, Object?>>(
      '/quick-entry-templates/$id',
      data: request.toJson(),
    );
    return QuickEntryTemplate.fromJson(_responseMap(response.data));
  }

  @override
  Future<void> deleteTemplate(String id) async {
    await _dio.delete<void>('/quick-entry-templates/$id');
  }

  @override
  Future<ExecuteQuickEntryResponse> executeTemplate(
    String id,
    ExecuteQuickEntryRequest request,
  ) async {
    final response = await _dio.post<Map<String, Object?>>(
      '/quick-entry-templates/$id/execute',
      data: request.toJson(),
    );
    return ExecuteQuickEntryResponse.fromJson(_responseMap(response.data));
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
