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
    );
  }
}
