import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/affluena_theme.dart';
import '../../../core/formatters/date_formatter.dart';
import '../../../core/formatters/money_formatter.dart';
import '../../shared/presentation/widgets/affluena_card.dart';
import '../../shared/presentation/widgets/metric_tile.dart';
import '../../shared/presentation/widgets/section_header.dart';
import '../application/insights_controller.dart';
import '../data/insight_models.dart';

class InsightsScreen extends ConsumerWidget {
  const InsightsScreen({super.key});

  static const path = '/insights';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(insightsControllerProvider);
    final controller = ref.read(insightsControllerProvider.notifier);
    final textTheme = Theme.of(context).textTheme;

    if (state.isLoading && state.report.metrics.isEmpty) {
      return const _InsightsLoading();
    }

    if (state.loadError != null && state.report.metrics.isEmpty) {
      return _InsightsError(onRetry: controller.load);
    }

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(
          AffluenaSpacing.space5,
          AffluenaSpacing.space4,
          AffluenaSpacing.space5,
          AffluenaSpacing.space8,
        ),
        children: [
          Text('Insights', style: textTheme.headlineMedium),
          const SizedBox(height: AffluenaSpacing.space5),
          _InsightsSummaryCard(state: state),
          const SizedBox(height: AffluenaSpacing.space5),
          if (state.actionError != null) ...[
            _MessageCard(message: state.actionError!, isError: true),
            const SizedBox(height: AffluenaSpacing.space3),
          ],
          if (state.actionMessage != null) ...[
            _MessageCard(message: state.actionMessage!, isError: false),
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
                label: 'Report rows',
                value: state.report.rows.length.toString(),
                helper: state.reportKind.label,
                icon: Icons.analytics_outlined,
              ),
              const SizedBox(width: AffluenaSpacing.space3),
              MetricTile(
                label: 'Exports',
                value: state.completedExportCount.toString(),
                helper: 'Completed',
                icon: Icons.file_download_outlined,
              ),
            ],
          ),
          const SizedBox(height: AffluenaSpacing.space3),
          Row(
            children: [
              MetricTile(
                label: 'Alerts',
                value: state.warningAlertCount.toString(),
                helper: 'Needs review',
                icon: Icons.notifications_active_outlined,
              ),
              const SizedBox(width: AffluenaSpacing.space3),
              MetricTile(
                label: 'Rules',
                value: state.enabledRuleCount.toString(),
                helper: 'Enabled',
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
    return Wrap(
      spacing: AffluenaSpacing.space2,
      runSpacing: AffluenaSpacing.space2,
      children: [
        for (final tab in InsightTab.values)
          ChoiceChip(
            key: Key('insights-tab-${tab.name}'),
            showCheckmark: false,
            selected: selected == tab,
            label: Text(tab.label),
            onSelected: (_) => onChanged(tab),
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
        const SectionHeader(title: 'Reports'),
        const SizedBox(height: AffluenaSpacing.space3),
        Wrap(
          spacing: AffluenaSpacing.space2,
          runSpacing: AffluenaSpacing.space2,
          children: [
            for (final kind in ReportKind.values)
              ChoiceChip(
                showCheckmark: false,
                selected: state.reportKind == kind,
                label: Text(kind.label),
                onSelected: state.isReportLoading
                    ? null
                    : (_) => controller.setReportKind(kind),
              ),
          ],
        ),
        const SizedBox(height: AffluenaSpacing.space4),
        if (state.isReportLoading)
          const LinearProgressIndicator(minHeight: 2)
        else if (state.report.metrics.isEmpty && state.report.rows.isEmpty)
          const _EmptyState(
            icon: Icons.analytics_outlined,
            title: 'No report data yet',
            body: 'Reports will appear after financial activity is recorded.',
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
                      helper: metric.helper,
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
            title: '${state.reportKind.label} rows',
            actionLabel: '${state.report.rows.length} rows',
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
                'Transaction CSV',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: AffluenaSpacing.space2),
              Text(
                'Generate this month transaction export and refresh job history.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: AffluenaSpacing.space4),
              FilledButton.icon(
                key: const Key('insights-export-button'),
                onPressed: state.isSaving ? null : controller.exportCsv,
                icon: const Icon(Icons.file_download_outlined),
                label: Text(state.isSaving ? 'Generating' : 'Export CSV'),
              ),
            ],
          ),
        ),
        const SizedBox(height: AffluenaSpacing.space5),
        SectionHeader(
          title: 'Export jobs',
          actionLabel: state.exportJobTotal == 0
              ? null
              : '${state.exportJobTotal} total',
        ),
        const SizedBox(height: AffluenaSpacing.space3),
        if (state.exportJobs.isEmpty)
          const _EmptyState(
            icon: Icons.file_download_outlined,
            title: 'No export jobs',
            body: 'Generated CSV exports will be listed here.',
          )
        else
          for (final job in state.exportJobs) ...[
            _ExportJobCard(job: job),
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
        title: 'No alerts',
        body:
            'Budget and due alerts will appear here when attention is needed.',
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(title: 'Alerts', actionLabel: '${alerts.length} total'),
        const SizedBox(height: AffluenaSpacing.space3),
        for (final alert in alerts) ...[
          _AlertCard(
            alert: alert,
            onTap: () => _showDetailSheet(
              context,
              title: alert.title,
              subtitle: '${alert.module} · ${alert.severity.label}',
              body: alert.description,
              meta: alert.actionPath,
            ),
          ),
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
        title: 'No activity',
        body: 'Recent audit trail items will appear after account changes.',
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(title: 'Activity', actionLabel: '$total total'),
        const SizedBox(height: AffluenaSpacing.space3),
        for (final activity in activities) ...[
          _ActivityCard(
            activity: activity,
            onTap: () => _showDetailSheet(
              context,
              title: activity.description,
              subtitle: '${activity.actionType} · ${activity.entityType}',
              body: 'Entity: ${activity.entityType}',
              meta: AffluenaDateFormatter.shortDate(activity.createdAt),
            ),
          ),
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
        title: 'No notification rules',
        body: 'Notification preferences will appear when defaults are seeded.',
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(title: 'Notification rules'),
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
              _StatusBadge(
                label: row.status.label,
                color: _reportStatusColor(context, row.status),
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
            'Previous ${MoneyFormatter.idr(row.previousAmountMinor)} · ${row.changePercent.toStringAsFixed(1)}%',
            style: textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}

class _ExportJobCard extends StatelessWidget {
  const _ExportJobCard({required this.job});

  final ExportJob job;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return AffluenaCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text(job.format, style: textTheme.titleMedium)),
              _StatusBadge(
                label: job.status.label,
                color: job.status == ExportJobStatus.completed
                    ? context.affluenaColors.success
                    : context.affluenaColors.coral,
              ),
            ],
          ),
          const SizedBox(height: AffluenaSpacing.space2),
          Text('${job.rowCount} rows', style: textTheme.bodyLarge),
          const SizedBox(height: AffluenaSpacing.space1),
          Text(
            AffluenaDateFormatter.shortDate(job.createdAt),
            style: textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}

class _AlertCard extends StatelessWidget {
  const _AlertCard({required this.alert, required this.onTap});

  final InsightAlert alert;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return InkWell(
      borderRadius: BorderRadius.circular(24),
      onTap: onTap,
      child: AffluenaCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(alert.title, style: textTheme.titleMedium),
                ),
                _StatusBadge(
                  label: alert.severity.label,
                  color: _severityColor(context, alert.severity),
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
  const _ActivityCard({required this.activity, required this.onTap});

  final ActivityItem activity;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return InkWell(
      borderRadius: BorderRadius.circular(24),
      onTap: onTap,
      child: AffluenaCard(
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: context.affluenaColors.forestSoft,
              child: Icon(
                Icons.history_outlined,
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
                    '${activity.entityType} · ${AffluenaDateFormatter.shortDate(activity.createdAt)}',
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
              labelText: 'Channel',
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

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: color.withAlpha(32),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AffluenaSpacing.space3,
          vertical: AffluenaSpacing.space1,
        ),
        child: Text(
          label,
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
            color: color,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

class _MessageCard extends StatelessWidget {
  const _MessageCard({required this.message, required this.isError});

  final String message;
  final bool isError;

  @override
  Widget build(BuildContext context) {
    final colors = context.affluenaColors;
    return AffluenaCard(
      backgroundColor: isError ? colors.coral.withAlpha(28) : colors.forestSoft,
      borderColor: isError ? colors.coral : colors.borderSubtle,
      child: Text(message),
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
    return const SafeArea(
      child: Padding(
        padding: EdgeInsets.all(AffluenaSpacing.space5),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            LinearProgressIndicator(minHeight: 2),
            SizedBox(height: AffluenaSpacing.space5),
            _EmptyState(
              icon: Icons.analytics_outlined,
              title: 'Loading insights',
              body: 'Fetching reports, exports, alerts, activity, and rules.',
            ),
          ],
        ),
      ),
    );
  }
}

class _InsightsError extends StatelessWidget {
  const _InsightsError({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(AffluenaSpacing.space5),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const _EmptyState(
              icon: Icons.cloud_off_outlined,
              title: 'Insights unavailable',
              body: 'Check your connection and try loading insights again.',
            ),
            const SizedBox(height: AffluenaSpacing.space4),
            FilledButton(onPressed: onRetry, child: const Text('Retry')),
          ],
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

String _formatMetricValue(ReportMetric metric) {
  final label = metric.label.toLowerCase();
  final helper = metric.helper.toLowerCase();
  if (label.contains('rate') || helper.contains('%')) {
    return '${metric.valueMinor}%';
  }
  return MoneyFormatter.idr(metric.valueMinor);
}

Color _reportStatusColor(BuildContext context, ReportRowStatus status) {
  final colors = context.affluenaColors;
  return switch (status) {
    ReportRowStatus.healthy => colors.success,
    ReportRowStatus.watch => colors.amber,
    ReportRowStatus.critical => colors.coral,
    ReportRowStatus.growth => colors.forest,
  };
}

Color _severityColor(BuildContext context, InsightSeverity severity) {
  final colors = context.affluenaColors;
  return switch (severity) {
    InsightSeverity.info => colors.forest,
    InsightSeverity.success => colors.success,
    InsightSeverity.warning => colors.amber,
    InsightSeverity.danger => colors.coral,
  };
}

Future<void> _showDetailSheet(
  BuildContext context, {
  required String title,
  required String subtitle,
  required String body,
  required String meta,
}) {
  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
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
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(child: Text(title, style: textTheme.titleLarge)),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              Text(subtitle, style: textTheme.bodySmall),
              const SizedBox(height: AffluenaSpacing.space4),
              Text(body, style: textTheme.bodyLarge),
              const SizedBox(height: AffluenaSpacing.space4),
              Text(meta, style: textTheme.labelMedium),
            ],
          ),
        ),
      );
    },
  );
}
