import 'package:affluena_mobile/core/api/api_error.dart';
import 'package:affluena_mobile/features/settings/data/security_preferences_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/auth_test_helpers.dart';

// Mirrors DashboardScreen's time-of-day greeting so dashboard assertions stay
// stable regardless of the local clock when the suite runs.
String _expectedGreeting() {
  final hour = DateTime.now().hour;
  if (hour < 12) return 'Good morning';
  if (hour < 17) return 'Good afternoon';
  return 'Good evening';
}

void main() {
  testWidgets('cold start with no token routes to login', (tester) async {
    final authRepository = FakeAuthRepository();

    await pumpAuthTestApp(tester, authRepository: authRepository);

    expect(find.text('Welcome back'), findsOneWidget);
    expect(find.byKey(const Key('login-email-field')), findsOneWidget);
    expect(authRepository.meCalls, 0);
  });

  testWidgets('valid token routes to dashboard after auth me', (tester) async {
    final authRepository = FakeAuthRepository();

    await pumpAuthTestApp(
      tester,
      tokenStore: authenticatedTokenStore(),
      authRepository: authRepository,
    );

    expect(find.text(_expectedGreeting()), findsOneWidget);
    expect(find.text('Total balance'), findsOneWidget);
    expect(authRepository.meCalls, 1);
  });

  testWidgets('device lock gates authenticated app until local auth succeeds', (
    tester,
  ) async {
    // Start with biometric failing so the lock screen's auto-prompt does not
    // immediately unlock; the lock screen must stay visible.
    final deviceAuth = FakeDeviceAuthService(authenticateResult: false);

    await pumpAuthTestApp(
      tester,
      tokenStore: authenticatedTokenStore(),
      securityPreferencesRepository: MemorySecurityPreferencesRepository(
        initialPreferences: const SecurityPreferences(deviceLockEnabled: true),
      ),
      deviceAuthService: deviceAuth,
    );

    // The lock screen auto-prompts biometric once on appearance (call #1).
    expect(find.text('Affluena locked'), findsOneWidget);
    expect(find.text(_expectedGreeting()), findsNothing);
    expect(deviceAuth.authenticateCalls, 1);

    // Let authentication succeed, then unlock via the button (call #2).
    deviceAuth.authenticateResult = true;
    await tester.tap(find.byKey(const Key('app-lock-unlock-button')));
    await tester.pumpAndSettle();

    expect(deviceAuth.authenticateCalls, 2);
    expect(find.text('Affluena locked'), findsNothing);
    expect(find.text(_expectedGreeting()), findsOneWidget);
  });

  testWidgets('expired session clears token and shows login reason', (
    tester,
  ) async {
    final tokenStore = authenticatedTokenStore();
    final authRepository = FakeAuthRepository(
      meError: sessionExpiredDioException(),
    );

    await pumpAuthTestApp(
      tester,
      tokenStore: tokenStore,
      authRepository: authRepository,
    );

    expect(find.text('Welcome back'), findsOneWidget);
    expect(find.text('Session expired. Please log in again.'), findsOneWidget);
    expect(await tokenStore.readAccessToken(), isNull);
    expect(await tokenStore.readRefreshToken(), isNull);
  });

  testWidgets('successful login saves tokens and routes to dashboard', (
    tester,
  ) async {
    final tokenStore = MemoryTokenStore();
    final authRepository = FakeAuthRepository();

    await pumpAuthTestApp(
      tester,
      tokenStore: tokenStore,
      authRepository: authRepository,
    );
    await tester.enterText(
      find.byKey(const Key('login-email-field')),
      'demo@affluena.com',
    );
    await tester.enterText(
      find.byKey(const Key('login-password-field')),
      'password123',
    );
    await tester.tap(find.byKey(const Key('login-submit-button')));
    await tester.pumpAndSettle();

    expect(find.text(_expectedGreeting()), findsOneWidget);
    expect(authRepository.loginCalls, 1);
    expect(await tokenStore.readAccessToken(), 'fresh-access-token');
    expect(await tokenStore.readRefreshToken(), 'fresh-refresh-token');
  });

  testWidgets('login failure remains on login and shows api error', (
    tester,
  ) async {
    final authRepository = FakeAuthRepository(
      loginError: const ApiException(message: 'Invalid email or password.'),
    );

    await pumpAuthTestApp(tester, authRepository: authRepository);
    await tester.enterText(
      find.byKey(const Key('login-email-field')),
      'demo@affluena.com',
    );
    await tester.enterText(
      find.byKey(const Key('login-password-field')),
      'wrong-password',
    );
    await tester.tap(find.byKey(const Key('login-submit-button')));
    await tester.pumpAndSettle();

    expect(find.text('Welcome back'), findsOneWidget);
    expect(find.text('Invalid email or password.'), findsOneWidget);
  });

  testWidgets('logout clears token and returns to login', (tester) async {
    final tokenStore = authenticatedTokenStore();

    await pumpAuthTestApp(tester, tokenStore: tokenStore);
    await tester.tap(find.text('More'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.byKey(const Key('settings-logout-button')),
      500,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.byKey(const Key('settings-logout-button')));
    await tester.pumpAndSettle();

    expect(find.text('Welcome back'), findsOneWidget);
    expect(find.text('You have logged out.'), findsOneWidget);
    expect(await tokenStore.readAccessToken(), isNull);
    expect(await tokenStore.readRefreshToken(), isNull);
  });
}
