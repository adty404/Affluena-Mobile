import 'package:flutter/material.dart';

import '../../../../app/theme/affluena_theme.dart';

enum StatusTone { success, warning, danger, neutral }

/// A compact status pill colored by semantic meaning rather than the brand
/// accent. Active/Paused/Cancelled must look different — status carries its own
/// visual weight.
class StatusBadge extends StatelessWidget {
  const StatusBadge({required this.label, this.tone = StatusTone.neutral, super.key});

  final String label;
  final StatusTone tone;

  /// Maps a backend status string to a tone + a human-readable label.
  factory StatusBadge.forStatus(String status, {String? label}) {
    final normalized = status.trim().toLowerCase();
    final tone = switch (normalized) {
      'active' || 'joined' || 'paid_off' || 'achieved' || 'completed' || 'success' =>
        StatusTone.success,
      'partial' || 'paused' || 'pending' || 'processing' => StatusTone.warning,
      'cancelled' || 'canceled' || 'rejected' || 'failed' || 'overdue' =>
        StatusTone.danger,
      _ => StatusTone.neutral,
    };
    return StatusBadge(label: label ?? _humanize(normalized), tone: tone);
  }

  static String _humanize(String value) {
    if (value.isEmpty) return value;
    return value
        .split('_')
        .map((w) => w.isEmpty ? w : '${w[0].toUpperCase()}${w.substring(1)}')
        .join(' ');
  }

  ({Color fg, Color bg}) _resolve(AffluenaSemanticColors c) {
    switch (tone) {
      case StatusTone.success:
        return (fg: c.success, bg: c.forestSoft);
      case StatusTone.warning:
        return (fg: c.amber, bg: Color.alphaBlend(c.amber.withAlpha(28), c.surfaceSoft));
      case StatusTone.danger:
        return (fg: c.coral, bg: Color.alphaBlend(c.coral.withAlpha(28), c.surfaceSoft));
      case StatusTone.neutral:
        return (fg: c.inkMuted, bg: c.surfaceTintSoft);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.affluenaColors;
    final textTheme = Theme.of(context).textTheme;
    final spec = _resolve(colors);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: spec.bg,
        borderRadius: BorderRadius.circular(AffluenaRadii.pill),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AffluenaSpacing.space3,
          vertical: AffluenaSpacing.space1,
        ),
        child: Text(
          label,
          style: textTheme.labelMedium?.copyWith(
            color: spec.fg,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}
