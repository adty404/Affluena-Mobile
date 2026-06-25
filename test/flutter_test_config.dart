import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
// The async in-memory backend lives in the platform-interface package, which is
// only a transitive dependency here; the import is test-only.
// ignore: depend_on_referenced_packages
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
// ignore: depend_on_referenced_packages
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

/// Global test bootstrap (auto-discovered by `flutter test`).
///
/// Several controllers construct a bare [SharedPreferencesAsync] (app theme
/// mode, first-run onboarding, etc.). Without a platform implementation that
/// throws "The SharedPreferencesAsyncPlatform instance must be set" the moment
/// any test builds the full app. Register an in-memory backend so those
/// providers resolve to their defaults instead of erroring.
Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  TestWidgetsFlutterBinding.ensureInitialized();
  SharedPreferencesAsyncPlatform.instance =
      InMemorySharedPreferencesAsync.empty();
  await testMain();
}
