import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_client.dart';
import '../../../core/api/api_json.dart';
import 'recurring_models.dart';

final recurringRepositoryProvider = Provider<RecurringRepository>((ref) {
  return DioRecurringRepository(ref.watch(dioProvider));
});

abstract interface class RecurringRepository {
  Future<RecurringRuleListResponse> listRules({
    int? limit,
    int? offset,
    String? sort,
  });

  Future<RecurringRule> getRule(String id);

  Future<RecurringRule> createRule(RecurringRuleRequest request);

  Future<RecurringRule> updateRule(String id, RecurringRuleRequest request);

  Future<void> deleteRule(String id);

  Future<RecurringRun> runRule(String id);
}

class DioRecurringRepository implements RecurringRepository {
  const DioRecurringRepository(this._dio);

  final Dio _dio;

  @override
  Future<RecurringRuleListResponse> listRules({
    int? limit,
    int? offset,
    String? sort,
  }) async {
    final response = await _dio.get<Map<String, Object?>>(
      '/recurring-transactions',
      queryParameters: _query({'limit': limit, 'offset': offset, 'sort': sort}),
    );
    return RecurringRuleListResponse.fromJson(_responseMap(response.data));
  }

  @override
  Future<RecurringRule> getRule(String id) async {
    final response = await _dio.get<Map<String, Object?>>(
      '/recurring-transactions/$id',
    );
    return RecurringRule.fromJson(_responseMap(response.data));
  }

  @override
  Future<RecurringRule> createRule(RecurringRuleRequest request) async {
    final response = await _dio.post<Map<String, Object?>>(
      '/recurring-transactions',
      data: request.toJson(),
    );
    return RecurringRule.fromJson(_responseMap(response.data));
  }

  @override
  Future<RecurringRule> updateRule(
    String id,
    RecurringRuleRequest request,
  ) async {
    final response = await _dio.put<Map<String, Object?>>(
      '/recurring-transactions/$id',
      data: request.toJson(),
    );
    return RecurringRule.fromJson(_responseMap(response.data));
  }

  @override
  Future<void> deleteRule(String id) async {
    await _dio.delete<void>('/recurring-transactions/$id');
  }

  @override
  Future<RecurringRun> runRule(String id) async {
    final response = await _dio.post<Map<String, Object?>>(
      '/recurring-transactions/$id/run',
      data: const <String, Object?>{},
    );
    return RecurringRun.fromJson(_responseMap(response.data));
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
