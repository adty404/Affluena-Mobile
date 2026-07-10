import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/affluena_theme.dart';
import '../../../core/formatters/money_formatter.dart';
import '../../shared/presentation/widgets/affluena_banner.dart';
import '../../shared/presentation/widgets/affluena_card.dart';
import '../../shared/presentation/widgets/affluena_chip_bar.dart';
import '../../shared/presentation/widgets/affluena_choice_chip.dart';
import '../../shared/presentation/widgets/affluena_skeleton.dart';
import '../../shared/presentation/widgets/drill_in_scaffold.dart';
import '../../shared/presentation/widgets/metric_tile.dart';
import '../../shared/presentation/widgets/section_header.dart';
import '../../shared/presentation/widgets/status_badge.dart';
import '../application/insights_controller.dart';
import '../data/insight_models.dart';
import 'insight_shared_widgets.dart';

/// Pengaturan → Laporan — the monthly income/expense reports, now a real
/// standalone screen (the old InsightsScreen hosted every insight section
/// behind one chip bar; each section is its own routed screen now). The
/// report-kind chips stay: they are THIS screen's sub-views, not a
/// cross-section switcher.
class LaporanScreen extends ConsumerWidget {
  const LaporanScreen({super.key});

  static const path = '/laporan';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(insightsControllerProvider);
    final controller = ref.read(insightsControllerProvider.notifier);
    final reportEmpty =
        state.report.metrics.isEmpty && state.report.rows.isEmpty;

    if (state.isLoading && reportEmpty) {
      return const InsightsLoadingScaffold(title: 'Laporan');
    }

    if (state.loadError != null && reportEmpty) {
      return InsightsErrorScaffold(
        title: 'Laporan',
        message: state.loadError!,
        onRetry: controller.load,
      );
    }

    return DrillInScaffold(
      title: 'Laporan',
      body: ListView(
        padding: AffluenaInsets.screen,
        children: [
          if (state.actionError != null) ...[
            AffluenaBanner.error(state.actionError!),
            const SizedBox(height: AffluenaSpacing.space3),
          ],
          AffluenaChipBar(
            chips: [
              for (final kind in ReportKind.values)
                AffluenaChoiceChip(
                  key: Key('report-kind-${kind.name}'),
                  selected: state.reportKind == kind,
                  label: kind.label,
                  onSelected: state.isReportLoading
                      ? null
                      : () => controller.setReportKind(kind),
                ),
            ],
          ),
          const SizedBox(height: AffluenaSpacing.space4),
          if (state.isReportLoading)
            const _ReportSkeleton()
          else if (reportEmpty)
            const InsightEmptyState(
              icon: Icons.analytics_outlined,
              title: 'Belum ada data laporan',
              body:
                  'Laporan akan muncul setelah ada aktivitas keuangan tercatat.',
            )
          else ...[
            if (state.report.metrics.isNotEmpty) ...[
              for (final pair in _metricPairs(state.report.metrics)) ...[
                Row(
                  children: [
                    for (final metric in pair) ...[
                      MetricTile(
                        label: metric.label,
                        value: _formatMetricValue(metric),
                        helper: _metricHelper(metric),
                        icon: _metricIcon(metric.tone),
                      ),
                      if (pair.indexOf(metric) == 0 && pair.length > 1)
                        const SizedBox(width: AffluenaSpacing.space3),
                    ],
                  ],
                ),
                const SizedBox(height: AffluenaSpacing.space3),
              ],
            ],
            SectionHeader(
              title: 'Baris ${state.reportKind.label}',
              actionLabel: '${state.report.rows.length} baris',
            ),
            const SizedBox(height: AffluenaSpacing.space3),
            for (final row in state.report.rows) ...[
              _ReportRowCard(row: row),
              const SizedBox(height: AffluenaSpacing.space3),
            ],
          ],
        ],
      ),
    );
  }
}

class _ReportRowCard extends StatelessWidget {
  const _ReportRowCard({required this.row});

  final ReportRow row;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return AffluenaCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text(row.name, style: textTheme.titleMedium)),
              StatusBadge(
                label: row.status.label,
                tone: _reportStatusTone(row.status),
              ),
            ],
          ),
          const SizedBox(height: AffluenaSpacing.space3),
          Text(
            MoneyFormatter.idr(row.amountMinor),
            style: textTheme.headlineSmall,
          ),
          const SizedBox(height: AffluenaSpacing.space2),
          Text('${row.category} · ${row.wallet}', style: textTheme.bodySmall),
          const SizedBox(height: AffluenaSpacing.space2),
          Text(
            'Sebelumnya ${MoneyFormatter.idr(row.previousAmountMinor)} · ${row.changePercent.toStringAsFixed(1)}%',
            style: textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}

class _ReportSkeleton extends StatelessWidget {
  const _ReportSkeleton();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Row(
          children: [
            Expanded(child: AffluenaSkeleton(height: 72, radius: 18)),
            SizedBox(width: AffluenaSpacing.space3),
            Expanded(child: AffluenaSkeleton(height: 72, radius: 18)),
          ],
        ),
        const SizedBox(height: AffluenaSpacing.space4),
        for (var i = 0; i < 3; i++) ...[
          AffluenaCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                AffluenaSkeleton.line(width: 160, height: 16),
                SizedBox(height: AffluenaSpacing.space3),
                AffluenaSkeleton.line(width: 120, height: 20),
                SizedBox(height: AffluenaSpacing.space2),
                AffluenaSkeleton.line(width: 200),
              ],
            ),
          ),
          const SizedBox(height: AffluenaSpacing.space3),
        ],
      ],
    );
  }
}

List<List<ReportMetric>> _metricPairs(List<ReportMetric> metrics) {
  final pairs = <List<ReportMetric>>[];
  for (var index = 0; index < metrics.length; index += 2) {
    pairs.add(metrics.skip(index).take(2).toList(growable: false));
  }
  return pairs;
}

IconData _metricIcon(String tone) {
  return switch (tone) {
    'positive' => Icons.trending_up,
    'negative' => Icons.trending_down,
    'success' => Icons.trending_up,
    'warning' => Icons.warning_amber_outlined,
    'danger' => Icons.priority_high,
    _ => Icons.insights_outlined,
  };
}

/// Formats a metric value from its explicit [MetricUnit] rather than guessing
/// from the label text.
String _formatMetricValue(ReportMetric metric) {
  return switch (metric.unit) {
    MetricUnit.percent => '${metric.valueMinor}%',
    MetricUnit.count => metric.valueMinor.toString(),
    MetricUnit.text => metric.helper.isEmpty ? '—' : metric.helper,
    MetricUnit.money => MoneyFormatter.idr(metric.valueMinor),
  };
}

/// For text metrics the helper string is promoted to the value, so suppress
/// the redundant secondary helper line.
String? _metricHelper(ReportMetric metric) {
  return metric.unit == MetricUnit.text ? null : metric.helper;
}

StatusTone _reportStatusTone(ReportRowStatus status) {
  return switch (status) {
    ReportRowStatus.healthy => StatusTone.success,
    ReportRowStatus.watch => StatusTone.warning,
    ReportRowStatus.critical => StatusTone.danger,
    ReportRowStatus.growth => StatusTone.success,
  };
}
