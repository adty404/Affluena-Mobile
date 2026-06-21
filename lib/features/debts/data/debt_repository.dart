import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_client.dart';
import '../../../core/api/api_json.dart';
import 'debt_models.dart';

final debtRepositoryProvider = Provider<DebtRepository>((ref) {
  return DioDebtRepository(ref.watch(dioProvider));
});

abstract interface class DebtRepository {
  Future<DebtListResponse> listDebts({int? limit, int? offset, String? sort});

  Future<Debt> getDebt(String id);

  Future<Debt> createDebt(DebtRequest request);

  Future<Debt> updateDebt(String id, DebtUpdateRequest request);

  Future<void> deleteDebt(String id);

  Future<DebtPayment> payDebt(String id, DebtPaymentRequest request);
}

class DioDebtRepository implements DebtRepository {
  const DioDebtRepository(this._dio);

  final Dio _dio;

  @override
  Future<DebtListResponse> listDebts({
    int? limit,
    int? offset,
    String? sort,
  }) async {
    final response = await _dio.get<Map<String, Object?>>(
      '/debts',
      queryParameters: _query({'limit': limit, 'offset': offset, 'sort': sort}),
    );
    return DebtListResponse.fromJson(_responseMap(response.data));
  }

  @override
  Future<Debt> getDebt(String id) async {
    final response = await _dio.get<Map<String, Object?>>('/debts/$id');
    return Debt.fromJson(_responseMap(response.data));
  }

  @override
  Future<Debt> createDebt(DebtRequest request) async {
    final response = await _dio.post<Map<String, Object?>>(
      '/debts',
      data: request.toJson(),
    );
    return Debt.fromJson(_responseMap(response.data));
  }

  @override
  Future<Debt> updateDebt(String id, DebtUpdateRequest request) async {
    final response = await _dio.put<Map<String, Object?>>(
      '/debts/$id',
      data: request.toJson(),
    );
    return Debt.fromJson(_responseMap(response.data));
  }

  @override
  Future<void> deleteDebt(String id) async {
    await _dio.delete<void>('/debts/$id');
  }

  @override
  Future<DebtPayment> payDebt(String id, DebtPaymentRequest request) async {
    final response = await _dio.post<Map<String, Object?>>(
      '/debts/$id/pay',
      data: request.toJson(),
    );
    return DebtPayment.fromJson(_responseMap(response.data));
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
