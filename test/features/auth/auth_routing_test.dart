import 'package:affluena_mobile/core/api/api_error.dart';
import 'package:affluena_mobile/features/settings/presentation/settings_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/auth_test_helpers.dart';

void main() {
  testWidgets('cold start with no token routes to login', (tester) async {
    final authRepository = FakeAuthRepository();

    await pumpAuthTestApp(tester, authRepository: authRepository);

    expect(find.byKey(const Key('login-email-field')), findsOneWidget);
    expect(find.byKey(const Key('login-email-field')), findsOneWidget);
    expect(authRepository.meCalls, 0);
  });

  testWidgets('valid token routes to the home shell after auth me', (
    tester,
  ) async {
    final authRepository = FakeAuthRepository();

    await pumpAuthTestApp(
      tester,
      tokenStore: authenticatedTokenStore(),
      authRepository: authRepository,
    );

    expect(find.text('Total saldo'), findsOneWidget);
    expect(find.byKey(const Key('nav-lainnya')), findsOneWidget);
    expect(authRepository.meCalls, 1);
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

    expect(find.byKey(const Key('login-email-field')), findsOneWidget);
    expect(find.text('Sesi berakhir. Silakan masuk lagi.'), findsOneWidget);
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

    expect(find.text('Total saldo'), findsOneWidget);
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

    expect(find.byKey(const Key('login-email-field')), findsOneWidget);
    expect(find.text('Invalid email or password.'), findsOneWidget);
  });

  testWidgets('logout clears token and returns to login', (tester) async {
    final tokenStore = authenticatedTokenStore();

    await pumpAuthTestApp(tester, tokenStore: tokenStore);
    await tester.tap(find.byKey(const Key('nav-lainnya')));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.byKey(const Key('settings-logout-button')),
      500,
      scrollable: find
          .descendant(
            of: find.byType(SettingsScreen),
            matching: find.byType(Scrollable),
          )
          .first,
    );
    await tester.tap(find.byKey(const Key('settings-logout-button')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('login-email-field')), findsOneWidget);
    expect(find.text('Kamu telah keluar.'), findsOneWidget);
    expect(await tokenStore.readAccessToken(), isNull);
    expect(await tokenStore.readRefreshToken(), isNull);
  });
}
