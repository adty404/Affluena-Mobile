import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Persists the "saldo disembunyikan" preference (the Beranda eye toggle).
/// Same storage mechanism as the onboarding preferences repository.
final amountVisibilityRepositoryProvider = Provider<AmountVisibilityRepository>(
  (ref) {
    return AmountVisibilityRepository(SharedPreferencesAsync());
  },
);

class AmountVisibilityRepository {
  const AmountVisibilityRepository(this._preferences);

  static const _key = 'affluena.amounts_visible';

  final SharedPreferencesAsync _preferences;

  Future<bool> isVisible() async {
    return await _preferences.getBool(_key) ?? true;
  }

  Future<void> setVisible(bool value) async {
    await _preferences.setBool(_key, value);
  }
}

/// Whether balance figures are shown (`true`, the default) or masked as
/// `Rp ••••••`. One global switch, toggled from the Beranda hero's eye icon
/// and read by every masked surface (hero totals, section-card amounts,
/// wallet/goal detail balances — see DESIGN.md "Saldo masking" for the exact
/// scope; the working ledger deliberately stays visible). Persisted, so the
/// choice survives restarts.
final amountVisibilityProvider =
    NotifierProvider<AmountVisibilityController, bool>(
      AmountVisibilityController.new,
    );

class AmountVisibilityController extends Notifier<bool> {
  /// Set the moment the user toggles, so an in-flight [_restore] can never
  /// stomp a choice made while storage was still being read.
  bool _userOverrode = false;

  @override
  bool build() {
    _restore();
    return true;
  }

  /// Fired unawaited from [build]: hydrate from storage; unreadable prefs
  /// fall back to visible (the default) — never block the UI on it.
  Future<void> _restore() async {
    try {
      final visible = await ref
          .read(amountVisibilityRepositoryProvider)
          .isVisible();
      if (!_userOverrode && visible != state) state = visible;
    } catch (_) {
      // Keep the in-memory default; the flag self-heals on the next toggle.
    }
  }

  /// Flips visibility optimistically and persists best-effort (a storage
  /// failure only means the choice doesn't survive the next cold start).
  Future<void> toggle() async {
    _userOverrode = true;
    state = !state;
    try {
      await ref.read(amountVisibilityRepositoryProvider).setVisible(state);
    } catch (_) {
      // Swallow: the in-session state is already flipped.
    }
  }
}
