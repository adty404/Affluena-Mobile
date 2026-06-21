import 'package:affluena_mobile/app/affluena_app.dart';
import 'package:affluena_mobile/core/api/api_error.dart';
import 'package:affluena_mobile/core/storage/secure_token_store.dart';
import 'package:affluena_mobile/features/auth/data/auth_models.dart';
import 'package:affluena_mobile/features/auth/data/auth_repository.dart';
import 'package:dio/dio.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

Widget authTestApp({
  required MemoryTokenStore tokenStore,
  required FakeAuthRepository authRepository,
}) {
  return ProviderScope(
    overrides: [
      secureTokenStoreProvider.overrideWithValue(tokenStore),
      authRepositoryProvider.overrideWithValue(authRepository),
    ],
    child: const AffluenaApp(),
  );
}

Future<void> pumpAuthTestApp(
  WidgetTester tester, {
  MemoryTokenStore? tokenStore,
  FakeAuthRepository? authRepository,
}) async {
  await tester.pumpWidget(
    authTestApp(
      tokenStore: tokenStore ?? MemoryTokenStore(),
      authRepository: authRepository ?? FakeAuthRepository(),
    ),
  );
  await tester.pumpAndSettle();
}

MemoryTokenStore authenticatedTokenStore() {
  return MemoryTokenStore(
    accessToken: 'access-token',
    refreshToken: 'refresh-token',
  );
}

DioException sessionExpiredDioException() {
  return DioException(
    requestOptions: RequestOptions(path: '/auth/me'),
    error: const SessionExpiredException(path: '/auth/me'),
    type: DioExceptionType.badResponse,
  );
}

class MemoryTokenStore extends SecureTokenStore {
  MemoryTokenStore({String? accessToken, String? refreshToken})
    : this._(MemoryTokenStorageBackend(), accessToken, refreshToken);

  MemoryTokenStore._(this.backend, String? accessToken, String? refreshToken)
    : super(backend) {
    backend.values['affluena.access_token'] = accessToken;
    backend.values['affluena.refresh_token'] = refreshToken;
  }

  final MemoryTokenStorageBackend backend;

  @override
  Future<String?> readAccessToken() {
    return backend.read(key: 'affluena.access_token');
  }

  @override
  Future<String?> readRefreshToken() {
    return backend.read(key: 'affluena.refresh_token');
  }

  @override
  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
  }) async {
    await backend.write(key: 'affluena.access_token', value: accessToken);
    await backend.write(key: 'affluena.refresh_token', value: refreshToken);
  }

  @override
  Future<void> clear() async {
    await backend.delete(key: 'affluena.access_token');
    await backend.delete(key: 'affluena.refresh_token');
  }
}

class MemoryTokenStorageBackend implements TokenStorageBackend {
  final values = <String, String?>{};

  @override
  Future<void> delete({required String key}) async {
    values.remove(key);
  }

  @override
  Future<String?> read({required String key}) async {
    return values[key];
  }

  @override
  Future<void> write({required String key, required String value}) async {
    values[key] = value;
  }
}

class FakeAuthRepository implements AuthRepository {
  FakeAuthRepository({
    this.meUser = demoUser,
    this.meError,
    this.loginSession = demoSession,
    this.loginError,
  });

  AuthUser? meUser;
  Object? meError;
  AuthSession? loginSession;
  Object? loginError;
  int meCalls = 0;
  int loginCalls = 0;

  @override
  Future<AuthSession> login(LoginRequest request) async {
    loginCalls += 1;
    if (loginError != null) throw loginError!;
    return loginSession!;
  }

  @override
  Future<AuthSession> register(RegisterRequest request) async {
    return loginSession!;
  }

  @override
  Future<AuthSession> refresh(String refreshToken) async {
    return loginSession!;
  }

  @override
  Future<AuthUser> me() async {
    meCalls += 1;
    if (meError != null) throw meError!;
    return meUser!;
  }

  @override
  Future<AuthUser> updateAccount(UpdateAccountRequest request) async {
    return meUser ?? demoUser;
  }

  @override
  Future<void> changePassword(ChangePasswordRequest request) async {}

  @override
  Future<List<AuthSessionRecord>> listSessions() async {
    return const [];
  }

  @override
  Future<void> revokeSession(String sessionId) async {}

  @override
  Future<void> requestPasswordReset(String email) async {}

  @override
  Future<void> resetPassword({
    required String token,
    required String newPassword,
  }) async {}
}

const demoUser = AuthUser(
  id: '11111111-1111-1111-1111-111111111111',
  email: 'demo@affluena.com',
  name: 'Demo User',
  avatarUrl: '',
  createdAt: '2026-06-01T00:00:00Z',
  updatedAt: '2026-06-01T00:00:00Z',
);

const demoSession = AuthSession(
  user: demoUser,
  tokens: AuthTokens(
    accessToken: 'fresh-access-token',
    refreshToken: 'fresh-refresh-token',
  ),
);
