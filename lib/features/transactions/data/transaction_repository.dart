import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_client.dart';
import '../../../core/api/api_json.dart';
import 'transaction_models.dart';

final transactionRepositoryProvider = Provider<TransactionRepository>((ref) {
  return DioTransactionRepository(ref.watch(dioProvider));
});

abstract interface class TransactionRepository {
  Future<TransactionListResponse> listTransactions({
    TransactionType? type,
    String? walletId,
    String? categoryId,
    String? tagId,
    String? from,
    String? to,
    int? limit,
    int? offset,
    String? sort,
  });

  Future<Transaction> getTransaction(String id);

  Future<Transaction> createTransaction(TransactionRequest request);

  Future<void> deleteTransaction(String id);
}

class DioTransactionRepository implements TransactionRepository {
  const DioTransactionRepository(this._dio);

  final Dio _dio;

  @override
  Future<TransactionListResponse> listTransactions({
    TransactionType? type,
    String? walletId,
    String? categoryId,
    String? tagId,
    String? from,
    String? to,
    int? limit,
    int? offset,
    String? sort,
  }) async {
    final response = await _dio.get<Map<String, Object?>>(
      '/transactions',
      queryParameters: _query({
        'type': type?.apiValue,
        'wallet_id': walletId,
        'category_id': categoryId,
        'tag_id': tagId,
        'from': from,
        'to': to,
        'limit': limit,
        'offset': offset,
        'sort': sort,
      }),
    );
    return TransactionListResponse.fromJson(_responseMap(response.data));
  }

  @override
  Future<Transaction> getTransaction(String id) async {
    final response = await _dio.get<Map<String, Object?>>('/transactions/$id');
    return Transaction.fromJson(_responseMap(response.data));
  }

  @override
  Future<Transaction> createTransaction(TransactionRequest request) async {
    final response = await _dio.post<Map<String, Object?>>(
      '/transactions',
      data: request.toJson(),
    );
    return Transaction.fromJson(_responseMap(response.data));
  }

  @override
  Future<void> deleteTransaction(String id) async {
    await _dio.delete<void>('/transactions/$id');
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
