import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/auth_test_helpers.dart';

/// Beranda's "Diperbarui HH.mm" stamp: set only when the dashboard summary's
/// REAL fetch path completes (dashboardRefreshedAtProvider.mark, timed by the
/// overridable clockProvider). The full-app harness pins the clock to
/// 2026-06-21 14:32, so the stamp is deterministic here and in goldens; tests
/// that override dashboardSummaryProvider directly never mark it, so the
/// stamp stays hidden there.
void main() {
  testWidgets('shows when the summary arrives, timed by the pinned clock', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await pumpAuthTestApp(tester, tokenStore: authenticatedTokenStore());

    expect(
      find.textContaining('Diperbarui 14.32'),
      findsOneWidget,
      reason: 'the summary fetch landed, stamped via the pinned clock',
    );
  });
}
