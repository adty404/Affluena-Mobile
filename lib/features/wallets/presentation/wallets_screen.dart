import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/affluena_theme.dart';
import '../../../core/formatters/money_formatter.dart';
import '../../shared/presentation/widgets/affluena_card.dart';
import '../../shared/presentation/widgets/metric_tile.dart';
import '../../shared/presentation/widgets/section_header.dart';
import '../application/wallets_controller.dart';
import '../data/wallet_models.dart';
import '../data/wallet_repository.dart';
import 'wallet_adjust_sheet.dart';
import 'wallet_detail_screen.dart';
import 'wallet_format.dart';

class WalletsScreen extends ConsumerWidget {
  const WalletsScreen({super.key});

  static const path = '/wallets';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final wallets = ref.watch(walletListProvider);

    return wallets.when(
      skipLoadingOnReload: true,
      loading: () => const _WalletsLoading(),
      error: (error, stackTrace) =>
          _WalletsError(onRetry: () => ref.invalidate(walletListProvider)),
      data: (wallets) => _WalletsContent(wallets: wallets),
    );
  }
}

class _WalletsContent extends ConsumerWidget {
  const _WalletsContent({required this.wallets});

  final List<Wallet> wallets;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textTheme = Theme.of(context).textTheme;

    return SafeArea(
      child: ListView(
        padding: AffluenaInsets.screen,
        children: [
          Row(
            children: [
              Expanded(child: Text('Wallets', style: textTheme.headlineMedium)),
              IconButton.filledTonal(
                onPressed: () => _showWalletForm(context, ref),
                icon: const Icon(Icons.add),
              ),
            ],
          ),
          const SizedBox(height: AffluenaSpacing.space5),
          if (wallets.isEmpty) ...[
            const _EmptyWalletState(),
          ] else ...[
            AffluenaCard(
              child: Row(
                children: [
                  MetricTile(
                    label: 'Total balance',
                    value: MoneyFormatter.idr(_totalBalance(wallets)),
                    helper: 'Across ${wallets.length} wallets',
                  ),
                  const SizedBox(width: AffluenaSpacing.space3),
                  MetricTile(
                    label: 'Shared',
                    value: _sharedWalletLabel(wallets),
                    helper: _sharedWalletHelper(wallets),
                    icon: Icons.group_outlined,
                  ),
                ],
              ),
            ),
            const SizedBox(height: AffluenaSpacing.space6),
            const SectionHeader(title: 'Your wallets'),
            const SizedBox(height: AffluenaSpacing.space3),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: EdgeInsets.zero,
              itemCount: wallets.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: AffluenaSpacing.space3,
                crossAxisSpacing: AffluenaSpacing.space3,
                mainAxisExtent: 188,
              ),
              itemBuilder: (context, index) {
                final wallet = wallets[index];
                return _WalletCard(
                  wallet: wallet,
                  onOpen: () =>
                      context.push(WalletDetailScreen.location(wallet.id)),
                  onEdit: (wallet.isGoal || wallet.isViewer)
                      ? null
                      : () => _showWalletForm(context, ref, wallet),
                );
              },
            ),
          ],
        ],
      ),
    );
  }
}

class _WalletCard extends StatelessWidget {
  const _WalletCard({required this.wallet, required this.onOpen, this.onEdit});

  final Wallet wallet;
  final VoidCallback onOpen;
  final VoidCallback? onEdit;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colors = context.affluenaColors;

    return InkWell(
      borderRadius: BorderRadius.circular(AffluenaRadii.card),
      onTap: onOpen,
      child: AffluenaCard(
        padding: const EdgeInsets.all(AffluenaSpacing.space4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                DecoratedBox(
                  decoration: BoxDecoration(
                    color: colors.forestSoft,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(AffluenaSpacing.space3),
                    child: Icon(walletIcon(wallet.type), color: colors.forest),
                  ),
                ),
                const Spacer(),
                if (_isShared(wallet))
                  Icon(Icons.group, size: 18, color: colors.inkMuted),
                if (onEdit != null)
                  IconButton(
                    key: Key('edit-wallet-${_walletKey(wallet)}'),
                    onPressed: onEdit,
                    visualDensity: VisualDensity.compact,
                    constraints: const BoxConstraints(
                      maxWidth: 36,
                      maxHeight: 36,
                    ),
                    padding: EdgeInsets.zero,
                    icon: const Icon(Icons.edit_outlined, size: 20),
                  ),
              ],
            ),
            const SizedBox(height: AffluenaSpacing.space3),
            Text(
              wallet.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: textTheme.titleMedium,
            ),
            const SizedBox(height: AffluenaSpacing.space1),
            Text(
              '${walletTypeLabel(wallet.type)} · ${_walletDescription(wallet)}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: textTheme.bodySmall,
            ),
            const Spacer(),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                MoneyFormatter.idr(wallet.balanceMinor),
                maxLines: 1,
                style: textTheme.titleMedium,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyWalletState extends StatelessWidget {
  const _EmptyWalletState();

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colors = context.affluenaColors;

    return AffluenaCard(
      backgroundColor: colors.forestSoft,
      borderColor: colors.forestSoft,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.account_balance_wallet_outlined),
          const SizedBox(height: AffluenaSpacing.space3),
          Text('No wallets yet', style: textTheme.titleMedium),
          const SizedBox(height: AffluenaSpacing.space1),
          Text(
            'Create a wallet before recording transactions.',
            style: textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}

class _WalletsLoading extends StatelessWidget {
  const _WalletsLoading();

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return SafeArea(
      child: ListView(
        padding: AffluenaInsets.screen,
        children: [
          Text('Wallets', style: textTheme.headlineMedium),
          const SizedBox(height: AffluenaSpacing.space5),
          const AffluenaCard(
            child: SizedBox(
              height: 120,
              child: Center(child: Text('Loading wallets')),
            ),
          ),
        ],
      ),
    );
  }
}

class _WalletsError extends StatelessWidget {
  const _WalletsError({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return SafeArea(
      child: ListView(
        padding: AffluenaInsets.screen,
        children: [
          Text('Wallets unavailable', style: textTheme.headlineMedium),
          const SizedBox(height: AffluenaSpacing.space5),
          AffluenaCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('We could not load your wallets.'),
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

class _WalletFormSheet extends ConsumerStatefulWidget {
  const _WalletFormSheet({this.wallet});

  final Wallet? wallet;

  @override
  ConsumerState<_WalletFormSheet> createState() => _WalletFormSheetState();
}

class _WalletFormSheetState extends ConsumerState<_WalletFormSheet> {
  late final TextEditingController _nameController;
  late final TextEditingController _balanceController;
  late WalletType _type;
  String? _error;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final wallet = widget.wallet;
    _nameController = TextEditingController(text: wallet?.name ?? '');
    _balanceController = TextEditingController(
      text: wallet == null ? '' : wallet.balanceMinor.toString(),
    );
    _type = wallet?.type == WalletType.goal
        ? WalletType.cash
        : wallet?.type ?? WalletType.cash;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _balanceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final isEditing = widget.wallet != null;

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
            Text(
              isEditing ? 'Edit wallet' : 'New wallet',
              style: textTheme.titleLarge,
            ),
            const SizedBox(height: AffluenaSpacing.space4),
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Name'),
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: AffluenaSpacing.space3),
            DropdownButtonFormField<WalletType>(
              initialValue: _type,
              decoration: const InputDecoration(labelText: 'Type'),
              items: [
                for (final type in _editableWalletTypes)
                  DropdownMenuItem(
                    value: type,
                    child: Text(walletTypeLabel(type)),
                  ),
              ],
              onChanged: _isSaving
                  ? null
                  : (value) => setState(() => _type = value ?? _type),
            ),
            if (!isEditing) ...[
              const SizedBox(height: AffluenaSpacing.space3),
              TextField(
                controller: _balanceController,
                decoration: const InputDecoration(
                  labelText: 'Starting balance',
                ),
                keyboardType: TextInputType.number,
              ),
            ],
            // When editing, the balance is never silently overwritten: the user
            // adjusts it through an `adjustment` (penyesuaian) transaction so the
            // change stays in the audit trail.
            if (isEditing) ...[
              const SizedBox(height: AffluenaSpacing.space4),
              Text(
                'Current balance ${MoneyFormatter.idr(widget.wallet!.balanceMinor)}',
                style: textTheme.bodySmall,
              ),
              const SizedBox(height: AffluenaSpacing.space2),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  key: const Key('wallet-edit-adjust-balance'),
                  onPressed: _isSaving ? null : _adjustBalance,
                  icon: const Icon(Icons.tune_outlined, size: 18),
                  label: const Text('Adjust balance (penyesuaian)'),
                ),
              ),
            ],
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
                onPressed: _isSaving ? null : _save,
                child: Text(_isSaving ? 'Saving...' : 'Save wallet'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _adjustBalance() async {
    final wallet = widget.wallet;
    if (wallet == null) return;
    // Stack the adjustment sheet over this edit sheet. On success, close the
    // edit sheet too and signal a refresh so the new balance shows immediately.
    final adjusted = await showWalletAdjustSheet(context, wallet);
    if (adjusted == true && mounted) {
      Navigator.of(context).pop(true);
    }
  }

  Future<void> _save() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      setState(() => _error = 'Wallet name is required.');
      return;
    }

    setState(() {
      _isSaving = true;
      _error = null;
    });

    final repository = ref.read(walletRepositoryProvider);
    final request = WalletRequest(
      name: name,
      type: _type,
      currencyCode: widget.wallet?.currencyCode ?? 'IDR',
      balanceMinor: widget.wallet == null
          ? _parseAmount(_balanceController.text)
          : null,
      color: widget.wallet?.color,
      description: widget.wallet?.description,
    );

    try {
      final wallet = widget.wallet;
      if (wallet == null) {
        await repository.createWallet(request);
      } else {
        await repository.updateWallet(wallet.id, request);
      }
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isSaving = false;
        _error = 'Wallet could not be saved.';
      });
    }
  }
}

Future<void> _showWalletForm(
  BuildContext context,
  WidgetRef ref, [
  Wallet? wallet,
]) async {
  final saved = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (context) => _WalletFormSheet(wallet: wallet),
  );
  if (saved == true) ref.invalidate(walletListProvider);
}

int _totalBalance(List<Wallet> wallets) {
  return wallets.fold(0, (total, wallet) => total + wallet.balanceMinor);
}

String _sharedWalletLabel(List<Wallet> wallets) {
  final count = wallets.where(_isShared).length;
  return count == 1 ? '1 wallet' : '$count wallets';
}

String _sharedWalletHelper(List<Wallet> wallets) {
  final members = wallets.fold<int>(
    0,
    (total, wallet) => total + wallet.members.length,
  );
  if (members == 0) return 'Private only';
  return members == 1 ? '1 member' : '$members members';
}

bool _isShared(Wallet wallet) {
  return wallet.members.isNotEmpty ||
      (wallet.role != null && wallet.role != 'owner');
}

String _walletDescription(Wallet wallet) {
  if (wallet.isGoal) return 'Read-only goal wallet';
  if (wallet.description.isNotEmpty) return wallet.description;
  if (_isShared(wallet)) return 'Shared wallet';
  return 'Private wallet';
}

String _walletKey(Wallet wallet) {
  return wallet.name.toLowerCase().replaceAll(RegExp('[^a-z0-9]+'), '-');
}

int _parseAmount(String value) {
  final digits = value.replaceAll(RegExp(r'[^0-9]'), '');
  if (digits.isEmpty) return 0;
  return int.tryParse(digits) ?? 0;
}

const _editableWalletTypes = [
  WalletType.cash,
  WalletType.bank,
  WalletType.eWallet,
  WalletType.investment,
];
