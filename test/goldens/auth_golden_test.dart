@Tags(['golden'])
library;

import 'package:affluena_mobile/app/theme/affluena_theme.dart';
import 'package:affluena_mobile/features/auth/application/auth_controller.dart';
import 'package:affluena_mobile/features/auth/presentation/auth_screens.dart';
import 'package:affluena_mobile/features/onboarding/presentation/onboarding_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// Golden (design-snapshot) tests of the re-skinned Onboarding & Auth screens —
/// the Sky & Denim look from the design guide. Baselines are host-specific
/// (generated on macOS); CI excludes the `golden` tag and runs them locally.
///
/// Goldens render with the test default font (no bundled app font), so they are
/// a layout drift detector, not a pixel match of the device.
class _UnauthController extends AuthController {
  @override
  AuthState build() => const AuthState.unauthenticated();
}

Future<void> _pump(WidgetTester tester, Widget screen) async {
  await tester.binding.setSurfaceSize(const Size(390, 844));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  await tester.pumpWidget(
    ProviderScope(
      overrides: [authControllerProvider.overrideWith(_UnauthController.new)],
      child: MaterialApp(theme: AffluenaTheme.light, home: screen),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('onboarding golden', (tester) async {
    await _pump(tester, const OnboardingScreen());
    await expectLater(
      find.byType(OnboardingScreen),
      matchesGoldenFile('goldens/auth_onboarding.png'),
    );
  });

  testWidgets('login golden', (tester) async {
    await _pump(tester, const LoginScreen());
    await expectLater(
      find.byType(LoginScreen),
      matchesGoldenFile('goldens/auth_login.png'),
    );
  });

  testWidgets('register golden', (tester) async {
    await _pump(tester, const RegisterScreen());
    await expectLater(
      find.byType(RegisterScreen),
      matchesGoldenFile('goldens/auth_register.png'),
    );
  });
}
