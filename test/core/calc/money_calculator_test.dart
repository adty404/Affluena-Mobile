import 'package:affluena_mobile/core/calc/money_calculator.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late MoneyCalculator calc;
  setUp(() => calc = MoneyCalculator());

  void type(String keys) {
    for (final k in keys.split('')) {
      calc.inputDigit(k);
    }
  }

  test('starts empty at zero', () {
    expect(calc.display, '0');
    expect(calc.displayValue, 0);
    expect(calc.amountMinor, 0);
    expect(calc.isEmpty, isTrue);
  });

  test('typing digits drops the leading zero', () {
    type('50000');
    expect(calc.display, '50000');
    expect(calc.amountMinor, 50000);
    expect(calc.isEmpty, isFalse);
  });

  test('"000" appends three zeros, but not onto a bare zero', () {
    calc.inputZeros();
    expect(calc.display, '0');
    type('5');
    calc.inputZeros();
    expect(calc.display, '5000');
    expect(calc.amountMinor, 5000);
  });

  test('caps the operand length', () {
    type('1234567890123456');
    expect(calc.display.length, 12);
  });

  test('backspace removes the last digit, bottoming out at zero', () {
    type('150');
    calc.backspace();
    expect(calc.display, '15');
    calc.backspace();
    calc.backspace();
    expect(calc.display, '0');
    calc.backspace();
    expect(calc.display, '0');
  });

  test('clear resets everything', () {
    type('500');
    calc.applyOperator('+');
    type('250');
    calc.clear();
    expect(calc.display, '0');
    expect(calc.amountMinor, 0);
    expect(calc.pendingOp, isNull);
  });

  test('addition: 50000 + 25000 = 75000', () {
    type('50000');
    calc.applyOperator('+');
    type('25000');
    calc.equals();
    expect(calc.display, '75000');
    expect(calc.amountMinor, 75000);
  });

  test('subtraction down to a negative clamps amountMinor to 0', () {
    type('30000');
    calc.applyOperator('-');
    type('50000');
    calc.equals();
    expect(calc.displayValue, -20000);
    expect(calc.amountMinor, 0);
  });

  test('multiplication: 1500 × 3 = 4500', () {
    type('1500');
    calc.applyOperator('×');
    type('3');
    calc.equals();
    expect(calc.amountMinor, 4500);
  });

  test('division rounds to a whole unit: 100000 ÷ 3 ≈ 33333', () {
    type('100000');
    calc.applyOperator('÷');
    type('3');
    calc.equals();
    expect(calc.amountMinor, 33333);
  });

  test('divide by zero yields 0 instead of crashing', () {
    type('5000');
    calc.applyOperator('÷');
    type('0');
    calc.equals();
    expect(calc.amountMinor, 0);
  });

  test('chains operators left-to-right: 10000 + 5000 + 2000 = 17000', () {
    type('10000');
    calc.applyOperator('+');
    type('5000');
    calc.applyOperator('+'); // folds 15000 before the next operand
    expect(calc.display, '15000');
    type('2000');
    calc.equals();
    expect(calc.amountMinor, 17000);
  });

  test('amountMinor evaluates a pending op even without pressing equals', () {
    type('50000');
    calc.applyOperator('+');
    type('30000');
    // user confirms (✓) without pressing '='
    expect(calc.amountMinor, 80000);
  });

  test('operator with no second operand keeps the stored value', () {
    type('50000');
    calc.applyOperator('+');
    expect(calc.amountMinor, 50000);
  });

  test('typing after equals starts a fresh operand', () {
    type('100');
    calc.applyOperator('+');
    type('50');
    calc.equals();
    expect(calc.display, '150');
    type('9');
    expect(calc.display, '9');
  });

  test('decimal entry then round on commit', () {
    type('100');
    calc.inputDecimal();
    type('50'); // 100.50
    expect(calc.display, '100.50');
    expect(calc.amountMinor, 101); // rounds
    calc.inputDecimal(); // ignored — already has a decimal point
    expect(calc.display, '100.50');
  });

  test('expressionPreview shows the stored operand + pending op', () {
    type('50000');
    calc.applyOperator('×');
    expect(calc.expressionPreview((v) => v.toString()), '50000 ×');
    expect(calc.expressionPreview((v) => v.toString()), isNotNull);
  });

  test('no preview when nothing is pending', () {
    type('50000');
    expect(calc.expressionPreview((v) => v.toString()), isNull);
  });
}
