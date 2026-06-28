import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/affluena_theme.dart';
import '../../../app/theme/sky_palette.dart';
import '../../../core/formatters/money_formatter.dart';
import '../../categories/data/category_models.dart';
import '../../shared/presentation/widgets/category_tree_picker_sheet.dart';
import '../../shared/presentation/widgets/lookup_selector_sheet.dart';
import '../../shared/presentation/widgets/sky_keypad.dart';
import '../../shared/presentation/widgets/sky_segmented_toggle.dart';
import '../../transactions/application/transaction_create_controller.dart';
import '../../transactions/data/transaction_models.dart';
import '../../wallets/data/wallet_models.dart';

/// Redesign Tahap 3 — the fast "quick-add" capture sheet. Opens from the Home
/// FAB (no wallet) or a long-press on a room (wallet pre-set). Reuses
/// [transactionCreateControllerProvider] for the writable-wallet + category
/// data and the create() mutation; owns its field state locally. Returns true
/// when a transaction was saved.
Future<bool?> showSkyQuickAddSheet(BuildContext context, {Wallet? wallet}) {
  return showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _SkyQuickAddSheet(initialWallet: wallet),
  );
}

class _SkyQuickAddSheet extends ConsumerStatefulWidget {
  const _SkyQuickAddSheet({this.initialWallet});

  final Wallet? initialWallet;

  @override
  ConsumerState<_SkyQuickAddSheet> createState() => _SkyQuickAddSheetState();
}

class _SkyQuickAddSheetState extends ConsumerState<_SkyQuickAddSheet> {
  TransactionType _type = TransactionType.expense;
  String _digits = '';
  String? _walletId;
  String? _categoryId;
  String? _error;

  CategoryType get _categoryType => _type == TransactionType.income
      ? CategoryType.income
      : CategoryType.expense;

  int get _amountMinor => _digits.isEmpty ? 0 : int.parse(_digits);

  @override
  void initState() {
    super.initState();
    _walletId = widget.initialWallet?.id;
  }

  void _onKey(String key) {
    setState(() {
      _error = null;
      final next = _digits + key;
      // Cap length and drop leading zeros.
      final trimmed = next.replaceFirst(RegExp(r'^0+(?=\d)'), '');
      if (trimmed.length <= 12) _digits = trimmed;
    });
  }

  void _onBackspace() {
    if (_digits.isEmpty) return;
    setState(() {
      _error = null;
      _digits = _digits.substring(0, _digits.length - 1);
    });
  }

  Future<void> _selectWallet(TransactionCreateState state) async {
    final selected = await showLookupSelectorSheet<String>(
      context: context,
      title: 'Pilih dompet',
      selectedValue: _walletId,
      options: [
        for (final wallet in state.wallets)
          LookupSelectorOption(
            value: wallet.id,
            label: wallet.name,
            subtitle: wallet.type.name,
          ),
      ],
    );
    if (selected == null) return;
    setState(() {
      _walletId = selected;
      _error = null;
    });
  }

  Future<void> _selectCategory(TransactionCreateState state) async {
    final categories = state.categoriesOfType(_categoryType);
    final selected = await showCategoryTreePicker(
      context: context,
      title: 'Kategori',
      selectedId: _categoryId,
      categories: [
        for (final category in categories)
          CategoryTreeEntry(
            id: category.id,
            name: category.name,
            parentId: category.parentId,
          ),
      ],
    );
    if (selected == null || selected.isEmpty) return;
    setState(() {
      _categoryId = selected;
      _error = null;
    });
  }

  String? _validate() {
    if (_walletId == null) return 'Pilih dompet dulu.';
    if (_amountMinor <= 0) return 'Masukkan jumlah lebih dari nol.';
    if (_categoryId == null) return 'Pilih kategori dulu.';
    return null;
  }

  Future<void> _save() async {
    final error = _validate();
    if (error != null) {
      setState(() => _error = error);
      return;
    }
    final request = TransactionRequest(
      type: _type,
      walletId: _walletId!,
      categoryId: _categoryId,
      amountMinor: _amountMinor,
      transactionAt: DateTime.now().toUtc().toIso8601String(),
    );
    final saved = await ref
        .read(transactionCreateControllerProvider.notifier)
        .create(request);
    if (!mounted) return;
    if (saved) {
      Navigator.of(context).pop(true);
      return;
    }
    setState(() {
      _error =
          ref.read(transactionCreateControllerProvider).actionError ??
          'Gagal menyimpan transaksi.';
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(transactionCreateControllerProvider);

    return SafeArea(
      top: false,
      child: Container(
        decoration: BoxDecoration(
          color: context.sky.sheet,
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(AffluenaRadii.sheet),
          ),
        ),
        padding: const EdgeInsets.fromLTRB(
          AffluenaSpacing.space5,
          AffluenaSpacing.space2,
          AffluenaSpacing.space5,
          AffluenaSpacing.space5,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 38,
                height: 4,
                margin: const EdgeInsets.only(bottom: AffluenaSpacing.space4),
                decoration: BoxDecoration(
                  color: context.sky.line,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Text(
              'Catat cepat',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: context.sky.ink,
              ),
            ),
            const SizedBox(height: AffluenaSpacing.space4),
            SkySegmentedToggle<TransactionType>(
              selected: _type,
              enabled: !state.isSaving,
              onChanged: (value) => setState(() {
                _type = value;
                _categoryId = null;
                _error = null;
              }),
              options: const [
                SkySegmentOption(
                  value: TransactionType.expense,
                  label: 'Pengeluaran',
                ),
                SkySegmentOption(
                  value: TransactionType.income,
                  label: 'Pemasukan',
                ),
              ],
            ),
            const SizedBox(height: AffluenaSpacing.space5),
            Center(
              child: Text(
                MoneyFormatter.idr(_amountMinor),
                style: TextStyle(
                  fontSize: 34,
                  fontWeight: FontWeight.w700,
                  color: context.sky.ink,
                  letterSpacing: -0.5,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ),
            const SizedBox(height: AffluenaSpacing.space4),
            Row(
              children: [
                Expanded(
                  child: _PickerChip(
                    icon: Icons.account_balance_wallet_outlined,
                    label: state.walletName(_walletId),
                    onTap: state.isSaving ? null : () => _selectWallet(state),
                  ),
                ),
                const SizedBox(width: AffluenaSpacing.space2),
                Expanded(
                  child: _PickerChip(
                    icon: Icons.category_outlined,
                    label: state.categoryName(_categoryId),
                    onTap: state.isSaving ? null : () => _selectCategory(state),
                  ),
                ),
              ],
            ),
            if (_error != null) ...[
              const SizedBox(height: AffluenaSpacing.space3),
              Text(
                _error!,
                style: TextStyle(fontSize: 12.5, color: context.sky.danger),
              ),
            ],
            const SizedBox(height: AffluenaSpacing.space4),
            SkyKeypad(onKey: _onKey, onBackspace: _onBackspace),
            const SizedBox(height: AffluenaSpacing.space4),
            FilledButton(
              onPressed: state.isSaving ? null : _save,
              style: FilledButton.styleFrom(
                backgroundColor: context.sky.accent,
                foregroundColor: Colors.white,
                minimumSize: const Size.fromHeight(50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AffluenaRadii.control),
                ),
              ),
              child: Text(state.isSaving ? 'Menyimpan…' : 'Simpan'),
            ),
          ],
        ),
      ),
    );
  }
}

class _PickerChip extends StatelessWidget {
  const _PickerChip({required this.icon, required this.label, this.onTap});

  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(AffluenaRadii.control);
    return Material(
      color: context.sky.surface,
      borderRadius: radius,
      child: InkWell(
        borderRadius: radius,
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AffluenaSpacing.space3,
            vertical: AffluenaSpacing.space3,
          ),
          decoration: BoxDecoration(
            borderRadius: radius,
            border: Border.all(color: context.sky.line),
          ),
          child: Row(
            children: [
              Icon(icon, size: 16, color: context.sky.accent),
              const SizedBox(width: AffluenaSpacing.space2),
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: context.sky.ink,
                  ),
                ),
              ),
              Icon(Icons.expand_more, size: 16, color: context.sky.faint),
            ],
          ),
        ),
      ),
    );
  }
}
