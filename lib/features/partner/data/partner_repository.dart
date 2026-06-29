import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_client.dart';
import 'partner_models.dart';

final partnerRepositoryProvider = Provider<PartnerRepository>((ref) {
  return DioPartnerRepository(ref.watch(dioProvider));
});

abstract interface class PartnerRepository {
  Future<PartnerListResponse> list();
  Future<void> invite(PartnerInviteRequest request);
  Future<void> respond(String id, PartnerRespondRequest request);
  Future<void> revoke(String id);
}

class DioPartnerRepository implements PartnerRepository {
  const DioPartnerRepository(this._dio);

  final Dio _dio;

  @override
  Future<PartnerListResponse> list() async {
    final response = await _dio.get<Map<String, Object?>>('/partners');
    return PartnerListResponse.fromJson(response.data ?? const {});
  }

  @override
  Future<void> invite(PartnerInviteRequest request) async {
    await _dio.post<Map<String, Object?>>(
      '/partners/invites',
      data: request.toJson(),
    );
  }

  @override
  Future<void> respond(String id, PartnerRespondRequest request) async {
    await _dio.patch<Map<String, Object?>>(
      '/partners/$id',
      data: request.toJson(),
    );
  }

  @override
  Future<void> revoke(String id) async {
    await _dio.delete<Map<String, Object?>>('/partners/$id');
  }
}
