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
    // _restore is fired unawaited from build(): if reading the persisted flag
    // threw, state would stay null forever and the router would pin the app
    // on the bootstrap splash. Unreadable prefs = treat as first-run; the
    // flag self-heals on the next successful complete().
    try {
      state = await ref
          .read(onboardingPreferencesRepositoryProvider)
          .isCompleted();
    } catch (_) {
      state = false;
    }
  }

  /// Marks onboarding complete and persists it. The state flip is optimistic
  /// and the persist is guarded: callers fire this unawaited, so a storage
  /// failure must never surface as an unobserved async error (worst case the
  /// user sees onboarding once more on the next cold start).
  Future<void> complete() async {
    state = true;
    try {
      await ref.read(onboardingPreferencesRepositoryProvider).setCompleted();
    } catch (_) {
      // Best-effort retry; if this also fails the flag simply stays unset.
      try {
        await ref.read(onboardingPreferencesRepositoryProvider).setCompleted();
      } catch (_) {
        // Swallow: onboarding may replay on next launch, nothing worse.
      }
    }
  }
}
