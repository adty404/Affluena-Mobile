import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_error.dart';
import '../../../core/storage/secure_token_store.dart';
import '../../notifications/application/notification_scheduler.dart';
import '../data/auth_models.dart';
import '../data/auth_repository.dart';

final authControllerProvider = NotifierProvider<AuthController, AuthState>(
  AuthController.new,
);

enum AuthStatus { checking, authenticated, unauthenticated }

/// Tone for the inline auth message so the UI can render errors as errors
/// (coral banner) and confirmations as success — never a neutral tint.
enum AuthMessageTone { info, success, error }

class AuthState {
  const AuthState._({
    required this.status,
    this.user,
    this.message,
    this.messageTone = AuthMessageTone.info,
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

  const AuthState.unauthenticated({
    String? message,
    AuthMessageTone messageTone = AuthMessageTone.info,
    bool isSubmitting = false,
  }) : this._(
         status: AuthStatus.unauthenticated,
         message: message,
         messageTone: messageTone,
         isSubmitting: isSubmitting,
       );

  final AuthStatus status;
  final AuthUser? user;
  final String? message;
  final AuthMessageTone messageTone;
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
        message: 'Periksa emailmu untuk kode reset.',
        messageTone: AuthMessageTone.success,
      );
      return true;
    } catch (error) {
      state = AuthState.unauthenticated(
        message: _authErrorMessage(error),
        messageTone: AuthMessageTone.error,
      );
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
        message: 'Kata sandi diperbarui. Masuk dengan kata sandi barumu.',
        messageTone: AuthMessageTone.success,
      );
      return true;
    } catch (error) {
      state = AuthState.unauthenticated(
        message: _authErrorMessage(error),
        messageTone: AuthMessageTone.error,
      );
      return false;
    }
  }

  /// Permanently deletes the account (password-confirmed server-side) and
  /// clears the local session. Returns null on success or an Indonesian error
  /// message; on failure the user STAYS signed in (nothing local is touched).
  Future<String?> deleteAccount(String password) async {
    try {
      await ref.read(authRepositoryProvider).deleteAccount(password);
    } catch (error) {
      return _authErrorMessage(error);
    }
    await ref.read(secureTokenStoreProvider).clear();
    // Same rationale as logout(): armed reminders carry this account's data.
    unawaited(ref.read(notificationSchedulerProvider).clear());
    state = const AuthState.unauthenticated(
      message: 'Akunmu sudah dihapus. Sampai jumpa lagi.',
      messageTone: AuthMessageTone.success,
    );
    return null;
  }

  Future<void> logout() async {
    final currentUser = state.user;
    if (currentUser != null) {
      state = AuthState.authenticated(currentUser, isSubmitting: true);
    }
    await ref.read(secureTokenStoreProvider).clear();
    // Armed device reminders carry this account's amounts and counterparty
    // names; wipe them fire-and-forget (purely local, no network) so they
    // can't keep firing for days after logout.
    unawaited(ref.read(notificationSchedulerProvider).clear());
    state = const AuthState.unauthenticated(message: 'Kamu telah keluar.');
  }

  void replaceUser(AuthUser user) {
    if (!state.isAuthenticated) return;
    state = AuthState.authenticated(user, isSubmitting: state.isSubmitting);
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
      // The stored session is being discarded — clear its device reminders
      // too (same rationale as logout).
      unawaited(ref.read(notificationSchedulerProvider).clear());
      state = AuthState.unauthenticated(
        message: _restoreSessionMessage(error),
        messageTone: AuthMessageTone.error,
      );
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
      state = AuthState.unauthenticated(
        message: _authErrorMessage(error),
        messageTone: AuthMessageTone.error,
      );
    }
  }

  String _restoreSessionMessage(Object error) {
    if (_isSessionExpired(error)) {
      return 'Sesi berakhir. Silakan masuk lagi.';
    }
    return 'Kami tidak bisa memulihkan sesimu. Silakan masuk lagi.';
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
      return 'Tidak bisa terhubung ke Affluena. Periksa koneksimu dan coba lagi.';
    }
    return 'Terjadi kesalahan. Silakan coba lagi.';
  }
}
