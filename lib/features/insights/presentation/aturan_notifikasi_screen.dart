import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/affluena_theme.dart';
import '../../notifications/presentation/device_notifications_card.dart';
import '../../shared/presentation/widgets/affluena_banner.dart';
import '../../shared/presentation/widgets/affluena_card.dart';
import '../../shared/presentation/widgets/drill_in_scaffold.dart';
import '../../shared/presentation/widgets/section_header.dart';
import '../application/insights_controller.dart';
import '../data/insight_models.dart';
import 'insight_shared_widgets.dart';

/// Pengaturan → Aturan notifikasi — the per-rule enable/channel preferences
/// plus the device-notifications permission card, now a real standalone
/// screen (previously the "Aturan" chip inside the old InsightsScreen).
class AturanNotifikasiScreen extends ConsumerWidget {
  const AturanNotifikasiScreen({super.key});

  static const path = '/aturan-notifikasi';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(insightsControllerProvider);
    final controller = ref.read(insightsControllerProvider.notifier);

    if (state.isLoading && state.rules.isEmpty) {
      return const InsightsLoadingScaffold(title: 'Aturan notifikasi');
    }

    if (state.loadError != null && state.rules.isEmpty) {
      return InsightsErrorScaffold(
        title: 'Aturan notifikasi',
        message: state.loadError!,
        onRetry: controller.load,
      );
    }

    return DrillInScaffold(
      title: 'Aturan notifikasi',
      body: ListView(
        padding: AffluenaInsets.screen,
        children: [
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
          // Android permission row for the local due reminders (renders
          // nothing on unsupported platforms). The reminders themselves are
          // gated by the same rules listed below — see NotificationScheduler.
          const DeviceNotificationsCard(),
          const SizedBox(height: AffluenaSpacing.space3),
          if (state.rules.isEmpty)
            const InsightEmptyState(
              icon: Icons.tune_outlined,
              title: 'Belum ada aturan notifikasi',
              body:
                  'Preferensi notifikasi akan muncul saat nilai bawaan dibuat.',
            )
          else ...[
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
        ],
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
