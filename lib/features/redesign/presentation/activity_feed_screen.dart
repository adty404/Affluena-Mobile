import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
  final response = await ref
      .watch(transactionRepositoryProvider)
      .listTransactions(limit: 100, offset: 0, sort: 'transaction_at_desc');
  return response.transactions;
});

/// Redesign Tahap 5 — the cross-wallet merged Activity timeline: day-grouped,
/// each row showing the wallet, time, amount, and a "kamu" tag for the current
/// user's own entries (the couple-transparency signal). Additive route.
class ActivityFeedScreen extends StatelessWidget {
  const ActivityFeedScreen({super.key});

  static const path = '/rooms-activity';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.sky.ground,
      body: const SafeArea(child: ActivityFeedView()),
    );
  }
}

/// The merged Activity timeline body (no Scaffold/back) — hosted standalone or
/// as a tab in the redesign nav shell.
class ActivityFeedView extends ConsumerWidget {
  const ActivityFeedView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final txAsync = ref.watch(recentActivityProvider);
    final wallets =
        ref.watch(walletListProvider).asData?.value ?? const <Wallet>[];
    final walletNames = {for (final w in wallets) w.id: w.name};
    final meId = ref.watch(authControllerProvider).user?.id;

    return ListView(
      padding: AffluenaInsets.screen,
      children: [
        Text(
          'Aktivitas',
          style: TextStyle(
            fontSize: 21,
            fontWeight: FontWeight.w700,
            color: context.sky.ink,
          ),
        ),
        const SizedBox(height: AffluenaSpacing.space4),
        txAsync.when(
          loading: () => Padding(
            padding: const EdgeInsets.symmetric(
              vertical: AffluenaSpacing.space6,
            ),
            child: Center(
              child: CircularProgressIndicator(color: context.sky.accent),
            ),
          ),
          error: (_, _) => Text(
            'Tidak bisa memuat aktivitas.',
            style: TextStyle(fontSize: 13, color: context.sky.muted),
          ),
          data: (txns) => txns.isEmpty
              ? Text(
                  'Belum ada transaksi.',
                  style: TextStyle(fontSize: 13, color: context.sky.faint),
                )
              : _Feed(txns: txns, walletNames: walletNames, meId: meId),
        ),
      ],
    );
  }
}

class _Feed extends StatelessWidget {
  const _Feed({
    required this.txns,
    required this.walletNames,
    required this.meId,
  });

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
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: context.sky.faint,
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: rows,
    );
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
    final sign = isIncome
        ? '+'
        : (tx.type == TransactionType.expense ? '-' : '');
    final amount = '$sign${MoneyFormatter.idr(tx.amountMinor.abs())}';
    final meta =
        '$walletName · ${AffluenaDateFormatter.time(tx.transactionAt)}${mine ? ' · kamu' : ''}';
    final initial = mine
        ? 'K'
        : (title.isNotEmpty ? title[0].toUpperCase() : '?');

    return Container(
      margin: const EdgeInsets.only(bottom: AffluenaSpacing.space2),
      padding: const EdgeInsets.symmetric(
        horizontal: AffluenaSpacing.space3,
        vertical: 11,
      ),
      decoration: BoxDecoration(
        color: context.sky.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.sky.line),
      ),
      child: Row(
        children: [
          Container(
            width: 30,
            height: 30,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: mine ? context.sky.accent : context.sky.avatarSecondary,
              shape: BoxShape.circle,
            ),
            child: Text(
              initial,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
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
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                    color: context.sky.ink,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  meta,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 11, color: context.sky.muted),
                ),
              ],
            ),
          ),
          const SizedBox(width: AffluenaSpacing.space2),
          Text(
            amount,
            style: TextStyle(
              fontSize: 13.5,
              fontWeight: FontWeight.w700,
              color: isIncome ? context.sky.income : context.sky.ink,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }
}
