import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/onboarding_preferences_repository.dart';

/// Whether the first-run onboarding has been completed.
///
/// `null` means the persisted flag is still loading — the router shows the
/// bootstrap splash until it resolves so onboarding never flashes for a
/// returning user.
final onboardingControllerProvider =
    NotifierProvider<OnboardingController, bool?>(OnboardingController.new);

class OnboardingController extends Notifier<bool?> {
  @override
  bool? build() {
    _restore();
    return null;
  }

  Future<void> _restore() async {
    state = await ref.read(onboardingPreferencesRepositoryProvider).isCompleted();
  }

  /// Marks onboarding complete and persists it.
  Future<void> complete() async {
    state = true;
    await ref.read(onboardingPreferencesRepositoryProvider).setCompleted();
  }
}
