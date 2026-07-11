/// A small immediate-execution (4-function) calculator for entering money
/// amounts. It lets the user do quick inline math while capturing a
/// transaction — e.g. `50000 + 25000` — before confirming.
///
/// Pure Dart, no Flutter, so it is easy to unit-test. The widget layer feeds it
/// button taps and reads [displayValue] / [amountMinor] / [expressionPreview].
///
/// Behaviour mirrors a phone calculator: the display shows the operand you are
/// typing (or the last result); operators chain left-to-right; `=` (or
/// confirming) evaluates the pending operation. Amounts are whole currency
/// units — [amountMinor] rounds the current value and never goes negative.
class MoneyCalculator {
  /// The number currently shown: the operand being typed, or a result. Always
  /// a parseable decimal string (e.g. "0", "50000", "1234.5").
  String _display = '0';

  /// The left-hand value captured when an operator was pressed.
  double? _stored;

  /// The pending operator symbol: '+', '-', '×' or '÷'.
  String? _op;

  /// When true, the next digit starts a fresh operand (set after an operator
  /// or after `=`), so typing replaces the shown result instead of appending.
  bool _startNew = true;

  static const _maxDigits = 12;

  String get display => _display;
  String? get pendingOp => _op;

  /// Has the user entered anything beyond the initial 0?
  bool get isEmpty => _op == null && _startNew && _display == '0';

  /// The value currently on the display (operand or last result).
  double get displayValue => double.tryParse(_display) ?? 0;

  int _digitCount(String s) => s.replaceAll('-', '').replaceAll('.', '').length;

  void inputDigit(String d) {
    if (_startNew) {
      _display = d;
      _startNew = false;
      return;
    }
    if (_display == '0') {
      if (d != '0') _display = d;
      return;
    }
    if (_digitCount(_display) < _maxDigits) _display += d;
  }

  /// The "000" key — appends up to three zeros to the current operand.
  void inputZeros() {
    if (_startNew) {
      _display = '0';
      _startNew = false;
      return;
    }
    if (_display == '0') return;
    for (var i = 0; i < 3 && _digitCount(_display) < _maxDigits; i++) {
      _display += '0';
    }
  }

  void inputDecimal() {
    if (_startNew) {
      _display = '0.';
      _startNew = false;
      return;
    }
    if (!_display.contains('.')) _display += '.';
  }

  void backspace() {
    if (_startNew) return; // showing a result; nothing in the operand to edit
    if (_display.length <= 1) {
      _display = '0';
      return;
    }
    final next = _display.substring(0, _display.length - 1);
    _display = (next.isEmpty || next == '-') ? '0' : next;
  }

  void clear() {
    _display = '0';
    _stored = null;
    _op = null;
    _startNew = true;
  }

  /// Replaces the current entry with a preset amount (the quick-amount
  /// chips): any pending operation is dropped and [minor] becomes the shown
  /// value. The next digit starts a fresh operand, mirroring `=`.
  void setAmountMinor(int minor) {
    _display = minor.toString();
    _stored = null;
    _op = null;
    _startNew = true;
  }

  void applyOperator(String op) {
    if (_op != null && !_startNew) {
      // Chain: fold the previous operation before starting the next one.
      _stored = _compute(_stored ?? 0, _op!, displayValue);
      _display = _format(_stored!);
    } else if (_op == null) {
      _stored = displayValue;
    }
    _op = op;
    _startNew = true;
  }

  void equals() {
    if (_op == null || _stored == null) return;
    final result = _compute(_stored!, _op!, displayValue);
    _display = _format(result);
    _stored = null;
    _op = null;
    _startNew = true;
  }

  /// The value to commit. Evaluates any pending operation, rounds to a whole
  /// unit, and clamps negatives/non-finite results to 0.
  int get amountMinor {
    double value = displayValue;
    if (_op != null && _stored != null && !_startNew) {
      value = _compute(_stored!, _op!, displayValue);
    } else if (_op != null && _stored != null && _startNew) {
      value = _stored!;
    }
    if (!value.isFinite || value <= 0) return 0;
    return value.round();
  }

  /// A short preview of the pending left operand + operator (e.g. "50.000 ×"),
  /// formatted via [format], or null when no operation is pending.
  String? expressionPreview(String Function(num value) format) {
    if (_op == null || _stored == null) return null;
    return '${format(_stored!.round())} $_op';
  }

  double _compute(double a, String op, double b) {
    switch (op) {
      case '+':
        return a + b;
      case '-':
        return a - b;
      case '×':
        return a * b;
      case '÷':
        return b == 0 ? 0 : a / b;
    }
    return b;
  }

  String _format(double v) {
    if (!v.isFinite) return '0';
    if (v == v.roundToDouble()) return v.toInt().toString();
    return v.toString();
  }
}
