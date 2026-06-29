import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_error.dart';
import '../../../core/storage/secure_token_store.dart';
import '../../auth/application/auth_controller.dart';
import '../../auth/data/auth_models.dart';
import '../../auth/data/auth_repository.dart';

final settingsProfileProvider =
    AsyncNotifierProvider<SettingsProfileController, AuthUser>(
      SettingsProfileController.new,
    );

final settingsSessionsProvider =
    AsyncNotifierProvider<SettingsSessionsController, List<AuthSessionRecord>>(
      SettingsSessionsController.new,
    );

/// The token suffix of the access token stored on *this* device, used to flag
/// the active session in the sessions list. Null when no token is stored.
final currentSessionTokenSuffixProvider = FutureProvider<String?>((ref) async {
  final token = await ref.watch(secureTokenStoreProvider).readAccessToken();
  if (token == null || token.isEmpty) return null;
  return token;
});

/// Returns true when [record] is the session backing this device, by matching
/// the stored access token against the record's token suffix.
bool isCurrentSession(AuthSessionRecord record, String? currentAccessToken) {
  final token = currentAccessToken?.trim();
  final suffix = record.tokenSuffix.trim();
  if (token == null || token.isEmpty || suffix.isEmpty) return false;
  return token.endsWith(suffix);
}

class SettingsActionResult {
  const SettingsActionResult._({required this.message, required this.success});

  const SettingsActionResult.success(String message)
    : this._(message: message, success: true);

  const SettingsActionResult.failure(String message)
    : this._(message: message, success: false);

  final String message;
  final bool success;
}

class SettingsProfileController extends AsyncNotifier<AuthUser> {
  @override
  Future<AuthUser> build() async {
    return ref.watch(authRepositoryProvider).me();
  }

  Future<SettingsActionResult> updateAccount(
    UpdateAccountRequest request,
  ) async {
    final previous = state.asData?.value;
    state = const AsyncLoading();
    try {
      final user = await ref
          .read(authRepositoryProvider)
          .updateAccount(request);
      ref.read(authControllerProvider.notifier).replaceUser(user);
      state = AsyncData(user);
      return const SettingsActionResult.success('Akun diperbarui.');
    } catch (error, stackTrace) {
      if (previous == null) {
        state = AsyncError(error, stackTrace);
      } else {
        state = AsyncData(previous);
      }
      return SettingsActionResult.failure(settingsErrorMessage(error));
    }
  }

  Future<SettingsActionResult> changePassword(
    ChangePasswordRequest request,
  ) async {
    try {
      final session = await ref
          .read(authRepositoryProvider)
          .changePassword(request);
      // The password change revoked every other session; persist the fresh
      // token pair so this device stays signed in with the new credentials.
      await ref
          .read(secureTokenStoreProvider)
          .saveTokens(
            accessToken: session.tokens.accessToken,
            refreshToken: session.tokens.refreshToken,
          );
      ref.read(authControllerProvider.notifier).replaceUser(session.user);
      state = AsyncData(session.user);
      return const SettingsActionResult.success('Kata sandi diperbarui.');
    } catch (error) {
      return SettingsActionResult.failure(settingsErrorMessage(error));
    }
  }
}

class SettingsSessionsController
    extends AsyncNotifier<List<AuthSessionRecord>> {
  @override
  Future<List<AuthSessionRecord>> build() async {
    return ref.watch(authRepositoryProvider).listSessions();
  }

  Future<SettingsActionResult> revokeSession(String sessionId) async {
    final previous = state.asData?.value ?? const <AuthSessionRecord>[];
    try {
      await ref.read(authRepositoryProvider).revokeSession(sessionId);
      state = AsyncData(
        previous
            .where((session) => session.id != sessionId)
            .toList(growable: false),
      );
      return const SettingsActionResult.success('Sesi dicabut.');
    } catch (error) {
      state = AsyncData(previous);
      return SettingsActionResult.failure(settingsErrorMessage(error));
    }
  }
}

String settingsErrorMessage(Object error) {
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
