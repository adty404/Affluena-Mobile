import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/affluena_theme.dart';
import '../../../core/formatters/money_formatter.dart';
import '../../shared/presentation/widgets/affluena_banner.dart';
import '../../shared/presentation/widgets/affluena_card.dart';
import '../../shared/presentation/widgets/drill_in_scaffold.dart';
import '../../shared/presentation/widgets/empty_state.dart';
import '../../shared/presentation/widgets/money_input.dart';
import '../../shared/presentation/widgets/section_header.dart';
import '../application/wallets_controller.dart';
import '../data/wallet_models.dart';
import '../data/wallet_repository.dart';
import 'wallet_adjust_sheet.dart';
import 'wallet_appearance.dart';
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
    // The Dompet list mirrors Beranda's Dompet section: goal-backing wallets
    // belong under Tabungan, and wallets shared TO you (viewer) live under
    // "Dibagikan untukku" (SharedWithMeScreen). Exclude both so this screen
    // only shows the wallets you actually own and spend from.
    final visible = wallets
        .where((w) => !w.isGoal && !w.isViewer)
        .toList(growable: false);

    return DrillInScaffold(
      title: 'Dompet',
      actions: [
        IconButton.filledTonal(
          onPressed: () => _showWalletForm(context, ref),
          icon: const Icon(Icons.add),
        ),
      ],
      body: ListView(
        padding: AffluenaInsets.screen,
        children: [
          if (visible.isEmpty) ...[
            EmptyState(
              icon: Icons.account_balance_wallet_outlined,
              title: 'Belum ada dompet',
              subtitle: 'Buat dompet dulu sebelum mencatat transaksi.',
              actionLabel: 'Buat dompet',
              onAction: () => _showWalletForm(context, ref),
            ),
          ] else ...[
            _WalletsSummary(wallets: visible),
            const SizedBox(height: AffluenaSpacing.space5),
            const SectionHeader(title: 'Dompet kamu'),
            const SizedBox(height: AffluenaSpacing.space3),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: EdgeInsets.zero,
              itemCount: visible.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: AffluenaSpacing.space3,
                crossAxisSpacing: AffluenaSpacing.space3,
                mainAxisExtent: 188,
              ),
              itemBuilder: (context, index) {
                final wallet = visible[index];
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

/// The wallets-screen hero: a calm `Total saldo` headline over a single row
/// of compact soft-tinted stat chips (Dompet / Bersama / Pribadi), mirroring
/// Beranda's Ringkasan tiles. No explainer paragraphs — the chips carry the
/// breakdown on their own, and the "Bersama" chip only appears once at least
/// one wallet is actually shared, so an all-private list never shows
/// "Bersama 0" noise.
class _WalletsSummary extends StatelessWidget {
  const _WalletsSummary({required this.wallets});

  final List<Wallet> wallets;

  @override
  Widget build(BuildContext context) {
    final colors = context.affluenaColors;
    final total = _totalBalance(wallets);
    final count = wallets.length;
    final shared = wallets.where(_isShared).length;
    final private = count - shared;

    return AffluenaCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Total saldo',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: colors.inkMuted,
            ),
          ),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              MoneyFormatter.idr(total),
              maxLines: 1,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.5,
                color: colors.ink,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ),
          const SizedBox(height: AffluenaSpacing.space4),
          Row(
            children: [
              _SummaryStatChip(
                icon: Icons.account_balance_wallet_outlined,
                label: 'Dompet',
                value: '$count',
              ),
              if (shared > 0) ...[
                const SizedBox(width: AffluenaSpacing.space2),
                _SummaryStatChip(
                  icon: Icons.group_outlined,
                  label: 'Bersama',
                  value: '$shared',
                ),
              ],
              const SizedBox(width: AffluenaSpacing.space2),
              _SummaryStatChip(
                icon: Icons.lock_outline,
                label: 'Pribadi',
                value: '$private',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// One compact soft-tinted stat chip in the wallets hero — small icon beside
/// a bold count and a muted label, the same tonal treatment as Beranda's
/// Ringkasan tiles but sized for a single quiet row.
class _SummaryStatChip extends StatelessWidget {
  const _SummaryStatChip({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final colors = context.affluenaColors;
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AffluenaSpacing.space3,
          vertical: AffluenaSpacing.space3,
        ),
        decoration: BoxDecoration(
          color: colors.surfaceTintSoft,
          borderRadius: BorderRadius.circular(AffluenaRadii.lg),
        ),
        child: Row(
          children: [
            Icon(icon, size: 16, color: colors.forest),
            const SizedBox(width: AffluenaSpacing.space2),
            Flexible(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    value,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: colors.ink,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                  Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 10.5, color: colors.inkMuted),
                  ),
                ],
              ),
            ),
          ],
        ),
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
    // A valid user-chosen wallet color paints the whole card SOLID — the same
    // treatment as Beranda's dashboard cards (bg + border = the color, white
    // title/balance, white70 type label, white icon on a translucent-white
    // tile). Missing/unparseable colors keep the default theming exactly as
    // before.
    final custom = parseWalletColor(wallet.color);
    final hasColor = custom != null;
    final accent = custom ?? colors.forest;
    final accentSoft = hasColor
        ? Colors.white.withValues(alpha: 0.2)
        : colors.forestSoft;

    return InkWell(
      borderRadius: BorderRadius.circular(AffluenaRadii.card),
      onTap: onOpen,
      child: AffluenaCard(
        padding: const EdgeInsets.all(AffluenaSpacing.space4),
        backgroundColor: hasColor ? accent : null,
        borderColor: hasColor ? accent : null,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                DecoratedBox(
                  decoration: BoxDecoration(
                    color: accentSoft,
                    borderRadius: BorderRadius.circular(AffluenaRadii.lg),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(AffluenaSpacing.space3),
                    child: Icon(
                      resolveWalletIcon(wallet),
                      color: hasColor ? Colors.white : accent,
                    ),
                  ),
                ),
                const Spacer(),
                if (_isShared(wallet))
                  Icon(
                    Icons.group,
                    size: 18,
                    color: hasColor ? Colors.white : colors.inkMuted,
                  ),
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
                    icon: Icon(
                      Icons.edit_outlined,
                      size: 20,
                      color: hasColor ? Colors.white : null,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: AffluenaSpacing.space3),
            Text(
              wallet.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: hasColor
                  ? textTheme.titleMedium?.copyWith(color: Colors.white)
                  : textTheme.titleMedium,
            ),
            const SizedBox(height: AffluenaSpacing.space1),
            Text(
              '${walletTypeLabel(wallet.type)} · ${_walletDescription(wallet)}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: hasColor
                  ? textTheme.bodySmall?.copyWith(color: Colors.white70)
                  : textTheme.bodySmall,
            ),
            const Spacer(),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                MoneyFormatter.idr(wallet.balanceMinor),
                maxLines: 1,
                style: hasColor
                    ? textTheme.titleMedium?.copyWith(color: Colors.white)
                    : textTheme.titleMedium,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WalletsLoading extends StatelessWidget {
  const _WalletsLoading();

  @override
  Widget build(BuildContext context) {
    return DrillInScaffold(
      title: 'Dompet',
      body: ListView(
        padding: AffluenaInsets.screen,
        children: const [
          AffluenaCard(
            child: SizedBox(
              height: 120,
              child: Center(child: Text('Memuat dompet')),
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
    return DrillInScaffold(
      title: 'Dompet',
      body: ListView(
        padding: AffluenaInsets.screen,
        children: [
          AffluenaCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Kami tidak dapat memuat dompet kamu.'),
                const SizedBox(height: AffluenaSpacing.space4),
                FilledButton.icon(
                  onPressed: onRetry,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Coba lagi'),
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
  // Starting balance in minor units (whole rupiah), captured via MoneyInput so
  // large IDR amounts are typed with thousand grouping. Create-only.
  int _initialBalanceMinor = 0;
  late WalletType _type;
  // Chosen appearance. Null = use the default (theme color / per-type icon).
  // When editing, seeded from the wallet so an unrelated edit preserves them.
  String? _color;
  String? _icon;
  String? _error;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final wallet = widget.wallet;
    _nameController = TextEditingController(text: wallet?.name ?? '');
    _type = wallet?.type == WalletType.goal
        ? WalletType.cash
        : wallet?.type ?? WalletType.cash;
    _color = (wallet != null && wallet.color.isNotEmpty) ? wallet.color : null;
    _icon = (wallet != null && wallet.icon.isNotEmpty) ? wallet.icon : null;
  }

  @override
  void dispose() {
    _nameController.dispose();
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
        // Scrollable so the form (and its inline error banner) never
        // overflows on small phones or with the keyboard open.
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isEditing ? 'Ubah dompet' : 'Dompet baru',
                style: textTheme.titleLarge,
              ),
              const SizedBox(height: AffluenaSpacing.space4),
              TextField(
                controller: _nameController,
                // The hint only shows while the field is empty, so edit mode
                // (prefilled) is unaffected.
                decoration: const InputDecoration(
                  labelText: 'Nama',
                  hintText: 'cth: Rekening BCA',
                ),
                // The next control is a dropdown that never receives keyboard
                // focus, so "next" would strand the focus; close instead.
                textInputAction: TextInputAction.done,
              ),
              const SizedBox(height: AffluenaSpacing.space3),
              DropdownButtonFormField<WalletType>(
                initialValue: _type,
                decoration: const InputDecoration(labelText: 'Jenis'),
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
              const SizedBox(height: AffluenaSpacing.space4),
              _PickerLabel('Warna'),
              const SizedBox(height: AffluenaSpacing.space2),
              _buildColorPicker(),
              const SizedBox(height: AffluenaSpacing.space4),
              _PickerLabel('Ikon'),
              const SizedBox(height: AffluenaSpacing.space2),
              _buildIconPicker(),
              if (!isEditing) ...[
                const SizedBox(height: AffluenaSpacing.space3),
                MoneyInput(
                  label: 'Saldo awal',
                  // Descriptive (not a numeric example): the live Rp grouping
                  // already shows the format while typing.
                  hint: 'Saldo dompet saat ini',
                  initialValue: _initialBalanceMinor,
                  enabled: !_isSaving,
                  onChanged: (value) =>
                      setState(() => _initialBalanceMinor = value ?? 0),
                ),
              ],
              // When editing, the balance is never silently overwritten: the user
              // adjusts it through an `adjustment` (penyesuaian) transaction so the
              // change stays in the audit trail.
              if (isEditing) ...[
                const SizedBox(height: AffluenaSpacing.space4),
                Text(
                  'Saldo saat ini ${MoneyFormatter.idr(widget.wallet!.balanceMinor)}',
                  style: textTheme.bodySmall,
                ),
                const SizedBox(height: AffluenaSpacing.space2),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    key: const Key('wallet-edit-adjust-balance'),
                    onPressed: _isSaving ? null : _adjustBalance,
                    icon: const Icon(Icons.tune_outlined, size: 18),
                    label: const Text('Sesuaikan saldo (penyesuaian)'),
                  ),
                ),
              ],
              if (_error != null) ...[
                const SizedBox(height: AffluenaSpacing.space3),
                AffluenaBanner.error(_error!),
              ],
              const SizedBox(height: AffluenaSpacing.space5),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _isSaving ? null : _save,
                  child: Text(_isSaving ? 'Menyimpan...' : 'Simpan dompet'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildColorPicker() {
    return ItemColorPickerRow(
      entity: 'wallet',
      selected: _color,
      enabled: !_isSaving,
      onChanged: (hex) => setState(() => _color = hex),
    );
  }

  Widget _buildIconPicker() {
    final colors = context.affluenaColors;
    final accent = _color != null
        ? resolveWalletColor(_color!, colors.forest)
        : colors.forest;
    final ids = kWalletIconCatalog.keys.toList(growable: false);
    return SizedBox(
      height: 48,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: ids.length,
        separatorBuilder: (_, _) =>
            const SizedBox(width: AffluenaSpacing.space3),
        itemBuilder: (context, index) {
          final id = ids[index];
          final selected = _icon == id;
          return GestureDetector(
            key: Key('wallet-icon-$id'),
            onTap: _isSaving ? null : () => setState(() => _icon = id),
            child: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: selected
                    ? accent.withValues(alpha: 0.16)
                    : colors.surfaceElevated,
                borderRadius: BorderRadius.circular(AffluenaRadii.md),
                border: Border.all(
                  color: selected ? accent : colors.borderSubtle,
                  width: selected ? 2 : 1,
                ),
              ),
              child: Icon(
                kWalletIconCatalog[id],
                color: selected ? accent : colors.inkMuted,
                size: 22,
              ),
            ),
          );
        },
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
      setState(() => _error = 'Nama dompet wajib diisi.');
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
      balanceMinor: widget.wallet == null ? _initialBalanceMinor : null,
      color: _color,
      icon: _icon,
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
        _error = 'Dompet tidak dapat disimpan.';
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

bool _isShared(Wallet wallet) {
  return wallet.members.isNotEmpty ||
      (wallet.role != null && wallet.role != 'owner');
}

/// Short privacy tag for the wallet card subtitle — deliberately terse
/// ("Bank · Bersama") so it never truncates in the narrow 2-column card. The
/// full description, if any, shows on the wallet detail screen.
String _walletDescription(Wallet wallet) {
  if (wallet.isGoal) return 'Target';
  if (_isShared(wallet)) return 'Bersama';
  return 'Pribadi';
}

String _walletKey(Wallet wallet) {
  return wallet.name.toLowerCase().replaceAll(RegExp('[^a-z0-9]+'), '-');
}

const _editableWalletTypes = [
  WalletType.cash,
  WalletType.bank,
  WalletType.eWallet,
  WalletType.investment,
];

class _PickerLabel extends StatelessWidget {
  const _PickerLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: Theme.of(
        context,
      ).textTheme.labelMedium?.copyWith(color: context.affluenaColors.inkMuted),
    );
  }
}
