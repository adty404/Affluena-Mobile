import 'package:flutter/material.dart';

import '../../../app/theme/affluena_theme.dart';
import '../data/dashboard_models.dart';

/// A compact, dependency-free income vs. expense bar chart for the last few
/// months. Built with [CustomPainter] — no charting package. Bars share a
/// single vertical scale so income and expense are visually comparable.
class CashflowTrendChart extends StatelessWidget {
  const CashflowTrendChart({required this.points, super.key});

  final List<CashflowTrendPoint> points;

  @override
  Widget build(BuildContext context) {
    final colors = context.affluenaColors;

    return SizedBox(
      height: 132,
      child: CustomPaint(
        painter: _CashflowTrendPainter(
          points: points,
          income: colors.forest,
          expense: colors.coral,
          axis: colors.borderSubtle,
          label: colors.inkMuted,
          labelStyle: Theme.of(context).textTheme.labelMedium,
        ),
        child: const SizedBox.expand(),
      ),
    );
  }
}

class _CashflowTrendPainter extends CustomPainter {
  _CashflowTrendPainter({
    required this.points,
    required this.income,
    required this.expense,
    required this.axis,
    required this.label,
    required this.labelStyle,
  });

  final List<CashflowTrendPoint> points;
  final Color income;
  final Color expense;
  final Color axis;
  final Color label;
  final TextStyle? labelStyle;

  static const double _labelGutter = 18;
  static const double _barRadius = 3;

  @override
  void paint(Canvas canvas, Size size) {
    if (points.isEmpty) return;

    final chartHeight = size.height - _labelGutter;
    final baselineY = chartHeight;

    final axisPaint = Paint()
      ..color = axis
      ..strokeWidth = 1;
    canvas.drawLine(
      Offset(0, baselineY),
      Offset(size.width, baselineY),
      axisPaint,
    );

    var maxValue = 0;
    for (final point in points) {
      if (point.incomeMinor > maxValue) maxValue = point.incomeMinor;
      if (point.expenseMinor > maxValue) maxValue = point.expenseMinor;
    }
    if (maxValue <= 0) maxValue = 1;

    final slot = size.width / points.length;
    final barWidth = (slot * 0.26).clamp(4.0, 18.0);
    final gap = barWidth * 0.35;

    final incomePaint = Paint()..color = income;
    final expensePaint = Paint()..color = expense;

    for (var i = 0; i < points.length; i++) {
      final point = points[i];
      final center = slot * i + slot / 2;
      final incomeHeight = chartHeight * (point.incomeMinor / maxValue);
      final expenseHeight = chartHeight * (point.expenseMinor / maxValue);

      _paintBar(
        canvas,
        center - barWidth - gap / 2,
        barWidth,
        incomeHeight,
        baselineY,
        incomePaint,
      );
      _paintBar(
        canvas,
        center + gap / 2,
        barWidth,
        expenseHeight,
        baselineY,
        expensePaint,
      );

      _paintLabel(
        canvas,
        _monthLabel(point.month),
        center,
        size.width,
        baselineY,
      );
    }
  }

  void _paintBar(
    Canvas canvas,
    double left,
    double width,
    double height,
    double baselineY,
    Paint paint,
  ) {
    final clamped = height.clamp(0.0, baselineY);
    if (clamped <= 0) return;
    final rect = RRect.fromRectAndCorners(
      Rect.fromLTWH(left, baselineY - clamped, width, clamped),
      topLeft: const Radius.circular(_barRadius),
      topRight: const Radius.circular(_barRadius),
    );
    canvas.drawRRect(rect, paint);
  }

  void _paintLabel(
    Canvas canvas,
    String text,
    double center,
    double maxWidth,
    double baselineY,
  ) {
    final painter = TextPainter(
      text: TextSpan(text: text, style: labelStyle?.copyWith(color: label)),
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
    )..layout();
    var dx = center - painter.width / 2;
    if (dx < 0) dx = 0;
    if (dx + painter.width > maxWidth) dx = maxWidth - painter.width;
    final dy = baselineY + (_labelGutter - painter.height) / 2;
    painter.paint(canvas, Offset(dx, dy));
  }

  static String _monthLabel(String monthKey) {
    // monthKey is "yyyy-MM"; render a short month name without a new dep.
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    final parts = monthKey.split('-');
    if (parts.length < 2) return monthKey;
    final month = int.tryParse(parts[1]);
    if (month == null || month < 1 || month > 12) return monthKey;
    return months[month - 1];
  }

  @override
  bool shouldRepaint(_CashflowTrendPainter oldDelegate) {
    return oldDelegate.points != points ||
        oldDelegate.income != income ||
        oldDelegate.expense != expense ||
        oldDelegate.axis != axis ||
        oldDelegate.label != label;
  }
}
