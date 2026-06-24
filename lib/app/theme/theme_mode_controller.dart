import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Persists the user's app-wide appearance choice (System / Light / Dark).
final themeModePreferencesRepositoryProvider =
    Provider<ThemeModePreferencesRepository>((ref) {
      return ThemeModePreferencesRepository(SharedPreferencesAsync());
    });

class ThemeModePreferencesRepository {
  const ThemeModePreferencesRepository(this._preferences);

  static const _key = 'affluena.appearance.theme_mode';

  final SharedPreferencesAsync _preferences;

  Future<ThemeMode> load() async {
    final value = await _preferences.getString(_key);
    return switch (value) {
      'light' => ThemeMode.light,
      'dark' => ThemeMode.dark,
      _ => ThemeMode.system,
    };
  }

  Future<void> save(ThemeMode mode) async {
    await _preferences.setString(_key, mode.name);
  }
}

/// App-wide theme mode. Defaults to [ThemeMode.system] (follow the OS) and
/// loads the saved override asynchronously on startup.
final appThemeModeProvider =
    NotifierProvider<AppThemeModeController, ThemeMode>(
      AppThemeModeController.new,
    );

class AppThemeModeController extends Notifier<ThemeMode> {
  @override
  ThemeMode build() {
    _restore();
    return ThemeMode.system;
  }

  Future<void> _restore() async {
    state = await ref.read(themeModePreferencesRepositoryProvider).load();
  }

  Future<void> setMode(ThemeMode mode) async {
    state = mode;
    await ref.read(themeModePreferencesRepositoryProvider).save(mode);
  }
}

extension ThemeModeLabel on ThemeMode {
  String get label => switch (this) {
    ThemeMode.system => 'System',
    ThemeMode.light => 'Light',
    ThemeMode.dark => 'Dark',
  };

  String get description => switch (this) {
    ThemeMode.system => 'Match your device setting',
    ThemeMode.light => 'Always light',
    ThemeMode.dark => 'Always dark',
  };

  IconData get icon => switch (this) {
    ThemeMode.system => Icons.brightness_auto_outlined,
    ThemeMode.light => Icons.light_mode_outlined,
    ThemeMode.dark => Icons.dark_mode_outlined,
  };
}
