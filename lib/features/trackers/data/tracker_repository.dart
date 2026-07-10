import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_client.dart';
import '../../../core/api/api_json.dart';
import 'tracker_models.dart';

final trackerRepositoryProvider = Provider<TrackerRepository>((ref) {
  return DioTrackerRepository(ref.watch(dioProvider));
});

abstract interface class TrackerRepository {
  Future<InstallmentListResponse> listInstallments({
    int? limit,
    int? offset,
    String? sort,
  });

  Future<Installment> getInstallment(String id);

  Future<Installment> createInstallment(InstallmentRequest request);

  Future<Installment> updateInstallment(String id, InstallmentRequest request);

  Future<void> deleteInstallment(String id);

  Future<InstallmentPayment> payInstallment(
    String id,
    TrackerPaymentRequest request,
  );

  /// GET /installments/:id/payments — the installment's recorded payments,
  /// ordered `paid_at` DESC by the API.
  Future<List<InstallmentPayment>> listInstallmentPayments(String id);

  Future<SubscriptionListResponse> listSubscriptions({
    int? limit,
    int? offset,
    String? sort,
  });

  Future<Subscription> getSubscription(String id);

  Future<Subscription> createSubscription(SubscriptionRequest request);

  Future<Subscription> updateSubscription(
    String id,
    SubscriptionRequest request,
  );

  Future<void> deleteSubscription(String id);

  Future<SubscriptionPayment> paySubscription(
    String id,
    TrackerPaymentRequest request,
  );

  /// GET /subscriptions/:id/payments — the subscription's recorded payments,
  /// ordered `paid_at` DESC by the API.
  Future<List<SubscriptionPayment>> listSubscriptionPayments(String id);
}

class DioTrackerRepository implements TrackerRepository {
  const DioTrackerRepository(this._dio);

  final Dio _dio;

  @override
  Future<InstallmentListResponse> listInstallments({
    int? limit,
    int? offset,
    String? sort,
  }) async {
    final response = await _dio.get<Map<String, Object?>>(
      '/installments',
      queryParameters: _query({'limit': limit, 'offset': offset, 'sort': sort}),
    );
    return InstallmentListResponse.fromJson(_responseMap(response.data));
  }

  @override
  Future<Installment> getInstallment(String id) async {
    final response = await _dio.get<Map<String, Object?>>('/installments/$id');
    return Installment.fromJson(_responseMap(response.data));
  }

  @override
  Future<Installment> createInstallment(InstallmentRequest request) async {
    final response = await _dio.post<Map<String, Object?>>(
      '/installments',
      data: request.toJson(),
    );
    return Installment.fromJson(_responseMap(response.data));
  }

  @override
  Future<Installment> updateInstallment(
    String id,
    InstallmentRequest request,
  ) async {
    final response = await _dio.put<Map<String, Object?>>(
      '/installments/$id',
      data: request.toJson(),
    );
    return Installment.fromJson(_responseMap(response.data));
  }

  @override
  Future<void> deleteInstallment(String id) async {
    await _dio.delete<void>('/installments/$id');
  }

  @override
  Future<InstallmentPayment> payInstallment(
    String id,
    TrackerPaymentRequest request,
  ) async {
    final response = await _dio.post<Map<String, Object?>>(
      '/installments/$id/pay',
      data: request.toJson(),
    );
    return InstallmentPayment.fromJson(_responseMap(response.data));
  }

  @override
  Future<List<InstallmentPayment>> listInstallmentPayments(String id) async {
    final response = await _dio.get<Map<String, Object?>>(
      '/installments/$id/payments',
    );
    return ApiJson.readObjectList(
      _responseMap(response.data),
      'payments',
    ).map(InstallmentPayment.fromJson).toList(growable: false);
  }

  @override
  Future<SubscriptionListResponse> listSubscriptions({
    int? limit,
    int? offset,
    String? sort,
  }) async {
    final response = await _dio.get<Map<String, Object?>>(
      '/subscriptions',
      queryParameters: _query({'limit': limit, 'offset': offset, 'sort': sort}),
    );
    return SubscriptionListResponse.fromJson(_responseMap(response.data));
  }

  @override
  Future<Subscription> getSubscription(String id) async {
    final response = await _dio.get<Map<String, Object?>>('/subscriptions/$id');
    return Subscription.fromJson(_responseMap(response.data));
  }

  @override
  Future<Subscription> createSubscription(SubscriptionRequest request) async {
    final response = await _dio.post<Map<String, Object?>>(
      '/subscriptions',
      data: request.toJson(),
    );
    return Subscription.fromJson(_responseMap(response.data));
  }

  @override
  Future<Subscription> updateSubscription(
    String id,
    SubscriptionRequest request,
  ) async {
    final response = await _dio.put<Map<String, Object?>>(
      '/subscriptions/$id',
      data: request.toJson(),
    );
    return Subscription.fromJson(_responseMap(response.data));
  }

  @override
  Future<void> deleteSubscription(String id) async {
    await _dio.delete<void>('/subscriptions/$id');
  }

  @override
  Future<SubscriptionPayment> paySubscription(
    String id,
    TrackerPaymentRequest request,
  ) async {
    final response = await _dio.post<Map<String, Object?>>(
      '/subscriptions/$id/pay',
      data: request.toJson(),
    );
    return SubscriptionPayment.fromJson(_responseMap(response.data));
  }

  @override
  Future<List<SubscriptionPayment>> listSubscriptionPayments(String id) async {
    final response = await _dio.get<Map<String, Object?>>(
      '/subscriptions/$id/payments',
    );
    return ApiJson.readObjectList(
      _responseMap(response.data),
      'payments',
    ).map(SubscriptionPayment.fromJson).toList(growable: false);
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
