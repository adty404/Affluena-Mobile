import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/affluena_theme.dart';
import '../../../app/theme/sky_palette.dart';
import '../../../core/formatters/date_formatter.dart';
import '../../../core/formatters/money_formatter.dart';
import '../../shared/presentation/appearance/item_appearance.dart';
import '../../shared/presentation/widgets/drill_in_scaffold.dart';
import '../../shared/presentation/widgets/sky_detail.dart';
import '../../shared/presentation/widgets/sky_progress_bar.dart';
import '../application/tracker_controller.dart';
import '../data/tracker_models.dart';

/// One month in the installment schedule. [kind]: 0 paid, 1 next-due, 2 upcoming.
typedef _ScheduleEntry = ({int number, DateTime due, int kind});

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
    // The item's chosen colour accents the hero + progress; status semantics
    // (paid off = income, cancelled = faint) stay untouched.
    final itemColor = parseItemColor(current.color);
    final accent = itemColor ?? context.sky.accent;
    final (statusLabel, statusColor) = _status(context, current.status, accent);
    final schedule = _buildSchedule(current);

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
            accent: itemColor,
          ),
          const SizedBox(height: AffluenaSpacing.space5),
          SkyProgressBar(
            value: current.paidPercent / 100,
            height: 8,
            fillColor: accent,
          ),
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
          if (current.canPay) ...[
            const SizedBox(height: AffluenaSpacing.space5),
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
          const SizedBox(height: AffluenaSpacing.space6),
          Row(
            children: [
              Text(
                'Jadwal',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: context.sky.ink,
                ),
              ),
              const Spacer(),
              Text(
                '${current.tenorMonths} bulan',
                style: TextStyle(fontSize: 12, color: context.sky.faint),
              ),
            ],
          ),
          const SizedBox(height: AffluenaSpacing.space3),
          SkyDetailCard(
            child: Column(
              children: [
                for (var i = 0; i < schedule.length; i++) ...[
                  if (i > 0)
                    Divider(
                      height: AffluenaSpacing.space4,
                      color: context.sky.line,
                    ),
                  _ScheduleRow(
                    entry: schedule[i],
                    amount: current.monthlyAmountMinor,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<_ScheduleEntry> _buildSchedule(Installment item) {
    final base = DateTime.tryParse(item.startDate) ?? DateTime.now();
    final paid = item.tenorMonths - item.remainingMonths;
    final entries = <_ScheduleEntry>[];
    for (var i = 0; i < item.tenorMonths; i++) {
      final year = base.year + ((base.month - 1 + i) ~/ 12);
      final month = ((base.month - 1 + i) % 12) + 1;
      final lastDay = DateTime(year, month + 1, 0).day;
      final day = item.dueDay.clamp(1, lastDay);
      final due = DateTime(year, month, day);
      final kind = i < paid
          ? 0
          : (i == paid && item.status == InstallmentStatus.active ? 1 : 2);
      entries.add((number: i + 1, due: due, kind: kind));
    }
    return entries;
  }

  (String, Color) _status(
    BuildContext context,
    InstallmentStatus status,
    Color accent,
  ) {
    return switch (status) {
      InstallmentStatus.active => (status.label, accent),
      InstallmentStatus.paidOff => (status.label, context.sky.income),
      InstallmentStatus.cancelled => (status.label, context.sky.faint),
    };
  }
}

class _ScheduleRow extends StatelessWidget {
  const _ScheduleRow({required this.entry, required this.amount});

  final _ScheduleEntry entry;
  final int amount;

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (entry.kind) {
      0 => ('Lunas', context.sky.income),
      1 => ('Berikutnya', context.sky.accent),
      _ => ('', context.sky.faint),
    };
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Bayar ke-${entry.number}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w600,
                  color: context.sky.ink,
                ),
              ),
              const SizedBox(height: 1),
              Text(
                AffluenaDateFormatter.shortDate(entry.due.toIso8601String()),
                style: TextStyle(fontSize: 11, color: context.sky.faint),
              ),
            ],
          ),
        ),
        if (label.isNotEmpty) ...[
          const SizedBox(width: AffluenaSpacing.space2),
          SkyStatusPill(label: label, color: color),
        ],
        const SizedBox(width: AffluenaSpacing.space2),
        Text(
          MoneyFormatter.idr(amount),
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: context.sky.ink,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
      ],
    );
  }
}
