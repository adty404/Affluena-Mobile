import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
// The async in-memory backend lives in the platform-interface package, which is
// only a transitive dependency here; the import is test-only.
// ignore: depend_on_referenced_packages
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
// ignore: depend_on_referenced_packages
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

import '../../helpers/auth_test_helpers.dart';

/// Saldo masking (the Beranda eye toggle): balances/summaries mask to
/// `Rp ••••••`; the working ledger (transaction rows) stays visible. See
/// DESIGN.md "Saldo masking".
void main() {
  setUp(() {
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
  });

  Future<void> pumpBeranda(WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 1400));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await pumpAuthTestApp(tester, tokenStore: authenticatedTokenStore());
  }

  testWidgets('eye toggle masks the hero total and wallet card balances', (
    tester,
  ) async {
    await pumpBeranda(tester);

    // Seeded wallet: balance 320.000 shows on the hero AND the Dompet card.
    expect(find.text('Rp 320.000'), findsNWidgets(2));
    expect(find.text('Rp ••••••'), findsNothing);
    expect(find.byIcon(Icons.visibility), findsOneWidget);

    await tester.tap(find.byKey(const Key('beranda-amount-visibility-toggle')));
    await tester.pumpAndSettle();

    // Both balance surfaces mask; no real digits remain.
    expect(find.text('Rp ••••••'), findsNWidgets(2));
    expect(find.text('Rp 320.000'), findsNothing);
    expect(find.byIcon(Icons.visibility_off), findsOneWidget);
  });

  testWidgets('hidden state persists across an app restart', (tester) async {
    await pumpBeranda(tester);
    await tester.tap(find.byKey(const Key('beranda-amount-visibility-toggle')));
    await tester.pumpAndSettle();
    expect(find.text('Rp ••••••'), findsNWidgets(2));

    // "Restart": a brand-new app over the same (in-memory) storage.
    await pumpAuthTestApp(tester, tokenStore: authenticatedTokenStore());
    await tester.pumpAndSettle();

    expect(find.text('Rp ••••••'), findsNWidgets(2));
    expect(find.text('Rp 320.000'), findsNothing);
  });

  testWidgets('the working ledger stays visible while balances are masked', (
    tester,
  ) async {
    await pumpBeranda(tester);
    await tester.tap(find.byKey(const Key('beranda-amount-visibility-toggle')));
    await tester.pumpAndSettle();

    // Open the Aktivitas feed — its transaction rows are the working ledger
    // and must keep real amounts even while balances are masked.
    await tester.tap(find.byKey(const Key('nav-aktivitas')));
    await tester.pumpAndSettle();

    // The seeded transaction (125.000 expense) renders with real digits.
    expect(find.textContaining('125.000'), findsWidgets);
  });
}
