import 'package:flutter/material.dart';

import '../../../../app/theme/affluena_theme.dart';
import '../../../../app/theme/sky_palette.dart';

/// Calculator-style keypad for the quick-add capture sheet: digits plus inline
/// arithmetic (+ − × ÷ =), clear, backspace, "000", decimal, and a primary
/// confirm (✓) action. Presentational only — it emits semantic taps; the parent
/// owns a [MoneyCalculator] and the save action.
class SkyCalcKeypad extends StatelessWidget {
  const SkyCalcKeypad({
    required this.onDigit,
    required this.onOperator,
    required this.onClear,
    required this.onBackspace,
    required this.onDecimal,
    required this.onEquals,
    required this.onConfirm,
    this.isSaving = false,
    super.key,
  });

  final ValueChanged<String> onDigit;
  final ValueChanged<String> onOperator;
  final VoidCallback onClear;
  final VoidCallback onBackspace;
  final VoidCallback onDecimal;
  final VoidCallback onEquals;
  final VoidCallback onConfirm;
  final bool isSaving;

  static const double _cellHeight = 52;

  @override
  Widget build(BuildContext context) {
    Widget gap() => const SizedBox(height: AffluenaSpacing.space2);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _row([
          _ActionCell(label: 'C', onTap: onClear),
          _OpCell(symbol: '÷', onTap: () => onOperator('÷')),
          _OpCell(symbol: '×', onTap: () => onOperator('×')),
          _IconCell(icon: Icons.backspace_outlined, onTap: onBackspace),
        ]),
        gap(),
        _row([
          _DigitCell(digit: '7', onTap: () => onDigit('7')),
          _DigitCell(digit: '8', onTap: () => onDigit('8')),
          _DigitCell(digit: '9', onTap: () => onDigit('9')),
          _OpCell(symbol: '−', onTap: () => onOperator('-')),
        ]),
        gap(),
        _row([
          _DigitCell(digit: '4', onTap: () => onDigit('4')),
          _DigitCell(digit: '5', onTap: () => onDigit('5')),
          _DigitCell(digit: '6', onTap: () => onDigit('6')),
          _OpCell(symbol: '+', onTap: () => onOperator('+')),
        ]),
        gap(),
        _row([
          _DigitCell(digit: '1', onTap: () => onDigit('1')),
          _DigitCell(digit: '2', onTap: () => onDigit('2')),
          _DigitCell(digit: '3', onTap: () => onDigit('3')),
          _OpCell(symbol: '=', onTap: onEquals),
        ]),
        gap(),
        _row([
          _ActionCell(label: ',', onTap: onDecimal, accent: false),
          _DigitCell(digit: '0', onTap: () => onDigit('0')),
          _ActionCell(label: '000', onTap: () => onDigit('000'), accent: false),
          _ConfirmCell(onTap: isSaving ? null : onConfirm, isSaving: isSaving),
        ]),
      ],
    );
  }

  Widget _row(List<Widget> cells) {
    final children = <Widget>[];
    for (var i = 0; i < cells.length; i++) {
      if (i > 0) children.add(const SizedBox(width: AffluenaSpacing.space2));
      children.add(Expanded(child: cells[i]));
    }
    return SizedBox(
      height: _cellHeight,
      child: Row(children: children),
    );
  }
}

class _Cell extends StatelessWidget {
  const _Cell({
    required this.child,
    required this.onTap,
    this.filled = false,
    super.key,
  });

  final Widget child;
  final VoidCallback? onTap;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(AffluenaRadii.md);
    return Material(
      color: filled ? context.sky.accent : context.sky.surface,
      borderRadius: radius,
      child: InkWell(
        borderRadius: radius,
        onTap: onTap,
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: radius,
            border: filled ? null : Border.all(color: context.sky.line),
          ),
          child: Center(child: child),
        ),
      ),
    );
  }
}

class _DigitCell extends StatelessWidget {
  const _DigitCell({required this.digit, required this.onTap});
  final String digit;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return _Cell(
      onTap: onTap,
      child: Text(
        digit,
        style: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: context.sky.ink,
          fontFeatures: const [FontFeature.tabularFigures()],
        ),
      ),
    );
  }
}

class _OpCell extends StatelessWidget {
  const _OpCell({required this.symbol, required this.onTap});
  final String symbol;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return _Cell(
      onTap: onTap,
      child: Text(
        symbol,
        style: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w600,
          color: context.sky.accent,
        ),
      ),
    );
  }
}

class _ActionCell extends StatelessWidget {
  const _ActionCell({
    required this.label,
    required this.onTap,
    this.accent = true,
  });
  final String label;
  final VoidCallback onTap;
  final bool accent;

  @override
  Widget build(BuildContext context) {
    return _Cell(
      onTap: onTap,
      child: Text(
        label,
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: accent ? context.sky.accent : context.sky.ink,
        ),
      ),
    );
  }
}

class _IconCell extends StatelessWidget {
  const _IconCell({required this.icon, required this.onTap});
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return _Cell(
      key: const Key('sky-calc-backspace'),
      onTap: onTap,
      child: Icon(icon, size: 20, color: context.sky.accent),
    );
  }
}

class _ConfirmCell extends StatelessWidget {
  const _ConfirmCell({required this.onTap, required this.isSaving});
  final VoidCallback? onTap;
  final bool isSaving;

  @override
  Widget build(BuildContext context) {
    return _Cell(
      key: const Key('sky-calc-confirm'),
      filled: true,
      onTap: onTap,
      child: isSaving
          ? SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation(context.sky.onAccent),
              ),
            )
          : Icon(Icons.check, size: 22, color: context.sky.onAccent),
    );
  }
}
