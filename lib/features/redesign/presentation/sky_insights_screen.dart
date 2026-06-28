import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/affluena_theme.dart';
import '../../../app/theme/sky_palette.dart';
import '../../../core/formatters/money_formatter.dart';
import '../../dashboard/application/dashboard_home_controller.dart';
import '../../dashboard/data/dashboard_models.dart';
import '../../dashboard/presentation/cashflow_trend_chart.dart';
import '../../shared/presentation/widgets/sky_progress_bar.dart';

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

    return ListView(
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
        _SkyCard(
          title: 'Arus kas',
          child: trend.when(
            loading: () => _loader(context),
            error: (_, _) => _errorText(context),
            data: (response) => response.trend.isEmpty
                ? _emptyText(context)
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
            error: (_, _) => _errorText(context),
            data: (response) => response.distribution.isEmpty
                ? _emptyText(context)
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
            error: (_, _) => _errorText(context),
            data: _ForecastBody.new,
          ),
        ),
      ],
    );
  }

  static Widget _loader(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: AffluenaSpacing.space4),
    child: Center(child: CircularProgressIndicator(color: context.sky.accent)),
  );

  static Widget _errorText(BuildContext context) => Text(
    'Tidak bisa memuat.',
    style: TextStyle(fontSize: 13, color: context.sky.muted),
  );

  static Widget _emptyText(BuildContext context) => Text(
    'Belum ada data.',
    style: TextStyle(fontSize: 13, color: context.sky.faint),
  );
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
