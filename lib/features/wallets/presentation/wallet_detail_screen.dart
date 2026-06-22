import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/affluena_theme.dart';
import '../../../core/formatters/money_formatter.dart';
import '../../shared/presentation/widgets/affluena_card.dart';
import '../../shared/presentation/widgets/metric_tile.dart';
import '../../shared/presentation/widgets/section_header.dart';
import '../application/wallet_detail_controller.dart';
import '../application/wallets_controller.dart';
import '../data/wallet_models.dart';
import '../data/wallet_repository.dart';
import 'wallet_display.dart';
import 'wallet_sharing_screen.dart';
import 'wallets_screen.dart';

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
                onPressed: () => context.go(WalletsScreen.path),
                icon: const Icon(Icons.arrow_back),
              ),
              const SizedBox(width: AffluenaSpacing.space2),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Wallet detail', style: textTheme.labelMedium),
                    const SizedBox(height: AffluenaSpacing.space1),
                    Text(wallet.name, style: textTheme.headlineMedium),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AffluenaSpacing.space5),
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
                    Chip(label: Text(walletRoleLabel(wallet.role))),
                    Chip(label: Text(walletStatusLabel(wallet.shareStatus))),
                    if (wallet.description.isNotEmpty)
                      Chip(label: Text(wallet.description)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: AffluenaSpacing.space6),
          const SectionHeader(title: 'Monthly analytics'),
          const SizedBox(height: AffluenaSpacing.space3),
          AffluenaCard(
            child: Column(
              children: [
                Row(
                  children: [
                    MetricTile(
                      label: 'Inflow',
                      value: MoneyFormatter.idr(state.analytics.inflowMinor),
                      helper: state.analytics.month,
                      icon: Icons.south_west,
                    ),
                    const SizedBox(width: AffluenaSpacing.space3),
                    MetricTile(
                      label: 'Outflow',
                      value: MoneyFormatter.idr(state.analytics.outflowMinor),
                      helper: state.analytics.month,
                      icon: Icons.north_east,
                    ),
                  ],
                ),
                const SizedBox(height: AffluenaSpacing.space3),
                _DetailRow(
                  icon: Icons.receipt_long_outlined,
                  title: 'Transactions',
                  value: state.analytics.transactionCount == 1
                      ? '1 transaction'
                      : '${state.analytics.transactionCount} transactions',
                ),
                if (state.analytics.lastActivityAt != null) ...[
                  const Divider(height: 1),
                  _DetailRow(
                    icon: Icons.history,
                    title: 'Last activity',
                    value: state.analytics.lastActivityAt!,
                  ),
                ],
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
          _MembersCard(members: state.members),
          const SizedBox(height: AffluenaSpacing.space6),
          const SectionHeader(title: 'Actions'),
          const SizedBox(height: AffluenaSpacing.space3),
          AffluenaCard(
            child: Column(
              children: [
                _ActionRow(
                  icon: Icons.group_add_outlined,
                  title: 'Wallet sharing',
                  value: 'Invites and member status',
                  onTap: () =>
                      context.go(WalletSharingScreen.location(wallet.id)),
                ),
                if (canDelete) ...[
                  const Divider(height: 1),
                  _ActionRow(
                    icon: Icons.delete_outline,
                    title: 'Delete wallet',
                    value: 'Requires confirmation',
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

class _WalletDetailLoading extends StatelessWidget {
  const _WalletDetailLoading();

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
          Text('Wallet detail', style: textTheme.headlineMedium),
          const SizedBox(height: AffluenaSpacing.space5),
          const AffluenaCard(
            child: SizedBox(
              height: 120,
              child: Center(child: Text('Loading wallet')),
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
          Text('Wallet unavailable', style: textTheme.headlineMedium),
          const SizedBox(height: AffluenaSpacing.space5),
          AffluenaCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('We could not load this wallet.'),
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

class _WalletIconMark extends StatelessWidget {
  const _WalletIconMark({required this.wallet});

  final Wallet wallet;

  @override
  Widget build(BuildContext context) {
    final colors = context.affluenaColors;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.forestSoft,
        borderRadius: BorderRadius.circular(AffluenaRadii.lg),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AffluenaSpacing.space4),
        child: Icon(walletIcon(wallet.type), color: colors.forest),
      ),
    );
  }
}

class _MembersCard extends StatelessWidget {
  const _MembersCard({required this.members});

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
            _MemberRow(member: member),
            if (index != members.length - 1) const Divider(height: 1),
          ],
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
    final textTheme = Theme.of(context).textTheme;
    final colors = context.affluenaColors;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AffluenaSpacing.space3),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: colors.surfaceTintSoft,
            foregroundColor: colors.forest,
            child: Text(
              member.email.isEmpty ? '?' : member.email[0].toUpperCase(),
            ),
          ),
          const SizedBox(width: AffluenaSpacing.space3),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(member.email, style: textTheme.bodyLarge),
                const SizedBox(height: AffluenaSpacing.space1),
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

Future<void> _showInviteSheet(
  BuildContext context,
  WidgetRef ref,
  String walletId,
) async {
  final invited = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (context) => _InviteMemberSheet(walletId: walletId),
  );
  if (invited == true) {
    ref
      ..invalidate(walletDetailProvider(walletId))
      ..invalidate(walletListProvider);
  }
}

class _InviteMemberSheet extends ConsumerStatefulWidget {
  const _InviteMemberSheet({required this.walletId});

  final String walletId;

  @override
  ConsumerState<_InviteMemberSheet> createState() => _InviteMemberSheetState();
}

class _InviteMemberSheetState extends ConsumerState<_InviteMemberSheet> {
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
              textInputAction: TextInputAction.done,
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

Future<void> _confirmDelete(BuildContext context, Wallet wallet) async {
  await showDialog<void>(
    context: context,
    builder: (context) => _DeleteWalletDialog(wallet: wallet),
  );
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
    return AlertDialog(
      title: Text('Delete ${widget.wallet.name}?'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('This removes the wallet after confirmation.'),
          if (_error != null) ...[
            const SizedBox(height: AffluenaSpacing.space3),
            Text(
              _error!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: _isDeleting ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _isDeleting ? null : _delete,
          child: Text(_isDeleting ? 'Deleting...' : 'Delete'),
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
      ref
        ..invalidate(walletListProvider)
        ..invalidate(walletDetailProvider(widget.wallet.id));
      if (!mounted) return;
      context.go(WalletsScreen.path);
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isDeleting = false;
        _error = 'Wallet could not be deleted.';
      });
    }
  }
}
