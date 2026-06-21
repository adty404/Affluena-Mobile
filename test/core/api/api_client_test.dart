import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:affluena_mobile/core/api/api_client.dart';
import 'package:affluena_mobile/core/api/api_error.dart';
import 'package:affluena_mobile/core/storage/secure_token_store.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('authenticated request adds bearer token', () async {
    final store = memoryTokenStore(accessToken: 'access-1');
    late RequestOptions captured;
    final adapter = HandlerAdapter((options) {
      captured = options;
      return jsonResponse({'ok': true});
    });
    final dio = createTestDio(store: store, adapter: adapter);

    await dio.get('/wallets');

    expect(captured.headers['Authorization'], 'Bearer access-1');
  });

  test('401 refreshes tokens and retries original request once', () async {
    final store = memoryTokenStore(
      accessToken: 'expired-access',
      refreshToken: 'refresh-1',
    );
    final pathCounts = <String, int>{};
    final adapter = HandlerAdapter((options) {
      final count = (pathCounts[options.path] ?? 0) + 1;
      pathCounts[options.path] = count;
      if (options.path == '/wallets' && count == 1) {
        expect(options.headers['Authorization'], 'Bearer expired-access');
        return jsonResponse({'error': 'expired'}, statusCode: 401);
      }
      if (options.path == '/auth/refresh') {
        return jsonResponse({
          'user': userJson,
          'tokens': {
            'access_token': 'fresh-access',
            'refresh_token': 'fresh-refresh',
          },
        });
      }
      expect(options.path, '/wallets');
      expect(options.headers['Authorization'], 'Bearer fresh-access');
      return jsonResponse({'wallets': [], 'pagination': paginationJson});
    });
    final dio = createTestDio(store: store, adapter: adapter);

    final response = await dio.get('/wallets');

    expect(response.statusCode, 200);
    expect(await store.readAccessToken(), 'fresh-access');
    expect(await store.readRefreshToken(), 'fresh-refresh');
    expect(pathCounts['/auth/refresh'], 1);
    expect(pathCounts['/wallets'], 2);
  });

  test('parallel 401 responses share one refresh call', () async {
    final store = memoryTokenStore(
      accessToken: 'expired-access',
      refreshToken: 'refresh-1',
    );
    final pathCounts = <String, int>{};
    final adapter = HandlerAdapter((options) async {
      final count = (pathCounts[options.path] ?? 0) + 1;
      pathCounts[options.path] = count;
      if ((options.path == '/wallets' || options.path == '/transactions') &&
          count == 1) {
        return jsonResponse({'error': 'expired'}, statusCode: 401);
      }
      if (options.path == '/auth/refresh') {
        await Future<void>.delayed(const Duration(milliseconds: 20));
        return jsonResponse({
          'user': userJson,
          'tokens': {
            'access_token': 'fresh-access',
            'refresh_token': 'fresh-refresh',
          },
        });
      }
      return jsonResponse({'ok': true});
    });
    final dio = createTestDio(store: store, adapter: adapter);

    await Future.wait([dio.get('/wallets'), dio.get('/transactions')]);

    expect(pathCounts['/auth/refresh'], 1);
    expect(pathCounts['/wallets'], 2);
    expect(pathCounts['/transactions'], 2);
  });

  test('refresh failure clears tokens and reports expired session', () async {
    final store = memoryTokenStore(
      accessToken: 'expired-access',
      refreshToken: 'refresh-1',
    );
    final adapter = HandlerAdapter((options) {
      if (options.path == '/auth/refresh') {
        return jsonResponse({'error': 'invalid refresh'}, statusCode: 401);
      }
      return jsonResponse({'error': 'expired'}, statusCode: 401);
    });
    final dio = createTestDio(store: store, adapter: adapter);

    await expectLater(
      dio.get('/wallets'),
      throwsA(
        isA<DioException>().having(
          (error) => error.error,
          'error',
          isA<SessionExpiredException>(),
        ),
      ),
    );
    expect(await store.readAccessToken(), isNull);
    expect(await store.readRefreshToken(), isNull);
  });

  test('password 401 maps api error without refreshing session', () async {
    final store = memoryTokenStore(
      accessToken: 'access-1',
      refreshToken: 'refresh-1',
    );
    final pathCounts = <String, int>{};
    final adapter = HandlerAdapter((options) {
      final count = (pathCounts[options.path] ?? 0) + 1;
      pathCounts[options.path] = count;
      if (options.path == '/auth/password') {
        return jsonResponse({
          'error': 'current password is incorrect',
        }, statusCode: 401);
      }
      return jsonResponse({
        'user': userJson,
        'tokens': {
          'access_token': 'fresh-access',
          'refresh_token': 'fresh-refresh',
        },
      });
    });
    final dio = createTestDio(store: store, adapter: adapter);

    await expectLater(
      dio.put('/auth/password', data: const {'current_password': 'wrong'}),
      throwsA(
        isA<DioException>().having(
          (error) => error.error,
          'error',
          isA<ApiException>().having(
            (error) => error.message,
            'message',
            'current password is incorrect',
          ),
        ),
      ),
    );
    expect(pathCounts['/auth/refresh'], isNull);
    expect(pathCounts['/auth/password'], 1);
    expect(await store.readAccessToken(), 'access-1');
    expect(await store.readRefreshToken(), 'refresh-1');
  });

  test('network failure maps to stable friendly api error', () async {
    final store = memoryTokenStore(accessToken: 'access-1');
    final adapter = HandlerAdapter((options) {
      throw DioException(
        requestOptions: options,
        type: DioExceptionType.connectionError,
        message:
            'The connection errored: Connection refused This indicates an error which most likely cannot be solved by the library.',
      );
    });
    final dio = createTestDio(store: store, adapter: adapter);

    await expectLater(
      dio.get('/wallets'),
      throwsA(
        isA<DioException>().having(
          (error) => error.error,
          'error',
          isA<ApiException>().having(
            (error) => error.message,
            'message',
            'Unable to reach Affluena. Check your connection and try again.',
          ),
        ),
      ),
    );
  });
}

Dio createTestDio({
  required SecureTokenStore store,
  required HttpClientAdapter adapter,
}) {
  final refreshDio = Dio(BaseOptions(baseUrl: 'http://api.test'));
  refreshDio.httpClientAdapter = adapter;
  final dio = createAffluenaDio(
    tokenStore: store,
    baseUrl: 'http://api.test',
    refreshDio: refreshDio,
  );
  dio.httpClientAdapter = adapter;
  return dio;
}

SecureTokenStore memoryTokenStore({String? accessToken, String? refreshToken}) {
  final backend = MemoryTokenStorageBackend();
  final store = SecureTokenStore(backend);
  if (accessToken != null || refreshToken != null) {
    backend.values['affluena.access_token'] = accessToken;
    backend.values['affluena.refresh_token'] = refreshToken;
  }
  return store;
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

class HandlerAdapter implements HttpClientAdapter {
  HandlerAdapter(this._handler);

  final FutureOr<ResponseBody> Function(RequestOptions options) _handler;

  @override
  void close({bool force = false}) {}

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    return _handler(options);
  }
}

ResponseBody jsonResponse(Object body, {int statusCode = 200}) {
  return ResponseBody.fromString(
    jsonEncode(body),
    statusCode,
    headers: {
      Headers.contentTypeHeader: [Headers.jsonContentType],
    },
  );
}

const paginationJson = {'total': 0, 'limit': 20, 'offset': 0};

const userJson = {
  'id': '11111111-1111-1111-1111-111111111111',
  'email': 'demo@affluena.com',
  'name': 'Demo User',
  'avatar_url': '',
  'created_at': '2026-06-01T00:00:00Z',
  'updated_at': '2026-06-01T00:00:00Z',
};
