import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/affluena_theme.dart';
import '../../../app/theme/sky_palette.dart';
import '../../../core/formatters/date_formatter.dart';
import '../../../core/formatters/money_formatter.dart';
import '../../shared/presentation/widgets/transaction_tile.dart';
import '../../transactions/data/transaction_models.dart';
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
                  const SizedBox(width: AffluenaSpacing.space2),
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

  @override
  Widget build(BuildContext context) {
    return Material(
      color: context.sky.surface,
      shape: CircleBorder(side: BorderSide(color: context.sky.line)),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: SizedBox(
          width: 36,
          height: 36,
          child: Icon(icon, size: 20, color: context.sky.ink),
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

  @override
  Widget build(BuildContext context) {
    final net = data?.netMinor ?? 0;
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
      child: Row(
        children: [
          _SummaryColumn(
            label: 'Pemasukan',
            value: data == null ? null : MoneyFormatter.idr(data!.incomeMinor),
            color: context.sky.income,
          ),
          _SummaryDivider(),
          _SummaryColumn(
            label: 'Pengeluaran',
            value: data == null ? null : MoneyFormatter.idr(data!.expenseMinor),
            color: context.sky.danger,
          ),
          _SummaryDivider(),
          _SummaryColumn(
            label: 'Selisih',
            value: data == null ? null : MoneyFormatter.signedIdr(net),
            color: context.sky.ink,
          ),
        ],
      ),
    );
  }
}

class _SummaryDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 30,
      margin: const EdgeInsets.symmetric(horizontal: AffluenaSpacing.space3),
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
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value ?? '—',
              maxLines: 1,
              style: TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.2,
                color: color,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
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
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Gagal memuat kalender.',
              style: TextStyle(fontSize: 13, color: context.sky.muted),
            ),
            TextButton(
              onPressed: () => ref.invalidate(calendarMonthProvider(monthKey)),
              child: const Text('Coba lagi'),
            ),
          ],
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

    return Padding(
      // Clear the floating nav pill at the bottom.
      padding: const EdgeInsets.fromLTRB(
        AffluenaSpacing.space4,
        0,
        AffluenaSpacing.space4,
        96,
      ),
      child: Column(children: rows),
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
      padding: const EdgeInsets.all(1.5),
      child: Material(
        color: loading
            ? context.sky.sheet
            : (hasActivity ? context.sky.surface : Colors.transparent),
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          onTap: hasActivity
              ? () => _showDaySheet(context, month, day, summary!)
              : null,
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
            padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 3),
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

void _showDaySheet(
  BuildContext context,
  DateTime month,
  int day,
  CalendarDaySummary summary,
) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (context) => _DayTransactionsSheet(
      day: DateTime(month.year, month.month, day),
      summary: summary,
    ),
  );
}

/// The tapped day's transactions with a mini summary header.
class _DayTransactionsSheet extends ConsumerWidget {
  const _DayTransactionsSheet({required this.day, required this.summary});

  final DateTime day;
  final CalendarDaySummary summary;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final wallets =
        ref.watch(walletListProvider).asData?.value ?? const <Wallet>[];
    final walletNames = {for (final w in wallets) w.id: w.name};

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AffluenaSpacing.space5,
          0,
          AffluenaSpacing.space5,
          AffluenaSpacing.space4,
        ),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.sizeOf(context).height * 0.7,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                AffluenaDateFormatter.dayHeader(day),
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: context.sky.ink,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${MoneyFormatter.signedIdr(summary.incomeMinor)} masuk · '
                '${MoneyFormatter.signedIdr(-summary.expenseMinor)} keluar · '
                'selisih ${MoneyFormatter.signedIdr(summary.netMinor)}',
                style: TextStyle(fontSize: 12, color: context.sky.muted),
              ),
              const SizedBox(height: AffluenaSpacing.space2),
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: summary.transactions.length,
                  itemBuilder: (context, index) {
                    final tx = summary.transactions[index];
                    return TransactionTile(
                      title: tx.note.isNotEmpty ? tx.note : _typeLabel(tx.type),
                      metadata:
                          '${AffluenaDateFormatter.time(tx.transactionAt)}'
                          '${walletNames[tx.walletId] != null ? ' · ${walletNames[tx.walletId]}' : ''}',
                      amount: switch (tx.type) {
                        TransactionType.income => MoneyFormatter.signedIdr(
                          tx.amountMinor,
                        ),
                        TransactionType.expense => MoneyFormatter.signedIdr(
                          -tx.amountMinor,
                        ),
                        _ => MoneyFormatter.idr(tx.amountMinor),
                      },
                      icon: _typeIcon(tx.type),
                      isIncome: tx.type == TransactionType.income,
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

  static IconData _typeIcon(TransactionType type) => switch (type) {
    TransactionType.income => Icons.south_west,
    TransactionType.expense => Icons.north_east,
    TransactionType.transfer => Icons.swap_horiz,
    TransactionType.adjustment => Icons.tune,
  };
}
