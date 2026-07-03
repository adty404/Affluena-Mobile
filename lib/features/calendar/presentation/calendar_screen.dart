import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/affluena_theme.dart';
import '../../../app/theme/sky_palette.dart';
import '../../../core/formatters/date_formatter.dart';
import '../../../core/formatters/money_formatter.dart';
import '../../categories/application/category_tag_management_controller.dart';
import '../../redesign/presentation/sky_quick_add_sheet.dart';
import '../../shared/presentation/widgets/error_state.dart';
import '../../shared/presentation/widgets/transaction_tile.dart';
import '../../transactions/application/transactions_controller.dart';
import '../../transactions/data/transaction_models.dart';
import '../../transactions/presentation/transaction_detail_sheet.dart';
import '../../transactions/presentation/transaction_display.dart';
import '../../wallets/application/wallets_controller.dart';
import '../../wallets/data/wallet_models.dart';
import '../application/calendar_providers.dart';

/// Kalender — a full-month money calendar, hosted as a tab in the redesign
/// nav shell. The header summarises the visible month (pemasukan ·
/// pengeluaran · selisih); every day cell shows its own mini summary; swiping
/// (or the chevrons) moves between months; tapping a day opens that day's
/// transactions in a bottom sheet.
class CalendarView extends ConsumerStatefulWidget {
  const CalendarView({super.key});

  @override
  ConsumerState<CalendarView> createState() => _CalendarViewState();
}

class _CalendarViewState extends ConsumerState<CalendarView> {
  static int _pageForMonth(DateTime month) =>
      (month.year - 2000) * 12 + (month.month - 1);
  static DateTime _monthForPage(int page) =>
      DateTime(2000 + page ~/ 12, page % 12 + 1);

  late final PageController _controller;
  late DateTime _month;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _month = DateTime(now.year, now.month);
    _controller = PageController(initialPage: _pageForMonth(_month));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _shiftMonth(int delta) {
    _controller.animateToPage(
      _pageForMonth(_month) + delta,
      duration: const Duration(milliseconds: 240),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    final monthKey = AffluenaDateFormatter.monthKey(_month);
    final dataAsync = ref.watch(calendarMonthProvider(monthKey));
    final data = dataAsync.asData?.value;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AffluenaSpacing.space5,
            AffluenaSpacing.space4,
            AffluenaSpacing.space5,
            0,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      AffluenaDateFormatter.monthLabelFull(_month),
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.3,
                        color: context.sky.ink,
                      ),
                    ),
                  ),
                  _ChevronButton(
                    key: const ValueKey('calendar-prev-month'),
                    icon: Icons.chevron_left,
                    onTap: () => _shiftMonth(-1),
                  ),
                  _ChevronButton(
                    key: const ValueKey('calendar-next-month'),
                    icon: Icons.chevron_right,
                    onTap: () => _shiftMonth(1),
                  ),
                ],
              ),
              const SizedBox(height: AffluenaSpacing.space3),
              _MonthSummaryCard(data: data, loading: dataAsync.isLoading),
              const SizedBox(height: AffluenaSpacing.space3),
              const _WeekdayHeader(),
              const SizedBox(height: AffluenaSpacing.space1),
            ],
          ),
        ),
        Expanded(
          child: PageView.builder(
            controller: _controller,
            onPageChanged: (page) =>
                setState(() => _month = _monthForPage(page)),
            itemBuilder: (context, page) =>
                _MonthGrid(month: _monthForPage(page)),
          ),
        ),
      ],
    );
  }
}

class _ChevronButton extends StatelessWidget {
  const _ChevronButton({required this.icon, required this.onTap, super.key});

  final IconData icon;
  final VoidCallback onTap;

  /// Visual diameter of the circle; the tappable area is [_hitSize].
  static const double _visualSize = 36;

  /// Minimum touch target (44px) — larger than the drawn circle so the
  /// chevron stays visually compact but is comfortable to hit.
  static const double _hitSize = 44;

  @override
  Widget build(BuildContext context) {
    return InkResponse(
      onTap: onTap,
      radius: _hitSize / 2,
      child: SizedBox(
        width: _hitSize,
        height: _hitSize,
        child: Center(
          child: Container(
            width: _visualSize,
            height: _visualSize,
            alignment: Alignment.center,
            decoration: ShapeDecoration(
              color: context.sky.surface,
              shape: CircleBorder(side: BorderSide(color: context.sky.line)),
            ),
            child: Icon(icon, size: 20, color: context.sky.ink),
          ),
        ),
      ),
    );
  }
}

/// Pemasukan · Pengeluaran · Selisih for the visible month.
class _MonthSummaryCard extends StatelessWidget {
  const _MonthSummaryCard({required this.data, required this.loading});

  final CalendarMonthData? data;
  final bool loading;

  static const _labelStyle = TextStyle(
    fontSize: 10.5,
    fontWeight: FontWeight.w600,
  );
  static const _valueStyle = TextStyle(
    fontSize: 13.5,
    fontWeight: FontWeight.w800,
    letterSpacing: -0.2,
    fontFeatures: [FontFeature.tabularFigures()],
  );

  @override
  Widget build(BuildContext context) {
    final net = data?.netMinor ?? 0;
    final entries = <({String label, String? value, Color color})>[
      (
        label: 'Pemasukan',
        value: data == null ? null : MoneyFormatter.idr(data!.incomeMinor),
        color: context.sky.income,
      ),
      (
        label: 'Pengeluaran',
        value: data == null ? null : MoneyFormatter.idr(data!.expenseMinor),
        color: context.sky.danger,
      ),
      (
        label: 'Selisih',
        value: data == null ? null : MoneyFormatter.signedIdr(net),
        color: context.sky.ink,
      ),
    ];

    return Container(
      decoration: BoxDecoration(
        color: context.sky.surface,
        border: Border.all(color: context.sky.line),
        borderRadius: BorderRadius.circular(AffluenaRadii.control),
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: AffluenaSpacing.space4,
        vertical: AffluenaSpacing.space3,
      ),
      // Responsive: three columns while every FULL value fits; otherwise
      // stack label:value rows so large amounts are never cut off.
      child: LayoutBuilder(
        builder: (context, constraints) {
          if (_rowFits(context, entries, constraints.maxWidth)) {
            return IntrinsicHeight(
              child: Row(
                children: [
                  for (var i = 0; i < entries.length; i++) ...[
                    if (i > 0) const _SummaryDivider(),
                    _SummaryColumn(
                      label: entries[i].label,
                      value: entries[i].value,
                      color: entries[i].color,
                    ),
                  ],
                ],
              ),
            );
          }
          return Column(
            children: [
              for (var i = 0; i < entries.length; i++) ...[
                if (i > 0) const SizedBox(height: AffluenaSpacing.space2),
                Row(
                  children: [
                    Text(
                      entries[i].label,
                      style: _labelStyle.copyWith(color: context.sky.muted),
                    ),
                    const SizedBox(width: AffluenaSpacing.space3),
                    // Expanded + scale-down as a last-resort guard so this
                    // branch can never overflow, whatever the font metrics.
                    Expanded(
                      child: Align(
                        alignment: Alignment.centerRight,
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            entries[i].value ?? '—',
                            maxLines: 1,
                            style: _valueStyle.copyWith(
                              fontSize: 14,
                              color: entries[i].color,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          );
        },
      ),
    );
  }

  /// True when three columns of full (untruncated) values fit [maxWidth],
  /// honoring the user's accessibility text scale.
  bool _rowFits(
    BuildContext context,
    List<({String label, String? value, Color color})> entries,
    double maxWidth,
  ) {
    if (!maxWidth.isFinite) return true;
    final scaler = MediaQuery.textScalerOf(context);
    double width(String text, TextStyle style) {
      final painter = TextPainter(
        text: TextSpan(text: text, style: style),
        maxLines: 1,
        textDirection: TextDirection.ltr,
        textScaler: scaler,
      )..layout();
      final w = painter.width;
      painter.dispose();
      return w;
    }

    var needed = 0.0;
    for (final entry in entries) {
      final labelWidth = width(entry.label, _labelStyle);
      final valueWidth = width(entry.value ?? '—', _valueStyle);
      needed += labelWidth > valueWidth ? labelWidth : valueWidth;
    }
    // Two divider gutters between the three columns.
    needed += 2 * AffluenaSpacing.space6;
    return needed <= maxWidth;
  }
}

class _SummaryDivider extends StatelessWidget {
  const _SummaryDivider();

  @override
  Widget build(BuildContext context) {
    // Stretches to the row's intrinsic height instead of a fixed magic size;
    // [width] is the whole gutter (divider + breathing room on both sides).
    return VerticalDivider(
      width: AffluenaSpacing.space6,
      thickness: 1,
      color: context.sky.line,
    );
  }
}

class _SummaryColumn extends StatelessWidget {
  const _SummaryColumn({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String? value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w600,
              color: context.sky.muted,
            ),
          ),
          const SizedBox(height: 2),
          // Truncate instead of FittedBox-down-scaling: a large IDR value
          // stays at a legible 13.5px and simply ellipsizes.
          Text(
            value ?? '—',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 13.5,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.2,
              color: color,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }
}

class _WeekdayHeader extends StatelessWidget {
  const _WeekdayHeader();

  static const _labels = ['Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab', 'Min'];

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (final label in _labels)
          Expanded(
            child: Center(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w700,
                  color: context.sky.faint,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

/// One month page: a Monday-first 7×6 grid of day cells.
class _MonthGrid extends ConsumerWidget {
  const _MonthGrid({required this.month});

  final DateTime month;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final monthKey = AffluenaDateFormatter.monthKey(month);
    final dataAsync = ref.watch(calendarMonthProvider(monthKey));

    if (dataAsync.hasError && dataAsync.asData == null) {
      return _RefreshableMonthPage(
        monthKey: monthKey,
        child: Center(
          child: ErrorState(
            message: 'Gagal memuat kalender. Coba lagi, ya.',
            onRetry: () => ref.invalidate(calendarMonthProvider(monthKey)),
          ),
        ),
      );
    }

    final data = dataAsync.asData?.value;
    final loading = data == null;

    final firstDay = DateTime(month.year, month.month, 1);
    final daysInMonth = DateTime(month.year, month.month + 1, 0).day;
    final leadingBlanks = firstDay.weekday - 1;
    final now = DateTime.now();
    final today = (now.year == month.year && now.month == month.month)
        ? now.day
        : null;

    final rows = <Widget>[];
    var day = 1 - leadingBlanks;
    while (day <= daysInMonth) {
      final cells = <Widget>[];
      for (var i = 0; i < 7; i++, day++) {
        if (day < 1 || day > daysInMonth) {
          cells.add(const Expanded(child: SizedBox.shrink()));
        } else {
          cells.add(
            Expanded(
              child: _DayCell(
                month: month,
                day: day,
                summary: data?.days[day],
                loading: loading,
                isToday: day == today,
              ),
            ),
          );
        }
      }
      rows.add(Expanded(child: Row(children: cells)));
    }

    return _RefreshableMonthPage(
      monthKey: monthKey,
      child: Padding(
        // Clear the floating nav pill at the bottom.
        padding: const EdgeInsets.fromLTRB(
          AffluenaSpacing.space4,
          0,
          AffluenaSpacing.space4,
          96,
        ),
        child: Column(children: rows),
      ),
    );
  }
}

/// Gives one month page real pull-to-refresh. The grid itself is not
/// scrollable (it fills the page with Expanded rows), so the page is wrapped
/// in an always-scrollable viewport sized exactly to the available height:
/// vertical drags feed the RefreshIndicator while horizontal month swipes
/// still reach the enclosing PageView.
class _RefreshableMonthPage extends ConsumerWidget {
  const _RefreshableMonthPage({required this.monthKey, required this.child});

  final String monthKey;
  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(calendarMonthProvider(monthKey));
        try {
          await ref.read(calendarMonthProvider(monthKey).future);
        } catch (_) {
          // The page renders its own error + retry.
        }
      },
      child: LayoutBuilder(
        builder: (context, constraints) => SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: SizedBox(height: constraints.maxHeight, child: child),
        ),
      ),
    );
  }
}

class _DayCell extends StatelessWidget {
  const _DayCell({
    required this.month,
    required this.day,
    required this.summary,
    required this.loading,
    required this.isToday,
  });

  final DateTime month;
  final int day;
  final CalendarDaySummary? summary;
  final bool loading;
  final bool isToday;

  @override
  Widget build(BuildContext context) {
    final hasActivity = summary != null;
    return Padding(
      padding: const EdgeInsets.all(AffluenaSpacing.space1 / 2),
      child: Material(
        color: loading
            ? context.sky.sheet
            : (hasActivity ? context.sky.surface : Colors.transparent),
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          // Every day is tappable: the sheet shows the day's transactions and
          // lets the user add a new one on that date (or edit an existing one).
          onTap: loading ? null : () => _showDaySheet(context, month, day),
          borderRadius: BorderRadius.circular(10),
          child: Container(
            decoration: BoxDecoration(
              border: Border.all(
                color: isToday
                    ? context.sky.accent
                    : (hasActivity && !loading
                          ? context.sky.line
                          : Colors.transparent),
                width: isToday ? 1.4 : 1,
              ),
              borderRadius: BorderRadius.circular(10),
            ),
            padding: const EdgeInsets.symmetric(
              horizontal: AffluenaSpacing.space1 / 2,
              vertical: AffluenaSpacing.space1,
            ),
            child: Column(
              children: [
                Text(
                  '$day',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: isToday ? FontWeight.w800 : FontWeight.w600,
                    color: isToday ? context.sky.accent : context.sky.muted,
                  ),
                ),
                if (summary != null) ...[
                  const Spacer(),
                  if (summary!.incomeMinor > 0)
                    _CellAmount(
                      text:
                          '+${MoneyFormatter.compactIdr(summary!.incomeMinor)}',
                      color: context.sky.income,
                    ),
                  if (summary!.expenseMinor > 0)
                    _CellAmount(
                      text:
                          '−${MoneyFormatter.compactIdr(summary!.expenseMinor)}',
                      color: context.sky.danger,
                    ),
                  _CellAmount(
                    text:
                        '${summary!.netMinor < 0 ? '−' : ''}${MoneyFormatter.compactIdr(summary!.netMinor)}',
                    color: context.sky.ink,
                    bold: true,
                  ),
                  const Spacer(),
                ] else
                  const Spacer(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CellAmount extends StatelessWidget {
  const _CellAmount({
    required this.text,
    required this.color,
    this.bold = false,
  });

  final String text;
  final Color color;
  final bool bold;

  @override
  Widget build(BuildContext context) {
    // Day-cell amounts keep FittedBox: values are already shortened via
    // MoneyFormatter.compactIdr, so scaling only kicks in on the narrowest
    // cells — while ellipsis at this width would hide the value entirely.
    return FittedBox(
      fit: BoxFit.scaleDown,
      child: Text(
        text,
        maxLines: 1,
        style: TextStyle(
          fontSize: 9,
          height: 1.25,
          fontWeight: bold ? FontWeight.w800 : FontWeight.w600,
          color: color,
          fontFeatures: const [FontFeature.tabularFigures()],
        ),
      ),
    );
  }
}

void _showDaySheet(BuildContext context, DateTime month, int day) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (context) =>
        _DayTransactionsSheet(day: DateTime(month.year, month.month, day)),
  );
}

/// The tapped day's transactions, with a mini summary header, an "add on this
/// date" button, and tap-to-edit on each row. It watches [calendarMonthProvider]
/// so adding/editing/deleting a transaction refreshes the list live (the shared
/// financial-refresh invalidates that provider on every money mutation).
class _DayTransactionsSheet extends ConsumerWidget {
  const _DayTransactionsSheet({required this.day});

  final DateTime day;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final monthKey = AffluenaDateFormatter.monthKey(day);
    final data = ref.watch(calendarMonthProvider(monthKey)).asData?.value;
    final summary = data?.days[day.day];
    final txns = summary?.transactions ?? const <Transaction>[];

    final wallets =
        ref.watch(walletListProvider).asData?.value ?? const <Wallet>[];
    final walletNames = {for (final w in wallets) w.id: w.name};
    // The category catalog resolves each row's chosen icon + color; the ledger
    // state powers tap-to-edit (detail sheet + edit/delete) without coupling to
    // the global transactions filter.
    final categories = ref.watch(categoryTagManagementControllerProvider);
    final txState = ref.watch(transactionsControllerProvider);

    final incomeMinor = summary?.incomeMinor ?? 0;
    final expenseMinor = summary?.expenseMinor ?? 0;
    final netMinor = summary?.netMinor ?? 0;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AffluenaSpacing.space5,
          AffluenaSpacing.space2,
          AffluenaSpacing.space5,
          AffluenaSpacing.space4,
        ),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.sizeOf(context).height * 0.8,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Clean title on its own line — no button crowding it.
              Text(
                AffluenaDateFormatter.dayHeader(day),
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.2,
                  color: context.sky.ink,
                ),
              ),
              const SizedBox(height: AffluenaSpacing.space3),
              // The same tidy 3-column summary the month header uses, so the
              // amounts never collide on one cramped line.
              IntrinsicHeight(
                child: Row(
                  children: [
                    _SummaryColumn(
                      label: 'Masuk',
                      value: MoneyFormatter.signedIdr(incomeMinor),
                      color: context.sky.income,
                    ),
                    const _SummaryDivider(),
                    _SummaryColumn(
                      label: 'Keluar',
                      value: MoneyFormatter.signedIdr(-expenseMinor),
                      color: context.sky.danger,
                    ),
                    const _SummaryDivider(),
                    _SummaryColumn(
                      label: 'Selisih',
                      value: MoneyFormatter.signedIdr(netMinor),
                      color: context.sky.ink,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AffluenaSpacing.space4),
              // Prominent, unmistakable full-width add action.
              FilledButton.icon(
                key: const Key('calendar-day-add'),
                onPressed: () => showSkyQuickAddSheet(context, date: day),
                icon: const Icon(Icons.add, size: 20),
                label: const Text('Tambah transaksi'),
                style: FilledButton.styleFrom(
                  backgroundColor: context.sky.accent,
                  foregroundColor: context.sky.onAccent,
                  minimumSize: const Size.fromHeight(48),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AffluenaRadii.control),
                  ),
                  textStyle: const TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(height: AffluenaSpacing.space4),
              if (txns.isNotEmpty) ...[
                Text(
                  'Transaksi',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.3,
                    color: context.sky.faint,
                  ),
                ),
                const SizedBox(height: AffluenaSpacing.space2),
              ],
              Flexible(
                child: txns.isEmpty
                    ? Padding(
                        padding: const EdgeInsets.symmetric(
                          vertical: AffluenaSpacing.space6,
                        ),
                        child: Text(
                          'Belum ada transaksi di tanggal ini.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 13,
                            color: context.sky.muted,
                          ),
                        ),
                      )
                    : ListView.builder(
                        shrinkWrap: true,
                        itemCount: txns.length,
                        itemBuilder: (context, index) {
                          final tx = txns[index];
                          final category = tx.categoryId == null
                              ? null
                              : categories.categoryById(tx.categoryId!);
                          final appearance = categoryAppearanceFor(
                            category,
                            type: tx.type,
                          );
                          return InkWell(
                            key: Key('calendar-day-txn-${tx.id}'),
                            onTap: () => showTransactionDetail(
                              context,
                              ref,
                              txState,
                              tx,
                            ),
                            borderRadius: BorderRadius.circular(
                              AffluenaRadii.md,
                            ),
                            child: TransactionTile(
                              title: tx.note.isNotEmpty
                                  ? tx.note
                                  : _typeLabel(tx.type),
                              metadata:
                                  '${AffluenaDateFormatter.time(tx.transactionAt)}'
                                  '${walletNames[tx.walletId] != null ? ' · ${walletNames[tx.walletId]}' : ''}',
                              amount: switch (tx.type) {
                                TransactionType.income =>
                                  MoneyFormatter.signedIdr(tx.amountMinor),
                                TransactionType.expense =>
                                  MoneyFormatter.signedIdr(-tx.amountMinor),
                                _ => MoneyFormatter.idr(tx.amountMinor),
                              },
                              icon: appearance.icon,
                              iconColor: appearance.color,
                              isIncome: tx.type == TransactionType.income,
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static String _typeLabel(TransactionType type) => switch (type) {
    TransactionType.income => 'Pemasukan',
    TransactionType.expense => 'Pengeluaran',
    TransactionType.transfer => 'Transfer',
    TransactionType.adjustment => 'Penyesuaian',
  };
}
