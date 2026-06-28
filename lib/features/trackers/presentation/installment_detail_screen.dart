import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/affluena_theme.dart';
import '../../../app/theme/sky_palette.dart';
import '../../../core/formatters/date_formatter.dart';
import '../../../core/formatters/money_formatter.dart';
import '../../shared/presentation/widgets/drill_in_scaffold.dart';
import '../../shared/presentation/widgets/sky_detail.dart';
import '../../shared/presentation/widgets/sky_progress_bar.dart';
import '../application/tracker_controller.dart';
import '../data/tracker_models.dart';

/// Per-installment detail (Cicilan) in the Sky & Denim language — opened from a
/// Beranda dashboard card. Reads the installment from the already-loaded
/// [trackerControllerProvider]; "Bayar cicilan" reuses [TrackerController.payInstallment].
class InstallmentDetailScreen extends ConsumerWidget {
  const InstallmentDetailScreen({required this.id, super.key});

  final String id;

  static const path = '/trackers/installment/:id';
  static String location(String id) => '/trackers/installment/$id';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(trackerControllerProvider);
    Installment? item;
    for (final i in state.installments) {
      if (i.id == id) {
        item = i;
        break;
      }
    }

    if (item == null) {
      return DrillInScaffold(
        title: 'Cicilan',
        body: SkyDetailPlaceholder(
          loading: state.isLoading,
          message: 'Cicilan tidak ditemukan.',
        ),
      );
    }

    final current = item;
    final paid = current.tenorMonths - current.remainingMonths;
    final remainingMinor = current.remainingMonths * current.monthlyAmountMinor;
    final (statusLabel, statusColor) = _status(context, current.status);

    return DrillInScaffold(
      title: current.name,
      body: ListView(
        padding: AffluenaInsets.screen,
        children: [
          SkyDetailHero(
            label: 'Cicilan per bulan',
            amount: '${MoneyFormatter.idr(current.monthlyAmountMinor)}/bln',
            sub:
                'Cicilan $paid dari ${current.tenorMonths} · sisa ${MoneyFormatter.idr(remainingMinor)}',
          ),
          const SizedBox(height: AffluenaSpacing.space5),
          SkyProgressBar(value: current.paidPercent / 100, height: 8),
          const SizedBox(height: AffluenaSpacing.space3),
          Row(
            children: [
              Text(
                'Terbayar ${current.paidPercent.round()}%',
                style: TextStyle(fontSize: 13, color: context.sky.muted),
              ),
              const Spacer(),
              SkyStatusPill(label: statusLabel, color: statusColor),
            ],
          ),
          const SizedBox(height: AffluenaSpacing.space5),
          SkyDetailCard(
            child: Column(
              children: [
                SkyDetailRow(
                  label: 'Jatuh tempo tiap',
                  value: 'Tanggal ${current.dueDay}',
                ),
                const SizedBox(height: AffluenaSpacing.space3),
                SkyDetailRow(
                  label: 'Sisa cicilan',
                  value: '${current.remainingMonths} bulan',
                ),
                const SizedBox(height: AffluenaSpacing.space3),
                SkyDetailRow(
                  label: 'Mulai',
                  value: AffluenaDateFormatter.shortDate(current.startDate),
                ),
              ],
            ),
          ),
          if (current.canPay) ...[
            const SizedBox(height: AffluenaSpacing.space6),
            FilledButton.icon(
              onPressed: () async {
                final ok = await skyConfirm(
                  context,
                  title: 'Bayar cicilan',
                  message:
                      'Catat pembayaran ${MoneyFormatter.idr(current.monthlyAmountMinor)} untuk ${current.name}?',
                  confirmLabel: 'Bayar',
                );
                if (ok && context.mounted) {
                  await ref
                      .read(trackerControllerProvider.notifier)
                      .payInstallment(current, const TrackerPaymentRequest());
                }
              },
              icon: const Icon(Icons.check_circle_outline),
              label: const Text('Bayar cicilan'),
            ),
          ],
        ],
      ),
    );
  }

  (String, Color) _status(BuildContext context, InstallmentStatus status) {
    return switch (status) {
      InstallmentStatus.active => (status.label, context.sky.accent),
      InstallmentStatus.paidOff => (status.label, context.sky.income),
      InstallmentStatus.cancelled => (status.label, context.sky.faint),
    };
  }
}
