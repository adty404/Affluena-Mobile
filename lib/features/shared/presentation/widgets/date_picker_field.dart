import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../app/theme/affluena_theme.dart';

/// A tappable date field that mirrors [SelectorRow] and opens the native date
/// picker. Replaces hand-typed `YYYY-MM-DD` / RFC3339 text fields so users
/// never type — or even see — a machine date format.
class DatePickerField extends StatelessWidget {
  const DatePickerField({
    required this.label,
    required this.value,
    required this.onChanged,
    this.icon = Icons.event_outlined,
    this.firstDate,
    this.lastDate,
    this.placeholder = 'Pilih tanggal',
    this.enabled = true,
    super.key,
  });

  final String label;
  final DateTime? value;
  final ValueChanged<DateTime> onChanged;
  final IconData icon;
  final DateTime? firstDate;
  final DateTime? lastDate;
  final String placeholder;
  final bool enabled;

  static final DateFormat _display = DateFormat('d MMM yyyy', 'id_ID');

  Future<void> _pick(BuildContext context) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: value ?? now,
      firstDate: firstDate ?? DateTime(now.year - 5),
      lastDate: lastDate ?? DateTime(now.year + 5),
    );
    if (picked != null) onChanged(picked);
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colors = context.affluenaColors;
    final hasValue = value != null;

    return Semantics(
      button: true,
      enabled: enabled,
      label: label,
      value: hasValue ? _display.format(value!) : placeholder,
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          onTap: enabled ? () => _pick(context) : null,
          borderRadius: BorderRadius.circular(AffluenaRadii.md),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 56),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                vertical: AffluenaSpacing.space2,
              ),
              child: Row(
                children: [
                  DecoratedBox(
                    decoration: BoxDecoration(
                      color: enabled
                          ? colors.forestSoft
                          : colors.surfaceTintSoft,
                      borderRadius: BorderRadius.circular(AffluenaRadii.md),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(AffluenaSpacing.space2),
                      child: Icon(
                        icon,
                        color: enabled ? colors.forest : colors.inkMuted,
                        size: 18,
                      ),
                    ),
                  ),
                  const SizedBox(width: AffluenaSpacing.space3),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(label, style: textTheme.bodySmall),
                        const SizedBox(height: AffluenaSpacing.space1),
                        Text(
                          hasValue ? _display.format(value!) : placeholder,
                          style: textTheme.bodyLarge?.copyWith(
                            color: hasValue ? colors.ink : colors.inkMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (enabled)
                    Icon(Icons.chevron_right, color: colors.inkMuted),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
