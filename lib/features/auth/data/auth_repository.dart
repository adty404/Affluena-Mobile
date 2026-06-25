import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_client.dart';
import '../../../core/api/api_json.dart';
import 'auth_models.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return DioAuthRepository(ref.watch(dioProvider));
});

abstract interface class AuthRepository {
  Future<AuthSession> login(LoginRequest request);

  Future<AuthSession> register(RegisterRequest request);

  Future<AuthSession> refresh(String refreshToken);

  Future<AuthUser> me();

  Future<AuthUser> updateAccount(UpdateAccountRequest request);

  Future<AuthSession> changePassword(ChangePasswordRequest request);

  Future<List<AuthSessionRecord>> listSessions();

  Future<void> revokeSession(String sessionId);

  Future<void> requestPasswordReset(String email);

  Future<void> resetPassword({
    required String token,
    required String newPassword,
  });
}

class DioAuthRepository implements AuthRepository {
  const DioAuthRepository(this._dio);

  final Dio _dio;

  @override
  Future<AuthSession> login(LoginRequest request) async {
    final response = await _dio.post<Map<String, Object?>>(
      '/auth/login',
      data: request.toJson(),
      options: AffluenaApiOptions.anonymous(),
    );
    return AuthSession.fromJson(_responseMap(response.data));
  }

  @override
  Future<AuthSession> register(RegisterRequest request) async {
    final response = await _dio.post<Map<String, Object?>>(
      '/auth/register',
      data: request.toJson(),
      options: AffluenaApiOptions.anonymous(),
    );
    return AuthSession.fromJson(_responseMap(response.data));
  }

  @override
  Future<AuthSession> refresh(String refreshToken) async {
    final response = await _dio.post<Map<String, Object?>>(
      '/auth/refresh',
      data: {'refresh_token': refreshToken},
      options: AffluenaApiOptions.anonymous(),
    );
    return AuthSession.fromJson(_responseMap(response.data));
  }

  @override
  Future<AuthUser> me() async {
    final response = await _dio.get<Map<String, Object?>>('/auth/me');
    return AuthUser.fromJson(
      ApiJson.readMap(_responseMap(response.data), 'user'),
    );
  }

  @override
  Future<AuthUser> updateAccount(UpdateAccountRequest request) async {
    final response = await _dio.put<Map<String, Object?>>(
      '/auth/account',
      data: request.toJson(),
    );
    return AuthUser.fromJson(
      ApiJson.readMap(_responseMap(response.data), 'user'),
    );
  }

  @override
  Future<AuthSession> changePassword(ChangePasswordRequest request) async {
    // Returns a fresh {user, tokens} pair: the server revokes all other
    // sessions on a password change, so the caller must persist the new tokens.
    final response = await _dio.put<Map<String, Object?>>(
      '/auth/password',
      data: request.toJson(),
    );
    return AuthSession.fromJson(_responseMap(response.data));
  }

  @override
  Future<List<AuthSessionRecord>> listSessions() async {
    final response = await _dio.get<Map<String, Object?>>('/auth/sessions');
    return ApiJson.readObjectList(
      _responseMap(response.data),
      'sessions',
    ).map(AuthSessionRecord.fromJson).toList(growable: false);
  }

  @override
  Future<void> revokeSession(String sessionId) async {
    await _dio.delete<void>('/auth/sessions/$sessionId');
  }

  @override
  Future<void> requestPasswordReset(String email) async {
    await _dio.post<void>(
      '/auth/forgot-password',
      data: {'email': email},
      options: AffluenaApiOptions.anonymous(),
    );
  }

  @override
  Future<void> resetPassword({
    required String token,
    required String newPassword,
  }) async {
    await _dio.post<void>(
      '/auth/reset-password',
      data: {'token': token, 'new_password': newPassword},
      options: AffluenaApiOptions.anonymous(),
    );
  }

  JsonMap _responseMap(Object? data) {
    if (data is Map<String, Object?>) return data;
    if (data is Map) return Map<String, Object?>.from(data);
    throw const FormatException('Expected response body to be an object.');
  }
}
