import 'package:affluena_mobile/core/formatters/date_formatter.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AffluenaDateFormatter.apiDate', () {
    test('strips the time from a stored RFC3339 UTC-midnight DATE value', () {
      expect(
        AffluenaDateFormatter.apiDate('2026-07-19T00:00:00Z'),
        '2026-07-19',
      );
    });

    test('never shifts the calendar day, whatever the offset', () {
      // A timezone conversion (e.g. .toLocal() in a negative UTC offset)
      // would turn this into 2026-07-18 — the prefix is the truth.
      expect(
        AffluenaDateFormatter.apiDate('2026-07-19T00:00:00+07:00'),
        '2026-07-19',
      );
      expect(
        AffluenaDateFormatter.apiDate('2026-07-19T23:59:59-05:00'),
        '2026-07-19',
      );
    });

    test('passes already-short dates through unchanged', () {
      expect(AffluenaDateFormatter.apiDate('2026-07-19'), '2026-07-19');
    });

    test('leaves unparseable values alone for the API to reject', () {
      expect(AffluenaDateFormatter.apiDate(''), '');
      expect(AffluenaDateFormatter.apiDate('not-a-date'), 'not-a-date');
    });

    test('trims surrounding whitespace', () {
      expect(
        AffluenaDateFormatter.apiDate(' 2026-07-19T00:00:00Z '),
        '2026-07-19',
      );
    });
  });
}
