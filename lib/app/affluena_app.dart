import 'package:flutter/material.dart';

import 'router.dart';
import 'theme/affluena_theme.dart';

class AffluenaApp extends StatelessWidget {
  const AffluenaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Affluena',
      debugShowCheckedModeBanner: false,
      theme: AffluenaTheme.light,
      darkTheme: AffluenaTheme.dark,
      routerConfig: appRouter,
    );
  }
}
