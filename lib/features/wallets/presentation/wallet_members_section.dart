import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/affluena_theme.dart';
import '../../../app/theme/sky_palette.dart';
import '../../auth/application/auth_controller.dart';
import '../../shared/presentation/widgets/affluena_banner.dart';
import '../../shared/presentation/widgets/affluena_card.dart';
import '../../shared/presentation/widgets/sky_avatar.dart';
import '../../shared/presentation/widgets/status_badge.dart';
import '../application/wallet_members_controller.dart';
import '../data/wallet_models.dart';
import 'wallet_display.dart';
import 'wallet_invite_sheet.dart';

/// Renders the members list with accept/decline affordances **only on the
/// signed-in user's own pending invitation row** — the API rejects responses
/// on someone else's invite, so other pending rows show a neutral waiting
/// line instead. Reused by both the detail screen and the sharing screen.
class WalletMembersSection extends ConsumerWidget {
  const WalletMembersSection({
    required this.walletId,
    required this.members,
    super.key,
  });

  final String walletId;
  final List<WalletMember> members;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final action = ref.watch(walletMembersControllerProvider(walletId));
    final controller = ref.read(
      walletMembersControllerProvider(walletId).notifier,
    );
    // Only the invitee can answer their own invitation (the API rejects a
    // response on anyone else's membership), so identify the signed-in user.
    final meId = ref.watch(authControllerProvider).user?.id;

    if (members.isEmpty) {
      return _MembersEmpty(
        onInvite: () => showWalletInviteSheet(context, ref, walletId),
      );
    }

    return AffluenaCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (action.error != null) ...[
            AffluenaBanner.error(action.error!, onRetry: controller.clearError),
            const SizedBox(height: AffluenaSpacing.space3),
          ],
          for (final (index, member) in members.indexed) ...[
            WalletMemberRow(
              member: member,
              isCurrentUser: member.userId == meId,
              isPending: action.isPending(member.userId),
              onAccept: () =>
                  controller.respond(member, WalletShareStatus.joined),
              onReject: () =>
                  controller.respond(member, WalletShareStatus.rejected),
            ),
            if (index != members.length - 1) const Divider(height: 1),
          ],
        ],
      ),
    );
  }
}

class WalletMemberRow extends StatelessWidget {
  const WalletMemberRow({
    required this.member,
    required this.isCurrentUser,
    required this.isPending,
    required this.onAccept,
    required this.onReject,
    super.key,
  });

  final WalletMember member;

  /// Whether this row is the signed-in user's own membership. Only the
  /// invitee may answer an invitation — accept/reject on someone else's
  /// pending row would always be rejected by the API.
  final bool isCurrentUser;

  /// Whether this row currently has a response in flight.
  final bool isPending;
  final VoidCallback onAccept;
  final VoidCallback onReject;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final isInvitePending =
        isCurrentUser && member.status == WalletShareStatus.pending;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AffluenaSpacing.space3),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              SkyAvatar(
                initial: member.email.isEmpty
                    ? '?'
                    : member.email[0].toUpperCase(),
                size: 40,
                // Deterministic per-member tone (shared with the room detail
                // screen) so members stop looking identical.
                color: context.sky.avatarColorFor(member.email),
              ),
              const SizedBox(width: AffluenaSpacing.space3),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(member.email, style: textTheme.bodyLarge),
                    const SizedBox(height: AffluenaSpacing.space1),
                    Text(
                      walletRoleLabel(member.role),
                      style: textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              StatusBadge(
                label: memberStatusLabel(member.status),
                tone: memberStatusTone(member.status),
              ),
            ],
          ),
          if (isInvitePending) ...[
            const SizedBox(height: AffluenaSpacing.space3),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: isPending ? null : onReject,
                    child: const Text('Tolak'),
                  ),
                ),
                const SizedBox(width: AffluenaSpacing.space3),
                Expanded(
                  child: FilledButton(
                    onPressed: isPending ? null : onAccept,
                    child: Text(isPending ? 'Memproses…' : 'Terima'),
                  ),
                ),
              ],
            ),
          ] else if (member.status == WalletShareStatus.pending) ...[
            // Someone else's unanswered invite: a neutral waiting line
            // (mirrors _PendingInviteCard) instead of buttons that the API
            // would always reject.
            const SizedBox(height: AffluenaSpacing.space2),
            Text(
              'Undangan untuk ${member.email} menunggu jawaban mereka.',
              style: textTheme.bodySmall,
            ),
          ],
        ],
      ),
    );
  }
}

class _MembersEmpty extends StatelessWidget {
  const _MembersEmpty({required this.onInvite});

  final VoidCallback onInvite;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return AffluenaCard(
      child: Column(
        children: [
          Icon(Icons.group_outlined, color: context.sky.accent, size: 32),
          const SizedBox(height: AffluenaSpacing.space3),
          Text(
            'Belum ada yang berbagi dompet ini',
            style: textTheme.titleMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AffluenaSpacing.space2),
          Text(
            'Undang seseorang lewat email untuk memantau saldo dan transaksi '
            'bersama.',
            style: textTheme.bodySmall,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AffluenaSpacing.space4),
          FilledButton.icon(
            onPressed: onInvite,
            icon: const Icon(Icons.person_add_alt_1_outlined),
            label: const Text('Undang anggota'),
          ),
        ],
      ),
    );
  }
}
