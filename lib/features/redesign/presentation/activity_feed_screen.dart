import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/affluena_theme.dart';
import '../../../app/theme/sky_palette.dart';
import '../../../core/formatters/date_formatter.dart';
import '../../../core/formatters/money_formatter.dart';
import '../../auth/application/auth_controller.dart';
import '../../transactions/data/transaction_models.dart';
import '../../transactions/data/transaction_repository.dart';
import '../../wallets/application/wallets_controller.dart';
import '../../wallets/data/wallet_models.dart';

/// Recent transactions across ALL wallets, newest first. A standalone provider
/// so the redesign Activity never clobbers the legacy Transactions tab filter.
final recentActivityProvider = FutureProvider<List<Transaction>>((ref) async {
  final response = await ref.watch(transactionRepositoryProvider).listTransactions(
        limit: 100,
        offset: 0,
        sort: 'transaction_at_desc',
      );
  return response.transactions;
});

/// Redesign Tahap 5 — the cross-wallet merged Activity timeline: day-grouped,
/// each row showing the wallet, time, amount, and a "kamu" tag for the current
/// user's own entries (the couple-transparency signal). Additive route.
class ActivityFeedScreen extends ConsumerWidget {
  const ActivityFeedScreen({super.key});

  static const path = '/rooms-activity';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final txAsync = ref.watch(recentActivityProvider);
    final wallets =
        ref.watch(walletListProvider).asData?.value ?? const <Wallet>[];
    final walletNames = {for (final w in wallets) w.id: w.name};
    final meId = ref.watch(authControllerProvider).user?.id;

    return Scaffold(
      backgroundColor: SkyPalette.ground,
      body: SafeArea(
        child: ListView(
          padding: AffluenaInsets.screen,
          children: [
            Row(
              children: [
                _BackButton(onTap: () => context.pop()),
                const SizedBox(width: AffluenaSpacing.space3),
                const Text(
                  'Aktivitas',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: SkyPalette.ink,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AffluenaSpacing.space4),
            txAsync.when(
              loading: () => const Padding(
                padding: EdgeInsets.symmetric(vertical: AffluenaSpacing.space6),
                child: Center(
                  child: CircularProgressIndicator(color: SkyPalette.accent),
                ),
              ),
              error: (_, _) => const Text(
                'Tidak bisa memuat aktivitas.',
                style: TextStyle(fontSize: 13, color: SkyPalette.muted),
              ),
              data: (txns) => txns.isEmpty
                  ? const Text(
                      'Belum ada transaksi.',
                      style: TextStyle(fontSize: 13, color: SkyPalette.faint),
                    )
                  : _Feed(txns: txns, walletNames: walletNames, meId: meId),
            ),
          ],
        ),
      ),
    );
  }
}

class _Feed extends StatelessWidget {
  const _Feed({required this.txns, required this.walletNames, required this.meId});

  final List<Transaction> txns;
  final Map<String, String> walletNames;
  final String? meId;

  @override
  Widget build(BuildContext context) {
    final rows = <Widget>[];
    DateTime? currentDay;
    for (final tx in txns) {
      final day = AffluenaDateFormatter.localDay(tx.transactionAt);
      if (currentDay == null || day != currentDay) {
        currentDay = day;
        rows.add(
          Padding(
            padding: const EdgeInsets.only(
              top: AffluenaSpacing.space3,
              bottom: AffluenaSpacing.space2,
            ),
            child: Text(
              AffluenaDateFormatter.dayHeader(day),
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: SkyPalette.faint,
              ),
            ),
          ),
        );
      }
      rows.add(
        _ActivityRow(
          tx: tx,
          walletName: walletNames[tx.walletId] ?? 'Dompet',
          mine: meId != null && tx.userId == meId,
        ),
      );
    }
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: rows);
  }
}

class _ActivityRow extends StatelessWidget {
  const _ActivityRow({
    required this.tx,
    required this.walletName,
    required this.mine,
  });

  final Transaction tx;
  final String walletName;
  final bool mine;

  static String _typeLabel(TransactionType type) => switch (type) {
        TransactionType.income => 'Pemasukan',
        TransactionType.expense => 'Pengeluaran',
        TransactionType.transfer => 'Transfer',
        TransactionType.adjustment => 'Penyesuaian',
      };

  @override
  Widget build(BuildContext context) {
    final isIncome = tx.type == TransactionType.income;
    final title = tx.note.isNotEmpty ? tx.note : _typeLabel(tx.type);
    final sign = isIncome ? '+' : (tx.type == TransactionType.expense ? '-' : '');
    final amount = '$sign${MoneyFormatter.idr(tx.amountMinor.abs())}';
    final meta =
        '$walletName · ${AffluenaDateFormatter.time(tx.transactionAt)}${mine ? ' · kamu' : ''}';

    return Container(
      margin: const EdgeInsets.only(bottom: AffluenaSpacing.space2),
      padding: const EdgeInsets.symmetric(
        horizontal: AffluenaSpacing.space3,
        vertical: AffluenaSpacing.space3,
      ),
      decoration: BoxDecoration(
        color: SkyPalette.surface,
        borderRadius: BorderRadius.circular(AffluenaRadii.lg),
        border: Border.all(color: SkyPalette.line),
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: isIncome ? SkyPalette.accentSoft : SkyPalette.sheet,
              borderRadius: BorderRadius.circular(AffluenaRadii.md),
              border: Border.all(
                color: isIncome ? SkyPalette.accentSoftBorder : SkyPalette.line,
              ),
            ),
            child: Icon(
              isIncome ? Icons.south_west : Icons.north_east,
              size: 17,
              color: isIncome ? SkyPalette.accent : SkyPalette.muted,
            ),
          ),
          const SizedBox(width: AffluenaSpacing.space3),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: SkyPalette.ink,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  meta,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 11, color: SkyPalette.faint),
                ),
              ],
            ),
          ),
          const SizedBox(width: AffluenaSpacing.space2),
          Text(
            amount,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: isIncome ? SkyPalette.income : SkyPalette.ink,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }
}

class _BackButton extends StatelessWidget {
  const _BackButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(AffluenaRadii.md);
    return Material(
      color: SkyPalette.surface,
      borderRadius: radius,
      child: InkWell(
        borderRadius: radius,
        onTap: onTap,
        child: Container(
          width: 38,
          height: 38,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: radius,
            border: Border.all(color: SkyPalette.line),
          ),
          child: const Icon(Icons.arrow_back, size: 19, color: SkyPalette.ink),
        ),
      ),
    );
  }
}
