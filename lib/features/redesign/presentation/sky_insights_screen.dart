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
    return const Scaffold(
      backgroundColor: SkyPalette.ground,
      body: SafeArea(child: SkyInsightsView()),
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
      padding: AffluenaInsets.screen,
      children: [
        const Text(
          'Insights',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: SkyPalette.ink,
          ),
        ),
        const SizedBox(height: AffluenaSpacing.space4),
        _SkyCard(
          title: 'Arus kas',
          child: trend.when(
            loading: _loader,
            error: (_, _) => _errorText,
            data: (response) => response.trend.isEmpty
                ? _emptyText
                : SizedBox(
                    height: 160,
                    child: CashflowTrendChart(points: response.trend),
                  ),
          ),
        ),
        _SkyCard(
          title: 'Ke mana uang pergi',
          child: distribution.when(
            loading: _loader,
            error: (_, _) => _errorText,
            data: (response) => response.distribution.isEmpty
                ? _emptyText
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
            loading: _loader,
            error: (_, _) => _errorText,
            data: _ForecastBody.new,
          ),
        ),
      ],
    );
  }

  static Widget _loader() => const Padding(
    padding: EdgeInsets.symmetric(vertical: AffluenaSpacing.space4),
    child: Center(child: CircularProgressIndicator(color: SkyPalette.accent)),
  );

  static const Widget _errorText = Text(
    'Tidak bisa memuat.',
    style: TextStyle(fontSize: 13, color: SkyPalette.muted),
  );

  static const Widget _emptyText = Text(
    'Belum ada data.',
    style: TextStyle(fontSize: 13, color: SkyPalette.faint),
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
              Expanded(
                child: Text(
                  item.categoryName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 12.5, color: SkyPalette.ink),
                ),
              ),
              const SizedBox(width: AffluenaSpacing.space2),
              Text(
                MoneyFormatter.idr(item.amountMinor),
                style: const TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: SkyPalette.ink,
                  fontFeatures: [FontFeature.tabularFigures()],
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          SkyProgressBar(value: (item.percentage / 100).clamp(0, 1).toDouble()),
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
    final statusColor = overBudget ? SkyPalette.danger : SkyPalette.income;
    final statusLabel = overBudget ? 'Lewat budget' : 'Aman, di bawah budget';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Perkiraan pengeluaran',
          style: TextStyle(fontSize: 11.5, color: SkyPalette.faint),
        ),
        const SizedBox(height: 2),
        Text(
          MoneyFormatter.idr(forecast.forecastedExpenseMinor),
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: SkyPalette.ink,
            fontFeatures: [FontFeature.tabularFigures()],
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
      padding: const EdgeInsets.all(AffluenaSpacing.space4),
      decoration: BoxDecoration(
        color: SkyPalette.surface,
        borderRadius: BorderRadius.circular(AffluenaRadii.card),
        border: Border.all(color: SkyPalette.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: SkyPalette.ink,
            ),
          ),
          const SizedBox(height: AffluenaSpacing.space3),
          child,
        ],
      ),
    );
  }
}
