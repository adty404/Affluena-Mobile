import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
    final distribution = ref.watch(dashboardExpenseDistributionProvider);
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
            title: 'Ke mana uang pergi',
            child: distribution.when(
              loading: () => _loader(context),
              error: (_, _) => _error(
                onRetry: () =>
                    ref.invalidate(dashboardExpenseDistributionProvider),
              ),
              data: (response) => response.distribution.isEmpty
                  ? _empty(icon: Icons.donut_small_outlined)
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        for (final item in response.distribution.take(6))
                          _DistributionRow(item: item),
                      ],
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
    ref.invalidate(currentMonthCategoryBreakdownProvider);
    ref.invalidate(dashboardCashflowTrendProvider);
    ref.invalidate(dashboardExpenseDistributionProvider);
    ref.invalidate(dashboardForecastProvider);
    await Future.wait([
      _awaitQuietly(ref.read(currentMonthCategoryBreakdownProvider.future)),
      _awaitQuietly(ref.read(dashboardCashflowTrendProvider.future)),
      _awaitQuietly(ref.read(dashboardExpenseDistributionProvider.future)),
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

  @override
  Widget build(BuildContext context) {
    final breakdown = ref.watch(currentMonthCategoryBreakdownProvider);
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
            'Ke mana uang bulan ini?',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: context.sky.ink,
            ),
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
              onRetry: () =>
                  ref.invalidate(currentMonthCategoryBreakdownProvider),
            ),
            data: (data) {
              final slices = isExpense
                  ? data.expenseByCategory
                  : data.incomeByCategory;
              final total = isExpense
                  ? data.expenseTotalMinor
                  : data.incomeTotalMinor;
              if (slices.isEmpty) {
                return _empty(isExpense: isExpense);
              }
              return _content(
                context: context,
                slices: slices,
                total: total,
                isExpense: isExpense,
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
    title: isExpense
        ? 'Belum ada pengeluaran bulan ini'
        : 'Belum ada pemasukan bulan ini',
    subtitle: 'Catat transaksi dulu untuk melihat rinciannya.',
  );
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

class _DistributionRow extends StatelessWidget {
  const _DistributionRow({required this.item});

  final ExpenseDistribution item;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Flexible(
                child: Text(
                  item.categoryName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                    color: context.sky.ink,
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Text(
                '${item.percentage.round()}%',
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                  color: context.sky.faint,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
              const Spacer(),
              Text(
                MoneyFormatter.idr(item.amountMinor),
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                  color: context.sky.ink,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          SkyProgressBar(
            value: (item.percentage / 100).clamp(0, 1).toDouble(),
            height: 8,
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
