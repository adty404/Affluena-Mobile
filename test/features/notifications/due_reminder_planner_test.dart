import 'package:affluena_mobile/features/dashboard/data/dashboard_models.dart';
import 'package:affluena_mobile/features/notifications/application/due_reminder_planner.dart';
import 'package:flutter_test/flutter_test.dart';

const _budget = BudgetSummary(
  limitMinor: 0,
  spentMinor: 0,
  remainingMinor: 0,
  usagePercent: 0,
);

DashboardSummary _summary({
  List<UpcomingSubscription> subscriptions = const [],
  List<UpcomingInstallment> installments = const [],
  List<UpcomingDebt> debts = const [],
}) {
  return DashboardSummary(
    month: '2026-07',
    netWorthMinor: 0,
    monthlyIncomeMinor: 0,
    monthlyExpenseMinor: 0,
    monthlyCashflowMinor: 0,
    budget: _budget,
    upcomingSubscriptions: subscriptions,
    upcomingInstallments: installments,
    upcomingDebts: debts,
  );
}

UpcomingSubscription _netflix({String due = '2026-07-10T00:00:00Z'}) {
  return UpcomingSubscription(
    id: 'sub-1',
    name: 'Netflix Premium',
    accountDetail: '',
    amountMinor: 186000,
    nextDueDate: due,
  );
}

const _enabled = {kDueReminderRuleKey};

// A quiet morning well before any 09:00 reminder instant.
final _now = DateTime(2026, 7, 5, 8);

void main() {
  group('planDueReminders', () {
    test('schedules H-3 and H-1 at 09:00 local for a due 5 days out', () {
      final planned = planDueReminders(
        summary: _summary(subscriptions: [_netflix()]),
        enabledRuleKeys: _enabled,
        now: _now,
      );

      expect(planned, hasLength(2));
      // Sorted soonest-first: H-3 (Jul 7) then H-1 (Jul 9).
      expect(planned[0].when, DateTime(2026, 7, 7, 9));
      expect(planned[0].title, 'Netflix Premium jatuh tempo 3 hari lagi');
      expect(planned[1].when, DateTime(2026, 7, 9, 9));
      expect(planned[1].title, 'Netflix Premium jatuh tempo besok');
      // The amount rides along, MoneyFormatter-formatted.
      expect(planned[0].body, contains('Rp 186.000'));
    });

    test('skips instants already in the past (only H-1 remains)', () {
      final planned = planDueReminders(
        // Due Jul 7: H-3 = Jul 4 09:00 (past), H-1 = Jul 6 09:00 (future).
        summary: _summary(
          subscriptions: [_netflix(due: '2026-07-07T00:00:00Z')],
        ),
        enabledRuleKeys: _enabled,
        now: _now,
      );

      expect(planned, hasLength(1));
      expect(planned.single.when, DateTime(2026, 7, 6, 9));
      expect(planned.single.title, 'Netflix Premium jatuh tempo besok');
    });

    test('plans nothing when every instant is already past', () {
      final planned = planDueReminders(
        // Due tomorrow: H-1 was today 09:00, but now it is 10:00.
        summary: _summary(
          subscriptions: [_netflix(due: '2026-07-06T00:00:00Z')],
        ),
        enabledRuleKeys: _enabled,
        now: DateTime(2026, 7, 5, 10),
      );

      expect(planned, isEmpty);
    });

    test('a disabled (or missing) due-reminder rule plans nothing', () {
      final summary = _summary(subscriptions: [_netflix()]);

      expect(
        planDueReminders(
          summary: summary,
          enabledRuleKeys: const {},
          now: _now,
        ),
        isEmpty,
      );
      expect(
        planDueReminders(
          summary: summary,
          // Other rules being on must not leak due reminders in.
          enabledRuleKeys: const {'budget-alert', 'weekly-summary'},
          now: _now,
        ),
        isEmpty,
      );
    });

    test('covers installments and debts with their own copy', () {
      final planned = planDueReminders(
        summary: _summary(
          installments: const [
            UpcomingInstallment(
              id: 'inst-1',
              name: 'iPhone 15',
              monthlyAmountMinor: 1200000,
              remainingMonths: 8,
              dueDate: '2026-07-12T00:00:00Z',
            ),
          ],
          debts: const [
            UpcomingDebt(
              id: 'debt-1',
              type: 'payable',
              counterpartyName: 'Andi',
              remainingAmountMinor: 500000,
              dueDate: '2026-07-11T00:00:00Z',
            ),
            UpcomingDebt(
              id: 'debt-2',
              type: 'receivable',
              counterpartyName: 'Sari',
              remainingAmountMinor: 250000,
              dueDate: '2026-07-11T00:00:00Z',
            ),
          ],
        ),
        enabledRuleKeys: _enabled,
        now: _now,
      );

      final titles = planned.map((p) => p.title).toSet();
      expect(titles, contains('iPhone 15 jatuh tempo 3 hari lagi'));
      expect(titles, contains('Utang ke Andi jatuh tempo 3 hari lagi'));
      expect(titles, contains('Piutang dari Sari jatuh tempo besok'));
      final installment = planned.firstWhere((p) => p.title.startsWith('iPhone'));
      expect(installment.body, contains('Rp 1.200.000'));
      final receivable = planned.firstWhere(
        (p) => p.title.startsWith('Piutang'),
      );
      expect(receivable.body, contains('Rp 250.000'));
    });

    test('sorts soonest-first and caps the batch at 50', () {
      final subs = [
        for (var i = 0; i < 40; i++)
          UpcomingSubscription(
            id: 'sub-$i',
            name: 'Layanan $i',
            accountDetail: '',
            amountMinor: 10000,
            // Dues spread from Jul 10 onward, one per day.
            nextDueDate: '2026-07-${(10 + i).toString().padLeft(2, '0')}',
          ),
      ];
      final planned = planDueReminders(
        summary: _summary(subscriptions: subs),
        enabledRuleKeys: _enabled,
        now: _now,
      );

      // 40 dues x 2 instants = 80, capped to the soonest 50.
      expect(planned, hasLength(50));
      for (var i = 1; i < planned.length; i++) {
        expect(
          planned[i].when.isBefore(planned[i - 1].when),
          isFalse,
          reason: 'planned reminders must stay sorted soonest-first',
        );
      }
    });

    test('ids are stable across replans and unique per instant', () {
      List<PlannedReminder> plan() => planDueReminders(
        summary: _summary(subscriptions: [_netflix()]),
        enabledRuleKeys: _enabled,
        now: _now,
      );

      final first = plan();
      final second = plan();
      expect(first.map((p) => p.id), second.map((p) => p.id));
      expect(first.map((p) => p.id).toSet(), hasLength(first.length));
      expect(first.every((p) => p.id > 0), isTrue);
    });

    test('a malformed due date is skipped quietly', () {
      final planned = planDueReminders(
        summary: _summary(subscriptions: [_netflix(due: 'nanti-deh')]),
        enabledRuleKeys: _enabled,
        now: _now,
      );
      expect(planned, isEmpty);
    });
  });
}
