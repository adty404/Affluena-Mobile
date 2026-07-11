import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../../../../app/theme/affluena_theme.dart';
import 'quick_amount_chips.dart';

/// A currency text field that displays grouped IDR (`Rp 1.234.567`) while the
/// user types and reports the value back as an integer in minor units.
///
/// IDR minor units are whole rupiah (no cents), so the digits the user enters
/// ARE the minor-unit value — this widget only adds grouping + the `Rp` prefix
/// so people never have to read or type a bare unformatted integer.
class MoneyInput extends StatefulWidget {
  const MoneyInput({
    required this.label,
    required this.onChanged,
    this.initialValue,
    this.validator,
    this.autovalidateMode,
    this.enabled = true,
    this.autofocus = false,
    this.focusNode,
    this.hint,
    this.helperText,
    this.showQuickAmounts = false,
    super.key,
  });

  final String label;
  final int? initialValue;
  final ValueChanged<int?> onChanged;
  final String? Function(int?)? validator;

  /// When set (e.g. [AutovalidateMode.onUserInteraction]) the [validator] runs
  /// as the user edits, surfacing the error under the field instead of only
  /// when a surrounding form validates on save.
  final AutovalidateMode? autovalidateMode;
  final bool enabled;
  final bool autofocus;
  final FocusNode? focusNode;
  final String? hint;

  /// Persistent helper line under the field (e.g. to explain what the amount
  /// means), shown via [InputDecoration.helperText].
  final String? helperText;

  /// Renders a [QuickAmountChips] strip under the field (`10rb … 1jt`);
  /// tapping a chip REPLACES the amount and reports it through [onChanged].
  /// Opt in on forms where a fresh amount is typically entered (transaction
  /// create/edit); leave off for odd fields like the adjustment "saldo baru".
  final bool showQuickAmounts;

  @override
  State<MoneyInput> createState() => _MoneyInputState();
}

class _MoneyInputState extends State<MoneyInput> {
  late final TextEditingController _controller;
  final _formatter = _ThousandsFormatter();

  @override
  void initState() {
    super.initState();
    final initial = widget.initialValue;
    _controller = TextEditingController(
      text: (initial == null || initial == 0)
          ? ''
          : _ThousandsFormatter.grouped(initial),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  int? _parse(String text) {
    final digits = text.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.isEmpty) return null;
    return int.tryParse(digits);
  }

  /// A quick-amount chip SETS the field (replaces, never adds) and reports the
  /// value exactly as if it had been typed.
  void _applyQuickAmount(int minor) {
    setState(() {
      _controller.text = _ThousandsFormatter.grouped(minor);
    });
    widget.onChanged(minor);
  }

  @override
  Widget build(BuildContext context) {
    final field = TextFormField(
      controller: _controller,
      enabled: widget.enabled,
      autofocus: widget.autofocus,
      focusNode: widget.focusNode,
      // Digits-only pad: amounts are whole rupiah, so the +/- and decimal keys
      // exposed by numberWithOptions have no valid use here.
      keyboardType: TextInputType.number,
      inputFormatters: [_formatter],
      decoration: InputDecoration(
        labelText: widget.label,
        hintText: widget.hint,
        helperText: widget.helperText,
        helperMaxLines: 2,
        prefixText: 'Rp ',
      ),
      validator: widget.validator == null
          ? null
          : (raw) => widget.validator!(_parse(raw ?? '')),
      autovalidateMode: widget.autovalidateMode,
      // setState keeps the chip strip's selected state in sync while typing.
      onChanged: (raw) => setState(() => widget.onChanged(_parse(raw))),
    );
    if (!widget.showQuickAmounts) return field;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        field,
        const SizedBox(height: AffluenaSpacing.space2),
        QuickAmountChips(
          onSelected: _applyQuickAmount,
          selectedMinor: _parse(_controller.text),
          enabled: widget.enabled,
        ),
      ],
    );
  }
}

/// Reformats raw digit input into `id_ID` grouped thousands as the user types,
/// keeping the caret at the end.
class _ThousandsFormatter extends TextInputFormatter {
  static final NumberFormat _decimal = NumberFormat.decimalPattern('id_ID');

  static String grouped(int value) => _decimal.format(value);

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digits = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.isEmpty) {
      return const TextEditingValue(text: '');
    }
    final value = int.tryParse(digits);
    if (value == null) return oldValue;
    final formatted = _decimal.format(value);
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}
