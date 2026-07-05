import '../../../core/formatters/money_formatter.dart';
import '../../dashboard/data/dashboard_models.dart';

/// The API rule key that gates due-date reminders (`notification_rules.rule_key`).
/// One server rule covers installments, subscriptions, AND debts — mirroring
/// the backend's own H-3/H-1 email/in-app reminders.
const String kDueReminderRuleKey = 'due-reminder';

/// Hard cap on the number of device notifications armed per resync.
const int kMaxPlannedReminders = 50;

/// One concrete local notification the device should arm: a stable id (so a
/// re-plan of the same due maps to the same slot), the local wall-clock
/// instant to fire at, and the user-facing copy.
class PlannedReminder {
  const PlannedReminder({
    required this.id,
    required this.when,
    required this.title,
    required this.body,
  });

  /// Deterministic per (kind, item id, H-offset) — replanning the same dues
  /// yields identical ids.
  final int id;

  /// Local wall-clock fire instant (H-3 / H-1 at 09:00).
  final DateTime when;

  final String title;
  final String body;

  @override
  String toString() => 'PlannedReminder($id, $when, "$title")';
}

/// Pure planning core for device due reminders — no plugin, no clock, no I/O,
/// so it is directly unit-testable.
///
/// Given the dashboard summary's upcoming dues, the user's enabled server-side
/// notification rule keys, and `now`, produce the exact batch of local
/// notifications to arm:
///
/// - every upcoming installment / subscription / debt gets a reminder at
///   **H-3 and H-1, 09:00 local time** (mirroring the server's rules);
/// - instants that are already in the past are skipped (e.g. only H-1 remains
///   when the due date is 2 days away);
/// - a disabled (or missing) `due-reminder` rule ⇒ an empty plan;
/// - the result is sorted soonest-first and capped at [cap] so a pathological
///   number of dues can't flood the notification manager.
///
/// Due dates arrive as RFC3339 timestamps even for DATE columns (see
/// CLAUDE.md); only the `YYYY-MM-DD` prefix is trusted.
List<PlannedReminder> planDueReminders({
  required DashboardSummary summary,
  required Set<String> enabledRuleKeys,
  required DateTime now,
  int cap = kMaxPlannedReminders,
}) {
  if (!enabledRuleKeys.contains(kDueReminderRuleKey)) {
    return const [];
  }

  final planned = <PlannedReminder>[];

  void plan({
    required String kind,
    required String id,
    required String dueDateIso,
    required String Function(int daysLeft) title,
    required String body,
  }) {
    final due = _dateOnly(dueDateIso);
    if (due == null) return;
    for (final offset in const [3, 1]) {
      final when = DateTime(due.year, due.month, due.day - offset, 9);
      if (!when.isAfter(now)) continue;
      planned.add(
        PlannedReminder(
          id: _stableId('$kind:$id:H-$offset'),
          when: when,
          title: title(offset),
          body: body,
        ),
      );
    }
  }

  for (final sub in summary.upcomingSubscriptions) {
    plan(
      kind: 'sub',
      id: sub.id,
      dueDateIso: sub.nextDueDate,
      title: (days) => '${sub.name} jatuh tempo ${_horizon(days)}',
      body:
          'Langganan ${MoneyFormatter.idr(sub.amountMinor)} — '
          'siapkan dananya, ya.',
    );
  }

  for (final inst in summary.upcomingInstallments) {
    plan(
      kind: 'inst',
      id: inst.id,
      dueDateIso: inst.dueDate,
      title: (days) => '${inst.name} jatuh tempo ${_horizon(days)}',
      body:
          'Cicilan ${MoneyFormatter.idr(inst.monthlyAmountMinor)} — '
          'siapkan dananya, ya.',
    );
  }

  for (final debt in summary.upcomingDebts) {
    final receivable = debt.type == 'receivable';
    final name = receivable
        ? 'Piutang dari ${debt.counterpartyName}'
        : 'Utang ke ${debt.counterpartyName}';
    plan(
      kind: 'debt',
      id: debt.id,
      dueDateIso: debt.dueDate,
      title: (days) => '$name jatuh tempo ${_horizon(days)}',
      body: receivable
          ? 'Sisa ${MoneyFormatter.idr(debt.remainingAmountMinor)} — '
                'waktunya menagih, ya.'
          : 'Sisa ${MoneyFormatter.idr(debt.remainingAmountMinor)} — '
                'siapkan dananya, ya.',
    );
  }

  planned.sort((a, b) => a.when.compareTo(b.when));
  return planned.length <= cap
      ? planned
      : planned.sublist(0, cap);
}

String _horizon(int daysLeft) => daysLeft == 1 ? 'besok' : '$daysLeft hari lagi';

/// Parses the `YYYY-MM-DD` prefix of an API date defensively (the API sends
/// full RFC3339 timestamps even for DATE columns; converting those to local
/// time could shift the calendar day). Returns null on malformed input.
DateTime? _dateOnly(String iso) {
  final match = RegExp(r'^(\d{4})-(\d{2})-(\d{2})').firstMatch(iso);
  if (match == null) return null;
  return DateTime(
    int.parse(match.group(1)!),
    int.parse(match.group(2)!),
    int.parse(match.group(3)!),
  );
}

/// FNV-1a over the key string, folded into a positive 31-bit int — the plugin
/// needs an int id, and this keeps it deterministic across app restarts.
int _stableId(String key) {
  var hash = 0x811c9dc5;
  for (final unit in key.codeUnits) {
    hash ^= unit;
    hash = (hash * 0x01000193) & 0xFFFFFFFF;
  }
  return hash & 0x7FFFFFFF;
}
