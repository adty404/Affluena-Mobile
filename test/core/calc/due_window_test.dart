import 'package:affluena_mobile/core/calc/due_window.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('withinSevenDays', () {
    test('a UTC-midnight instant exactly 7 days out is included', () {
      // API DATE values arrive as UTC-midnight instants. Comparing the raw
      // instant against local bounds dropped this edge day in WIB (+07:00).
      final now = DateTime.now();
      final sevenOut = DateTime.utc(now.year, now.month, now.day + 7);
      expect(withinSevenDays(sevenOut), isTrue);
    });

    test('today is included', () {
      expect(withinSevenDays(DateTime.now()), isTrue);
    });

    test('an overdue date is excluded', () {
      final now = DateTime.now();
      // Two days back so no timezone offset can pull it into the window.
      final overdue = DateTime.utc(now.year, now.month, now.day - 2);
      expect(withinSevenDays(overdue), isFalse);
    });

    test('a date past the window is excluded', () {
      final now = DateTime.now();
      // Two days past the edge so no offset can pull it back in.
      final farOut = DateTime.utc(now.year, now.month, now.day + 9);
      expect(withinSevenDays(farOut), isFalse);
    });
  });
}
