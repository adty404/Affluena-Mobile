import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/affluena_theme.dart';
import '../../../core/formatters/date_formatter.dart';
import '../../shared/presentation/widgets/affluena_banner.dart';
import '../../shared/presentation/widgets/affluena_card.dart';
import '../../shared/presentation/widgets/affluena_skeleton.dart';
import '../../shared/presentation/widgets/metric_tile.dart';
import '../../shared/presentation/widgets/section_header.dart';
import '../../shared/presentation/widgets/status_badge.dart';
import '../application/audit_log_controller.dart';
import '../data/insight_models.dart';
import '../data/insights_repository.dart';

class AuditLogScreen extends ConsumerStatefulWidget {
  const AuditLogScreen({super.key});

  static const path = '/audit-logs';

  @override
  ConsumerState<AuditLogScreen> createState() => _AuditLogScreenState();
}

class _AuditLogScreenState extends ConsumerState<AuditLogScreen> {
  String? _detailError;

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(auditLogControllerProvider);
    final controller = ref.read(auditLogControllerProvider.notifier);
    final textTheme = Theme.of(context).textTheme;

    if (state.isLoading &&
        state.activities.isEmpty &&
        state.systemLogs.isEmpty) {
      return const _AuditLogLoading();
    }

    if (state.loadError != null &&
        state.activities.isEmpty &&
        state.systemLogs.isEmpty) {
      return _AuditLogError(message: state.loadError!, onRetry: controller.load);
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
          Text('Audit logs', style: textTheme.headlineMedium),
          const SizedBox(height: AffluenaSpacing.space5),
          _AuditSummaryCard(state: state),
          if (_detailError != null) ...[
            const SizedBox(height: AffluenaSpacing.space3),
            AffluenaBanner(
              message: _detailError!,
              onDismiss: () => setState(() => _detailError = null),
            ),
          ],
          const SizedBox(height: AffluenaSpacing.space5),
          _AuditLogTabs(
            selected: state.selectedTab,
            onChanged: controller.setTab,
          ),
          const SizedBox(height: AffluenaSpacing.space5),
          switch (state.selectedTab) {
            AuditLogTab.activity => _ActivityLogSection(
              activities: state.activities,
              total: state.activityTotal,
              onOpen: _openActivityDetail,
            ),
            AuditLogTab.system => _SystemLogSection(
              logs: state.systemLogs,
              onOpen: _openSystemLogDetail,
            ),
          },
        ],
      ),
    );
  }

  Future<void> _openActivityDetail(ActivityItem activity) async {
    setState(() => _detailError = null);
    try {
      final detail = await ref
          .read(insightsRepositoryProvider)
          .getActivity(activity.id);
      if (!mounted) return;
      await _showActivityDetailSheet(context, detail);
    } catch (_) {
      if (!mounted) return;
      setState(() => _detailError = 'Activity detail could not be loaded.');
    }
  }

  Future<void> _openSystemLogDetail(SystemLog log) async {
    setState(() => _detailError = null);
    try {
      final detail = await ref
          .read(insightsRepositoryProvider)
          .getSystemLog(log.id);
      if (!mounted) return;
      await _showSystemLogDetailSheet(context, detail);
    } catch (_) {
      if (!mounted) return;
      setState(() => _detailError = 'System log detail could not be loaded.');
    }
  }
}

class _AuditSummaryCard extends StatelessWidget {
  const _AuditSummaryCard({required this.state});

  final AuditLogState state;

  @override
  Widget build(BuildContext context) {
    return AffluenaCard(
      child: Row(
        children: [
          MetricTile(
            label: 'Activity',
            value: _activityCountLabel(state.activityTotal),
            helper: 'User actions',
            icon: Icons.history_outlined,
          ),
          const SizedBox(width: AffluenaSpacing.space3),
          MetricTile(
            label: 'System',
            value: _systemLogCountLabel(state.systemLogTotal),
            helper: 'API requests',
            icon: Icons.http_outlined,
          ),
        ],
      ),
    );
  }
}

class _AuditLogTabs extends StatelessWidget {
  const _AuditLogTabs({required this.selected, required this.onChanged});

  final AuditLogTab selected;
  final ValueChanged<AuditLogTab> onChanged;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AffluenaSpacing.space2,
      runSpacing: AffluenaSpacing.space2,
      children: [
        ChoiceChip(
          key: const Key('audit-log-tab-activity'),
          showCheckmark: false,
          selected: selected == AuditLogTab.activity,
          label: const Text('Activity'),
          onSelected: (_) => onChanged(AuditLogTab.activity),
        ),
        ChoiceChip(
          key: const Key('audit-log-tab-system'),
          showCheckmark: false,
          selected: selected == AuditLogTab.system,
          label: const Text('System logs'),
          onSelected: (_) => onChanged(AuditLogTab.system),
        ),
      ],
    );
  }
}

class _ActivityLogSection extends StatelessWidget {
  const _ActivityLogSection({
    required this.activities,
    required this.total,
    required this.onOpen,
  });

  final List<ActivityItem> activities;
  final int total;
  final ValueChanged<ActivityItem> onOpen;

  @override
  Widget build(BuildContext context) {
    if (activities.isEmpty) {
      return const _EmptyState(
        icon: Icons.history_outlined,
        title: 'No activity',
        body: 'Account activity will appear after you change financial data.',
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(title: 'Activity', actionLabel: '$total total'),
        const SizedBox(height: AffluenaSpacing.space3),
        for (final activity in activities) ...[
          _ActivityLogCard(activity: activity, onTap: () => onOpen(activity)),
          const SizedBox(height: AffluenaSpacing.space3),
        ],
      ],
    );
  }
}

class _SystemLogSection extends StatelessWidget {
  const _SystemLogSection({required this.logs, required this.onOpen});

  final List<SystemLog> logs;
  final ValueChanged<SystemLog> onOpen;

  @override
  Widget build(BuildContext context) {
    if (logs.isEmpty) {
      return const _EmptyState(
        icon: Icons.http_outlined,
        title: 'No system logs',
        body: 'Recent authenticated API requests will appear here.',
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(
          title: 'System logs',
          actionLabel: '${logs.length} recent',
        ),
        const SizedBox(height: AffluenaSpacing.space3),
        for (final log in logs) ...[
          _SystemLogCard(log: log, onTap: () => onOpen(log)),
          const SizedBox(height: AffluenaSpacing.space3),
        ],
      ],
    );
  }
}

class _ActivityLogCard extends StatelessWidget {
  const _ActivityLogCard({required this.activity, required this.onTap});

  final ActivityItem activity;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return InkWell(
      borderRadius: BorderRadius.circular(AffluenaRadii.card),
      onTap: onTap,
      child: AffluenaCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    activity.description,
                    style: textTheme.titleMedium,
                  ),
                ),
                StatusBadge.forStatus(
                  activity.actionType,
                  label: _humanize(activity.actionType),
                ),
              ],
            ),
            const SizedBox(height: AffluenaSpacing.space2),
            Text(
              '${_humanize(activity.actionType)} · ${_humanize(activity.entityType)}',
              style: textTheme.bodySmall,
            ),
            const SizedBox(height: AffluenaSpacing.space1),
            Text(
              AffluenaDateFormatter.shortDate(activity.createdAt),
              style: textTheme.labelMedium,
            ),
          ],
        ),
      ),
    );
  }
}

class _SystemLogCard extends StatelessWidget {
  const _SystemLogCard({required this.log, required this.onTap});

  final SystemLog log;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return InkWell(
      borderRadius: BorderRadius.circular(AffluenaRadii.card),
      onTap: onTap,
      child: AffluenaCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    '${log.method} ${log.path}',
                    style: textTheme.titleMedium,
                  ),
                ),
                StatusBadge(
                  label: log.statusCode.toString(),
                  tone: _statusCodeTone(log.statusCode),
                ),
              ],
            ),
            const SizedBox(height: AffluenaSpacing.space2),
            Text(
              '${log.statusCode} · ${log.latencyMs} ms',
              style: textTheme.bodyLarge,
            ),
            const SizedBox(height: AffluenaSpacing.space1),
            Text(log.userAgent, style: textTheme.bodySmall),
          ],
        ),
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

class _AuditLogLoading extends StatelessWidget {
  const _AuditLogLoading();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(
          AffluenaSpacing.space5,
          AffluenaSpacing.space4,
          AffluenaSpacing.space5,
          AffluenaSpacing.space8,
        ),
        children: [
          Text(
            'Audit logs',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: AffluenaSpacing.space5),
          const AffluenaCard(
            child: Row(
              children: [
                Expanded(child: AffluenaSkeleton(height: 72, radius: 18)),
                SizedBox(width: AffluenaSpacing.space3),
                Expanded(child: AffluenaSkeleton(height: 72, radius: 18)),
              ],
            ),
          ),
          const SizedBox(height: AffluenaSpacing.space5),
          const Wrap(
            spacing: AffluenaSpacing.space2,
            children: [
              AffluenaSkeleton(width: 84, height: 32, radius: AffluenaRadii.pill),
              AffluenaSkeleton(
                width: 104,
                height: 32,
                radius: AffluenaRadii.pill,
              ),
            ],
          ),
          const SizedBox(height: AffluenaSpacing.space5),
          for (var i = 0; i < 4; i++) ...[
            AffluenaCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  AffluenaSkeleton.line(width: 180, height: 16),
                  SizedBox(height: AffluenaSpacing.space3),
                  AffluenaSkeleton.line(width: 140),
                  SizedBox(height: AffluenaSpacing.space2),
                  AffluenaSkeleton.line(width: 100),
                ],
              ),
            ),
            const SizedBox(height: AffluenaSpacing.space3),
          ],
        ],
      ),
    );
  }
}

class _AuditLogError extends StatelessWidget {
  const _AuditLogError({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(AffluenaSpacing.space5),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Audit logs',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: AffluenaSpacing.space5),
            AffluenaBanner.error(message),
            const SizedBox(height: AffluenaSpacing.space4),
            FilledButton(
              key: const Key('audit-log-retry-button'),
              onPressed: onRetry,
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}

/// Title-cases a snake_case / lowercase backend token for display.
String _humanize(String value) {
  if (value.isEmpty) return value;
  return value
      .split(RegExp(r'[_\s]+'))
      .where((word) => word.isNotEmpty)
      .map((w) => '${w[0].toUpperCase()}${w.substring(1)}')
      .join(' ');
}

StatusTone _statusCodeTone(int statusCode) {
  if (statusCode >= 500) return StatusTone.danger;
  if (statusCode >= 400) return StatusTone.warning;
  if (statusCode >= 200 && statusCode < 300) return StatusTone.success;
  return StatusTone.neutral;
}

Future<void> _showActivityDetailSheet(
  BuildContext context,
  ActivityItem activity,
) {
  return _showAuditDetailSheet(
    context,
    title: activity.description,
    subtitle:
        '${_humanize(activity.actionType)} · ${_humanize(activity.entityType)}',
    rows: [
      _DetailRowData('Action', _humanize(activity.actionType)),
      _DetailRowData('Entity', _humanize(activity.entityType)),
      _DetailRowData(
        'Recorded',
        AffluenaDateFormatter.shortDate(activity.createdAt),
      ),
      // The audit API exposes only the raw entity UUID (no human-readable
      // name), so it is surfaced as a de-emphasised technical reference.
      if (activity.entityId.isNotEmpty)
        _DetailRowData(
          'Reference ID',
          activity.entityId,
          isTechnical: true,
        ),
    ],
  );
}

Future<void> _showSystemLogDetailSheet(BuildContext context, SystemLog log) {
  return _showAuditDetailSheet(
    context,
    title: '${log.method} ${log.path}',
    subtitle: '${log.statusCode} · ${log.latencyMs} ms',
    rows: [
      _DetailRowData('Client IP', log.clientIp),
      _DetailRowData('User agent', log.userAgent),
      if (log.requestPayload != null && log.requestPayload!.isNotEmpty)
        _DetailRowData(
          'Request payload',
          log.requestPayload!,
          isTechnical: true,
        ),
      if (log.responsePayload != null && log.responsePayload!.isNotEmpty)
        _DetailRowData(
          'Response payload',
          log.responsePayload!,
          isTechnical: true,
        ),
      _DetailRowData('Created', AffluenaDateFormatter.shortDate(log.createdAt)),
    ],
  );
}

Future<void> _showAuditDetailSheet(
  BuildContext context, {
  required String title,
  required String subtitle,
  required List<_DetailRowData> rows,
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
          child: SingleChildScrollView(
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
                Text(subtitle, style: textTheme.bodyMedium),
                const SizedBox(height: AffluenaSpacing.space4),
                for (final row in rows) ...[
                  _DetailRow(row: row),
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

class _DetailRowData {
  const _DetailRowData(this.label, this.value, {this.isTechnical = false});

  final String label;
  final String value;

  /// When true the row is rendered de-emphasised (muted, monospace) and the
  /// label is suffixed with "(debug)" to signal it is a raw technical value.
  final bool isTechnical;
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.row});

  final _DetailRowData row;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colors = context.affluenaColors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          row.isTechnical ? '${row.label} (debug)' : row.label,
          style: textTheme.labelMedium?.copyWith(
            color: row.isTechnical ? colors.inkMuted : null,
          ),
        ),
        const SizedBox(height: AffluenaSpacing.space1),
        Text(
          row.value,
          style: row.isTechnical
              ? textTheme.bodySmall?.copyWith(
                  color: colors.inkMuted,
                  fontFamily: 'monospace',
                )
              : textTheme.bodyMedium,
        ),
      ],
    );
  }
}

String _activityCountLabel(int count) {
  return count == 1 ? '1 activity' : '$count activities';
}

String _systemLogCountLabel(int count) {
  return count == 1 ? '1 system request' : '$count system requests';
}
