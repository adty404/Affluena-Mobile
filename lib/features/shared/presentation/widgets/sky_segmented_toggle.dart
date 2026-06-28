import 'package:flutter/material.dart';

import '../../../../app/theme/affluena_theme.dart';
import '../../../../app/theme/sky_palette.dart';

/// One option in a [SkySegmentedToggle].
class SkySegmentOption<T> {
  const SkySegmentOption({required this.value, required this.label});

  final T value;
  final String label;
}

/// A calm 2+ option segmented control used across the redesign — e.g.
/// Pengeluaran/Pemasukan and the "ke: Dompetku / Dompet Kita" toggle in
/// quick-add.
class SkySegmentedToggle<T> extends StatelessWidget {
  const SkySegmentedToggle({
    required this.options,
    required this.selected,
    required this.onChanged,
    this.enabled = true,
    super.key,
  });

  final List<SkySegmentOption<T>> options;
  final T selected;
  final ValueChanged<T> onChanged;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: SkyPalette.accentSoft,
        borderRadius: BorderRadius.circular(AffluenaRadii.control),
      ),
      child: Row(
        children: [
          for (final option in options)
            Expanded(
              child: _Segment(
                label: option.label,
                active: option.value == selected,
                onTap: enabled ? () => onChanged(option.value) : null,
              ),
            ),
        ],
      ),
    );
  }
}

class _Segment extends StatelessWidget {
  const _Segment({required this.label, required this.active, this.onTap});

  final String label;
  final bool active;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: active ? SkyPalette.surface : Colors.transparent,
          borderRadius: BorderRadius.circular(AffluenaRadii.md),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 9),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: active ? SkyPalette.ink : SkyPalette.muted,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
