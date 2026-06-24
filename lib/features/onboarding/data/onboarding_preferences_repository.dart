import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Persists whether the first-run onboarding has been completed.
final onboardingPreferencesRepositoryProvider =
    Provider<OnboardingPreferencesRepository>((ref) {
      return OnboardingPreferencesRepository(SharedPreferencesAsync());
    });

class OnboardingPreferencesRepository {
  const OnboardingPreferencesRepository(this._preferences);

  static const _key = 'affluena.onboarding.completed';

  final SharedPreferencesAsync _preferences;

  Future<bool> isCompleted() async {
    return await _preferences.getBool(_key) ?? false;
  }

  Future<void> setCompleted() async {
    await _preferences.setBool(_key, true);
  }
}
