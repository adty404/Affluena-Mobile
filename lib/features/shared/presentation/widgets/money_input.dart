import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

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
    this.enabled = true,
    this.autofocus = false,
    this.hint,
    super.key,
  });

  final String label;
  final int? initialValue;
  final ValueChanged<int?> onChanged;
  final String? Function(int?)? validator;
  final bool enabled;
  final bool autofocus;
  final String? hint;

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

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: _controller,
      enabled: widget.enabled,
      autofocus: widget.autofocus,
      keyboardType: const TextInputType.numberWithOptions(decimal: false),
      inputFormatters: [_formatter],
      decoration: InputDecoration(
        labelText: widget.label,
        hintText: widget.hint,
        prefixText: 'Rp ',
      ),
      validator: widget.validator == null
          ? null
          : (raw) => widget.validator!(_parse(raw ?? '')),
      onChanged: (raw) => widget.onChanged(_parse(raw)),
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
