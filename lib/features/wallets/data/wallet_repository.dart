import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_client.dart';
import '../../../core/api/api_json.dart';
import 'wallet_models.dart';

final walletRepositoryProvider = Provider<WalletRepository>((ref) {
  return DioWalletRepository(ref.watch(dioProvider));
});

abstract interface class WalletRepository {
  Future<WalletListResponse> listWallets({
    int? limit,
    int? offset,
    String? sort,
  });

  Future<Wallet> createWallet(WalletRequest request);

  Future<Wallet> getWallet(String id);

  Future<Wallet> updateWallet(String id, WalletRequest request);

  Future<void> deleteWallet(String id);

  Future<WalletInviteResponse> inviteMember(
    String id,
    WalletInviteRequest request,
  );

  Future<WalletInviteResponse> respondInvite(
    String id,
    String memberId,
    WalletInviteResponse response,
  );

  Future<WalletMembersResponse> listMembers(String id);

  Future<WalletAnalytics> getAnalytics(String id, {String? month});
}

class DioWalletRepository implements WalletRepository {
  const DioWalletRepository(this._dio);

  final Dio _dio;

  @override
  Future<WalletListResponse> listWallets({
    int? limit,
    int? offset,
    String? sort,
  }) async {
    final response = await _dio.get<Map<String, Object?>>(
      '/wallets',
      queryParameters: _query({'limit': limit, 'offset': offset, 'sort': sort}),
    );
    return WalletListResponse.fromJson(_responseMap(response.data));
  }

  @override
  Future<Wallet> createWallet(WalletRequest request) async {
    final response = await _dio.post<Map<String, Object?>>(
      '/wallets',
      data: request.toCreateJson(),
    );
    return Wallet.fromJson(_responseMap(response.data));
  }

  @override
  Future<Wallet> getWallet(String id) async {
    final response = await _dio.get<Map<String, Object?>>('/wallets/$id');
    return Wallet.fromJson(_responseMap(response.data));
  }

  @override
  Future<Wallet> updateWallet(String id, WalletRequest request) async {
    final response = await _dio.put<Map<String, Object?>>(
      '/wallets/$id',
      data: request.toUpdateJson(),
    );
    return Wallet.fromJson(_responseMap(response.data));
  }

  @override
  Future<void> deleteWallet(String id) async {
    await _dio.delete<void>('/wallets/$id');
  }

  @override
  Future<WalletInviteResponse> inviteMember(
    String id,
    WalletInviteRequest request,
  ) async {
    final response = await _dio.post<Map<String, Object?>>(
      '/wallets/$id/invites',
      data: request.toJson(),
    );
    return WalletInviteResponse.fromJson(_responseMap(response.data));
  }

  @override
  Future<WalletInviteResponse> respondInvite(
    String id,
    String memberId,
    WalletInviteResponse response,
  ) async {
    final result = await _dio.patch<Map<String, Object?>>(
      '/wallets/$id/members/$memberId',
      data: response.toJson(),
    );
    return WalletInviteResponse.fromJson(_responseMap(result.data));
  }

  @override
  Future<WalletMembersResponse> listMembers(String id) async {
    final response = await _dio.get<Map<String, Object?>>(
      '/wallets/$id/members',
    );
    return WalletMembersResponse.fromJson(_responseMap(response.data));
  }

  @override
  Future<WalletAnalytics> getAnalytics(String id, {String? month}) async {
    final response = await _dio.get<Map<String, Object?>>(
      '/wallets/$id/analytics',
      queryParameters: _query({'month': month}),
    );
    return WalletAnalytics.fromJson(_responseMap(response.data));
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
