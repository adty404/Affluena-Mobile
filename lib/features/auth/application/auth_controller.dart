import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_error.dart';
import '../../../core/storage/secure_token_store.dart';
import '../data/auth_models.dart';
import '../data/auth_repository.dart';

final authControllerProvider = NotifierProvider<AuthController, AuthState>(
  AuthController.new,
);

enum AuthStatus { checking, authenticated, unauthenticated }

class AuthState {
  const AuthState._({
    required this.status,
    this.user,
    this.message,
    this.isSubmitting = false,
  });

  const AuthState.checking()
    : this._(status: AuthStatus.checking, isSubmitting: false);

  const AuthState.authenticated(AuthUser user, {bool isSubmitting = false})
    : this._(
        status: AuthStatus.authenticated,
        user: user,
        isSubmitting: isSubmitting,
      );

  const AuthState.unauthenticated({String? message, bool isSubmitting = false})
    : this._(
        status: AuthStatus.unauthenticated,
        message: message,
        isSubmitting: isSubmitting,
      );

  final AuthStatus status;
  final AuthUser? user;
  final String? message;
  final bool isSubmitting;

  bool get isAuthenticated => status == AuthStatus.authenticated;
  bool get isChecking => status == AuthStatus.checking;
}

class AuthController extends Notifier<AuthState> {
  @override
  AuthState build() {
    Future<void>.microtask(_restoreSession);
    return const AuthState.checking();
  }

  Future<void> login({required String email, required String password}) async {
    if (state.isSubmitting) return;

    state = const AuthState.unauthenticated(isSubmitting: true);
    await _authenticate(
      () => ref
          .read(authRepositoryProvider)
          .login(LoginRequest(email: email.trim(), password: password)),
    );
  }

  Future<void> register({
    required String email,
    required String password,
  }) async {
    if (state.isSubmitting) return;

    state = const AuthState.unauthenticated(isSubmitting: true);
    await _authenticate(
      () => ref
          .read(authRepositoryProvider)
          .register(RegisterRequest(email: email.trim(), password: password)),
    );
  }

  Future<bool> requestPasswordReset(String email) async {
    if (state.isSubmitting) return false;

    state = const AuthState.unauthenticated(isSubmitting: true);
    try {
      await ref.read(authRepositoryProvider).requestPasswordReset(email.trim());
      state = const AuthState.unauthenticated(
        message: 'Password reset instructions were sent.',
      );
      return true;
    } catch (error) {
      state = AuthState.unauthenticated(message: _authErrorMessage(error));
      return false;
    }
  }

  Future<bool> resetPassword({
    required String token,
    required String newPassword,
  }) async {
    if (state.isSubmitting) return false;

    state = const AuthState.unauthenticated(isSubmitting: true);
    try {
      await ref
          .read(authRepositoryProvider)
          .resetPassword(token: token.trim(), newPassword: newPassword);
      state = const AuthState.unauthenticated(
        message: 'Password updated. Log in with your new password.',
      );
      return true;
    } catch (error) {
      state = AuthState.unauthenticated(message: _authErrorMessage(error));
      return false;
    }
  }

  Future<void> logout() async {
    final currentUser = state.user;
    if (currentUser != null) {
      state = AuthState.authenticated(currentUser, isSubmitting: true);
    }
    await ref.read(secureTokenStoreProvider).clear();
    state = const AuthState.unauthenticated(message: 'You have logged out.');
  }

  Future<void> _restoreSession() async {
    final tokenStore = ref.read(secureTokenStoreProvider);
    final accessToken = await tokenStore.readAccessToken();
    if (accessToken == null || accessToken.isEmpty) {
      state = const AuthState.unauthenticated();
      return;
    }

    try {
      final user = await ref.read(authRepositoryProvider).me();
      state = AuthState.authenticated(user);
    } catch (error) {
      await tokenStore.clear();
      state = AuthState.unauthenticated(message: _restoreSessionMessage(error));
    }
  }

  Future<void> _authenticate(Future<AuthSession> Function() request) async {
    try {
      final session = await request();
      await ref
          .read(secureTokenStoreProvider)
          .saveTokens(
            accessToken: session.tokens.accessToken,
            refreshToken: session.tokens.refreshToken,
          );
      state = AuthState.authenticated(session.user);
    } catch (error) {
      state = AuthState.unauthenticated(message: _authErrorMessage(error));
    }
  }

  String _restoreSessionMessage(Object error) {
    if (_isSessionExpired(error)) {
      return 'Session expired. Please log in again.';
    }
    return 'We could not restore your session. Please log in again.';
  }

  bool _isSessionExpired(Object error) {
    if (error is SessionExpiredException) return true;
    if (error is DioException) return error.error is SessionExpiredException;
    return false;
  }

  String _authErrorMessage(Object error) {
    if (error is ApiException) return error.message;
    if (error is DioException) {
      final inner = error.error;
      if (inner is ApiException) return inner.message;
      final data = error.response?.data;
      if (data is Map<String, Object?>) {
        final message = data['message'] ?? data['error'];
        if (message is String && message.isNotEmpty) return message;
      }
      return 'Unable to reach Affluena. Check your connection and try again.';
    }
    return 'Something went wrong. Please try again.';
  }
}
