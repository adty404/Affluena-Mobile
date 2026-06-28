import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/affluena_theme.dart';
import '../../../core/formatters/money_formatter.dart';
import '../../shared/presentation/widgets/affluena_banner.dart';
import '../../shared/presentation/widgets/affluena_card.dart';
import '../../shared/presentation/widgets/affluena_skeleton.dart';
import '../../shared/presentation/widgets/metric_tile.dart';
import '../application/wallet_detail_controller.dart';
import '../data/wallet_models.dart';
import 'wallet_display.dart';

/// Self-contained monthly analytics card. Loads from its own provider so a slow
/// or failing analytics call only affects this card, and carries a month picker
/// that re-fetches just the analytics.
class WalletAnalyticsSection extends ConsumerWidget {
  const WalletAnalyticsSection({required this.walletId, super.key});

  final String walletId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final analytics = ref.watch(walletAnalyticsProvider(walletId));
    final month = ref.watch(walletAnalyticsMonthProvider(walletId));

    return Column(
      children: [
        _MonthStepper(
          month: month,
          onChanged: (value) => ref
              .read(walletAnalyticsMonthProvider(walletId).notifier)
              .select(value),
        ),
        const SizedBox(height: AffluenaSpacing.space3),
        analytics.when(
          skipLoadingOnReload: true,
          loading: () => const _AnalyticsLoading(),
          error: (error, stackTrace) => AffluenaCard(
            child: AffluenaBanner.error(
              'Analitik bulan ini tidak dapat dimuat.',
              onRetry: () => ref.invalidate(walletAnalyticsProvider(walletId)),
            ),
          ),
          data: (data) => _AnalyticsCard(analytics: data),
        ),
      ],
    );
  }
}

class _MonthStepper extends StatelessWidget {
  const _MonthStepper({required this.month, required this.onChanged});

  final DateTime month;
  final ValueChanged<DateTime> onChanged;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colors = context.affluenaColors;
    final now = DateTime.now();
    final atLatest = month.year == now.year && month.month == now.month;

    return AffluenaCard(
      padding: const EdgeInsets.symmetric(
        horizontal: AffluenaSpacing.space3,
        vertical: AffluenaSpacing.space2,
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: () => onChanged(DateTime(month.year, month.month - 1)),
            icon: const Icon(Icons.chevron_left),
            tooltip: 'Bulan sebelumnya',
          ),
          Expanded(
            child: Column(
              children: [
                Text('Bulan analitik', style: textTheme.labelMedium),
                const SizedBox(height: AffluenaSpacing.space1),
                Text(
                  walletMonthLabelFromDate(month),
                  style: textTheme.titleMedium,
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: atLatest
                ? null
                : () => onChanged(DateTime(month.year, month.month + 1)),
            icon: Icon(
              Icons.chevron_right,
              color: atLatest ? colors.inkMuted : null,
            ),
            tooltip: 'Bulan berikutnya',
          ),
        ],
      ),
    );
  }
}

class _AnalyticsCard extends StatelessWidget {
  const _AnalyticsCard({required this.analytics});

  final WalletAnalytics analytics;

  @override
  Widget build(BuildContext context) {
    final monthLabel = walletMonthLabel(analytics.month);
    final activity = walletActivityLabel(analytics.lastActivityAt);

    return AffluenaCard(
      child: Column(
        children: [
          Row(
            children: [
              MetricTile(
                label: 'Pemasukan',
                value: MoneyFormatter.idr(analytics.inflowMinor),
                helper: monthLabel,
                icon: Icons.south_west,
              ),
              const SizedBox(width: AffluenaSpacing.space3),
              MetricTile(
                label: 'Pengeluaran',
                value: MoneyFormatter.idr(analytics.outflowMinor),
                helper: monthLabel,
                icon: Icons.north_east,
              ),
            ],
          ),
          const SizedBox(height: AffluenaSpacing.space3),
          _DetailRow(
            icon: Icons.receipt_long_outlined,
            title: 'Transaksi',
            value: analytics.transactionCount == 1
                ? '1 transaksi'
                : '${analytics.transactionCount} transaksi',
          ),
          if (activity != null) ...[
            const Divider(height: 1),
            _DetailRow(
              icon: Icons.history,
              title: 'Aktivitas terakhir',
              value: activity,
            ),
          ],
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.icon,
    required this.title,
    required this.value,
  });

  final IconData icon;
  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colors = context.affluenaColors;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AffluenaSpacing.space3),
      child: Row(
        children: [
          Icon(icon, color: colors.forest),
          const SizedBox(width: AffluenaSpacing.space3),
          Expanded(child: Text(title, style: textTheme.bodyMedium)),
          Text(value, style: textTheme.bodyLarge),
        ],
      ),
    );
  }
}

class _AnalyticsLoading extends StatelessWidget {
  const _AnalyticsLoading();

  @override
  Widget build(BuildContext context) {
    return AffluenaCard(
      child: Column(
        children: const [
          Row(
            children: [
              Expanded(child: AffluenaSkeleton(height: 96, radius: 18)),
              SizedBox(width: AffluenaSpacing.space3),
              Expanded(child: AffluenaSkeleton(height: 96, radius: 18)),
            ],
          ),
          SizedBox(height: AffluenaSpacing.space4),
          AffluenaSkeleton.line(width: 180),
          SizedBox(height: AffluenaSpacing.space3),
          AffluenaSkeleton.line(width: 140),
        ],
      ),
    );
  }
}
