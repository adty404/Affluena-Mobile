import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/affluena_theme.dart';
import '../../../app/theme/sky_palette.dart';
import '../../../core/formatters/date_formatter.dart';
import '../../../core/formatters/money_formatter.dart';
import '../../shared/presentation/widgets/drill_in_scaffold.dart';
import '../../shared/presentation/widgets/sky_detail.dart';
import '../application/tracker_controller.dart';
import '../data/tracker_models.dart';

/// Per-subscription detail (Langganan) in the Sky & Denim language — opened from
/// a Beranda dashboard card. Reads the subscription from the already-loaded
/// [trackerControllerProvider]; pay / pause reuse the existing controller actions.
class SubscriptionDetailScreen extends ConsumerWidget {
  const SubscriptionDetailScreen({required this.id, super.key});

  final String id;

  static const path = '/trackers/subscription/:id';
  static String location(String id) => '/trackers/subscription/$id';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(trackerControllerProvider);
    Subscription? item;
    for (final s in state.subscriptions) {
      if (s.id == id) {
        item = s;
        break;
      }
    }

    if (item == null) {
      return DrillInScaffold(
        title: 'Langganan',
        body: SkyDetailPlaceholder(
          loading: state.isLoading,
          message: 'Langganan tidak ditemukan.',
        ),
      );
    }

    final current = item;
    final controller = ref.read(trackerControllerProvider.notifier);
    final (statusLabel, statusColor) = _status(context, current.status);

    return DrillInScaffold(
      title: current.name,
      body: ListView(
        padding: AffluenaInsets.screen,
        children: [
          SkyDetailHero(
            label: 'Biaya langganan',
            amount: MoneyFormatter.idr(current.amountMinor),
            sub:
                '${current.billingCycle.label} · tagih berikutnya ${AffluenaDateFormatter.shortDate(current.nextDueDate)}',
          ),
          const SizedBox(height: AffluenaSpacing.space4),
          Align(
            alignment: Alignment.centerLeft,
            child: SkyStatusPill(label: statusLabel, color: statusColor),
          ),
          if (current.canPay) ...[
            const SizedBox(height: AffluenaSpacing.space6),
            FilledButton.icon(
              onPressed: () async {
                final ok = await skyConfirm(
                  context,
                  title: 'Bayar langganan',
                  message:
                      'Catat pembayaran ${MoneyFormatter.idr(current.amountMinor)} untuk ${current.name}?',
                  confirmLabel: 'Bayar',
                );
                if (ok && context.mounted) {
                  await controller.paySubscription(
                    current,
                    const TrackerPaymentRequest(),
                  );
                }
              },
              icon: const Icon(Icons.check_circle_outline),
              label: const Text('Bayar sekarang'),
            ),
          ],
          if (current.status == SubscriptionStatus.active) ...[
            const SizedBox(height: AffluenaSpacing.space3),
            OutlinedButton.icon(
              onPressed: () => controller.setSubscriptionStatus(
                current,
                SubscriptionStatus.paused,
              ),
              icon: const Icon(Icons.pause_circle_outline),
              label: const Text('Jeda langganan'),
            ),
          ] else if (current.status == SubscriptionStatus.paused) ...[
            const SizedBox(height: AffluenaSpacing.space3),
            OutlinedButton.icon(
              onPressed: () => controller.setSubscriptionStatus(
                current,
                SubscriptionStatus.active,
              ),
              icon: const Icon(Icons.play_circle_outline),
              label: const Text('Lanjutkan langganan'),
            ),
          ],
        ],
      ),
    );
  }

  (String, Color) _status(BuildContext context, SubscriptionStatus status) {
    return switch (status) {
      SubscriptionStatus.active => (status.label, context.sky.accent),
      SubscriptionStatus.paused => (status.label, context.sky.muted),
      SubscriptionStatus.cancelled => (status.label, context.sky.faint),
    };
  }
}
