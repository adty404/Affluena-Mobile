import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'router.dart';
import 'theme/affluena_theme.dart';
import 'theme/theme_mode_controller.dart';

class AffluenaApp extends ConsumerWidget {
  const AffluenaApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp.router(
      title: 'Affluena',
      debugShowCheckedModeBanner: false,
      theme: AffluenaTheme.light,
      darkTheme: AffluenaTheme.dark,
      themeMode: ref.watch(appThemeModeProvider),
      routerConfig: ref.watch(appRouterProvider),
      // Standard finance-app behaviour (BCA/Gojek do the same): honour the
      // system font-size setting but cap it at 1.1× — unbounded scaling breaks
      // money layouts (truncated balances, wrapped rows) and the app's own
      // type scale already errs large. No minimum clamp: shrinking is safe.
      builder: (context, child) {
        final mediaQuery = MediaQuery.of(context);
        return MediaQuery(
          data: mediaQuery.copyWith(
            textScaler: mediaQuery.textScaler.clamp(maxScaleFactor: 1.1),
          ),
          child: child ?? const SizedBox.shrink(),
        );
      },
    );
  }
}
