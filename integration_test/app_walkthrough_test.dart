import 'dart:io' show Platform;

import 'package:affluena_mobile/app/affluena_app.dart';
import 'package:affluena_mobile/app/provider_retry.dart';
import 'package:affluena_mobile/app/router.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:intl/date_symbol_data_local.dart';

/// Drives the real Affluena app against a live API (seeded demo user) on a
/// simulator and screenshots every module so the UI can be visually verified.
/// Navigation is driven through the app's GoRouter directly (reliable) rather
/// than by tapping list rows.
///
///   fvm flutter drive \
///     --driver test_driver/integration_test.dart \
///     --target integration_test/app_walkthrough_test.dart \
///     -d SIMULATOR_ID \
///     --dart-define=AFFLUENA_API_BASE_URL=http://localhost:8080/api/v1
void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('walkthrough every module', (tester) async {
    await initializeDateFormatting('id_ID');

    final container = ProviderContainer(retry: noProviderRetry);
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(container: container, child: const AffluenaApp()),
    );
    await tester.pumpAndSettle(const Duration(seconds: 2));
    if (Platform.isAndroid) {
      await binding.convertFlutterSurfaceToImage();
    }

    Future<void> shot(String name) async {
      await tester.pumpAndSettle();
      if (Platform.isAndroid) {
        await binding.convertFlutterSurfaceToImage();
      }
      await binding.takeScreenshot(name);
    }

    // --- Log in as the seeded demo user (skipped if a session is restored) ---
    if (find.byKey(const Key('login-email-field')).evaluate().isNotEmpty) {
      await tester.enterText(
        find.byKey(const Key('login-email-field')),
        'demo@affluena.com',
      );
      await tester.enterText(
        find.byKey(const Key('login-password-field')),
        'password123',
      );
      await tester.pump();
      await shot('00-login');
      await tester.tap(find.byKey(const Key('login-submit-button')));
      await tester.pumpAndSettle(const Duration(seconds: 4));
    }
    await shot('01-dashboard');

    // --- Visit every module route through the app's router ---
    final router = container.read(appRouterProvider);
    Future<void> visit(String path, String name) async {
      router.go(path);
      await tester.pumpAndSettle(const Duration(seconds: 2));
      await shot(name);
    }

    await visit('/wallets', '02-wallets');
    await visit('/quick-entry', '03-quick-entry');
    await visit('/transactions', '04-transactions');
    await visit('/transactions/new', '05-transaction-create');
    await visit('/transactions/split', '06-split-bill');
    await visit('/budgets', '07-budgets');
    await visit('/debts', '08-debts');
    await visit('/trackers', '09-installments-subscriptions');
    await visit('/recurring', '10-recurring');
    await visit('/goals', '11-goals');
    await visit('/categories-tags', '12-categories-tags');
    await visit('/quick-entry/templates', '13-quick-entry-templates');
    await visit('/insights', '14-insights');
    await visit('/audit-logs', '15-audit-logs');
    await visit('/settings', '16-settings');
    await visit('/security', '17-security');
  });
}
