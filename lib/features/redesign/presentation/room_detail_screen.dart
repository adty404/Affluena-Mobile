import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/affluena_theme.dart';
import '../../../app/theme/sky_palette.dart';
import '../../../core/formatters/date_formatter.dart';
import '../../../core/formatters/money_formatter.dart';
import '../../shared/presentation/widgets/sky_avatar.dart';
import '../../transactions/data/transaction_models.dart';
import '../../transactions/data/transaction_repository.dart';
import '../../wallets/application/wallet_detail_controller.dart';
import '../../wallets/data/wallet_models.dart';
import '../../wallets/presentation/wallet_display.dart';
import 'sky_quick_add_sheet.dart';

/// Transactions for a single wallet (room), most-recent first. Isolated from the
/// global transactions controller so opening a room never clobbers the main
/// Activity filter.
final walletTransactionsProvider =
    FutureProvider.family<List<Transaction>, String>((ref, walletId) async {
      final response = await ref
          .watch(transactionRepositoryProvider)
          .listTransactions(
            walletId: walletId,
            limit: 50,
            offset: 0,
            sort: 'transaction_at_desc',
          );
      return response.transactions;
    });

/// Redesign Tahap 4 — the "room" (wallet) detail: balance, members & access
/// (surfacing the viewer role), in-context quick-add, and this wallet's
/// transactions with who-logged-it attribution. Additive route /rooms/:walletId.
class RoomDetailScreen extends ConsumerWidget {
  const RoomDetailScreen({required this.walletId, super.key});

  final String walletId;

  static const path = '/rooms/:walletId';
  static String location(String walletId) => '/rooms/$walletId';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detailAsync = ref.watch(walletDetailProvider(walletId));

    return Scaffold(
      backgroundColor: context.sky.ground,
      body: SafeArea(
        child: detailAsync.when(
          loading: () => Center(
            child: CircularProgressIndicator(color: context.sky.accent),
          ),
          error: (error, _) => _DetailError(
            onBack: () => context.pop(),
            onRetry: () => ref.invalidate(walletDetailProvider(walletId)),
          ),
          data: (detail) =>
              _RoomDetailContent(walletId: walletId, detail: detail),
        ),
      ),
    );
  }
}

class _RoomDetailContent extends ConsumerWidget {
  const _RoomDetailContent({required this.walletId, required this.detail});

  final String walletId;
  final WalletDetailState detail;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final wallet = detail.wallet;
    final txAsync = ref.watch(walletTransactionsProvider(walletId));

    return ListView(
      padding: AffluenaInsets.screen,
      children: [
        Row(
          children: [
            _BackButton(onTap: () => context.pop()),
            const SizedBox(width: AffluenaSpacing.space3),
            Expanded(
              child: Text(
                wallet.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: context.sky.ink,
                ),
              ),
            ),
            _RolePill(label: walletRoleLabel(wallet.role)),
          ],
        ),
        const SizedBox(height: AffluenaSpacing.space5),
        Text(
          'Saldo',
          style: TextStyle(fontSize: 11.5, color: context.sky.muted),
        ),
        const SizedBox(height: 2),
        Text(
          MoneyFormatter.idr(wallet.balanceMinor),
          style: TextStyle(
            fontSize: 30,
            fontWeight: FontWeight.w700,
            color: context.sky.ink,
            letterSpacing: -0.4,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
        if (detail.members.isNotEmpty) ...[
          const SizedBox(height: AffluenaSpacing.space5),
          _MembersCard(members: detail.members),
        ],
        const SizedBox(height: AffluenaSpacing.space4),
        if (wallet.canWrite)
          DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: context.sky.accent.withValues(alpha: 0.35),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: FilledButton.icon(
              onPressed: () async {
                final saved = await showSkyQuickAddSheet(
                  context,
                  wallet: wallet,
                );
                if (saved == true) {
                  ref
                    ..invalidate(walletDetailProvider(walletId))
                    ..invalidate(walletTransactionsProvider(walletId));
                }
              },
              icon: const Icon(Icons.add, size: 18),
              label: const Text(
                'Catat di sini',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
              style: FilledButton.styleFrom(
                backgroundColor: context.sky.accent,
                foregroundColor: context.sky.onAccent,
                minimumSize: const Size.fromHeight(46),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ),
        const SizedBox(height: AffluenaSpacing.space5),
        Text(
          'Transaksi',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: context.sky.muted,
          ),
        ),
        const SizedBox(height: AffluenaSpacing.space2),
        txAsync.when(
          loading: () => Padding(
            padding: const EdgeInsets.symmetric(
              vertical: AffluenaSpacing.space5,
            ),
            child: Center(
              child: CircularProgressIndicator(color: context.sky.accent),
            ),
          ),
          error: (_, _) => Text(
            'Tidak bisa memuat transaksi.',
            style: TextStyle(fontSize: 13, color: context.sky.muted),
          ),
          data: (txns) => txns.isEmpty
              ? Text(
                  'Belum ada transaksi di dompet ini.',
                  style: TextStyle(fontSize: 13, color: context.sky.faint),
                )
              : _TransactionList(txns: txns),
        ),
      ],
    );
  }
}

class _TransactionList extends StatelessWidget {
  const _TransactionList({required this.txns});

  final List<Transaction> txns;

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
      rows.add(_TransactionRow(tx: tx));
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: rows,
    );
  }
}

class _TransactionRow extends StatelessWidget {
  const _TransactionRow({required this.tx});

  final Transaction tx;

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

    return Container(
      margin: const EdgeInsets.only(bottom: AffluenaSpacing.space2),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: context.sky.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.sky.line),
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: context.sky.sheet,
              borderRadius: BorderRadius.circular(11),
              border: Border.all(color: context.sky.line),
            ),
            child: Icon(
              isIncome
                  ? Icons.south_west
                  : (tx.type == TransactionType.expense
                        ? Icons.north_east
                        : Icons.swap_horiz),
              size: 18,
              color: context.sky.muted,
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
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: context.sky.ink,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  AffluenaDateFormatter.time(tx.transactionAt),
                  style: TextStyle(fontSize: 11, color: context.sky.faint),
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
              color: isIncome ? context.sky.income : context.sky.ink,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }
}

class _MembersCard extends StatelessWidget {
  const _MembersCard({required this.members});

  final List<WalletMember> members;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: context.sky.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.sky.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: AffluenaSpacing.space2),
            child: Text(
              'Anggota & akses',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: context.sky.ink,
              ),
            ),
          ),
          for (final member in members)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 5),
              child: _MemberRow(member: member),
            ),
        ],
      ),
    );
  }
}

class _MemberRow extends StatelessWidget {
  const _MemberRow({required this.member});

  final WalletMember member;

  @override
  Widget build(BuildContext context) {
    final initial = member.email.isEmpty ? '?' : member.email[0].toUpperCase();
    final isOwner = member.role == 'owner';
    return Row(
      children: [
        SkyAvatar(
          initial: initial,
          size: 30,
          color: initial == 'A'
              ? context.sky.avatarPrimary
              : context.sky.avatarSecondary,
        ),
        const SizedBox(width: AffluenaSpacing.space3),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                member.email,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: context.sky.ink,
                ),
              ),
              const SizedBox(height: 1),
              Text(
                walletRoleLabel(member.role),
                style: TextStyle(fontSize: 10.5, color: context.sky.muted),
              ),
            ],
          ),
        ),
        const SizedBox(width: AffluenaSpacing.space2),
        _RolePill(label: walletRoleLabel(member.role), isOwner: isOwner),
      ],
    );
  }
}

class _RolePill extends StatelessWidget {
  const _RolePill({required this.label, this.isOwner = true});

  final String label;
  final bool isOwner;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: isOwner ? context.sky.accentSoft : context.sky.ground,
        borderRadius: BorderRadius.circular(9),
        border: Border.all(
          color: isOwner ? context.sky.accentSoftBorder : context.sky.line,
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: isOwner ? context.sky.accentInk : context.sky.muted,
        ),
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
      color: context.sky.surface,
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
            border: Border.all(color: context.sky.line),
          ),
          child: Icon(Icons.arrow_back, size: 19, color: context.sky.ink),
        ),
      ),
    );
  }
}

class _DetailError extends StatelessWidget {
  const _DetailError({required this.onBack, required this.onRetry});

  final VoidCallback onBack;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: AffluenaInsets.screen,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _BackButton(onTap: onBack),
          const Spacer(),
          Center(
            child: Text(
              'Tidak bisa memuat dompet.',
              style: TextStyle(fontSize: 14, color: context.sky.muted),
            ),
          ),
          Center(
            child: TextButton(
              onPressed: onRetry,
              style: TextButton.styleFrom(foregroundColor: context.sky.accent),
              child: const Text('Coba lagi'),
            ),
          ),
          const Spacer(),
        ],
      ),
    );
  }
}
