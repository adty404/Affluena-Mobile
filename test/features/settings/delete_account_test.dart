import 'package:affluena_mobile/core/api/api_error.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/auth_test_helpers.dart';

/// Pengaturan → Hapus akun: the in-app half of the Google Play
/// account-deletion requirement (password-confirmed, permanent).
void main() {
  Future<void> openDeleteSheet(WidgetTester tester) async {
    await tester.tap(find.byKey(const Key('nav-lainnya')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('settings-delete-account-row')));
    await tester.pumpAndSettle();
  }

  testWidgets('deletes the account with the entered password and signs out', (
    tester,
  ) async {
    final authRepository = FakeAuthRepository();

    await pumpAuthTestApp(
      tester,
      tokenStore: authenticatedTokenStore(),
      authRepository: authRepository,
    );
    await openDeleteSheet(tester);

    expect(find.text('Hapus akun'), findsWidgets);
    await tester.enterText(
      find.byKey(const Key('settings-delete-account-password-field')),
      'password123',
    );
    await tester.tap(find.byKey(const Key('settings-delete-account-button')));
    await tester.pumpAndSettle();

    // The repo received the password re-entry and the session ended: the
    // router lands back on the login screen with the farewell message.
    expect(authRepository.deleteAccountPasswords, ['password123']);
    expect(
      find.text('Akunmu sudah dihapus. Sampai jumpa lagi.'),
      findsOneWidget,
    );
  });

  testWidgets('wrong password shows the API error and stays signed in', (
    tester,
  ) async {
    final authRepository = FakeAuthRepository(
      deleteAccountError: const ApiException(
        statusCode: 401,
        message: 'Kata sandi salah.',
      ),
    );

    await pumpAuthTestApp(
      tester,
      tokenStore: authenticatedTokenStore(),
      authRepository: authRepository,
    );
    await openDeleteSheet(tester);

    await tester.enterText(
      find.byKey(const Key('settings-delete-account-password-field')),
      'salah',
    );
    await tester.tap(find.byKey(const Key('settings-delete-account-button')));
    await tester.pumpAndSettle();

    // Error surfaces in the sheet; nothing was torn down locally.
    expect(find.text('Kata sandi salah.'), findsOneWidget);
    expect(
      find.byKey(const Key('settings-delete-account-password-field')),
      findsOneWidget,
    );
  });

  testWidgets('empty password blocks submission client-side', (tester) async {
    final authRepository = FakeAuthRepository();

    await pumpAuthTestApp(
      tester,
      tokenStore: authenticatedTokenStore(),
      authRepository: authRepository,
    );
    await openDeleteSheet(tester);

    await tester.tap(find.byKey(const Key('settings-delete-account-button')));
    await tester.pumpAndSettle();

    expect(
      find.text('Masukkan kata sandimu untuk konfirmasi.'),
      findsOneWidget,
    );
    expect(authRepository.deleteAccountPasswords, isEmpty);
  });
}
