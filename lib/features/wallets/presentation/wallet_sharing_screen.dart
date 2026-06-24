import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/affluena_theme.dart';
import '../../shared/presentation/widgets/affluena_banner.dart';
import '../../shared/presentation/widgets/affluena_card.dart';
import '../../shared/presentation/widgets/affluena_skeleton.dart';
import '../../shared/presentation/widgets/drill_in_scaffold.dart';
import '../../shared/presentation/widgets/section_header.dart';
import '../../shared/presentation/widgets/status_badge.dart';
import '../application/wallet_detail_controller.dart';
import 'wallet_display.dart';
import 'wallet_invite_sheet.dart';
import 'wallet_members_section.dart';

const _screenPadding = EdgeInsets.fromLTRB(
  AffluenaSpacing.space5,
  AffluenaSpacing.space4,
  AffluenaSpacing.space5,
  AffluenaSpacing.space8,
);

class WalletSharingScreen extends ConsumerWidget {
  const WalletSharingScreen({required this.walletId, super.key});

  static const path = '/wallets/:walletId/sharing';

  static String location(String walletId) => '/wallets/$walletId/sharing';

  final String walletId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detail = ref.watch(walletDetailProvider(walletId));
    return detail.when(
      skipLoadingOnReload: true,
      loading: () => const _WalletSharingLoading(),
      error: (error, stackTrace) => _WalletSharingError(
        onRetry: () => ref.invalidate(walletDetailProvider(walletId)),
      ),
      data: (state) => _WalletSharingContent(state: state),
    );
  }
}

class _WalletSharingContent extends ConsumerWidget {
  const _WalletSharingContent({required this.state});

  final WalletDetailState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final wallet = state.wallet;
    final textTheme = Theme.of(context).textTheme;

    return DrillInScaffold(
      title: 'Sharing',
      body: ListView(
        padding: _screenPadding,
        children: [
          AffluenaCard(
            backgroundColor: context.affluenaColors.forestSoft,
            borderColor: context.affluenaColors.forestSoft,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(wallet.name, style: textTheme.titleLarge),
                const SizedBox(height: AffluenaSpacing.space3),
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
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: AffluenaSpacing.space6),
          SectionHeader(
            title: 'Members',
            actionLabel: 'Invite member',
            onAction: () => showWalletInviteSheet(context, ref, wallet.id),
          ),
          const SizedBox(height: AffluenaSpacing.space3),
          WalletMembersSection(walletId: wallet.id, members: state.members),
          const SizedBox(height: AffluenaSpacing.space6),
          const SectionHeader(title: 'Access'),
          const SizedBox(height: AffluenaSpacing.space3),
          AffluenaCard(
            child: Column(
              children: [
                _AccessRow(
                  title: 'Wallet',
                  value: wallet.name,
                  icon: Icons.account_balance_wallet_outlined,
                ),
                const Divider(height: 1),
                _AccessRow(
                  title: 'Role',
                  value: walletRoleLabel(wallet.role),
                  icon: Icons.verified_user_outlined,
                ),
                const Divider(height: 1),
                _AccessRow(
                  title: 'Status',
                  value: walletStatusLabel(wallet.shareStatus),
                  icon: Icons.shield_outlined,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _WalletSharingLoading extends StatelessWidget {
  const _WalletSharingLoading();

  @override
  Widget build(BuildContext context) {
    return DrillInScaffold(
      title: 'Sharing',
      body: ListView(
        padding: _screenPadding,
        children: [
          AffluenaCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                AffluenaSkeleton.line(width: 160, height: 22),
                SizedBox(height: AffluenaSpacing.space3),
                AffluenaSkeleton.line(width: 200),
              ],
            ),
          ),
          const SizedBox(height: AffluenaSpacing.space6),
          const AffluenaSkeleton.line(width: 120, height: 16),
          const SizedBox(height: AffluenaSpacing.space3),
          AffluenaCard(
            child: Column(
              children: const [
                Row(
                  children: [
                    AffluenaSkeleton.circle(),
                    SizedBox(width: AffluenaSpacing.space3),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          AffluenaSkeleton.line(width: 160),
                          SizedBox(height: AffluenaSpacing.space2),
                          AffluenaSkeleton.line(width: 80),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _WalletSharingError extends StatelessWidget {
  const _WalletSharingError({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return DrillInScaffold(
      title: 'Sharing',
      body: ListView(
        padding: _screenPadding,
        children: [
          AffluenaBanner.error(
            'We could not load wallet sharing.',
            onRetry: onRetry,
          ),
        ],
      ),
    );
  }
}

class _AccessRow extends StatelessWidget {
  const _AccessRow({
    required this.title,
    required this.value,
    required this.icon,
  });

  final String title;
  final String value;
  final IconData icon;

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
