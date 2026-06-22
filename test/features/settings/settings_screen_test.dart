import 'package:affluena_mobile/core/api/api_error.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/auth_test_helpers.dart';

void main() {
  testWidgets('loads profile and session list from auth API', (tester) async {
    final authRepository = FakeAuthRepository();

    await pumpAuthTestApp(
      tester,
      tokenStore: authenticatedTokenStore(),
      authRepository: authRepository,
    );
    await _openSettings(tester);

    expect(find.text('Demo User'), findsOneWidget);
    expect(find.text('demo@affluena.com'), findsOneWidget);

    await tester.tap(find.byKey(const Key('settings-sessions-row')));
    await tester.pumpAndSettle();

    expect(find.text('Signed-in sessions'), findsOneWidget);
    expect(find.text('Chrome on macOS'), findsOneWidget);
    expect(find.textContaining('ab12'), findsOneWidget);
    expect(authRepository.meCalls, 2);
    expect(authRepository.listSessionsCalls, 1);
  });

  testWidgets('updates account and refreshes visible profile copy', (
    tester,
  ) async {
    final authRepository = FakeAuthRepository();

    await pumpAuthTestApp(
      tester,
      tokenStore: authenticatedTokenStore(),
      authRepository: authRepository,
    );
    await _openSettings(tester);

    await tester.tap(find.byKey(const Key('settings-account-row')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('settings-name-field')),
      'Ayu Finance',
    );
    await tester.tap(find.byKey(const Key('settings-account-save-button')));
    await tester.pumpAndSettle();

    expect(authRepository.updateAccountRequests, hasLength(1));
    expect(authRepository.updateAccountRequests.single.name, 'Ayu Finance');
    expect(find.text('Ayu Finance'), findsOneWidget);
    expect(find.text('Account updated.'), findsOneWidget);
  });

  testWidgets('validates password and surfaces API errors', (tester) async {
    final authRepository = FakeAuthRepository(
      changePasswordError: const ApiException(
        message: 'current password is incorrect',
      ),
    );

    await pumpAuthTestApp(
      tester,
      tokenStore: authenticatedTokenStore(),
      authRepository: authRepository,
    );
    await _openSettings(tester);

    await tester.tap(find.byKey(const Key('settings-password-row')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('settings-current-password-field')),
      'password123',
    );
    await tester.enterText(
      find.byKey(const Key('settings-new-password-field')),
      'short',
    );
    await tester.tap(find.byKey(const Key('settings-password-save-button')));
    await tester.pumpAndSettle();

    expect(
      find.text('Password must be at least 8 characters.'),
      findsOneWidget,
    );
    expect(authRepository.changePasswordRequests, isEmpty);

    await tester.enterText(
      find.byKey(const Key('settings-new-password-field')),
      'newpassword123',
    );
    await tester.tap(find.byKey(const Key('settings-password-save-button')));
    await tester.pumpAndSettle();

    expect(authRepository.changePasswordRequests, hasLength(1));
    expect(find.text('current password is incorrect'), findsOneWidget);
  });

  testWidgets('revokes a session only after confirmation', (tester) async {
    final authRepository = FakeAuthRepository();

    await pumpAuthTestApp(
      tester,
      tokenStore: authenticatedTokenStore(),
      authRepository: authRepository,
    );
    await _openSettings(tester);

    await tester.tap(find.byKey(const Key('settings-sessions-row')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('settings-revoke-session-99999999')));
    await tester.pumpAndSettle();

    expect(authRepository.revokedSessionIds, isEmpty);
    expect(find.text('Revoke this session?'), findsOneWidget);
    expect(
      find.textContaining('If this is your current session'),
      findsOneWidget,
    );

    await tester.tap(find.byKey(const Key('settings-confirm-revoke-button')));
    await tester.pumpAndSettle();

    expect(authRepository.revokedSessionIds, [seededAuthSession.id]);
    expect(find.text('Session revoked.'), findsOneWidget);
    expect(find.text('Chrome on macOS'), findsNothing);
    expect(find.text('No active sessions found.'), findsOneWidget);
  });

  testWidgets('session list error can retry', (tester) async {
    final authRepository = FakeAuthRepository(
      listSessionsError: const ApiException(
        message:
            'Unable to reach Affluena. Check your connection and try again.',
      ),
    );

    await pumpAuthTestApp(
      tester,
      tokenStore: authenticatedTokenStore(),
      authRepository: authRepository,
    );
    await _openSettings(tester);

    await tester.tap(find.byKey(const Key('settings-sessions-row')));
    await tester.pumpAndSettle();

    expect(
      find.text(
        'Unable to reach Affluena. Check your connection and try again.',
      ),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('settings-sessions-retry-button')),
      findsOneWidget,
    );
    authRepository.listSessionsError = null;
    await tester.tap(find.byKey(const Key('settings-sessions-retry-button')));
    await tester.pumpAndSettle();

    expect(find.text('Chrome on macOS'), findsOneWidget);
    expect(authRepository.listSessionsCalls, 2);
  });

  testWidgets('device lock is configurable from settings and security center', (
    tester,
  ) async {
    final securityRepository = MemorySecurityPreferencesRepository();
    final deviceAuth = FakeDeviceAuthService();

    await pumpAuthTestApp(
      tester,
      tokenStore: authenticatedTokenStore(),
      authRepository: FakeAuthRepository(),
      securityPreferencesRepository: securityRepository,
      deviceAuthService: deviceAuth,
    );
    await _openSettings(tester);

    expect(find.text('Device lock'), findsOneWidget);
    expect(find.text('Off • device authentication'), findsOneWidget);
    expect(find.byKey(const Key('settings-device-lock-row')), findsOneWidget);
    expect(find.text('Unavailable in this build'), findsNothing);

    await tester.drag(find.byType(ListView).first, const Offset(0, -120));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(Switch).first);
    await tester.pumpAndSettle();

    expect(deviceAuth.authenticateCalls, 1);
    expect(securityRepository.savedPreferences.single.deviceLockEnabled, true);
    expect(find.text('Device lock enabled.'), findsOneWidget);
    expect(find.text('On • device authentication'), findsOneWidget);

    await tester.tap(find.text('Security center'));
    await tester.pumpAndSettle();

    expect(find.text('Security center'), findsOneWidget);
    expect(find.text('Device lock'), findsOneWidget);
    expect(find.text('On • device authentication'), findsOneWidget);
    expect(find.byKey(const Key('security-device-lock-row')), findsOneWidget);
    expect(find.text('Unavailable in this build'), findsNothing);
  });

  testWidgets(
    'security center shows unsupported protections without toggle controls',
    (tester) async {
      final securityRepository = MemorySecurityPreferencesRepository();

      await pumpAuthTestApp(
        tester,
        tokenStore: authenticatedTokenStore(),
        authRepository: FakeAuthRepository(),
        securityPreferencesRepository: securityRepository,
      );
      await _openSettings(tester);

      await tester.tap(find.text('Security center').first);
      await tester.pumpAndSettle();

      expect(find.text('Security center'), findsOneWidget);
      expect(find.byKey(const Key('security-device-lock-row')), findsOneWidget);
      expect(find.byType(Switch), findsOneWidget);

      await tester.drag(find.byType(ListView).first, const Offset(0, -520));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('security-two-factor-row')), findsOneWidget);
      expect(find.text('Security alerts'), findsOneWidget);
      expect(find.text('Managed in notification rules'), findsOneWidget);
      expect(find.text('Two-factor authentication'), findsOneWidget);
      expect(find.text('Not available in this API build'), findsOneWidget);
      expect(find.text('Push notifications'), findsOneWidget);
      expect(find.text('Waiting for push provider support'), findsOneWidget);
      expect(find.text('Login email alerts'), findsOneWidget);
      expect(
        find.text('No dedicated login-alert endpoint yet'),
        findsOneWidget,
      );

      await tester.tap(find.byKey(const Key('security-two-factor-row')));
      await tester.pumpAndSettle();

      expect(securityRepository.savedPreferences, isEmpty);
      expect(find.text('Two-factor authentication'), findsOneWidget);
      expect(find.byType(Switch), findsOneWidget);
    },
  );
}

Future<void> _openSettings(WidgetTester tester) async {
  await tester.tap(find.text('More'));
  await tester.pumpAndSettle();
}
