import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/affluena_theme.dart';
import '../../../core/api/api_error.dart';
import '../../shared/presentation/widgets/affluena_banner.dart';
import '../application/wallet_detail_controller.dart';
import '../application/wallets_controller.dart';
import '../data/wallet_models.dart';
import '../data/wallet_repository.dart';

/// Opens the invite sheet. On a successful invite the wallet detail and list
/// providers are invalidated so the new pending member appears.
Future<void> showWalletInviteSheet(
  BuildContext context,
  WidgetRef ref,
  String walletId,
) async {
  final invited = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (context) => _WalletInviteSheet(walletId: walletId),
  );
  if (invited == true) {
    ref
      ..invalidate(walletDetailProvider(walletId))
      ..invalidate(walletListProvider);
  }
}

class _WalletInviteSheet extends ConsumerStatefulWidget {
  const _WalletInviteSheet({required this.walletId});

  final String walletId;

  @override
  ConsumerState<_WalletInviteSheet> createState() => _WalletInviteSheetState();
}

class _WalletInviteSheetState extends ConsumerState<_WalletInviteSheet> {
  final _emailController = TextEditingController();
  WalletInviteRole _role = WalletInviteRole.member;
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
      child: SingleChildScrollView(
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
              const SizedBox(height: AffluenaSpacing.space2),
              Text(
                'Send an invitation by email. They can accept or decline from '
                'their own account.',
                style: textTheme.bodySmall,
              ),
              const SizedBox(height: AffluenaSpacing.space4),
              TextField(
                controller: _emailController,
                decoration: const InputDecoration(labelText: 'Email address'),
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.done,
                enabled: !_isSaving,
                onChanged: (_) {
                  if (_error != null) setState(() => _error = null);
                },
                onSubmitted: (_) => _invite(),
              ),
              const SizedBox(height: AffluenaSpacing.space4),
              Text('What they can do', style: textTheme.labelMedium),
              const SizedBox(height: AffluenaSpacing.space2),
              SegmentedButton<WalletInviteRole>(
                segments: const [
                  ButtonSegment(
                    value: WalletInviteRole.viewer,
                    label: Text('Boleh lihat'),
                    icon: Icon(Icons.visibility_outlined),
                  ),
                  ButtonSegment(
                    value: WalletInviteRole.member,
                    label: Text('Boleh catat'),
                    icon: Icon(Icons.edit_outlined),
                  ),
                ],
                selected: {_role},
                onSelectionChanged: _isSaving
                    ? null
                    : (selection) => setState(() => _role = selection.first),
              ),
              if (_error != null) ...[
                const SizedBox(height: AffluenaSpacing.space3),
                AffluenaBanner.error(_error!),
              ],
              const SizedBox(height: AffluenaSpacing.space5),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _isSaving ? null : _invite,
                  child: Text(_isSaving ? 'Sending…' : 'Send invite'),
                ),
              ),
            ],
          ),
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
          .inviteMember(
            widget.walletId,
            WalletInviteRequest(email: email, role: _role),
          );
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _isSaving = false;
        _error = _inviteError(error);
      });
    }
  }

  String _inviteError(Object error) {
    if (error is ApiException) return error.message;
    if (error is DioException) {
      final inner = error.error;
      if (inner is ApiException) return inner.message;
    }
    return 'Invite could not be sent.';
  }
}
