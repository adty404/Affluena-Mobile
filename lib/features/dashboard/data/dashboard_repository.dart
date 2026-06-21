import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_client.dart';
import '../../../core/api/api_json.dart';
import 'dashboard_models.dart';

final dashboardRepositoryProvider = Provider<DashboardRepository>((ref) {
  return DioDashboardRepository(ref.watch(dioProvider));
});

abstract interface class DashboardRepository {
  Future<DashboardSummary> summary({String? month});

  Future<CashflowTrendResponse> cashflowTrend({int? months});

  Future<ExpenseDistributionResponse> expenseDistribution({String? month});

  Future<DashboardForecast> forecast({String? month});
}

class DioDashboardRepository implements DashboardRepository {
  const DioDashboardRepository(this._dio);

  final Dio _dio;

  @override
  Future<DashboardSummary> summary({String? month}) async {
    final response = await _dio.get<Map<String, Object?>>(
      '/dashboard/summary',
      queryParameters: _query({'month': month}),
    );
    return DashboardSummary.fromJson(_responseMap(response.data));
  }

  @override
  Future<CashflowTrendResponse> cashflowTrend({int? months}) async {
    final response = await _dio.get<Map<String, Object?>>(
      '/dashboard/cashflow-trend',
      queryParameters: _query({'months': months}),
    );
    return CashflowTrendResponse.fromJson(_responseMap(response.data));
  }

  @override
  Future<ExpenseDistributionResponse> expenseDistribution({
    String? month,
  }) async {
    final response = await _dio.get<Map<String, Object?>>(
      '/dashboard/expense-distribution',
      queryParameters: _query({'month': month}),
    );
    return ExpenseDistributionResponse.fromJson(_responseMap(response.data));
  }

  @override
  Future<DashboardForecast> forecast({String? month}) async {
    final response = await _dio.get<Map<String, Object?>>(
      '/dashboard/forecast',
      queryParameters: _query({'month': month}),
    );
    return DashboardForecast.fromJson(_responseMap(response.data));
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
