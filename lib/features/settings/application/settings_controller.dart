import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_error.dart';
import '../../../core/storage/secure_token_store.dart';
import '../../auth/application/auth_controller.dart';
import '../../auth/data/auth_models.dart';
import '../../auth/data/auth_repository.dart';
import '../data/security_preferences_repository.dart';
import 'device_auth_service.dart';

final settingsProfileProvider =
    AsyncNotifierProvider<SettingsProfileController, AuthUser>(
      SettingsProfileController.new,
    );

final settingsSessionsProvider =
    AsyncNotifierProvider<SettingsSessionsController, List<AuthSessionRecord>>(
      SettingsSessionsController.new,
    );

final securityPreferencesProvider =
    AsyncNotifierProvider<
      SecurityPreferencesController,
      SecurityPreferencesState
    >(SecurityPreferencesController.new);

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

class SecurityPreferencesController
    extends AsyncNotifier<SecurityPreferencesState> {
  @override
  Future<SecurityPreferencesState> build() async {
    final repository = ref.watch(securityPreferencesRepositoryProvider);
    final preferences = await repository.load();
    final isSupported = await ref
        .watch(deviceAuthServiceProvider)
        .isSupported();
    return SecurityPreferencesState(
      preferences: preferences,
      isDeviceAuthSupported: isSupported,
    );
  }

  Future<void> setDeviceLockEnabled(bool enabled) async {
    final current = state.asData?.value;
    if (current == null || current.isSaving) return;

    state = AsyncData(
      current.copyWith(isSaving: true, actionError: null, actionMessage: null),
    );

    if (enabled && !current.isDeviceAuthSupported) {
      state = AsyncData(
        current.copyWith(
          actionError: 'Device authentication is not available on this device.',
        ),
      );
      return;
    }

    if (enabled) {
      final authenticated = await ref
          .read(deviceAuthServiceProvider)
          .authenticate();
      if (!authenticated) {
        state = AsyncData(
          current.copyWith(actionError: 'Device authentication was cancelled.'),
        );
        return;
      }
    }

    try {
      final nextPreferences = await ref
          .read(securityPreferencesRepositoryProvider)
          .save(current.preferences.copyWith(deviceLockEnabled: enabled));
      state = AsyncData(
        current.copyWith(
          preferences: nextPreferences,
          isSaving: false,
          actionMessage: enabled
              ? 'Device lock enabled.'
              : 'Device lock disabled.',
        ),
      );
    } catch (_) {
      state = AsyncData(
        current.copyWith(
          isSaving: false,
          actionError: 'Device lock preference could not be saved.',
        ),
      );
    }
  }
}

class SecurityPreferencesState {
  const SecurityPreferencesState({
    required this.preferences,
    required this.isDeviceAuthSupported,
    this.isSaving = false,
    this.actionMessage,
    this.actionError,
  });

  final SecurityPreferences preferences;
  final bool isDeviceAuthSupported;
  final bool isSaving;
  final String? actionMessage;
  final String? actionError;

  bool get canConfigureDeviceLock => isDeviceAuthSupported && !isSaving;

  String get deviceLockValue {
    if (!isDeviceAuthSupported) return 'Unavailable on this device';
    return preferences.deviceLockEnabled
        ? 'On • device authentication'
        : 'Off • device authentication';
  }

  SecurityPreferencesState copyWith({
    SecurityPreferences? preferences,
    bool? isDeviceAuthSupported,
    bool? isSaving,
    String? actionMessage,
    String? actionError,
  }) {
    return SecurityPreferencesState(
      preferences: preferences ?? this.preferences,
      isDeviceAuthSupported:
          isDeviceAuthSupported ?? this.isDeviceAuthSupported,
      isSaving: isSaving ?? false,
      actionMessage: actionMessage,
      actionError: actionError,
    );
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
