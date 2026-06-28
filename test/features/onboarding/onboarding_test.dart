import 'package:affluena_mobile/app/affluena_app.dart';
import 'package:affluena_mobile/app/provider_retry.dart';
import 'package:affluena_mobile/app/router.dart';
import 'package:affluena_mobile/core/storage/secure_token_store.dart';
import 'package:affluena_mobile/features/auth/application/auth_controller.dart';
import 'package:affluena_mobile/features/auth/data/auth_repository.dart';
import 'package:affluena_mobile/features/onboarding/data/onboarding_preferences_repository.dart';
import 'package:affluena_mobile/features/onboarding/presentation/onboarding_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/date_symbol_data_local.dart';

import '../../helpers/auth_test_helpers.dart';

void main() {
  setUpAll(() async {
    // Match the other full-app suites: locale data must be ready before any of
    // the date-formatting surfaces (reachable post-onboarding) build.
    await initializeDateFormatting('id_ID');
  });

  testWidgets('first run shows onboarding instead of login', (tester) async {
    final preferences = _FakeOnboardingPreferencesRepository();

    await tester.pumpWidget(_onboardingTestApp(preferences: preferences));
    await tester.pumpAndSettle();

    // The first-run gate routes to the onboarding screen, never to login.
    expect(find.byType(OnboardingScreen), findsOneWidget);
    expect(find.text('Catat uang dalam hitungan detik'), findsOneWidget);
    expect(find.byKey(const Key('onboarding-primary-button')), findsOneWidget);
    expect(find.text('Lanjut'), findsOneWidget);
    expect(find.text('Selamat datang kembali'), findsNothing);
  });

  testWidgets('completing onboarding persists and routes to login', (
    tester,
  ) async {
    final preferences = _FakeOnboardingPreferencesRepository();

    await tester.pumpWidget(_onboardingTestApp(preferences: preferences));
    await tester.pumpAndSettle();

    expect(find.byType(OnboardingScreen), findsOneWidget);

    // Page through every slide via the primary CTA ("Lanjut") until it becomes
    // the final "Mulai" action.
    while (find.text('Mulai').evaluate().isEmpty) {
      await tester.tap(find.byKey(const Key('onboarding-primary-button')));
      await tester.pumpAndSettle(const Duration(milliseconds: 400));
    }

    expect(find.text('Mulai'), findsOneWidget);
    await tester.tap(find.byKey(const Key('onboarding-primary-button')));
    await tester.pumpAndSettle(const Duration(milliseconds: 400));

    // Pressing "Mulai" marks onboarding complete and persists the flag.
    expect(preferences.setCompletedCalls, 1);

    // With the gate cleared, the next navigation is no longer forced back to
    // onboarding: an unauthenticated user resolves through to login. (Standing
    // on /onboarding is itself allowed once complete so it can be reviewed from
    // settings, so drive a fresh navigation the way the launching app does.)
    _router(tester).go('/');
    await tester.pumpAndSettle();

    expect(find.byType(OnboardingScreen), findsNothing);
    expect(find.text('Selamat datang kembali'), findsOneWidget);
    expect(find.byKey(const Key('login-email-field')), findsOneWidget);
  });
}

GoRouter _router(WidgetTester tester) {
  final context = tester.element(find.byType(AffluenaApp));
  return ProviderScope.containerOf(context).read(appRouterProvider);
}

Widget _onboardingTestApp({
  required _FakeOnboardingPreferencesRepository preferences,
}) {
  return ProviderScope(
    retry: noProviderRetry,
    overrides: [
      secureTokenStoreProvider.overrideWithValue(MemoryTokenStore()),
      authRepositoryProvider.overrideWithValue(FakeAuthRepository()),
      // Real OnboardingController, but backed by a fake repo so isCompleted()
      // deterministically resolves to false (first-run) regardless of platform.
      onboardingPreferencesRepositoryProvider.overrideWithValue(preferences),
      // Drive the unauthenticated state directly, mirroring the other suites,
      // so the post-onboarding redirect resolves to login rather than bootstrap.
      authControllerProvider.overrideWith(_UnauthenticatedAuthController.new),
    ],
    child: const AffluenaApp(),
  );
}

/// An [AuthController] fixed in the unauthenticated state (no token store or
/// network), so completing onboarding routes straight to the login screen.
class _UnauthenticatedAuthController extends AuthController {
  @override
  AuthState build() => const AuthState.unauthenticated();
}

class _FakeOnboardingPreferencesRepository
    implements OnboardingPreferencesRepository {
  /// First-run: the persisted flag starts unset (false) and only flips once
  /// [setCompleted] is called.
  bool completed = false;
  int setCompletedCalls = 0;

  @override
  Future<bool> isCompleted() async => completed;

  @override
  Future<void> setCompleted() async {
    setCompletedCalls += 1;
    completed = true;
  }
}
