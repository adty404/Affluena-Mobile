import 'package:affluena_mobile/core/api/api_error.dart';
import 'package:affluena_mobile/features/settings/presentation/settings_screen.dart';
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

    // The Settings screen now renders inside a DrillInScaffold whose AppBar
    // shows the localized title instead of a large in-body "Profile" headline.
    expect(find.byType(SettingsScreen), findsOneWidget);
    expect(find.text('Pengaturan'), findsOneWidget);
    expect(find.text('Demo User'), findsOneWidget);
    expect(find.text('demo@affluena.com'), findsOneWidget);

    await tester.tap(find.byKey(const Key('settings-sessions-row')));
    await tester.pumpAndSettle();

    expect(find.text('Sesi yang masuk'), findsOneWidget);
    // The session row now shows the parsed device label (deviceLabel) instead
    // of the raw user-agent string. The seeded UA "Chrome on macOS" resolves to
    // the browser-only label "Chrome".
    expect(find.text('Chrome'), findsOneWidget);
    expect(find.text('Chrome on macOS'), findsNothing);
    // Raw token-suffix copy ("Token ending ab12") was dropped from the UI.
    expect(find.textContaining('ab12'), findsNothing);
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
    expect(find.text('Akun diperbarui.'), findsOneWidget);
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
    await tester.enterText(
      find.byKey(const Key('settings-confirm-password-field')),
      'short',
    );
    await tester.tap(find.byKey(const Key('settings-password-save-button')));
    await tester.pumpAndSettle();

    // The shared AuthValidators.password copy is now localized to Indonesian.
    expect(find.text('Gunakan minimal 8 karakter.'), findsOneWidget);
    expect(authRepository.changePasswordRequests, isEmpty);

    await tester.enterText(
      find.byKey(const Key('settings-new-password-field')),
      'newpassword123',
    );
    // The sheet now requires a matching confirm-password field before it will
    // submit; fill it so validation passes.
    await tester.enterText(
      find.byKey(const Key('settings-confirm-password-field')),
      'newpassword123',
    );
    await tester.tap(find.byKey(const Key('settings-password-save-button')));
    await tester.pumpAndSettle();

    expect(authRepository.changePasswordRequests, hasLength(1));
    expect(find.text('current password is incorrect'), findsOneWidget);
  });

  testWidgets('password change persists the refreshed token pair', (
    tester,
  ) async {
    final authRepository = FakeAuthRepository();
    final tokenStore = authenticatedTokenStore();

    await pumpAuthTestApp(
      tester,
      tokenStore: tokenStore,
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
      'newpassword123',
    );
    await tester.enterText(
      find.byKey(const Key('settings-confirm-password-field')),
      'newpassword123',
    );
    await tester.tap(find.byKey(const Key('settings-password-save-button')));
    await tester.pumpAndSettle();

    expect(authRepository.changePasswordRequests, hasLength(1));
    // The server revokes all other sessions on a password change and returns a
    // fresh pair; the device must persist it to stay signed in.
    expect(await tokenStore.readAccessToken(), 'fresh-access-token');
    expect(await tokenStore.readRefreshToken(), 'fresh-refresh-token');
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
    expect(find.text('Cabut sesi ini?'), findsOneWidget);
    // The seeded session is not the current device, so the confirm sheet warns
    // that the other device will be signed out.
    expect(
      find.textContaining('Perangkat itu akan dikeluarkan'),
      findsOneWidget,
    );

    await tester.tap(find.byKey(const Key('sky-confirm-accept')));
    await tester.pumpAndSettle();

    expect(authRepository.revokedSessionIds, [seededAuthSession.id]);
    expect(find.text('Sesi dicabut.'), findsOneWidget);
    // The parsed device label is gone once the only session is revoked.
    expect(find.text('Chrome'), findsNothing);
    expect(find.text('Tidak ada sesi lain'), findsOneWidget);
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

    // Errors now render through AffluenaBanner.error, which keeps the message
    // and exposes a retry affordance ("Coba lagi") instead of a keyed button.
    expect(
      find.text(
        'Unable to reach Affluena. Check your connection and try again.',
      ),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('settings-sessions-error-banner')),
      findsOneWidget,
    );
    final retryAction = find.descendant(
      of: find.byKey(const Key('settings-sessions-error-banner')),
      matching: find.text('Coba lagi'),
    );
    expect(retryAction, findsOneWidget);
    authRepository.listSessionsError = null;
    await tester.tap(retryAction);
    await tester.pumpAndSettle();

    expect(find.text('Chrome'), findsOneWidget);
    expect(authRepository.listSessionsCalls, 2);
  });
}

Future<void> _openSettings(WidgetTester tester) async {
  // The redesign shell exposes Settings via the "Lainnya" bottom-nav item,
  // which pushes the Settings route.
  await tester.tap(find.byKey(const Key('nav-lainnya')));
  await tester.pumpAndSettle();
}
