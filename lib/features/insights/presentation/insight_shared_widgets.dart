import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/affluena_theme.dart';
import '../../../core/formatters/date_formatter.dart';
import '../../shared/presentation/widgets/affluena_banner.dart';
import '../../shared/presentation/widgets/affluena_card.dart';
import '../../shared/presentation/widgets/affluena_skeleton.dart';
import '../../shared/presentation/widgets/drill_in_scaffold.dart';
import '../../shared/presentation/widgets/status_badge.dart';
import '../data/insight_models.dart';
import '../data/insights_repository.dart';
import 'audit_log_screen.dart' show copyTechnicalValue;

/// Shared building blocks for the Laporan / Ekspor / Peringatan & Aktivitas /
/// Aturan notifikasi screens — the standalone screens that replaced the old
/// single chip-tabbed InsightsScreen. They all read the same
/// `insightsControllerProvider` state; only the surface split.

class InsightEmptyState extends StatelessWidget {
  const InsightEmptyState({
    required this.icon,
    required this.title,
    required this.body,
    super.key,
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

/// First-load skeleton shared by the insight screens (each keeps its own
/// DrillInScaffold title).
class InsightsLoadingScaffold extends StatelessWidget {
  const InsightsLoadingScaffold({required this.title, super.key});

  final String title;

  @override
  Widget build(BuildContext context) {
    return DrillInScaffold(
      title: title,
      body: ListView(
        padding: AffluenaInsets.screen,
        children: [
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
      ),
    );
  }
}

class InsightsErrorScaffold extends StatelessWidget {
  const InsightsErrorScaffold({
    required this.title,
    required this.message,
    required this.onRetry,
    super.key,
  });

  final String title;
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return DrillInScaffold(
      title: title,
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

StatusTone insightSeverityTone(InsightSeverity severity) {
  return switch (severity) {
    InsightSeverity.info => StatusTone.neutral,
    InsightSeverity.success => StatusTone.success,
    InsightSeverity.warning => StatusTone.warning,
    InsightSeverity.danger => StatusTone.danger,
  };
}

String humanizeInsightLabel(String value) {
  if (value.isEmpty) return value;
  return value
      .split(RegExp(r'[_\s]+'))
      .where((word) => word.isNotEmpty)
      .map((w) => '${w[0].toUpperCase()}${w.substring(1)}')
      .join(' ');
}

IconData insightActivityIcon(String actionType) {
  final normalized = actionType.toLowerCase();
  if (normalized.contains('create')) return Icons.add_circle_outline;
  if (normalized.contains('update') || normalized.contains('edit')) {
    return Icons.edit_outlined;
  }
  if (normalized.contains('delete')) return Icons.delete_outline;
  return Icons.history_outlined;
}

Future<void> openActivityDetailSheet(
  BuildContext context,
  ActivityItem activity,
) {
  return showInsightDetailSheet(
    context,
    title: activity.description,
    subtitle:
        '${humanizeInsightLabel(activity.actionType)} · ${humanizeInsightLabel(activity.entityType)}',
    rows: [
      InsightDetailRow('Aksi', humanizeInsightLabel(activity.actionType)),
      InsightDetailRow('Entitas', humanizeInsightLabel(activity.entityType)),
      InsightDetailRow(
        'Dicatat',
        AffluenaDateFormatter.shortDate(activity.createdAt),
      ),
      if (activity.entityId.isNotEmpty)
        InsightDetailRow('ID referensi', activity.entityId, isTechnical: true),
    ],
  );
}

Future<void> openAlertDetailSheet(
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
  await showInsightDetailSheet(
    context,
    title: detail.title,
    subtitle:
        '${humanizeInsightLabel(detail.module)} · ${detail.severity.label}',
    badge: StatusBadge(
      label: detail.severity.label,
      tone: insightSeverityTone(detail.severity),
    ),
    body: detail.description,
    rows: [
      InsightDetailRow('Jenis', humanizeInsightLabel(detail.type)),
      InsightDetailRow('Modul', humanizeInsightLabel(detail.module)),
      InsightDetailRow(
        'Dibuat',
        AffluenaDateFormatter.shortDate(detail.createdAt),
      ),
    ],
  );
}

class InsightDetailRow {
  const InsightDetailRow(this.label, this.value, {this.isTechnical = false});

  final String label;
  final String value;
  final bool isTechnical;
}

class InsightSheetDetailRow extends StatelessWidget {
  const InsightSheetDetailRow({required this.row, super.key});

  final InsightDetailRow row;

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

Future<void> showInsightDetailSheet(
  BuildContext context, {
  required String title,
  required String subtitle,
  required List<InsightDetailRow> rows,
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
                  InsightSheetDetailRow(row: row),
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
