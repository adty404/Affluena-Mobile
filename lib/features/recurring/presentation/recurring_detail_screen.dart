import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/affluena_theme.dart';
import '../../../app/theme/sky_palette.dart';
import '../../../core/formatters/date_formatter.dart';
import '../../../core/formatters/money_formatter.dart';
import '../../shared/presentation/widgets/drill_in_scaffold.dart';
import '../../shared/presentation/widgets/sky_detail.dart';
import '../application/recurring_controller.dart';
import '../data/recurring_models.dart';

/// Per-rule detail (Berulang) in the Sky & Denim language — opened from a
/// Beranda dashboard card. Reads the rule from the already-loaded
/// [recurringControllerProvider]; "Jalankan sekarang" reuses [RecurringController.runRule].
class RecurringDetailScreen extends ConsumerWidget {
  const RecurringDetailScreen({required this.id, super.key});

  final String id;

  static const path = '/recurring/:id';
  static String location(String id) => '/recurring/$id';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(recurringControllerProvider);
    RecurringRule? rule;
    for (final r in state.rules) {
      if (r.id == id) {
        rule = r;
        break;
      }
    }

    if (rule == null) {
      return DrillInScaffold(
        title: 'Berulang',
        body: SkyDetailPlaceholder(
          loading: state.isLoading,
          message: 'Transaksi berulang tidak ditemukan.',
        ),
      );
    }

    final current = rule;
    final income = current.type == RecurringType.income;
    final (statusLabel, statusColor) = _status(context, current.status);

    return DrillInScaffold(
      title: current.name,
      body: ListView(
        padding: AffluenaInsets.screen,
        children: [
          SkyDetailHero(
            label: current.type.label,
            amount: MoneyFormatter.idr(current.amountMinor),
            sub:
                '${current.frequency.label} · berikutnya ${AffluenaDateFormatter.shortDate(current.nextRunAt)}',
            amountColor: income ? context.sky.income : null,
          ),
          const SizedBox(height: AffluenaSpacing.space4),
          Align(
            alignment: Alignment.centerLeft,
            child: SkyStatusPill(label: statusLabel, color: statusColor),
          ),
          if (current.canRun) ...[
            const SizedBox(height: AffluenaSpacing.space6),
            FilledButton.icon(
              onPressed: () async {
                final ok = await skyConfirm(
                  context,
                  title: 'Jalankan sekarang',
                  message:
                      'Catat ${current.type.label.toLowerCase()} ${MoneyFormatter.idr(current.amountMinor)} untuk ${current.name} sekarang?',
                  confirmLabel: 'Jalankan',
                );
                if (ok && context.mounted) {
                  await ref
                      .read(recurringControllerProvider.notifier)
                      .runRule(current);
                }
              },
              icon: const Icon(Icons.play_arrow_outlined),
              label: const Text('Jalankan sekarang'),
            ),
          ],
        ],
      ),
    );
  }

  (String, Color) _status(BuildContext context, RecurringStatus status) {
    return switch (status) {
      RecurringStatus.active => (status.label, context.sky.accent),
      RecurringStatus.paused => (status.label, context.sky.muted),
      RecurringStatus.cancelled => (status.label, context.sky.faint),
    };
  }
}
