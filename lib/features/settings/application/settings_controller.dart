import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_error.dart';
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
      return const SettingsActionResult.success('Account updated.');
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
      await ref.read(authRepositoryProvider).changePassword(request);
      return const SettingsActionResult.success('Password updated.');
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
      return const SettingsActionResult.success('Session revoked.');
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
    return 'Unable to reach Affluena. Check your connection and try again.';
  }
  return 'Something went wrong. Please try again.';
}
