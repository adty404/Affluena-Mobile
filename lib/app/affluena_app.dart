import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'router.dart';
import 'theme/affluena_theme.dart';

class AffluenaApp extends ConsumerWidget {
  const AffluenaApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp.router(
      title: 'Affluena',
      debugShowCheckedModeBanner: false,
      theme: AffluenaTheme.light,
      darkTheme: AffluenaTheme.dark,
      routerConfig: ref.watch(appRouterProvider),
    );
  }
}
