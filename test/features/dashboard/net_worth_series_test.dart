import 'package:affluena_mobile/features/dashboard/application/net_worth_series.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('buildNetWorthSeries', () {
    test('anchors the newest point at the current net worth', () {
      final series = buildNetWorthSeries(1000, [100, 200, 300]);
      expect(series.length, 3);
      expect(series.last, 1000);
    });

    test('walks backward subtracting each month\'s net cashflow', () {
      // Months (oldest → newest) with net cashflows 100, 200, 300 and a
      // current net worth of 1000:
      //   series[2] = 1000 (anchor, current month closed with +300)
      //   series[1] = 1000 - 300 = 700
      //   series[0] = 700 - 200 = 500  (cashflow[0] never subtracts — it
      //   happened DURING the oldest month, whose closing balance this is)
      expect(buildNetWorthSeries(1000, [100, 200, 300]), [500, 700, 1000]);
    });

    test('a negative month raises the reconstructed past balance', () {
      // The current month LOST 400 (net), so a month ago the balance was
      // 400 higher than today.
      expect(buildNetWorthSeries(600, [0, -400]), [1000, 600]);
    });

    test('preserves the oldest-to-newest order for a 12-point walk', () {
      final cashflows = List<int>.generate(12, (i) => (i + 1) * 10);
      final series = buildNetWorthSeries(0, cashflows);
      expect(series.length, 12);
      expect(series.last, 0);
      // Each step forward adds that month's cashflow back.
      for (var i = 1; i < series.length; i++) {
        expect(series[i] - series[i - 1], cashflows[i]);
      }
    });

    test('single-point input returns just the anchor', () {
      expect(buildNetWorthSeries(4200, [999]), [4200]);
    });

    test('empty input returns an empty series', () {
      expect(buildNetWorthSeries(4200, []), isEmpty);
    });

    test('handles a negative current net worth', () {
      expect(buildNetWorthSeries(-500, [0, 250]), [-750, -500]);
    });
  });

  group('buildNetWorthSeries — earliest-wallet clamping', () {
    // Reconstructed values without clamping: [500, 700, 1000].
    const cashflows = [100, 200, 300];
    const months = ['2026-04', '2026-05', '2026-06'];

    test('drops points older than the earliest wallet creation month', () {
      expect(
        buildNetWorthSeries(
          1000,
          cashflows,
          monthKeys: months,
          earliestWalletCreatedAt: '2026-05-10T08:00:00Z',
        ),
        [700, 1000],
      );
    });

    test('keeps the full series when the wallet predates the window', () {
      expect(
        buildNetWorthSeries(
          1000,
          cashflows,
          monthKeys: months,
          earliestWalletCreatedAt: '2025-01-01T00:00:00Z',
        ),
        [500, 700, 1000],
      );
    });

    test('keeps only the anchor when every bucket predates the wallet', () {
      // The current net worth itself is real even if the trend history is
      // older than the first wallet.
      expect(
        buildNetWorthSeries(
          1000,
          cashflows,
          monthKeys: months,
          earliestWalletCreatedAt: '2026-07-01T00:00:00Z',
        ),
        [1000],
      );
    });

    test('accepts RFC3339 month bucket labels (DATE-as-timestamp)', () {
      expect(
        buildNetWorthSeries(
          1000,
          cashflows,
          monthKeys: const [
            '2026-04-01T00:00:00Z',
            '2026-05-01T00:00:00Z',
            '2026-06-01T00:00:00Z',
          ],
          earliestWalletCreatedAt: '2026-05-10T08:00:00Z',
        ),
        [700, 1000],
      );
    });

    test('skips clamping without month keys', () {
      expect(
        buildNetWorthSeries(
          1000,
          cashflows,
          earliestWalletCreatedAt: '2026-05-10T08:00:00Z',
        ),
        [500, 700, 1000],
      );
    });

    test('skips clamping without an earliest wallet date', () {
      expect(buildNetWorthSeries(1000, cashflows, monthKeys: months), [
        500,
        700,
        1000,
      ]);
    });

    test('fails open on mismatched month-key length', () {
      expect(
        buildNetWorthSeries(
          1000,
          cashflows,
          monthKeys: const ['2026-05', '2026-06'],
          earliestWalletCreatedAt: '2026-05-10T08:00:00Z',
        ),
        [500, 700, 1000],
      );
    });

    test('fails open on malformed labels', () {
      expect(
        buildNetWorthSeries(
          1000,
          cashflows,
          monthKeys: const ['garbage', '2026-05', '2026-06'],
          earliestWalletCreatedAt: '2026-05-10T08:00:00Z',
        ),
        [500, 700, 1000],
      );
      expect(
        buildNetWorthSeries(
          1000,
          cashflows,
          monthKeys: months,
          earliestWalletCreatedAt: 'not-a-date',
        ),
        [500, 700, 1000],
      );
    });
  });
}
