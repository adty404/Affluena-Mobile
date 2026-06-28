import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/affluena_theme.dart';
import '../../../app/theme/sky_palette.dart';
import '../../../core/formatters/date_formatter.dart';
import '../../../core/formatters/money_formatter.dart';
import '../../auth/application/auth_controller.dart';
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
  final response = await ref.watch(transactionRepositoryProvider).listTransactions(
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
      backgroundColor: SkyPalette.ground,
      body: SafeArea(
        child: detailAsync.when(
          loading: () => const Center(
            child: CircularProgressIndicator(color: SkyPalette.accent),
          ),
          error: (error, _) => _DetailError(
            onBack: () => context.pop(),
            onRetry: () => ref.invalidate(walletDetailProvider(walletId)),
          ),
          data: (detail) => _RoomDetailContent(walletId: walletId, detail: detail),
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
    final me = ref.watch(authControllerProvider).user;
    final membersById = {for (final m in detail.members) m.userId: m};

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
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: SkyPalette.ink,
                ),
              ),
            ),
            _RolePill(label: walletRoleLabel(wallet.role)),
          ],
        ),
        const SizedBox(height: AffluenaSpacing.space5),
        const Text(
          'Saldo',
          style: TextStyle(fontSize: 11.5, color: SkyPalette.faint),
        ),
        const SizedBox(height: 2),
        Text(
          MoneyFormatter.idr(wallet.balanceMinor),
          style: const TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w700,
            color: SkyPalette.ink,
            letterSpacing: -0.4,
            fontFeatures: [FontFeature.tabularFigures()],
          ),
        ),
        if (detail.members.isNotEmpty) ...[
          const SizedBox(height: AffluenaSpacing.space5),
          _MembersCard(members: detail.members),
        ],
        const SizedBox(height: AffluenaSpacing.space4),
        if (wallet.canWrite)
          FilledButton.icon(
            onPressed: () async {
              final saved = await showSkyQuickAddSheet(context, wallet: wallet);
              if (saved == true) {
                ref
                  ..invalidate(walletDetailProvider(walletId))
                  ..invalidate(walletTransactionsProvider(walletId));
              }
            },
            icon: const Icon(Icons.add, size: 18),
            label: const Text('Catat di sini'),
            style: FilledButton.styleFrom(
              backgroundColor: SkyPalette.accent,
              foregroundColor: Colors.white,
              minimumSize: const Size.fromHeight(48),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AffluenaRadii.control),
              ),
            ),
          ),
        const SizedBox(height: AffluenaSpacing.space5),
        const Text(
          'Transaksi',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: SkyPalette.muted,
          ),
        ),
        const SizedBox(height: AffluenaSpacing.space2),
        txAsync.when(
          loading: () => const Padding(
            padding: EdgeInsets.symmetric(vertical: AffluenaSpacing.space5),
            child: Center(
              child: CircularProgressIndicator(color: SkyPalette.accent),
            ),
          ),
          error: (_, _) => const Text(
            'Tidak bisa memuat transaksi.',
            style: TextStyle(fontSize: 13, color: SkyPalette.muted),
          ),
          data: (txns) => txns.isEmpty
              ? const Text(
                  'Belum ada transaksi di dompet ini.',
                  style: TextStyle(fontSize: 13, color: SkyPalette.faint),
                )
              : _TransactionList(txns: txns, membersById: membersById, meId: me?.id, meEmail: me?.email),
        ),
      ],
    );
  }
}

class _TransactionList extends StatelessWidget {
  const _TransactionList({
    required this.txns,
    required this.membersById,
    required this.meId,
    required this.meEmail,
  });

  final List<Transaction> txns;
  final Map<String, WalletMember> membersById;
  final String? meId;
  final String? meEmail;

  String _whoInitial(Transaction tx) {
    if (meId != null && tx.userId == meId) {
      return (meEmail == null || meEmail!.isEmpty)
          ? 'A'
          : meEmail![0].toUpperCase();
    }
    final email = membersById[tx.userId]?.email ?? '';
    return email.isEmpty ? '?' : email[0].toUpperCase();
  }

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
      rows.add(_TransactionRow(tx: tx, whoInitial: _whoInitial(tx)));
    }
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: rows);
  }
}

class _TransactionRow extends StatelessWidget {
  const _TransactionRow({required this.tx, required this.whoInitial});

  final Transaction tx;
  final String whoInitial;

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
          SkyAvatar(initial: whoInitial, size: 24),
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
                  AffluenaDateFormatter.time(tx.transactionAt),
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

class _MembersCard extends StatelessWidget {
  const _MembersCard({required this.members});

  final List<WalletMember> members;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AffluenaSpacing.space3),
      decoration: BoxDecoration(
        color: SkyPalette.surface,
        borderRadius: BorderRadius.circular(AffluenaRadii.lg),
        border: Border.all(color: SkyPalette.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Padding(
            padding: EdgeInsets.only(bottom: AffluenaSpacing.space2),
            child: Text(
              'Anggota & akses',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: SkyPalette.ink,
              ),
            ),
          ),
          for (final member in members)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 5),
              child: Row(
                children: [
                  SkyAvatar(
                    initial: member.email.isEmpty
                        ? '?'
                        : member.email[0].toUpperCase(),
                    size: 26,
                    color: SkyPalette.avatarSecondary,
                  ),
                  const SizedBox(width: AffluenaSpacing.space3),
                  Expanded(
                    child: Text(
                      member.email,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: SkyPalette.ink,
                      ),
                    ),
                  ),
                  _RolePill(label: walletRoleLabel(member.role)),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _RolePill extends StatelessWidget {
  const _RolePill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: SkyPalette.accentSoft,
        borderRadius: BorderRadius.circular(AffluenaRadii.pill),
        border: Border.all(color: SkyPalette.accentSoftBorder),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: SkyPalette.accentInk,
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
          child: const Icon(
            Icons.arrow_back,
            size: 19,
            color: SkyPalette.ink,
          ),
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
          const Center(
            child: Text(
              'Tidak bisa memuat dompet.',
              style: TextStyle(fontSize: 14, color: SkyPalette.muted),
            ),
          ),
          Center(
            child: TextButton(
              onPressed: onRetry,
              style: TextButton.styleFrom(foregroundColor: SkyPalette.accent),
              child: const Text('Coba lagi'),
            ),
          ),
          const Spacer(),
        ],
      ),
    );
  }
}
