import 'package:flutter/material.dart';

import '../../../../app/theme/affluena_theme.dart';

class AffluenaCard extends StatelessWidget {
  const AffluenaCard({
    required this.child,
    this.padding = const EdgeInsets.all(AffluenaSpacing.space5),
    this.backgroundColor,
    this.borderColor,
    super.key,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color? backgroundColor;
  final Color? borderColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: backgroundColor ?? theme.cardColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: borderColor ?? AffluenaColors.borderSubtle),
      ),
      child: Padding(padding: padding, child: child),
    );
  }
}
