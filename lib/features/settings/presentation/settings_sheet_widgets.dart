import 'package:flutter/material.dart';

import '../../../app/theme/affluena_theme.dart';

class SettingsSheetFrame extends StatelessWidget {
  const SettingsSheetFrame({
    required this.title,
    required this.child,
    super.key,
  });

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    final textTheme = Theme.of(context).textTheme;
    return Padding(
      padding: EdgeInsets.fromLTRB(
        AffluenaSpacing.space5,
        AffluenaSpacing.space5,
        AffluenaSpacing.space5,
        bottomInset + AffluenaSpacing.space5,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(title, style: textTheme.titleLarge),
            const SizedBox(height: AffluenaSpacing.space4),
            child,
          ],
        ),
      ),
    );
  }
}

class SettingsInlineMessage extends StatelessWidget {
  const SettingsInlineMessage({
    required this.message,
    required this.isError,
    super.key,
  });

  final String message;
  final bool isError;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: isError
            ? AffluenaColors.coral.withAlpha(24)
            : AffluenaColors.forestSoft,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isError ? AffluenaColors.coral : AffluenaColors.borderSubtle,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AffluenaSpacing.space3),
        child: Text(message),
      ),
    );
  }
}
