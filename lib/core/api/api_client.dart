import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../config/app_config.dart';
import '../storage/secure_token_store.dart';
import 'api_error.dart';
import 'api_json.dart';

const _networkErrorMessage =
    'Tidak bisa terhubung ke Affluena. Periksa koneksimu dan coba lagi.';

final dioProvider = Provider<Dio>((ref) {
  final tokenStore = ref.watch(secureTokenStoreProvider);
  return createAffluenaDio(tokenStore: tokenStore);
});

abstract final class AffluenaApiOptions {
  static const anonymousKey = 'affluena.anonymous';
  static const retriedKey = 'affluena.retried';

  static Options anonymous() {
    return Options(extra: const {anonymousKey: true});
  }
}

Dio createAffluenaDio({
  required SecureTokenStore tokenStore,
  String baseUrl = AppConfig.apiBaseUrl,
  Dio? refreshDio,
  void Function()? onSessionExpired,
}) {
  final dio = Dio(_baseOptions(baseUrl));
  final refreshClient = refreshDio ?? Dio(_baseOptions(baseUrl));
  Future<bool>? refreshInFlight;

  Future<bool> refreshTokens() {
    refreshInFlight ??=
        _refreshTokens(
          refreshClient: refreshClient,
          tokenStore: tokenStore,
        ).whenComplete(() {
          refreshInFlight = null;
        });
    return refreshInFlight!;
  }

  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) async {
        if (_isAnonymous(options)) {
          handler.next(options);
          return;
        }

        final token = await tokenStore.readAccessToken();
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        handler.next(options);
      },
      onError: (error, handler) async {
        final response = error.response;
        final options = error.requestOptions;
        if (_shouldRefreshOnUnauthorized(options, response)) {
          final refreshed = await refreshTokens();
          if (refreshed) {
            final accessToken = await tokenStore.readAccessToken();
            if (accessToken != null) {
              try {
                final retryResponse = await _retryWithAccessToken(
                  dio,
                  options,
                  accessToken,
                );
                handler.resolve(retryResponse);
              } on DioException catch (retryError) {
                handler.reject(_mapApiError(retryError));
              }
              return;
            }
          }

          await tokenStore.clear();
          onSessionExpired?.call();
          handler.reject(
            DioException(
              requestOptions: options,
              response: response,
              type: DioExceptionType.badResponse,
              error: SessionExpiredException(path: options.path),
            ),
          );
          return;
        }

        handler.reject(_mapApiError(error));
      },
    ),
  );

  return dio;
}

BaseOptions _baseOptions(String baseUrl) {
  return BaseOptions(
    baseUrl: baseUrl,
    connectTimeout: const Duration(seconds: 15),
    receiveTimeout: const Duration(seconds: 20),
    contentType: Headers.jsonContentType,
    headers: const {'Accept': 'application/json'},
  );
}

bool _isAnonymous(RequestOptions options) {
  return options.extra[AffluenaApiOptions.anonymousKey] == true;
}

bool _wasRetried(RequestOptions options) {
  return options.extra[AffluenaApiOptions.retriedKey] == true;
}

bool _shouldRefreshOnUnauthorized(
  RequestOptions options,
  Response<dynamic>? response,
) {
  if (response?.statusCode != 401) return false;
  if (_isAnonymous(options) || _wasRetried(options)) return false;
  return options.path != '/auth/password';
}

Future<bool> _refreshTokens({
  required Dio refreshClient,
  required SecureTokenStore tokenStore,
}) async {
  final refreshToken = await tokenStore.readRefreshToken();
  if (refreshToken == null) return false;

  try {
    final response = await refreshClient.post<Map<String, Object?>>(
      '/auth/refresh',
      data: {'refresh_token': refreshToken},
      options: AffluenaApiOptions.anonymous(),
    );
    final body = _responseMap(response.data);
    final tokens = ApiJson.readMap(body, 'tokens');
    await tokenStore.saveTokens(
      accessToken: ApiJson.readString(tokens, 'access_token'),
      refreshToken: ApiJson.readString(tokens, 'refresh_token'),
    );
    return true;
  } on Object {
    await tokenStore.clear();
    return false;
  }
}

Future<Response<dynamic>> _retryWithAccessToken(
  Dio dio,
  RequestOptions request,
  String accessToken,
) {
  final headers = Map<String, Object?>.from(request.headers);
  headers['Authorization'] = 'Bearer $accessToken';
  final extra = Map<String, Object?>.from(request.extra);
  extra[AffluenaApiOptions.retriedKey] = true;

  return dio.request<dynamic>(
    request.path,
    data: request.data,
    queryParameters: request.queryParameters,
    options: Options(
      method: request.method,
      headers: headers,
      responseType: request.responseType,
      contentType: request.contentType,
      extra: extra,
    ),
    cancelToken: request.cancelToken,
    onReceiveProgress: request.onReceiveProgress,
    onSendProgress: request.onSendProgress,
  );
}

DioException _mapApiError(DioException error) {
  final response = error.response;
  if (response == null) {
    return DioException(
      requestOptions: error.requestOptions,
      type: error.type,
      error: ApiException(
        message: _networkErrorMessage,
        path: error.requestOptions.path,
      ),
    );
  }

  return DioException(
    requestOptions: error.requestOptions,
    response: response,
    type: error.type,
    error: ApiException(
      message: _errorMessage(response),
      statusCode: response.statusCode,
      path: error.requestOptions.path,
    ),
  );
}

String _errorMessage(Response<dynamic> response) {
  final data = response.data;
  if (data is Map) {
    final message = data['message'];
    if (message is String && message.isNotEmpty) return message;
    final error = data['error'];
    if (error is String && error.isNotEmpty) return error;
  }
  return response.statusMessage ?? 'Request failed.';
}

JsonMap _responseMap(Object? data) {
  if (data is Map<String, Object?>) return data;
  if (data is Map) return Map<String, Object?>.from(data);
  throw const FormatException('Expected response body to be an object.');
}
