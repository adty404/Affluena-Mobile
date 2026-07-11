import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/auth_test_helpers.dart';

void main() {
  testWidgets('system text scale is clamped to at most 1.1×', (tester) async {
    // Simulate a device set to a huge system font (the 125%+ setting that
    // broke money layouts before the clamp).
    tester.platformDispatcher.textScaleFactorTestValue = 1.5;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

    await pumpAuthTestApp(tester, tokenStore: authenticatedTokenStore());

    // Any text inside the app must resolve the clamped scaler (max 1.1), not
    // the raw 1.5 system value.
    final context = tester.element(find.text('Total saldo'));
    final scaler = MediaQuery.textScalerOf(context);
    expect(scaler.scale(10), closeTo(11, 0.001));
  });

  testWidgets('smaller-than-default text scale passes through unclamped', (
    tester,
  ) async {
    tester.platformDispatcher.textScaleFactorTestValue = 0.85;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

    await pumpAuthTestApp(tester, tokenStore: authenticatedTokenStore());

    // No minimum clamp: a user who prefers smaller type keeps it.
    final context = tester.element(find.text('Total saldo'));
    final scaler = MediaQuery.textScalerOf(context);
    expect(scaler.scale(10), closeTo(8.5, 0.001));
  });
}
