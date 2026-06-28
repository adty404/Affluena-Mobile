import 'package:flutter/material.dart';

import '../../../../app/theme/affluena_theme.dart';
import '../../../../app/theme/sky_palette.dart';

/// The numeric keypad for the redesign's quick-add capture sheet.
///
/// Presentational only: it emits taps via [onKey] (a digit string, or "000")
/// and [onBackspace]; the parent owns and formats the amount value. Wiring into
/// the capture sheet + transactions API lands in a later stage.
class SkyKeypad extends StatelessWidget {
  const SkyKeypad({required this.onKey, required this.onBackspace, super.key});

  final ValueChanged<String> onKey;
  final VoidCallback onBackspace;

  static const _digits = [
    '1',
    '2',
    '3',
    '4',
    '5',
    '6',
    '7',
    '8',
    '9',
    '000',
    '0',
  ];

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 3,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: AffluenaSpacing.space2,
      crossAxisSpacing: AffluenaSpacing.space2,
      childAspectRatio: 2,
      children: [
        for (final digit in _digits)
          _Key(
            onTap: () => onKey(digit),
            child: Text(
              digit,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: context.sky.ink,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ),
        _Key(
          key: const Key('sky-keypad-backspace'),
          onTap: onBackspace,
          child: Icon(
            Icons.backspace_outlined,
            size: 20,
            color: context.sky.muted,
          ),
        ),
      ],
    );
  }
}

class _Key extends StatelessWidget {
  const _Key({required this.child, required this.onTap, super.key});

  final Widget child;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(AffluenaRadii.md);
    return Material(
      color: context.sky.surface,
      borderRadius: radius,
      child: InkWell(
        borderRadius: radius,
        onTap: onTap,
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: radius,
            border: Border.all(color: context.sky.line),
          ),
          child: Center(child: child),
        ),
      ),
    );
  }
}
