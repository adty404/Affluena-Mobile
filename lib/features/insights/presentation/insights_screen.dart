import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/affluena_theme.dart';
import '../../../core/formatters/date_formatter.dart';
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
import '../application/csv_share_service.dart';
import '../application/insights_controller.dart';
import '../data/insight_models.dart';
import '../data/insights_repository.dart';
import 'audit_log_screen.dart' show copyTechnicalValue;

class InsightsScreen extends ConsumerStatefulWidget {
  const InsightsScreen({this.initialTab = InsightTab.reports, super.key});

  static const path = '/insights';

  static String location(InsightTab tab) {
    return tab == InsightTab.reports ? path : '$path?tab=${tab.name}';
  }

  static InsightTab tabFromQuery(String? value) {
    return InsightTab.values.firstWhere(
      (tab) => tab.name == value,
      orElse: () => InsightTab.reports,
    );
  }

  final InsightTab initialTab;

  @override
  ConsumerState<InsightsScreen> createState() => _InsightsScreenState();
}

class _InsightsScreenState extends ConsumerState<InsightsScreen> {
  @override
  void initState() {
    super.initState();
    _syncInitialTab();
  }

  @override
  void didUpdateWidget(covariant InsightsScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialTab != widget.initialTab) {
      _syncInitialTab();
    }
  }

  void _syncInitialTab() {
    Future<void>.microtask(() {
      if (!mounted) return;
      final controller = ref.read(insightsControllerProvider.notifier);
      final state = ref.read(insightsControllerProvider);
      if (state.selectedTab != widget.initialTab) {
        controller.setTab(widget.initialTab);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(insightsControllerProvider);
    final controller = ref.read(insightsControllerProvider.notifier);

    if (state.isLoading && state.report.metrics.isEmpty) {
      return const _InsightsLoading();
    }

    if (state.loadError != null && state.report.metrics.isEmpty) {
      return _InsightsError(
        message: state.loadError!,
        onRetry: controller.load,
      );
    }

    return DrillInScaffold(
      title: 'Wawasan',
      body: ListView(
        padding: AffluenaInsets.screen,
        children: [
          _InsightsSummaryCard(state: state),
          const SizedBox(height: AffluenaSpacing.space5),
          if (state.actionError != null) ...[
            AffluenaBanner.error(state.actionError!),
            const SizedBox(height: AffluenaSpacing.space3),
          ],
          if (state.actionMessage != null) ...[
            AffluenaBanner.success(
              state.actionMessage!,
              onDismiss: controller.clearActionMessage,
            ),
            const SizedBox(height: AffluenaSpacing.space3),
          ],
          _InsightTabs(
            selected: state.selectedTab,
            onChanged: controller.setTab,
          ),
          const SizedBox(height: AffluenaSpacing.space5),
          switch (state.selectedTab) {
            InsightTab.reports => _ReportsSection(
              state: state,
              controller: controller,
            ),
            InsightTab.exports => _ExportsSection(
              state: state,
              controller: controller,
            ),
            InsightTab.alerts => _AlertsSection(alerts: state.alerts),
            InsightTab.activity => _ActivitySection(
              activities: state.activities,
              total: state.activityTotal,
            ),
            InsightTab.rules => _RulesSection(
              state: state,
              controller: controller,
            ),
          },
        ],
      ),
    );
  }
}

class _InsightsSummaryCard extends StatelessWidget {
  const _InsightsSummaryCard({required this.state});

  final InsightsState state;

  @override
  Widget build(BuildContext context) {
    return AffluenaCard(
      child: Column(
        children: [
          Row(
            children: [
              MetricTile(
                label: 'Baris laporan',
                value: state.report.rows.length.toString(),
                helper: state.reportKind.label,
                icon: Icons.analytics_outlined,
              ),
              const SizedBox(width: AffluenaSpacing.space3),
              MetricTile(
                label: 'Ekspor',
                value: state.completedExportCount.toString(),
                helper: 'Selesai',
                icon: Icons.file_download_outlined,
              ),
            ],
          ),
          const SizedBox(height: AffluenaSpacing.space3),
          Row(
            children: [
              MetricTile(
                label: 'Peringatan',
                value: state.warningAlertCount.toString(),
                helper: 'Perlu ditinjau',
                icon: Icons.notifications_active_outlined,
              ),
              const SizedBox(width: AffluenaSpacing.space3),
              MetricTile(
                label: 'Aturan',
                value: state.enabledRuleCount.toString(),
                helper: 'Aktif',
                icon: Icons.tune_outlined,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _InsightTabs extends StatelessWidget {
  const _InsightTabs({required this.selected, required this.onChanged});

  final InsightTab selected;
  final ValueChanged<InsightTab> onChanged;

  @override
  Widget build(BuildContext context) {
    return AffluenaChipBar(
      chips: [
        // CSV export is hidden for now; only the reports/insights tabs show.
        for (final tab in InsightTab.values.where(
          (t) => t != InsightTab.exports,
        ))
          AffluenaChoiceChip(
            key: Key('insights-tab-${tab.name}'),
            selected: selected == tab,
            label: tab.label,
            onSelected: () => onChanged(tab),
          ),
      ],
    );
  }
}

class _ReportsSection extends StatelessWidget {
  const _ReportsSection({required this.state, required this.controller});

  final InsightsState state;
  final InsightsController controller;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(title: 'Laporan'),
        const SizedBox(height: AffluenaSpacing.space3),
        AffluenaChipBar(
          chips: [
            for (final kind in ReportKind.values)
              AffluenaChoiceChip(
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
        else if (state.report.metrics.isEmpty && state.report.rows.isEmpty)
          const _EmptyState(
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
    );
  }
}

class _ExportsSection extends StatelessWidget {
  const _ExportsSection({required this.state, required this.controller});

  final InsightsState state;
  final InsightsController controller;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AffluenaCard(
          backgroundColor: context.affluenaColors.surfaceTintSoft,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'CSV transaksi',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: AffluenaSpacing.space2),
              Text(
                'Buat ekspor transaksi bulan ini lalu bagikan atau simpan '
                'berkas CSV-nya.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: AffluenaSpacing.space4),
              FilledButton.icon(
                key: const Key('insights-export-button'),
                onPressed: state.isSaving ? null : controller.exportCsv,
                icon: state.isSaving
                    ? const SizedBox.square(
                        dimension: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.ios_share_outlined),
                label: Text(state.isSaving ? 'Menyiapkan' : 'Ekspor CSV'),
              ),
            ],
          ),
        ),
        const SizedBox(height: AffluenaSpacing.space5),
        SectionHeader(
          title: 'Tugas ekspor',
          actionLabel: state.exportJobTotal == 0
              ? null
              : '${state.exportJobTotal} total',
        ),
        const SizedBox(height: AffluenaSpacing.space3),
        if (state.exportJobs.isEmpty)
          const _EmptyState(
            icon: Icons.file_download_outlined,
            title: 'Belum ada tugas ekspor',
            body: 'Ekspor CSV yang dibuat akan muncul di sini.',
          )
        else
          for (final job in state.exportJobs) ...[
            _ExportJobCard(job: job, controller: controller),
            const SizedBox(height: AffluenaSpacing.space3),
          ],
      ],
    );
  }
}

class _AlertsSection extends StatelessWidget {
  const _AlertsSection({required this.alerts});

  final List<InsightAlert> alerts;

  @override
  Widget build(BuildContext context) {
    if (alerts.isEmpty) {
      return const _EmptyState(
        icon: Icons.notifications_none_outlined,
        title: 'Belum ada peringatan',
        body:
            'Peringatan anggaran dan jatuh tempo akan muncul di sini saat perlu diperhatikan.',
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(
          title: 'Peringatan',
          actionLabel: '${alerts.length} total',
        ),
        const SizedBox(height: AffluenaSpacing.space3),
        for (final alert in alerts) ...[
          _AlertCard(alert: alert),
          const SizedBox(height: AffluenaSpacing.space3),
        ],
      ],
    );
  }
}

class _ActivitySection extends StatelessWidget {
  const _ActivitySection({required this.activities, required this.total});

  final List<ActivityItem> activities;
  final int total;

  @override
  Widget build(BuildContext context) {
    if (activities.isEmpty) {
      return const _EmptyState(
        icon: Icons.history_outlined,
        title: 'Belum ada aktivitas',
        body:
            'Catatan jejak audit terbaru akan muncul setelah ada perubahan akun.',
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(title: 'Aktivitas', actionLabel: '$total total'),
        const SizedBox(height: AffluenaSpacing.space3),
        for (final activity in activities) ...[
          _ActivityCard(activity: activity),
          const SizedBox(height: AffluenaSpacing.space3),
        ],
      ],
    );
  }
}

class _RulesSection extends StatelessWidget {
  const _RulesSection({required this.state, required this.controller});

  final InsightsState state;
  final InsightsController controller;

  @override
  Widget build(BuildContext context) {
    if (state.rules.isEmpty) {
      return const _EmptyState(
        icon: Icons.tune_outlined,
        title: 'Belum ada aturan notifikasi',
        body: 'Preferensi notifikasi akan muncul saat nilai bawaan dibuat.',
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(title: 'Aturan notifikasi'),
        const SizedBox(height: AffluenaSpacing.space3),
        for (final rule in state.rules) ...[
          _NotificationRuleCard(
            rule: rule,
            isSaving: state.isSaving,
            onEnabledChanged: (enabled) => controller.updateRule(
              rule,
              NotificationRuleUpdate(enabled: enabled),
            ),
            onChannelChanged: (channel) => controller.updateRule(
              rule,
              NotificationRuleUpdate(channel: channel),
            ),
          ),
          const SizedBox(height: AffluenaSpacing.space3),
        ],
      ],
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

class _ExportJobCard extends StatelessWidget {
  const _ExportJobCard({required this.job, required this.controller});

  final ExportJob job;
  final InsightsController controller;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return InkWell(
      borderRadius: BorderRadius.circular(AffluenaRadii.card),
      onTap: () =>
          _openExportJobDetail(context, job: job, controller: controller),
      child: AffluenaCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    job.format.toUpperCase(),
                    style: textTheme.titleMedium,
                  ),
                ),
                StatusBadge.forStatus(job.status.name, label: job.status.label),
              ],
            ),
            const SizedBox(height: AffluenaSpacing.space2),
            Text('${job.rowCount} baris', style: textTheme.bodyLarge),
            const SizedBox(height: AffluenaSpacing.space1),
            Text(
              AffluenaDateFormatter.shortDate(job.createdAt),
              style: textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}

class _AlertCard extends ConsumerWidget {
  const _AlertCard({required this.alert});

  final InsightAlert alert;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textTheme = Theme.of(context).textTheme;
    return InkWell(
      borderRadius: BorderRadius.circular(AffluenaRadii.card),
      onTap: () => _openAlertDetail(context, ref, alert),
      child: AffluenaCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(alert.title, style: textTheme.titleMedium),
                ),
                StatusBadge(
                  label: alert.severity.label,
                  tone: _severityTone(alert.severity),
                ),
              ],
            ),
            const SizedBox(height: AffluenaSpacing.space2),
            Text(alert.description, style: textTheme.bodySmall),
            const SizedBox(height: AffluenaSpacing.space2),
            Text(alert.module, style: textTheme.labelMedium),
          ],
        ),
      ),
    );
  }
}

class _ActivityCard extends StatelessWidget {
  const _ActivityCard({required this.activity});

  final ActivityItem activity;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return InkWell(
      borderRadius: BorderRadius.circular(AffluenaRadii.card),
      onTap: () => _openActivityDetail(context, activity),
      child: AffluenaCard(
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: context.affluenaColors.forestSoft,
              child: Icon(
                _activityIcon(activity.actionType),
                color: context.affluenaColors.forest,
              ),
            ),
            const SizedBox(width: AffluenaSpacing.space4),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(activity.description, style: textTheme.titleSmall),
                  const SizedBox(height: AffluenaSpacing.space1),
                  Text(
                    '${_humanize(activity.entityType)} · ${AffluenaDateFormatter.shortDate(activity.createdAt)}',
                    style: textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NotificationRuleCard extends StatelessWidget {
  const _NotificationRuleCard({
    required this.rule,
    required this.isSaving,
    required this.onEnabledChanged,
    required this.onChannelChanged,
  });

  final NotificationRule rule;
  final bool isSaving;
  final ValueChanged<bool> onEnabledChanged;
  final ValueChanged<NotificationChannel> onChannelChanged;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return AffluenaCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Material(
            type: MaterialType.transparency,
            child: SwitchListTile(
              key: Key('notification-rule-${rule.ruleKey}-switch'),
              contentPadding: EdgeInsets.zero,
              value: rule.enabled,
              onChanged: isSaving ? null : onEnabledChanged,
              title: Text(rule.title, style: textTheme.titleMedium),
              subtitle: Text(rule.description, style: textTheme.bodySmall),
            ),
          ),
          const SizedBox(height: AffluenaSpacing.space2),
          DropdownButtonFormField<NotificationChannel>(
            initialValue: rule.channel,
            decoration: const InputDecoration(
              labelText: 'Saluran',
              prefixIcon: Icon(Icons.campaign_outlined),
            ),
            items: [
              for (final channel in NotificationChannel.values)
                DropdownMenuItem(value: channel, child: Text(channel.label)),
            ],
            onChanged: isSaving || !rule.enabled
                ? null
                : (value) {
                    if (value != null && value != rule.channel) {
                      onChannelChanged(value);
                    }
                  },
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({
    required this.icon,
    required this.title,
    required this.body,
  });

  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return AffluenaCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: context.affluenaColors.forest),
          const SizedBox(height: AffluenaSpacing.space3),
          Text(title, style: textTheme.titleMedium),
          const SizedBox(height: AffluenaSpacing.space1),
          Text(body, style: textTheme.bodySmall),
        ],
      ),
    );
  }
}

class _InsightsLoading extends StatelessWidget {
  const _InsightsLoading();

  @override
  Widget build(BuildContext context) {
    return DrillInScaffold(
      title: 'Wawasan',
      body: ListView(
        padding: AffluenaInsets.screen,
        children: [
          const AffluenaCard(child: _SummarySkeleton()),
          const SizedBox(height: AffluenaSpacing.space5),
          const Wrap(
            spacing: AffluenaSpacing.space2,
            runSpacing: AffluenaSpacing.space2,
            children: [
              AffluenaSkeleton(
                width: 80,
                height: 32,
                radius: AffluenaRadii.pill,
              ),
              AffluenaSkeleton(
                width: 80,
                height: 32,
                radius: AffluenaRadii.pill,
              ),
              AffluenaSkeleton(
                width: 72,
                height: 32,
                radius: AffluenaRadii.pill,
              ),
              AffluenaSkeleton(
                width: 72,
                height: 32,
                radius: AffluenaRadii.pill,
              ),
            ],
          ),
          const SizedBox(height: AffluenaSpacing.space5),
          const _ReportSkeleton(),
        ],
      ),
    );
  }
}

class _SummarySkeleton extends StatelessWidget {
  const _SummarySkeleton();

  @override
  Widget build(BuildContext context) {
    return const Column(
      children: [
        Row(
          children: [
            Expanded(child: AffluenaSkeleton(height: 72, radius: 18)),
            SizedBox(width: AffluenaSpacing.space3),
            Expanded(child: AffluenaSkeleton(height: 72, radius: 18)),
          ],
        ),
        SizedBox(height: AffluenaSpacing.space3),
        Row(
          children: [
            Expanded(child: AffluenaSkeleton(height: 72, radius: 18)),
            SizedBox(width: AffluenaSpacing.space3),
            Expanded(child: AffluenaSkeleton(height: 72, radius: 18)),
          ],
        ),
      ],
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

class _InsightsError extends StatelessWidget {
  const _InsightsError({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return DrillInScaffold(
      title: 'Wawasan',
      body: Padding(
        padding: const EdgeInsets.all(AffluenaSpacing.space5),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [AffluenaBanner.error(message, onRetry: onRetry)],
        ),
      ),
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

IconData _activityIcon(String actionType) {
  final normalized = actionType.toLowerCase();
  if (normalized.contains('create')) return Icons.add_circle_outline;
  if (normalized.contains('update') || normalized.contains('edit')) {
    return Icons.edit_outlined;
  }
  if (normalized.contains('delete')) return Icons.delete_outline;
  return Icons.history_outlined;
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

/// For text metrics the helper string is promoted to the value, so suppress the
/// redundant secondary helper line.
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

StatusTone _severityTone(InsightSeverity severity) {
  return switch (severity) {
    InsightSeverity.info => StatusTone.neutral,
    InsightSeverity.success => StatusTone.success,
    InsightSeverity.warning => StatusTone.warning,
    InsightSeverity.danger => StatusTone.danger,
  };
}

String _humanize(String value) {
  if (value.isEmpty) return value;
  return value
      .split(RegExp(r'[_\s]+'))
      .where((word) => word.isNotEmpty)
      .map((w) => '${w[0].toUpperCase()}${w.substring(1)}')
      .join(' ');
}

Future<void> _openActivityDetail(BuildContext context, ActivityItem activity) {
  return _showDetailSheet(
    context,
    title: activity.description,
    subtitle:
        '${_humanize(activity.actionType)} · ${_humanize(activity.entityType)}',
    rows: [
      _DetailRow('Aksi', _humanize(activity.actionType)),
      _DetailRow('Entitas', _humanize(activity.entityType)),
      _DetailRow(
        'Dicatat',
        AffluenaDateFormatter.shortDate(activity.createdAt),
      ),
      if (activity.entityId.isNotEmpty)
        _DetailRow('ID referensi', activity.entityId, isTechnical: true),
    ],
  );
}

Future<void> _openAlertDetail(
  BuildContext context,
  WidgetRef ref,
  InsightAlert alert,
) async {
  InsightAlert detail = alert;
  try {
    detail = await ref.read(insightsRepositoryProvider).getAlert(alert.id);
  } catch (_) {
    // Fall back to the list payload we already have; the sheet still opens.
  }
  if (!context.mounted) return;
  await _showDetailSheet(
    context,
    title: detail.title,
    subtitle: '${_humanize(detail.module)} · ${detail.severity.label}',
    badge: StatusBadge(
      label: detail.severity.label,
      tone: _severityTone(detail.severity),
    ),
    body: detail.description,
    rows: [
      _DetailRow('Jenis', _humanize(detail.type)),
      _DetailRow('Modul', _humanize(detail.module)),
      _DetailRow('Dibuat', AffluenaDateFormatter.shortDate(detail.createdAt)),
    ],
  );
}

Future<void> _openExportJobDetail(
  BuildContext context, {
  required ExportJob job,
  required InsightsController controller,
}) {
  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (sheetContext) {
      return _ExportJobDetailSheet(job: job, controller: controller);
    },
  );
}

class _ExportJobDetailSheet extends StatefulWidget {
  const _ExportJobDetailSheet({required this.job, required this.controller});

  final ExportJob job;
  final InsightsController controller;

  @override
  State<_ExportJobDetailSheet> createState() => _ExportJobDetailSheetState();
}

class _ExportJobDetailSheetState extends State<_ExportJobDetailSheet> {
  bool _isSharing = false;
  bool _isRetrying = false;
  String? _error;

  Future<void> _share() async {
    setState(() {
      _isSharing = true;
      _error = null;
    });
    try {
      final outcome = await widget.controller.shareExportJob(widget.job);
      if (!mounted) return;
      switch (outcome) {
        case CsvShareOutcome.shared:
          Navigator.of(context).pop();
        case CsvShareOutcome.dismissed:
          setState(() => _isSharing = false);
        case CsvShareOutcome.unavailable:
          setState(() {
            _isSharing = false;
            _error = 'Berbagi tidak tersedia di perangkat ini.';
          });
        case CsvShareOutcome.empty:
          setState(() {
            _isSharing = false;
            _error = 'Ekspor ini sudah tidak punya baris untuk dibagikan.';
          });
      }
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isSharing = false;
        _error = 'Ekspor tidak dapat dibagikan. Coba lagi.';
      });
    }
  }

  /// Re-submits a failed export with the same parameters (a fresh job is
  /// recorded server-side and the job list refreshed), then hands the new CSV
  /// to the share sheet so the retry immediately delivers the file.
  Future<void> _retry() async {
    setState(() {
      _isRetrying = true;
      _error = null;
    });
    try {
      final outcome = await widget.controller.retryExportJob(widget.job);
      if (!mounted) return;
      switch (outcome) {
        case CsvShareOutcome.shared:
        case CsvShareOutcome.dismissed:
          // The re-run succeeded; the refreshed list now shows the new job.
          Navigator.of(context).pop();
        case CsvShareOutcome.unavailable:
          setState(() {
            _isRetrying = false;
            _error =
                'Ekspor baru berhasil dibuat, tetapi berbagi tidak tersedia '
                'di perangkat ini.';
          });
        case CsvShareOutcome.empty:
          setState(() {
            _isRetrying = false;
            _error =
                'Rentang tanggal ini sudah tidak punya transaksi untuk '
                'diekspor.';
          });
      }
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isRetrying = false;
        _error = 'Ekspor ulang gagal. Coba lagi.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final job = widget.job;
    final textTheme = Theme.of(context).textTheme;
    final canShare = job.status == ExportJobStatus.completed;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AffluenaSpacing.space5,
          0,
          AffluenaSpacing.space5,
          AffluenaSpacing.space5,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Ekspor ${job.format.toUpperCase()}',
                      style: textTheme.titleLarge,
                    ),
                  ),
                  StatusBadge.forStatus(
                    job.status.name,
                    label: job.status.label,
                  ),
                ],
              ),
              const SizedBox(height: AffluenaSpacing.space4),
              _SheetDetailRow(row: _DetailRow('Baris', '${job.rowCount}')),
              const SizedBox(height: AffluenaSpacing.space3),
              _SheetDetailRow(
                row: _DetailRow(
                  'Dibuat',
                  AffluenaDateFormatter.shortDate(job.createdAt),
                ),
              ),
              if (job.fromAt != null) ...[
                const SizedBox(height: AffluenaSpacing.space3),
                _SheetDetailRow(
                  row: _DetailRow(
                    'Dari',
                    AffluenaDateFormatter.shortDate(job.fromAt!),
                  ),
                ),
              ],
              if (job.toAt != null) ...[
                const SizedBox(height: AffluenaSpacing.space3),
                _SheetDetailRow(
                  row: _DetailRow(
                    'Sampai',
                    AffluenaDateFormatter.shortDate(job.toAt!),
                  ),
                ),
              ],
              if (_error != null) ...[
                const SizedBox(height: AffluenaSpacing.space4),
                AffluenaBanner.error(_error!),
              ],
              const SizedBox(height: AffluenaSpacing.space5),
              if (canShare)
                FilledButton.icon(
                  onPressed: _isSharing ? null : _share,
                  icon: _isSharing
                      ? const SizedBox.square(
                          dimension: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.ios_share_outlined),
                  label: Text(_isSharing ? 'Menyiapkan' : 'Unduh / bagikan'),
                )
              else ...[
                AffluenaBanner(
                  message:
                      'Ekspor ini gagal dibuat, jadi tidak ada berkas yang bisa '
                      'diunduh.',
                  tone: AffluenaBannerTone.warning,
                ),
                const SizedBox(height: AffluenaSpacing.space3),
                FilledButton.icon(
                  key: const Key('export-job-retry-button'),
                  onPressed: _isRetrying ? null : _retry,
                  icon: _isRetrying
                      ? const SizedBox.square(
                          dimension: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.refresh),
                  label: Text(_isRetrying ? 'Mengulang ekspor' : 'Coba lagi'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _DetailRow {
  const _DetailRow(this.label, this.value, {this.isTechnical = false});

  final String label;
  final String value;
  final bool isTechnical;
}

class _SheetDetailRow extends StatelessWidget {
  const _SheetDetailRow({required this.row});

  final _DetailRow row;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colors = context.affluenaColors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          row.isTechnical ? '${row.label} (debug)' : row.label,
          style: textTheme.labelMedium?.copyWith(color: colors.inkMuted),
        ),
        const SizedBox(height: AffluenaSpacing.space1),
        if (row.isTechnical)
          // Technical IDs are opaque UUIDs the user may need elsewhere (bug
          // reports, support) — tap-to-copy beats screenshotting them.
          InkWell(
            onTap: () => copyTechnicalValue(context, row.label, row.value),
            borderRadius: BorderRadius.circular(AffluenaRadii.md),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Flexible(
                  child: Text(
                    row.value,
                    style: textTheme.bodySmall?.copyWith(
                      color: colors.inkMuted,
                      fontFamily: 'monospace',
                    ),
                  ),
                ),
                const SizedBox(width: AffluenaSpacing.space2),
                Icon(Icons.copy_outlined, size: 14, color: colors.inkMuted),
              ],
            ),
          )
        else
          Text(row.value, style: textTheme.bodyMedium),
      ],
    );
  }
}

Future<void> _showDetailSheet(
  BuildContext context, {
  required String title,
  required String subtitle,
  required List<_DetailRow> rows,
  String? body,
  Widget? badge,
}) {
  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (context) {
      final textTheme = Theme.of(context).textTheme;
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AffluenaSpacing.space5,
            0,
            AffluenaSpacing.space5,
            AffluenaSpacing.space5,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(child: Text(title, style: textTheme.titleLarge)),
                    if (badge != null) ...[
                      const SizedBox(width: AffluenaSpacing.space2),
                      badge,
                    ],
                  ],
                ),
                const SizedBox(height: AffluenaSpacing.space1),
                Text(subtitle, style: textTheme.bodySmall),
                if (body != null && body.isNotEmpty) ...[
                  const SizedBox(height: AffluenaSpacing.space4),
                  Text(body, style: textTheme.bodyLarge),
                ],
                const SizedBox(height: AffluenaSpacing.space4),
                for (final row in rows) ...[
                  _SheetDetailRow(row: row),
                  const SizedBox(height: AffluenaSpacing.space3),
                ],
              ],
            ),
          ),
        ),
      );
    },
  );
}
