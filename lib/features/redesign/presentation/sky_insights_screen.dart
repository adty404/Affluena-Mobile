import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../app/theme/affluena_theme.dart';
import '../../../app/theme/sky_palette.dart';
import '../../../core/formatters/money_formatter.dart';
import '../../categories/data/category_models.dart';
import '../../dashboard/application/dashboard_home_controller.dart';
import '../../dashboard/data/dashboard_models.dart';
import '../../dashboard/presentation/cashflow_trend_chart.dart';
import '../../insights/application/category_breakdown_providers.dart';
import '../../shared/presentation/widgets/empty_state.dart';
import '../../shared/presentation/widgets/error_state.dart';
import '../../shared/presentation/widgets/sky_progress_bar.dart';
import '../../shared/presentation/widgets/sky_segmented_toggle.dart';

/// Redesign Tahap 6 — Insights: the heavy analytics (cashflow trend, expense
/// distribution, forecast) deliberately kept OFF the Home so the rooms screen
/// stays calm. Reuses the existing dashboard analytics providers + chart.
/// Additive route.
class SkyInsightsScreen extends StatelessWidget {
  const SkyInsightsScreen({super.key});

  static const path = '/rooms-insights';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.sky.ground,
      body: const SafeArea(child: SkyInsightsView()),
    );
  }
}

/// The Insights body (no Scaffold/back) — hosted standalone or as a tab in the
/// redesign nav shell.
class SkyInsightsView extends ConsumerWidget {
  const SkyInsightsView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final trend = ref.watch(dashboardCashflowTrendProvider);
    final forecast = ref.watch(dashboardForecastProvider);

    return RefreshIndicator(
      onRefresh: () => _refresh(ref),
      child: ListView(
        // Always scrollable so pull-to-refresh works even on a short page.
        physics: const AlwaysScrollableScrollPhysics(),
        // Extra bottom padding so the last row clears the floating nav pill.
        padding: AffluenaInsets.screen.copyWith(bottom: 120),
        children: [
          Text(
            'Wawasan',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: context.sky.ink,
            ),
          ),
          const SizedBox(height: AffluenaSpacing.space4),
          const _CategoryBreakdownCard(),
          _SkyCard(
            title: 'Arus kas',
            child: trend.when(
              loading: () => _loader(context),
              error: (_, _) => _error(
                onRetry: () => ref.invalidate(dashboardCashflowTrendProvider),
              ),
              data: (response) => response.trend.isEmpty
                  ? _empty(icon: Icons.show_chart)
                  : SizedBox(
                      height: 160,
                      child: CashflowTrendChart(points: response.trend),
                    ),
            ),
          ),
          _SkyCard(
            title: 'Perkiraan bulan ini',
            child: forecast.when(
              loading: () => _loader(context),
              error: (_, _) => _error(
                onRetry: () => ref.invalidate(dashboardForecastProvider),
              ),
              data: _ForecastBody.new,
            ),
          ),
        ],
      ),
    );
  }

  /// Pull-to-refresh: re-fetch all three analytics in parallel. Each card
  /// renders its own error + retry, so failures never throw out of here.
  Future<void> _refresh(WidgetRef ref) async {
    // The breakdown card owns its own (period-keyed) provider instance and
    // re-reads on refresh; invalidate the whole family so any period reloads.
    ref.invalidate(categoryBreakdownProvider);
    ref.invalidate(dashboardCashflowTrendProvider);
    ref.invalidate(dashboardForecastProvider);
    await Future.wait([
      _awaitQuietly(ref.read(dashboardCashflowTrendProvider.future)),
      _awaitQuietly(ref.read(dashboardForecastProvider.future)),
    ]);
  }

  static Future<void> _awaitQuietly(Future<Object?> future) async {
    try {
      await future;
    } catch (_) {
      // The card renders its own error + retry.
    }
  }

  static Widget _loader(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: AffluenaSpacing.space4),
    child: Center(child: CircularProgressIndicator(color: context.sky.accent)),
  );

  static Widget _error({required VoidCallback onRetry}) =>
      ErrorState.compact(message: 'Tidak bisa memuat.', onRetry: onRetry);

  static Widget _empty({required IconData icon}) => EmptyState(
    icon: icon,
    title: 'Belum ada data',
    subtitle: 'Catat transaksi dulu untuk mengisi wawasan ini.',
  );
}

/// The headline Wawasan section: the current month's transactions broken down
/// by category, switchable between Pengeluaran (expense) and Pemasukan (income)
/// via a [SkySegmentedToggle]. Renders a ranked horizontal-bar list — each row
/// is the category's chosen icon (in its color on a soft tile) + name + amount
/// + a colored proportion bar + percentage — the clearest, on-brand fit for
/// "where did the money go / come from" given categories already carry colors.
class _CategoryBreakdownCard extends ConsumerStatefulWidget {
  const _CategoryBreakdownCard();

  @override
  ConsumerState<_CategoryBreakdownCard> createState() =>
      _CategoryBreakdownCardState();
}

class _CategoryBreakdownCardState
    extends ConsumerState<_CategoryBreakdownCard> {
  CategoryType _type = CategoryType.expense;
  _InsightPeriod _period = _InsightPeriod.month;
  late DateTime _anchor;
  DateRange? _customRange;

  @override
  void initState() {
    super.initState();
    _anchor = DateTime.now();
  }

  static DateTime _day(DateTime d) => DateTime(d.year, d.month, d.day);

  /// The concrete inclusive date range for the selected period + anchor.
  DateRange get _range {
    final a = _day(_anchor);
    switch (_period) {
      case _InsightPeriod.day:
        return DateRange(from: a, to: a);
      case _InsightPeriod.week:
        final start = a.subtract(Duration(days: a.weekday - 1)); // Monday-first
        return DateRange(from: start, to: start.add(const Duration(days: 6)));
      case _InsightPeriod.month:
        return DateRange(
          from: DateTime(a.year, a.month, 1),
          to: DateTime(a.year, a.month + 1, 0),
        );
      case _InsightPeriod.quarter:
        final startMonth = ((a.month - 1) ~/ 3) * 3 + 1;
        return DateRange(
          from: DateTime(a.year, startMonth, 1),
          to: DateTime(a.year, startMonth + 3, 0),
        );
      case _InsightPeriod.year:
        return DateRange(
          from: DateTime(a.year, 1, 1),
          to: DateTime(a.year, 12, 31),
        );
      case _InsightPeriod.all:
        return DateRange(from: DateTime(2000, 1, 1), to: _day(DateTime.now()));
      case _InsightPeriod.custom:
        return _customRange ?? DateRange(from: a, to: a);
    }
  }

  /// The anchor shifted one period forward (+1) or back (-1).
  DateTime _shifted(int dir) {
    final a = _anchor;
    return switch (_period) {
      _InsightPeriod.day => a.add(Duration(days: dir)),
      _InsightPeriod.week => a.add(Duration(days: 7 * dir)),
      _InsightPeriod.month => DateTime(a.year, a.month + dir, 1),
      _InsightPeriod.quarter => DateTime(a.year, a.month + 3 * dir, 1),
      _InsightPeriod.year => DateTime(a.year + dir, 1, 1),
      _InsightPeriod.all || _InsightPeriod.custom => a,
    };
  }

  bool get _canNavigate =>
      _period != _InsightPeriod.all && _period != _InsightPeriod.custom;

  /// Never page into the future — disable "next" once the range reaches today.
  bool get _canGoForward =>
      _canNavigate && _range.to.isBefore(_day(DateTime.now()));

  String _rangeLabel() {
    final range = _range;
    String d(DateTime x) => DateFormat('d MMM', 'id_ID').format(x);
    return switch (_period) {
      _InsightPeriod.day => DateFormat(
        'EEEE, d MMM y',
        'id_ID',
      ).format(range.from),
      _InsightPeriod.week => '${d(range.from)} – ${d(range.to)}',
      _InsightPeriod.month => DateFormat('MMMM y', 'id_ID').format(range.from),
      _InsightPeriod.quarter =>
        'Kuartal ${((range.from.month - 1) ~/ 3) + 1} ${range.from.year}',
      _InsightPeriod.year => '${range.from.year}',
      _InsightPeriod.all => 'Sepanjang waktu',
      _InsightPeriod.custom =>
        '${d(range.from)} – ${DateFormat('d MMM y', 'id_ID').format(range.to)}',
    };
  }

  Future<void> _pickCustomRange() async {
    final now = DateTime.now();
    final existing = _customRange;
    final initial = existing != null
        ? DateTimeRange(start: existing.from, end: existing.to)
        : DateTimeRange(
            start: DateTime(now.year, now.month, 1),
            end: _day(now),
          );
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: DateTime(now.year + 1, 12, 31),
      initialDateRange: initial,
    );
    if (picked == null || !mounted) return;
    setState(() {
      _period = _InsightPeriod.custom;
      _customRange = DateRange(from: picked.start, to: picked.end);
    });
  }

  @override
  Widget build(BuildContext context) {
    final breakdown = ref.watch(categoryBreakdownProvider(_range));
    final isExpense = _type == CategoryType.expense;

    return Container(
      margin: const EdgeInsets.only(bottom: AffluenaSpacing.space3),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: context.sky.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.sky.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Ke mana uang?',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: context.sky.ink,
            ),
          ),
          const SizedBox(height: AffluenaSpacing.space3),
          _PeriodChips(
            selected: _period,
            onSelected: (p) {
              if (p == _InsightPeriod.custom) {
                _pickCustomRange();
                return;
              }
              setState(() => _period = p);
            },
          ),
          const SizedBox(height: AffluenaSpacing.space2),
          _PeriodNavBar(
            label: _rangeLabel(),
            onPrev: _canNavigate
                ? () => setState(() => _anchor = _shifted(-1))
                : null,
            onNext: _canGoForward
                ? () => setState(() => _anchor = _shifted(1))
                : null,
            onTapLabel: _period == _InsightPeriod.custom
                ? _pickCustomRange
                : null,
          ),
          const SizedBox(height: AffluenaSpacing.space3),
          SkySegmentedToggle<CategoryType>(
            selected: _type,
            onChanged: (value) => setState(() => _type = value),
            options: const [
              SkySegmentOption(
                value: CategoryType.expense,
                label: 'Pengeluaran',
              ),
              SkySegmentOption(value: CategoryType.income, label: 'Pemasukan'),
            ],
          ),
          const SizedBox(height: AffluenaSpacing.space3),
          breakdown.when(
            loading: () => SkyInsightsView._loader(context),
            error: (_, _) => SkyInsightsView._error(
              onRetry: () => ref.invalidate(categoryBreakdownProvider(_range)),
            ),
            data: (data) {
              final slices = isExpense
                  ? data.expenseByCategory
                  : data.incomeByCategory;
              final total = isExpense
                  ? data.expenseTotalMinor
                  : data.incomeTotalMinor;
              final body = slices.isEmpty
                  ? _empty(isExpense: isExpense)
                  : _content(
                      context: context,
                      slices: slices,
                      total: total,
                      isExpense: isExpense,
                    );
              if (!data.truncated) return body;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _TruncationNotice(),
                  const SizedBox(height: AffluenaSpacing.space3),
                  body,
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _content({
    required BuildContext context,
    required List<CategorySlice> slices,
    required int total,
    required bool isExpense,
  }) {
    final totalColor = isExpense ? context.sky.danger : context.sky.income;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          isExpense ? 'Total pengeluaran' : 'Total pemasukan',
          style: TextStyle(fontSize: 11.5, color: context.sky.faint),
        ),
        const SizedBox(height: 2),
        Text(
          MoneyFormatter.idr(total),
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: totalColor,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
        const SizedBox(height: AffluenaSpacing.space3),
        for (final slice in slices)
          _CategorySliceRow(slice: slice, barColor: totalColor),
      ],
    );
  }

  Widget _empty({required bool isExpense}) => EmptyState(
    icon: isExpense ? Icons.trending_down : Icons.trending_up,
    title: isExpense ? 'Belum ada pengeluaran' : 'Belum ada pemasukan',
    subtitle: 'Tidak ada transaksi pada periode ini.',
  );
}

/// Shown when the breakdown hit its 5.000-transaction fetch cap, so the totals
/// below are computed from only the newest rows and may under-report.
class _TruncationNotice extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final amber = context.affluenaColors.amber;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: amber.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: amber.withValues(alpha: 0.35)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline, size: 15, color: amber),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Menampilkan 5.000 transaksi terbaru — total mungkin tidak '
              'lengkap.',
              style: TextStyle(
                fontSize: 11.5,
                height: 1.35,
                color: context.sky.ink,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// The periods the Wawasan breakdown can be scoped to.
enum _InsightPeriod { day, week, month, quarter, year, all, custom }

/// A horizontally-scrollable row of period chips (Hari … Semua, Atur).
class _PeriodChips extends StatelessWidget {
  const _PeriodChips({required this.selected, required this.onSelected});

  final _InsightPeriod selected;
  final ValueChanged<_InsightPeriod> onSelected;

  static const _labels = <_InsightPeriod, String>{
    _InsightPeriod.day: 'Hari',
    _InsightPeriod.week: 'Minggu',
    _InsightPeriod.month: 'Bulan',
    _InsightPeriod.quarter: 'Kuartal',
    _InsightPeriod.year: 'Tahun',
    _InsightPeriod.all: 'Semua',
    _InsightPeriod.custom: 'Atur',
  };

  @override
  Widget build(BuildContext context) {
    final sky = context.sky;
    // A non-lazy Row (not ListView) so every chip is built even when scrolled
    // off-screen — the pager relies on all periods being findable/tappable.
    return SizedBox(
      height: 32,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            for (final period in _InsightPeriod.values) ...[
              GestureDetector(
                key: Key('insight-period-${period.name}'),
                onTap: () => onSelected(period),
                child: Container(
                  alignment: Alignment.center,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: period == selected ? sky.accent : sky.sheet,
                    borderRadius: BorderRadius.circular(AffluenaRadii.pill),
                    border: Border.all(
                      color: period == selected ? sky.accent : sky.line,
                    ),
                  ),
                  child: Text(
                    _labels[period]!,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: period == selected ? sky.onAccent : sky.muted,
                    ),
                  ),
                ),
              ),
              if (period != _InsightPeriod.values.last)
                const SizedBox(width: 6),
            ],
          ],
        ),
      ),
    );
  }
}

/// The prev/next pager around the current period's label. Arrows are disabled
/// when they don't apply (no going into the future; "Semua"/"Atur" don't page);
/// for a custom range, tapping the label re-opens the range picker.
class _PeriodNavBar extends StatelessWidget {
  const _PeriodNavBar({
    required this.label,
    this.onPrev,
    this.onNext,
    this.onTapLabel,
  });

  final String label;
  final VoidCallback? onPrev;
  final VoidCallback? onNext;
  final VoidCallback? onTapLabel;

  @override
  Widget build(BuildContext context) {
    final sky = context.sky;
    return Row(
      children: [
        _NavArrow(icon: Icons.chevron_left, onTap: onPrev),
        Expanded(
          child: GestureDetector(
            onTap: onTapLabel,
            behavior: HitTestBehavior.opaque,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Flexible(
                  child: Text(
                    label,
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: sky.ink,
                    ),
                  ),
                ),
                if (onTapLabel != null) ...[
                  const SizedBox(width: 4),
                  Icon(
                    Icons.edit_calendar_outlined,
                    size: 15,
                    color: sky.muted,
                  ),
                ],
              ],
            ),
          ),
        ),
        _NavArrow(icon: Icons.chevron_right, onTap: onNext),
      ],
    );
  }
}

class _NavArrow extends StatelessWidget {
  const _NavArrow({required this.icon, this.onTap});

  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final sky = context.sky;
    return IconButton(
      onPressed: onTap,
      visualDensity: VisualDensity.compact,
      iconSize: 20,
      icon: Icon(icon, color: onTap != null ? sky.ink : sky.line),
    );
  }
}

/// One ranked category row: a colored icon tile, the name + amount, and a
/// proportion bar with its percentage. The bar/tile use the category's own
/// color when set, else the type's semantic color (danger/income) so a slice
/// without a color still reads clearly.
class _CategorySliceRow extends StatelessWidget {
  const _CategorySliceRow({required this.slice, required this.barColor});

  final CategorySlice slice;

  /// The type's semantic color, used when the category has no chosen color.
  final Color barColor;

  @override
  Widget build(BuildContext context) {
    final accent = slice.color ?? barColor;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 34,
            height: 34,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(AffluenaRadii.md),
            ),
            child: Icon(slice.icon, size: 18, color: accent),
          ),
          const SizedBox(width: AffluenaSpacing.space3),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        slice.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                          color: context.sky.ink,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '${slice.percentOfTotal.round()}%',
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                        color: context.sky.faint,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                    const Spacer(),
                    Text(
                      MoneyFormatter.idr(slice.amountMinor),
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        color: context.sky.ink,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                SkyProgressBar(
                  value: (slice.percentOfTotal / 100).clamp(0, 1).toDouble(),
                  height: 8,
                  fillColor: accent,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ForecastBody extends StatelessWidget {
  const _ForecastBody(this.forecast);

  final DashboardForecast forecast;

  @override
  Widget build(BuildContext context) {
    final overBudget = forecast.status == ForecastStatus.overbudget;
    final statusColor = overBudget ? context.sky.danger : context.sky.income;
    final statusLabel = overBudget ? 'Lewat budget' : 'Aman, di bawah budget';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Perkiraan pengeluaran',
          style: TextStyle(fontSize: 11.5, color: context.sky.faint),
        ),
        const SizedBox(height: 2),
        Text(
          MoneyFormatter.idr(forecast.forecastedExpenseMinor),
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: context.sky.ink,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
        const SizedBox(height: AffluenaSpacing.space2),
        Row(
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: statusColor,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: AffluenaSpacing.space2),
            Text(
              statusLabel,
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: statusColor,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _SkyCard extends StatelessWidget {
  const _SkyCard({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AffluenaSpacing.space3),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: context.sky.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.sky.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: context.sky.ink,
            ),
          ),
          const SizedBox(height: AffluenaSpacing.space3),
          child,
        ],
      ),
    );
  }
}
