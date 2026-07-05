/// Whether [date] falls inside the "due soon" window: today through 7 days
/// from now, inclusive, evaluated on whole LOCAL calendar days.
///
/// API due dates arrive as RFC3339 `Z` instants; comparing the raw instant
/// against local-midnight bounds is off by one in +07:00 (WIB) — a due date
/// stored as UTC midnight exactly 7 days out lands at 07:00 local and would
/// fall outside the window, while overdue dates would count forever.
/// Normalizing via [DateTime.toLocal] first, then comparing date-only, keeps
/// the window correct in every timezone. Shared by the debt and tracker
/// controllers' "jatuh tempo" counts.
bool withinSevenDays(DateTime date) {
  final local = date.toLocal();
  final d = DateTime(local.year, local.month, local.day);
  final today = DateTime.now();
  final start = DateTime(today.year, today.month, today.day);
  final end = DateTime(today.year, today.month, today.day + 7);
  return !d.isBefore(start) && !d.isAfter(end);
}
