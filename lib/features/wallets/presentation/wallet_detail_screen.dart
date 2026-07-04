import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/affluena_theme.dart';
import '../../../core/formatters/money_formatter.dart';
import '../../auth/application/auth_controller.dart';
import '../../shared/application/financial_refresh.dart';
import '../../shared/presentation/widgets/affluena_banner.dart';
import '../../shared/presentation/widgets/affluena_card.dart';
import '../../shared/presentation/widgets/affluena_skeleton.dart';
import '../../shared/presentation/widgets/drill_in_scaffold.dart';
import '../../shared/presentation/widgets/section_header.dart';
import '../../shared/presentation/widgets/status_badge.dart';
import '../application/wallet_detail_controller.dart';
import '../application/wallet_members_controller.dart';
import '../data/wallet_models.dart';
import '../data/wallet_repository.dart';
import 'wallet_adjust_sheet.dart';
import 'wallet_analytics_section.dart';
import 'wallet_appearance.dart';
import 'wallet_display.dart';
import 'wallet_invite_sheet.dart';
import 'wallet_members_section.dart';
import 'wallet_sharing_screen.dart';

const _screenPadding = EdgeInsets.fromLTRB(
  AffluenaSpacing.space5,
  AffluenaSpacing.space4,
  AffluenaSpacing.space5,
  AffluenaSpacing.space8,
);

class WalletDetailScreen extends ConsumerWidget {
  const WalletDetailScreen({required this.walletId, super.key});

  static const path = '/wallets/:walletId';

  static String location(String walletId) => '/wallets/$walletId';

  final String walletId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detail = ref.watch(walletDetailProvider(walletId));
    return detail.when(
      skipLoadingOnReload: true,
      loading: () => const _WalletDetailLoading(),
      error: (error, stackTrace) => _WalletDetailError(
        onRetry: () => ref.invalidate(walletDetailProvider(walletId)),
      ),
      data: (state) => _WalletDetailContent(state: state),
    );
  }
}

class _WalletDetailContent extends ConsumerWidget {
  const _WalletDetailContent({required this.state});

  final WalletDetailState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final wallet = state.wallet;
    final textTheme = Theme.of(context).textTheme;
    final canDelete = wallet.role == null || wallet.role == 'owner';
    final canWrite = wallet.canWrite; // viewers get a read-only detail screen

    return DrillInScaffold(
      title: wallet.name.isEmpty ? 'Dompet' : wallet.name,
      body: ListView(
        padding: _screenPadding,
        children: [
          AffluenaCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    _WalletIconMark(wallet: wallet),
                    const SizedBox(width: AffluenaSpacing.space4),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            MoneyFormatter.idr(wallet.balanceMinor),
                            style: textTheme.displaySmall,
                          ),
                          const SizedBox(height: AffluenaSpacing.space1),
                          Text(
                            '${walletTypeLabel(wallet.type)} · ${wallet.currencyCode}',
                            style: textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AffluenaSpacing.space4),
                Wrap(
                  spacing: AffluenaSpacing.space2,
                  runSpacing: AffluenaSpacing.space2,
                  children: [
                    StatusBadge(
                      label: walletRoleLabel(wallet.role),
                      tone: StatusTone.neutral,
                    ),
                    StatusBadge(
                      label: walletStatusLabel(wallet.shareStatus),
                      tone: walletShareTone(wallet.shareStatus),
                    ),
                    if (wallet.description.isNotEmpty)
                      StatusBadge(
                        label: wallet.description,
                        tone: StatusTone.neutral,
                      ),
                  ],
                ),
              ],
            ),
          ),
          if (wallet.shareStatus == WalletShareStatus.pending) ...[
            const SizedBox(height: AffluenaSpacing.space4),
            _PendingInviteCard(wallet: wallet),
          ],
          const SizedBox(height: AffluenaSpacing.space6),
          const SectionHeader(title: 'Analitik bulanan'),
          const SizedBox(height: AffluenaSpacing.space3),
          WalletAnalyticsSection(walletId: wallet.id),
          const SizedBox(height: AffluenaSpacing.space6),
          SectionHeader(
            title: 'Anggota',
            actionLabel: canWrite ? 'Undang anggota' : null,
            onAction: canWrite
                ? () => showWalletInviteSheet(context, ref, wallet.id)
                : null,
          ),
          const SizedBox(height: AffluenaSpacing.space3),
          WalletMembersSection(walletId: wallet.id, members: state.members),
          const SizedBox(height: AffluenaSpacing.space6),
          const SectionHeader(title: 'Tindakan'),
          const SizedBox(height: AffluenaSpacing.space3),
          AffluenaCard(
            child: Column(
              children: [
                if (!wallet.isGoal && canWrite) ...[
                  _ActionRow(
                    icon: Icons.tune_rounded,
                    title: 'Sesuaikan saldo',
                    value: 'Tetapkan saldo baru (penyesuaian)',
                    onTap: () => showWalletAdjustSheet(context, wallet),
                  ),
                  const Divider(height: 1),
                ],
                _ActionRow(
                  icon: Icons.group_add_outlined,
                  title: 'Berbagi dompet',
                  value: 'Undangan dan status anggota',
                  onTap: () =>
                      context.push(WalletSharingScreen.location(wallet.id)),
                ),
                if (canDelete) ...[
                  const Divider(height: 1),
                  _ActionRow(
                    icon: Icons.delete_outline,
                    title: 'Hapus dompet',
                    value: 'Perlu konfirmasi',
                    isDestructive: true,
                    onTap: () => _confirmDelete(context, wallet),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Banner that lets the invitee accept or decline their own pending invitation
/// to this wallet directly from the detail header. Anyone else (e.g. the owner
/// looking at a wallet with an unanswered invite) sees a neutral "waiting for
/// their answer" line instead of buttons they cannot use.
class _PendingInviteCard extends ConsumerWidget {
  const _PendingInviteCard({required this.wallet});

  final Wallet wallet;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textTheme = Theme.of(context).textTheme;
    final colors = context.affluenaColors;
    final action = ref.watch(walletMembersControllerProvider(wallet.id));
    final controller = ref.read(
      walletMembersControllerProvider(wallet.id).notifier,
    );
    // Only the invitee themself may answer: match the signed-in user against
    // the pending membership instead of guessing from the members list.
    final meId = ref.watch(authControllerProvider).user?.id;
    final self = _selfMember(wallet, meId);
    final pendingOther = self == null ? _firstPendingMember(wallet) : null;
    final isBusy = self != null && action.isPending(self.userId);

    return AffluenaCard(
      backgroundColor: Color.alphaBlend(
        colors.amber.withAlpha(24),
        colors.surfaceSoft,
      ),
      borderColor: colors.amber.withAlpha(90),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.mark_email_unread_outlined, color: colors.amber),
              const SizedBox(width: AffluenaSpacing.space3),
              Expanded(
                child: Text(
                  self != null
                      ? 'Kamu punya undangan yang menunggu untuk dompet bersama ini.'
                      : 'Dompet ini punya undangan berbagi yang belum dijawab.',
                  style: textTheme.bodyMedium?.copyWith(color: colors.ink),
                ),
              ),
            ],
          ),
          if (action.error != null) ...[
            const SizedBox(height: AffluenaSpacing.space3),
            AffluenaBanner.error(action.error!),
          ],
          const SizedBox(height: AffluenaSpacing.space4),
          if (self == null)
            Text(
              pendingOther != null
                  ? 'Undangan untuk ${pendingOther.email} menunggu jawaban mereka.'
                  : 'Undangan ini bisa dijawab dari perangkat tujuan undangan.',
              style: textTheme.bodySmall,
            )
          else
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: isBusy
                        ? null
                        : () => controller.respond(
                            self,
                            WalletShareStatus.rejected,
                          ),
                    child: const Text('Tolak'),
                  ),
                ),
                const SizedBox(width: AffluenaSpacing.space3),
                Expanded(
                  child: FilledButton(
                    onPressed: isBusy
                        ? null
                        : () => controller.respond(
                            self,
                            WalletShareStatus.joined,
                          ),
                    child: Text(isBusy ? 'Memproses…' : 'Terima'),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  /// The signed-in user's own pending membership, or null when the pending
  /// invite belongs to someone else (e.g. the owner viewing a wallet whose
  /// invitee hasn't answered) or when the auth user isn't resolved yet.
  WalletMember? _selfMember(Wallet wallet, String? meId) {
    if (meId == null) return null;
    for (final member in wallet.members) {
      if (member.userId == meId && member.status == WalletShareStatus.pending) {
        return member;
      }
    }
    return null;
  }

  WalletMember? _firstPendingMember(Wallet wallet) {
    for (final member in wallet.members) {
      if (member.status == WalletShareStatus.pending) return member;
    }
    return null;
  }
}

class _WalletDetailLoading extends StatelessWidget {
  const _WalletDetailLoading();

  @override
  Widget build(BuildContext context) {
    return DrillInScaffold(
      title: 'Dompet',
      body: ListView(
        padding: _screenPadding,
        children: [
          AffluenaCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Row(
                  children: [
                    AffluenaSkeleton(width: 56, height: 56),
                    SizedBox(width: AffluenaSpacing.space4),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          AffluenaSkeleton.line(width: 160, height: 26),
                          SizedBox(height: AffluenaSpacing.space2),
                          AffluenaSkeleton.line(width: 120),
                        ],
                      ),
                    ),
                  ],
                ),
                SizedBox(height: AffluenaSpacing.space4),
                AffluenaSkeleton.line(width: 200, height: 24),
              ],
            ),
          ),
          const SizedBox(height: AffluenaSpacing.space6),
          const AffluenaSkeleton.line(width: 160, height: 16),
          const SizedBox(height: AffluenaSpacing.space3),
          AffluenaCard(
            child: Column(
              children: const [
                Row(
                  children: [
                    Expanded(child: AffluenaSkeleton(height: 96, radius: 18)),
                    SizedBox(width: AffluenaSpacing.space3),
                    Expanded(child: AffluenaSkeleton(height: 96, radius: 18)),
                  ],
                ),
                SizedBox(height: AffluenaSpacing.space3),
                AffluenaSkeleton.line(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _WalletDetailError extends StatelessWidget {
  const _WalletDetailError({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return DrillInScaffold(
      title: 'Dompet',
      body: ListView(
        padding: _screenPadding,
        children: [
          AffluenaBanner.error(
            'Kami tidak dapat memuat dompet ini.',
            onRetry: onRetry,
          ),
        ],
      ),
    );
  }
}

class _WalletIconMark extends StatelessWidget {
  const _WalletIconMark({required this.wallet});

  final Wallet wallet;

  @override
  Widget build(BuildContext context) {
    final colors = context.affluenaColors;
    final hasColor = wallet.color.isNotEmpty;
    final accent = hasColor
        ? resolveWalletColor(wallet.color, colors.forest)
        : colors.forest;
    final accentSoft = hasColor
        ? accent.withValues(alpha: 0.14)
        : colors.forestSoft;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: accentSoft,
        borderRadius: BorderRadius.circular(AffluenaRadii.lg),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AffluenaSpacing.space4),
        child: Icon(resolveWalletIcon(wallet), color: accent),
      ),
    );
  }
}

class _ActionRow extends StatelessWidget {
  const _ActionRow({
    required this.icon,
    required this.title,
    required this.value,
    required this.onTap,
    this.isDestructive = false,
  });

  final IconData icon;
  final String title;
  final String value;
  final VoidCallback onTap;
  final bool isDestructive;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colors = context.affluenaColors;
    final color = isDestructive ? colors.coral : colors.forest;

    return InkWell(
      borderRadius: BorderRadius.circular(AffluenaRadii.lg),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AffluenaSpacing.space3),
        child: Row(
          children: [
            Icon(icon, color: color),
            const SizedBox(width: AffluenaSpacing.space3),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: textTheme.bodyLarge?.copyWith(color: color),
                  ),
                  const SizedBox(height: AffluenaSpacing.space1),
                  Text(value, style: textTheme.bodySmall),
                ],
              ),
            ),
            const Icon(Icons.chevron_right),
          ],
        ),
      ),
    );
  }
}

Future<void> _confirmDelete(BuildContext context, Wallet wallet) async {
  final deleted = await showDialog<bool>(
    context: context,
    builder: (context) => _DeleteWalletDialog(wallet: wallet),
  );
  // The wallet is gone — leave its (now stale) detail screen and return to the
  // previous screen (the wallets list).
  if (deleted == true && context.mounted) {
    context.pop();
  }
}

class _DeleteWalletDialog extends ConsumerStatefulWidget {
  const _DeleteWalletDialog({required this.wallet});

  final Wallet wallet;

  @override
  ConsumerState<_DeleteWalletDialog> createState() =>
      _DeleteWalletDialogState();
}

class _DeleteWalletDialogState extends ConsumerState<_DeleteWalletDialog> {
  String? _error;
  bool _isDeleting = false;

  @override
  Widget build(BuildContext context) {
    final colors = context.affluenaColors;

    return AlertDialog(
      title: Text('Hapus ${widget.wallet.name}?'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Ini akan menghapus dompet setelah dikonfirmasi.'),
          if (_error != null) ...[
            const SizedBox(height: AffluenaSpacing.space3),
            AffluenaBanner.error(_error!),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: _isDeleting ? null : () => Navigator.of(context).pop(),
          child: const Text('Batal'),
        ),
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: colors.coral),
          onPressed: _isDeleting ? null : _delete,
          child: Text(_isDeleting ? 'Menghapus…' : 'Hapus'),
        ),
      ],
    );
  }

  Future<void> _delete() async {
    setState(() {
      _isDeleting = true;
      _error = null;
    });

    try {
      await ref.read(walletRepositoryProvider).deleteWallet(widget.wallet.id);
      // Deleting a wallet removes its rows from the ledger, Aktivitas, calendar,
      // dashboard, and budgets — not just the wallet list/detail. Refresh every
      // money surface so nothing keeps showing the deleted wallet's transactions.
      ref.invalidateFinancialData();
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isDeleting = false;
        _error = 'Dompet tidak dapat dihapus.';
      });
    }
  }
}
