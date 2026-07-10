import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/affluena_theme.dart';
import '../../../core/formatters/date_formatter.dart';
import '../../shared/presentation/widgets/affluena_card.dart';
import '../../shared/presentation/widgets/drill_in_scaffold.dart';
import '../../shared/presentation/widgets/section_header.dart';
import '../../shared/presentation/widgets/status_badge.dart';
import '../application/insights_controller.dart';
import '../data/insight_models.dart';
import 'insight_shared_widgets.dart';

/// Pengaturan → Peringatan & Aktivitas — budget/due alerts over the account's
/// audit-trail feed, now a real standalone screen. The two lists stay together
/// (they shared one Pengaturan entry) but as stacked sections on one scroll —
/// no cross-section chip bar.
class PeringatanAktivitasScreen extends ConsumerWidget {
  const PeringatanAktivitasScreen({super.key});

  static const path = '/peringatan-aktivitas';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(insightsControllerProvider);
    final controller = ref.read(insightsControllerProvider.notifier);
    final empty = state.alerts.isEmpty && state.activities.isEmpty;

    if (state.isLoading && empty) {
      return const InsightsLoadingScaffold(title: 'Peringatan & Aktivitas');
    }

    if (state.loadError != null && empty) {
      return InsightsErrorScaffold(
        title: 'Peringatan & Aktivitas',
        message: state.loadError!,
        onRetry: controller.load,
      );
    }

    return DrillInScaffold(
      title: 'Peringatan & Aktivitas',
      body: ListView(
        padding: AffluenaInsets.screen,
        children: [
          SectionHeader(
            title: 'Peringatan',
            actionLabel: state.alerts.isEmpty
                ? null
                : '${state.alerts.length} total',
          ),
          const SizedBox(height: AffluenaSpacing.space3),
          if (state.alerts.isEmpty)
            const InsightEmptyState(
              icon: Icons.notifications_none_outlined,
              title: 'Belum ada peringatan',
              body:
                  'Peringatan anggaran dan jatuh tempo akan muncul di sini saat perlu diperhatikan.',
            )
          else
            for (final alert in state.alerts) ...[
              _AlertCard(alert: alert),
              const SizedBox(height: AffluenaSpacing.space3),
            ],
          const SizedBox(height: AffluenaSpacing.space5),
          SectionHeader(
            title: 'Aktivitas',
            actionLabel: state.activityTotal == 0
                ? null
                : '${state.activityTotal} total',
          ),
          const SizedBox(height: AffluenaSpacing.space3),
          if (state.activities.isEmpty)
            const InsightEmptyState(
              icon: Icons.history_outlined,
              title: 'Belum ada aktivitas',
              body:
                  'Catatan jejak audit terbaru akan muncul setelah ada perubahan akun.',
            )
          else
            for (final activity in state.activities) ...[
              _ActivityCard(activity: activity),
              const SizedBox(height: AffluenaSpacing.space3),
            ],
        ],
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
      onTap: () => openAlertDetailSheet(context, ref, alert),
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
                  tone: insightSeverityTone(alert.severity),
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
      onTap: () => openActivityDetailSheet(context, activity),
      child: AffluenaCard(
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: context.affluenaColors.forestSoft,
              child: Icon(
                insightActivityIcon(activity.actionType),
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
                    '${humanizeInsightLabel(activity.entityType)} · ${AffluenaDateFormatter.shortDate(activity.createdAt)}',
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
