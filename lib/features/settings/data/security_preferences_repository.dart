import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

final securityPreferencesRepositoryProvider =
    Provider<SecurityPreferencesRepository>((ref) {
      return SharedPreferencesSecurityPreferencesRepository(
        SharedPreferencesAsync(),
      );
    });

class SecurityPreferences {
  const SecurityPreferences({required this.deviceLockEnabled});

  static const disabled = SecurityPreferences(deviceLockEnabled: false);

  final bool deviceLockEnabled;

  SecurityPreferences copyWith({bool? deviceLockEnabled}) {
    return SecurityPreferences(
      deviceLockEnabled: deviceLockEnabled ?? this.deviceLockEnabled,
    );
  }
}

abstract interface class SecurityPreferencesRepository {
  Future<SecurityPreferences> load();

  Future<SecurityPreferences> save(SecurityPreferences preferences);
}

class SharedPreferencesSecurityPreferencesRepository
    implements SecurityPreferencesRepository {
  const SharedPreferencesSecurityPreferencesRepository(this._preferences);

  static const _deviceLockEnabledKey = 'affluena.security.device_lock_enabled';

  final SharedPreferencesAsync _preferences;

  @override
  Future<SecurityPreferences> load() async {
    final enabled = await _preferences.getBool(_deviceLockEnabledKey) ?? false;
    return SecurityPreferences(deviceLockEnabled: enabled);
  }

  @override
  Future<SecurityPreferences> save(SecurityPreferences preferences) async {
    await _preferences.setBool(
      _deviceLockEnabledKey,
      preferences.deviceLockEnabled,
    );
    return preferences;
  }
}
