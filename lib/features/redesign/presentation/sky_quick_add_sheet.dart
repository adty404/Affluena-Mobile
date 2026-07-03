import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/affluena_theme.dart';
import '../../../app/theme/sky_palette.dart';
import '../../../core/calc/money_calculator.dart';
import '../../../core/formatters/money_formatter.dart';
import '../../categories/data/category_models.dart';
import '../../quick_entry/application/quick_entry_templates_controller.dart';
import '../../quick_entry/data/quick_entry_models.dart';
import '../../quick_entry/presentation/quick_entry_templates_screen.dart';
import '../../shared/presentation/widgets/category_tree_picker_sheet.dart';
import '../../shared/presentation/widgets/lookup_selector_sheet.dart';
import '../../shared/presentation/widgets/sky_calc_keypad.dart';
import '../../shared/presentation/widgets/sky_segmented_toggle.dart';
import '../../transactions/application/transaction_create_controller.dart';
import '../../transactions/data/transaction_models.dart';
import '../../wallets/data/wallet_models.dart';

/// Redesign Tahap 3 — the fast "quick-add" capture sheet. Opens from the Home
/// FAB (no wallet) or a long-press on a room (wallet pre-set). Reuses
/// [transactionCreateControllerProvider] for the writable-wallet + category
/// data and the create() mutation; owns its field state locally. Returns true
/// when a transaction was saved.
Future<bool?> showSkyQuickAddSheet(
  BuildContext context, {
  Wallet? wallet,
  DateTime? date,
}) {
  return showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _SkyQuickAddSheet(initialWallet: wallet, date: date),
  );
}

class _SkyQuickAddSheet extends ConsumerStatefulWidget {
  const _SkyQuickAddSheet({this.initialWallet, this.date});

  final Wallet? initialWallet;

  /// The calendar day this transaction is being recorded for. When set, the
  /// transaction is stamped on this date (keeping the local wall-clock time)
  /// instead of "now", so quick-adding from a day sheet lands on that day.
  final DateTime? date;

  @override
  ConsumerState<_SkyQuickAddSheet> createState() => _SkyQuickAddSheetState();
}

class _SkyQuickAddSheetState extends ConsumerState<_SkyQuickAddSheet> {
  TransactionType _type = TransactionType.expense;
  final _calc = MoneyCalculator();
  String? _walletId;
  String? _categoryId;
  String? _error;

  CategoryType get _categoryType => _type == TransactionType.income
      ? CategoryType.income
      : CategoryType.expense;

  @override
  void initState() {
    super.initState();
    _walletId = widget.initialWallet?.id;
  }

  /// The ISO-8601 (UTC) instant to stamp a transaction with. For a chosen
  /// calendar day, keep the current wall-clock time so the row sorts naturally
  /// and the local-day bucket round-trips back to the picked date; otherwise
  /// use now.
  String _transactionAtIso() {
    final date = widget.date;
    if (date == null) return DateTime.now().toUtc().toIso8601String();
    final now = DateTime.now();
    return DateTime(
      date.year,
      date.month,
      date.day,
      now.hour,
      now.minute,
      now.second,
    ).toUtc().toIso8601String();
  }

  void _run(void Function() action) {
    setState(() {
      _error = null;
      action();
    });
  }

  void _onDigit(String d) =>
      _run(() => d == '000' ? _calc.inputZeros() : _calc.inputDigit(d));
  void _onOperator(String op) => _run(() => _calc.applyOperator(op));
  void _onEquals() => _run(_calc.equals);
  void _onDecimal() => _run(_calc.inputDecimal);
  void _onClear() => _run(_calc.clear);
  void _onBackspace() => _run(_calc.backspace);

  Future<void> _selectWallet(TransactionCreateState state) async {
    final selected = await showLookupSelectorSheet<String>(
      context: context,
      title: 'Pilih dompet',
      searchHint: 'Cari dompet',
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
      quickAdd: CategoryQuickAdd(type: _categoryType),
      onMutated: () =>
          ref.read(transactionCreateControllerProvider.notifier).load(),
      categories: [
        for (final category in categories)
          CategoryTreeEntry.fromCategory(category),
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
    if (_calc.amountMinor <= 0) return 'Masukkan jumlah lebih dari nol.';
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
      amountMinor: _calc.amountMinor,
      transactionAt: _transactionAtIso(),
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

  /// One-tap: record a quick-entry template as-is (its own wallet, category and
  /// amount) and close the sheet, mirroring the chips on the full quick-entry
  /// screen. No picker needed — the template carries everything.
  Future<void> _useTemplate(QuickEntryTemplate template) async {
    final messenger = ScaffoldMessenger.of(context);
    final executed = await ref
        .read(quickEntryTemplatesControllerProvider.notifier)
        .executeTemplate(
          template,
          ExecuteQuickEntryRequest(transactionAt: _transactionAtIso()),
        );
    if (!mounted) return;
    if (executed) {
      messenger.showSnackBar(
        SnackBar(content: Text('${template.name} dicatat.')),
      );
      Navigator.of(context).pop(true);
      return;
    }
    setState(() {
      _error =
          ref.read(quickEntryTemplatesControllerProvider).actionError ??
          'Template gagal dijalankan.';
    });
  }

  /// Close the sheet and open the manage-templates screen.
  void _manageTemplates() {
    final router = GoRouter.of(context);
    Navigator.of(context).pop();
    router.push(QuickEntryTemplatesScreen.path);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(transactionCreateControllerProvider);
    final templatesState = ref.watch(quickEntryTemplatesControllerProvider);
    // Opened from a wallet long-press → only that wallet's templates. Opened
    // from the FAB (no wallet) → templates from every wallet.
    final scopedWallet = widget.initialWallet;
    final templates = templatesState.templates
        .where(
          (template) =>
              template.type == _type &&
              (scopedWallet == null || template.walletId == scopedWallet.id),
        )
        .toList(growable: false);
    final preview = _calc.expressionPreview(
      (value) => MoneyFormatter.idr(value.round()),
    );

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
              scopedWallet == null
                  ? 'Catat cepat'
                  : 'Catat cepat · ${scopedWallet.name}',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: context.sky.ink,
              ),
            ),
            const SizedBox(height: AffluenaSpacing.space4),
            Padding(
              padding: const EdgeInsets.only(left: 2, bottom: 6),
              child: Text(
                'PAKAI TEMPLATE',
                style: TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                  color: context.sky.faint,
                ),
              ),
            ),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: const ClampingScrollPhysics(),
              child: Row(
                children: [
                  for (final template in templates) ...[
                    _TemplateChip(
                      name: template.name,
                      amount: MoneyFormatter.idr(template.amountMinor),
                      onTap: templatesState.isSaving
                          ? null
                          : () => _useTemplate(template),
                    ),
                    const SizedBox(width: AffluenaSpacing.space2),
                  ],
                  _TemplateChip(
                    name: 'Kelola',
                    amount: 'Atur',
                    muted: true,
                    onTap: _manageTemplates,
                  ),
                ],
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
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (preview != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 2),
                      child: Text(
                        preview,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: context.sky.faint,
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                      ),
                    ),
                  Text(
                    MoneyFormatter.idr(_calc.displayValue.round()),
                    style: TextStyle(
                      fontSize: 34,
                      fontWeight: FontWeight.w700,
                      color: context.sky.ink,
                      letterSpacing: -0.5,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AffluenaSpacing.space4),
            Row(
              children: [
                Expanded(
                  child: _PickerChip(
                    icon: Icons.account_balance_wallet_outlined,
                    label: state.walletName(_walletId),
                    isPlaceholder: _walletId == null,
                    onTap: state.isSaving ? null : () => _selectWallet(state),
                  ),
                ),
                const SizedBox(width: AffluenaSpacing.space2),
                Expanded(
                  child: _PickerChip(
                    icon: Icons.category_outlined,
                    label: state.categoryName(_categoryId),
                    isPlaceholder: _categoryId == null,
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
            ] else if (_validate() != null) ...[
              // Surface why the save will fail BEFORE the tap — muted, not
              // alarmed, so the sheet never feels broken on open.
              const SizedBox(height: AffluenaSpacing.space3),
              Text(
                _validate()!,
                style: TextStyle(fontSize: 12.5, color: context.sky.faint),
              ),
            ],
            const SizedBox(height: AffluenaSpacing.space4),
            SkyCalcKeypad(
              onDigit: _onDigit,
              onOperator: _onOperator,
              onClear: _onClear,
              onBackspace: _onBackspace,
              onDecimal: _onDecimal,
              onEquals: _onEquals,
              onConfirm: _save,
              isSaving: state.isSaving,
            ),
          ],
        ),
      ),
    );
  }
}

class _PickerChip extends StatelessWidget {
  const _PickerChip({
    required this.icon,
    required this.label,
    this.onTap,
    this.isPlaceholder = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  /// Render [label] in the muted ink so an unselected placeholder ("Pilih
  /// dompet") reads differently from a chosen wallet/category.
  final bool isPlaceholder;

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
                    color: isPlaceholder ? context.sky.muted : context.sky.ink,
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

/// A one-tap preset chip in the "PAKAI TEMPLATE" row: template name over its
/// amount. The trailing "Kelola" chip uses [muted] for its sub-label.
class _TemplateChip extends StatelessWidget {
  const _TemplateChip({
    required this.name,
    required this.amount,
    this.onTap,
    this.muted = false,
  });

  final String name;
  final String amount;
  final VoidCallback? onTap;
  final bool muted;

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
            vertical: AffluenaSpacing.space2,
          ),
          decoration: BoxDecoration(
            borderRadius: radius,
            border: Border.all(color: context.sky.line),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  color: context.sky.ink,
                ),
              ),
              const SizedBox(height: 1),
              Text(
                amount,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w500,
                  color: muted ? context.sky.faint : context.sky.muted,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
