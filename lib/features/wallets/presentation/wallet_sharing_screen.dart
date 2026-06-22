import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/affluena_theme.dart';
import '../../shared/presentation/widgets/affluena_card.dart';
import '../../shared/presentation/widgets/section_header.dart';
import '../application/wallet_detail_controller.dart';
import '../application/wallets_controller.dart';
import '../data/wallet_models.dart';
import '../data/wallet_repository.dart';
import 'wallet_detail_screen.dart';
import 'wallet_display.dart';

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

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(
          AffluenaSpacing.space5,
          AffluenaSpacing.space4,
          AffluenaSpacing.space5,
          AffluenaSpacing.space8,
        ),
        children: [
          Row(
            children: [
              IconButton(
                onPressed: () =>
                    context.go(WalletDetailScreen.location(wallet.id)),
                icon: const Icon(Icons.arrow_back),
              ),
              const SizedBox(width: AffluenaSpacing.space2),
              Expanded(
                child: Text('Wallet sharing', style: textTheme.headlineMedium),
              ),
            ],
          ),
          const SizedBox(height: AffluenaSpacing.space5),
          AffluenaCard(
            backgroundColor: context.affluenaColors.forestSoft,
            borderColor: context.affluenaColors.forestSoft,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(wallet.name, style: textTheme.titleLarge),
                const SizedBox(height: AffluenaSpacing.space2),
                Text(
                  'Role: ${walletRoleLabel(wallet.role)} · Status: ${walletStatusLabel(wallet.shareStatus)}',
                  style: textTheme.bodyMedium,
                ),
              ],
            ),
          ),
          const SizedBox(height: AffluenaSpacing.space6),
          SectionHeader(
            title: 'Members',
            actionLabel: 'Invite member',
            onAction: () => _showInviteSheet(context, ref, wallet.id),
          ),
          const SizedBox(height: AffluenaSpacing.space3),
          _SharingMembersCard(members: state.members),
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
    final textTheme = Theme.of(context).textTheme;
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(
          AffluenaSpacing.space5,
          AffluenaSpacing.space4,
          AffluenaSpacing.space5,
          AffluenaSpacing.space8,
        ),
        children: [
          Text('Wallet sharing', style: textTheme.headlineMedium),
          const SizedBox(height: AffluenaSpacing.space5),
          const AffluenaCard(
            child: SizedBox(
              height: 120,
              child: Center(child: Text('Loading sharing')),
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
    final textTheme = Theme.of(context).textTheme;
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(
          AffluenaSpacing.space5,
          AffluenaSpacing.space4,
          AffluenaSpacing.space5,
          AffluenaSpacing.space8,
        ),
        children: [
          Text('Sharing unavailable', style: textTheme.headlineMedium),
          const SizedBox(height: AffluenaSpacing.space5),
          AffluenaCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('We could not load wallet sharing.'),
                const SizedBox(height: AffluenaSpacing.space4),
                FilledButton.icon(
                  onPressed: onRetry,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Retry'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SharingMembersCard extends StatelessWidget {
  const _SharingMembersCard({required this.members});

  final List<WalletMember> members;

  @override
  Widget build(BuildContext context) {
    if (members.isEmpty) {
      return const AffluenaCard(child: Text('No invited members yet.'));
    }

    return AffluenaCard(
      child: Column(
        children: [
          for (final (index, member) in members.indexed) ...[
            _SharingMemberRow(member: member),
            if (index != members.length - 1) const Divider(height: 1),
          ],
        ],
      ),
    );
  }
}

class _SharingMemberRow extends StatelessWidget {
  const _SharingMemberRow({required this.member});

  final WalletMember member;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colors = context.affluenaColors;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AffluenaSpacing.space3),
      child: Row(
        children: [
          Icon(Icons.person_outline, color: colors.forest),
          const SizedBox(width: AffluenaSpacing.space3),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(member.email, style: textTheme.bodyLarge),
                Text(
                  '${walletRoleLabel(member.role)} · ${memberStatusLabel(member.status)}',
                  style: textTheme.bodySmall,
                ),
              ],
            ),
          ),
          Chip(label: Text(memberStatusLabel(member.status))),
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

Future<void> _showInviteSheet(
  BuildContext context,
  WidgetRef ref,
  String walletId,
) async {
  final invited = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (context) => _SharingInviteSheet(walletId: walletId),
  );
  if (invited == true) {
    ref
      ..invalidate(walletDetailProvider(walletId))
      ..invalidate(walletListProvider);
  }
}

class _SharingInviteSheet extends ConsumerStatefulWidget {
  const _SharingInviteSheet({required this.walletId});

  final String walletId;

  @override
  ConsumerState<_SharingInviteSheet> createState() =>
      _SharingInviteSheetState();
}

class _SharingInviteSheetState extends ConsumerState<_SharingInviteSheet> {
  final _emailController = TextEditingController();
  String? _error;
  bool _isSaving = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          AffluenaSpacing.space5,
          AffluenaSpacing.space2,
          AffluenaSpacing.space5,
          MediaQuery.viewInsetsOf(context).bottom + AffluenaSpacing.space5,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Invite member', style: textTheme.titleLarge),
            const SizedBox(height: AffluenaSpacing.space4),
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(labelText: 'Email address'),
              keyboardType: TextInputType.emailAddress,
            ),
            if (_error != null) ...[
              const SizedBox(height: AffluenaSpacing.space3),
              Text(
                _error!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ],
            const SizedBox(height: AffluenaSpacing.space5),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _isSaving ? null : _invite,
                child: Text(_isSaving ? 'Sending...' : 'Send invite'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _invite() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      setState(() => _error = 'Email is required.');
      return;
    }

    setState(() {
      _isSaving = true;
      _error = null;
    });

    try {
      await ref
          .read(walletRepositoryProvider)
          .inviteMember(widget.walletId, WalletInviteRequest(email: email));
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isSaving = false;
        _error = 'Invite could not be sent.';
      });
    }
  }
}
