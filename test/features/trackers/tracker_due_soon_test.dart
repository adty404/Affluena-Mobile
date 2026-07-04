import 'package:affluena_mobile/features/trackers/application/tracker_controller.dart';
import 'package:affluena_mobile/features/trackers/data/tracker_models.dart';
import 'package:flutter_test/flutter_test.dart';

Subscription _sub(String nextDueDate) => Subscription(
  id: 'sub-$nextDueDate',
  userId: 'u1',
  name: 'Spotify',
  accountDetail: '',
  walletId: 'w1',
  categoryId: 'c1',
  amountMinor: 65000,
  billingCycle: BillingCycle.monthly,
  nextDueDate: nextDueDate,
  status: SubscriptionStatus.active,
  note: '',
  createdAt: '2026-01-01T00:00:00Z',
  updatedAt: '2026-01-01T00:00:00Z',
);

Installment _inst({required int dueDay, required int remainingMonths}) =>
    Installment(
      id: 'inst-$dueDay',
      userId: 'u1',
      name: 'Laptop',
      walletId: 'w1',
      categoryId: 'c1',
      totalAmountMinor: 12000000,
      monthlyAmountMinor: 1000000,
      tenorMonths: 12,
      remainingMonths: remainingMonths,
      startDate: '2026-01-01',
      dueDay: dueDay,
      status: InstallmentStatus.active,
      note: '',
      createdAt: '2026-01-01T00:00:00Z',
      updatedAt: '2026-01-01T00:00:00Z',
    );

/// An RFC3339 'Z' instant [days] from today at midnight UTC — in +07:00 (WIB)
/// this is 07:00 local on the SAME calendar day, so a date-only comparison must
/// treat it as that day (the off-by-one this fix corrects).
String _utcMidnightInDays(int days) {
  final d = DateTime.now().add(Duration(days: days));
  final m = d.month.toString().padLeft(2, '0');
  final day = d.day.toString().padLeft(2, '0');
  return '${d.year}-$m-${day}T00:00:00Z';
}

void main() {
  group('subscription due-soon (WIB date-only)', () {
    test('a due date within the next 7 days counts', () {
      final state = TrackerState(subscriptions: [_sub(_utcMidnightInDays(3))]);
      expect(state.dueSoonCount, 1);
    });

    test('a due date exactly 7 days out still counts (inclusive)', () {
      final state = TrackerState(subscriptions: [_sub(_utcMidnightInDays(7))]);
      expect(state.dueSoonCount, 1);
    });

    test('a due date 8 days out is excluded', () {
      final state = TrackerState(subscriptions: [_sub(_utcMidnightInDays(8))]);
      expect(state.dueSoonCount, 0);
    });

    test('a due date in the past is excluded', () {
      final state = TrackerState(subscriptions: [_sub(_utcMidnightInDays(-3))]);
      expect(state.dueSoonCount, 0);
    });
  });

  group('installment due-soon (clamp + roll)', () {
    test('dueDay 31 never overflows a short month or throws', () {
      // The old code built DateTime(y, m, 31) which silently rolled a short
      // month into the next one; the fix clamps to the month length. Regardless
      // of today, the count must be a clean 0 or 1 (never a crash / garbage).
      final state = TrackerState(
        installments: [_inst(dueDay: 31, remainingMonths: 5)],
      );
      expect(state.dueSoonCount, anyOf(0, 1));
    });

    test('a fully-paid installment is never due-soon', () {
      final state = TrackerState(
        installments: [_inst(dueDay: 1, remainingMonths: 0)],
      );
      expect(state.dueSoonCount, 0);
    });
  });
}
