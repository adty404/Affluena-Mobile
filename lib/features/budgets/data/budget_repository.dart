import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_client.dart';
import '../../../core/api/api_json.dart';
import 'budget_models.dart';

final budgetRepositoryProvider = Provider<BudgetRepository>((ref) {
  return DioBudgetRepository(ref.watch(dioProvider));
});

abstract interface class BudgetRepository {
  Future<BudgetListResponse> listBudgets({
    String? month,
    int? limit,
    int? offset,
    String? sort,
  });

  Future<Budget> getBudget(String id);

  Future<Budget> createBudget(BudgetRequest request);

  Future<Budget> updateBudget(String id, BudgetRequest request);

  Future<void> deleteBudget(String id);

  Future<BudgetAlertsResponse> getAlerts({String? month});

  Future<BudgetReportResponse> getReport({String? month});
}

class DioBudgetRepository implements BudgetRepository {
  const DioBudgetRepository(this._dio);

  final Dio _dio;

  @override
  Future<BudgetListResponse> listBudgets({
    String? month,
    int? limit,
    int? offset,
    String? sort,
  }) async {
    final response = await _dio.get<Map<String, Object?>>(
      '/category-budgets',
      queryParameters: _query({
        'month': month,
        'limit': limit,
        'offset': offset,
        'sort': sort,
      }),
    );
    return BudgetListResponse.fromJson(_responseMap(response.data));
  }

  @override
  Future<Budget> getBudget(String id) async {
    final response = await _dio.get<Map<String, Object?>>(
      '/category-budgets/$id',
    );
    return Budget.fromJson(_responseMap(response.data));
  }

  @override
  Future<Budget> createBudget(BudgetRequest request) async {
    final response = await _dio.post<Map<String, Object?>>(
      '/category-budgets',
      data: request.toJson(),
    );
    return Budget.fromJson(_responseMap(response.data));
  }

  @override
  Future<Budget> updateBudget(String id, BudgetRequest request) async {
    final response = await _dio.put<Map<String, Object?>>(
      '/category-budgets/$id',
      data: request.toJson(),
    );
    return Budget.fromJson(_responseMap(response.data));
  }

  @override
  Future<void> deleteBudget(String id) async {
    await _dio.delete<void>('/category-budgets/$id');
  }

  @override
  Future<BudgetAlertsResponse> getAlerts({String? month}) async {
    final response = await _dio.get<Map<String, Object?>>(
      '/category-budgets/alerts',
      queryParameters: _query({'month': month}),
    );
    return BudgetAlertsResponse.fromJson(_responseMap(response.data));
  }

  @override
  Future<BudgetReportResponse> getReport({String? month}) async {
    final response = await _dio.get<Map<String, Object?>>(
      '/category-budgets/report',
      queryParameters: _query({'month': month}),
    );
    return BudgetReportResponse.fromJson(_responseMap(response.data));
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
