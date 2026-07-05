import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/affluena_theme.dart';
import '../../../app/theme/sky_palette.dart';
import '../../../core/formatters/date_formatter.dart';
import '../../../core/formatters/money_formatter.dart';
import '../../shared/presentation/appearance/item_appearance.dart';
import '../../shared/presentation/widgets/drill_in_scaffold.dart';
import '../../shared/presentation/widgets/sky_detail.dart';
import '../application/tracker_controller.dart';
import '../data/tracker_models.dart';

/// Per-subscription detail (Langganan) in the Sky & Denim language — opened from
/// a Beranda dashboard card. Reads the subscription from the already-loaded
/// [trackerControllerProvider]; pay / pause reuse the existing controller actions.
/// (The API has no payment-history endpoint, so the schedule shows the next few
/// *upcoming* bills computed from the billing cycle.)
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
    // The item's chosen colour accents the hero + active status pill;
    // paused/cancelled semantics stay untouched.
    final itemColor = parseItemColor(current.color);
    final accent = itemColor ?? context.sky.accent;
    final (statusLabel, statusColor) = _status(context, current.status, accent);
    final upcoming = current.status == SubscriptionStatus.active
        ? _upcomingBills(current)
        : const <DateTime>[];

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
            accent: itemColor,
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
                  final messenger = ScaffoldMessenger.of(context);
                  await controller.paySubscription(
                    current,
                    const TrackerPaymentRequest(),
                  );
                  _showActionError(ref, messenger);
                }
              },
              icon: const Icon(Icons.check_circle_outline),
              label: const Text('Bayar sekarang'),
            ),
          ],
          if (current.status == SubscriptionStatus.active) ...[
            const SizedBox(height: AffluenaSpacing.space3),
            OutlinedButton.icon(
              onPressed: () async {
                final messenger = ScaffoldMessenger.of(context);
                await controller.setSubscriptionStatus(
                  current,
                  SubscriptionStatus.paused,
                );
                _showActionError(ref, messenger);
              },
              icon: const Icon(Icons.pause_circle_outline),
              label: const Text('Jeda langganan'),
            ),
          ] else if (current.status == SubscriptionStatus.paused) ...[
            const SizedBox(height: AffluenaSpacing.space3),
            OutlinedButton.icon(
              onPressed: () async {
                final messenger = ScaffoldMessenger.of(context);
                await controller.setSubscriptionStatus(
                  current,
                  SubscriptionStatus.active,
                );
                _showActionError(ref, messenger);
              },
              icon: const Icon(Icons.play_circle_outline),
              label: const Text('Lanjutkan langganan'),
            ),
          ],
          if (upcoming.isNotEmpty) ...[
            const SizedBox(height: AffluenaSpacing.space6),
            Text(
              'Tagihan berikutnya',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: context.sky.ink,
              ),
            ),
            const SizedBox(height: AffluenaSpacing.space3),
            SkyDetailCard(
              child: Column(
                children: [
                  for (var i = 0; i < upcoming.length; i++) ...[
                    if (i > 0)
                      Divider(
                        height: AffluenaSpacing.space4,
                        color: context.sky.line,
                      ),
                    SkyDetailRow(
                      label: AffluenaDateFormatter.shortDate(
                        upcoming[i].toIso8601String(),
                      ),
                      value: MoneyFormatter.idr(current.amountMinor),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// Surfaces a swallowed save failure: [TrackerController]'s `_save` folds
  /// errors into `state.actionError` instead of throwing, and this screen has
  /// no inline banner — without a SnackBar the tapped action looks dead.
  void _showActionError(WidgetRef ref, ScaffoldMessengerState messenger) {
    final error = ref.read(trackerControllerProvider).actionError;
    if (error == null) return;
    messenger.showSnackBar(SnackBar(content: Text(error)));
  }

  List<DateTime> _upcomingBills(Subscription item, {int count = 4}) {
    final base = DateTime.tryParse(item.nextDueDate);
    if (base == null) return const [];
    final bills = <DateTime>[];
    var due = DateTime(base.year, base.month, base.day);
    for (var i = 0; i < count; i++) {
      bills.add(due);
      if (item.billingCycle == BillingCycle.weekly) {
        due = due.add(const Duration(days: 7));
      } else {
        final year = due.month == 12 ? due.year + 1 : due.year;
        final month = due.month == 12 ? 1 : due.month + 1;
        final lastDay = DateTime(year, month + 1, 0).day;
        due = DateTime(year, month, base.day.clamp(1, lastDay));
      }
    }
    return bills;
  }

  (String, Color) _status(
    BuildContext context,
    SubscriptionStatus status,
    Color accent,
  ) {
    return switch (status) {
      SubscriptionStatus.active => (status.label, accent),
      SubscriptionStatus.paused => (status.label, context.sky.muted),
      SubscriptionStatus.cancelled => (status.label, context.sky.faint),
    };
  }
}
