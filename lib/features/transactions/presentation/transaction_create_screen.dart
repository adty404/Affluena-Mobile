import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/affluena_theme.dart';
import '../../../core/formatters/tag_formatter.dart';
import '../../categories/data/category_models.dart';
import '../../shared/presentation/widgets/affluena_banner.dart';
import '../../shared/presentation/widgets/affluena_card.dart';
import '../../shared/presentation/widgets/affluena_chip_bar.dart';
import '../../shared/presentation/widgets/affluena_choice_chip.dart';
import '../../shared/presentation/widgets/affluena_skeleton.dart';
import '../../shared/presentation/widgets/category_tree_picker_sheet.dart';
import '../../shared/presentation/widgets/date_time_picker_field.dart';
import '../../shared/presentation/widgets/drill_in_scaffold.dart';
import '../../shared/presentation/widgets/lookup_selector_sheet.dart';
import '../../shared/presentation/widgets/money_input.dart';
import '../../shared/presentation/widgets/section_header.dart';
import '../../shared/presentation/widgets/selector_row.dart';
import '../../tags/data/tag_models.dart';
import '../application/transaction_create_controller.dart';
import '../data/transaction_models.dart';
import 'adjustment_direction_control.dart';

class TransactionCreateScreen extends ConsumerStatefulWidget {
  const TransactionCreateScreen({super.key});

  static const path = '/transactions/new';

  @override
  ConsumerState<TransactionCreateScreen> createState() =>
      _TransactionCreateScreenState();
}

class _TransactionCreateScreenState
    extends ConsumerState<TransactionCreateScreen> {
  TransactionType _type = TransactionType.expense;
  int? _amountMinor;
  bool _decrease = false;
  String? _walletId;
  String? _toWalletId;
  String? _categoryId;
  String? _tagId;
  DateTime _date = DateTime.now();
  final _noteController = TextEditingController();
  String? _validationError;

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  bool get _isTransfer => _type == TransactionType.transfer;

  bool get _isAdjustment => _type == TransactionType.adjustment;

  bool get _needsCategory =>
      _type == TransactionType.income || _type == TransactionType.expense;

  CategoryType get _categoryType => _type == TransactionType.income
      ? CategoryType.income
      : CategoryType.expense;

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(transactionCreateControllerProvider);
    final controller = ref.read(transactionCreateControllerProvider.notifier);
    final textTheme = Theme.of(context).textTheme;

    if (state.isLoading && state.wallets.isEmpty) {
      return const _TransactionCreateLoading();
    }

    if (state.loadError != null && state.wallets.isEmpty) {
      return _TransactionCreateLoadError(onRetry: controller.load);
    }

    final categories = _needsCategory
        ? state.categoriesOfType(_categoryType)
        : const <Category>[];

    return DrillInScaffold(
      title: 'Transaksi baru',
      body: ListView(
        padding: AffluenaInsets.screen,
        children: [
          const _Intro(),
          const SizedBox(height: AffluenaSpacing.space5),
          SectionHeader(title: 'Jenis'),
          const SizedBox(height: AffluenaSpacing.space3),
          _TypeChips(
            selected: _type,
            enabled: !state.isSaving,
            onChanged: _onTypeChanged,
          ),
          const SizedBox(height: AffluenaSpacing.space5),
          AffluenaCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (_isAdjustment) ...[
                  AdjustmentDirectionControl(
                    decrease: _decrease,
                    enabled: !state.isSaving,
                    onChanged: (decrease) => setState(() {
                      _decrease = decrease;
                      _clearErrors();
                    }),
                  ),
                  const SizedBox(height: AffluenaSpacing.space3),
                ],
                MoneyInput(
                  key: const Key('transaction-create-amount-field'),
                  label: 'Jumlah',
                  // Bare digits: MoneyInput hardcodes the 'Rp ' prefix.
                  hint: '50.000',
                  initialValue: _amountMinor,
                  enabled: !state.isSaving,
                  onChanged: (value) => setState(() {
                    _amountMinor = value;
                    _validationError = null;
                  }),
                ),
                const SizedBox(height: AffluenaSpacing.space3),
                SelectorRow(
                  key: const Key('transaction-create-wallet-selector'),
                  label: _isTransfer ? 'Dari dompet' : 'Dompet',
                  value: state.walletName(_walletId),
                  icon: Icons.account_balance_wallet_outlined,
                  enabled: state.wallets.isNotEmpty && !state.isSaving,
                  onTap: state.wallets.isEmpty ? null : _selectWallet,
                ),
                if (_isTransfer) ...[
                  const Divider(height: 1),
                  SelectorRow(
                    key: const Key('transaction-create-to-wallet-selector'),
                    label: 'Ke dompet',
                    value: state.walletName(_toWalletId),
                    icon: Icons.swap_horiz_rounded,
                    enabled: state.wallets.length > 1 && !state.isSaving,
                    onTap: state.wallets.length > 1 ? _selectToWallet : null,
                  ),
                ],
                if (_needsCategory) ...[
                  const Divider(height: 1),
                  SelectorRow(
                    key: const Key('transaction-create-category-selector'),
                    label: 'Kategori',
                    value: state.categoryName(_categoryId),
                    icon: Icons.category_outlined,
                    enabled: categories.isNotEmpty && !state.isSaving,
                    onTap: categories.isEmpty
                        ? null
                        : () => _selectCategory(categories),
                  ),
                ],
                const Divider(height: 1),
                const SizedBox(height: AffluenaSpacing.space3),
                DateTimePickerField(
                  key: const Key('transaction-create-date-field'),
                  label: 'Tanggal & waktu',
                  value: _date,
                  enabled: !state.isSaving,
                  onChanged: (value) => setState(() {
                    _date = value;
                    _validationError = null;
                  }),
                ),
                const SizedBox(height: AffluenaSpacing.space3),
                TextField(
                  key: const Key('transaction-create-note-field'),
                  controller: _noteController,
                  enabled: !state.isSaving,
                  textInputAction: TextInputAction.done,
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.notes_outlined),
                    labelText: 'Catatan (opsional)',
                    hintText: 'cth: Makan siang',
                  ),
                  onChanged: (_) => _clearErrors(),
                ),
              ],
            ),
          ),
          if (state.tags.isNotEmpty) ...[
            const SizedBox(height: AffluenaSpacing.space5),
            SectionHeader(title: 'Tag'),
            const SizedBox(height: AffluenaSpacing.space3),
            _TagChips(
              tags: state.tags,
              selectedTagId: _tagId,
              enabled: !state.isSaving,
              onChanged: (value) => setState(() {
                _tagId = value;
                _clearErrors();
              }),
            ),
          ],
          if (_validationError != null) ...[
            const SizedBox(height: AffluenaSpacing.space4),
            AffluenaBanner(
              message: _validationError!,
              tone: AffluenaBannerTone.warning,
            ),
          ],
          if (state.actionError != null) ...[
            const SizedBox(height: AffluenaSpacing.space4),
            AffluenaBanner.error(
              state.actionError!,
              onRetry: () => _submit(state),
            ),
          ],
          const SizedBox(height: AffluenaSpacing.space5),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              key: const Key('transaction-create-submit-button'),
              onPressed: state.isSaving ? null : () => _submit(state),
              icon: const Icon(Icons.check),
              label: Text(
                state.isSaving ? 'Menyimpan...' : 'Simpan transaksi',
                style: textTheme.labelLarge,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _onTypeChanged(TransactionType type) {
    if (_type == type) return;
    setState(() {
      _type = type;
      _categoryId = null;
      if (!_isTransfer) _toWalletId = null;
      if (!_isAdjustment) _decrease = false;
      _clearErrors();
    });
  }

  void _clearErrors() {
    if (_validationError == null &&
        ref.read(transactionCreateControllerProvider).actionError == null) {
      return;
    }
    setState(() => _validationError = null);
    ref.read(transactionCreateControllerProvider.notifier).clearActionError();
  }

  Future<void> _selectWallet() async {
    final state = ref.read(transactionCreateControllerProvider);
    final selected = await showLookupSelectorSheet<String>(
      context: context,
      title: _isTransfer ? 'Dari dompet' : 'Dompet',
      searchHint: 'Cari dompet',
      selectedValue: _walletId,
      options: [
        for (final wallet in state.wallets)
          LookupSelectorOption<String>(
            value: wallet.id,
            label: wallet.name,
            subtitle: wallet.type.name,
            icon: Icons.account_balance_wallet_outlined,
          ),
      ],
    );
    if (!mounted || selected == null) return;
    setState(() {
      _walletId = selected;
      if (_toWalletId == selected) _toWalletId = null;
      _clearErrors();
    });
  }

  Future<void> _selectToWallet() async {
    final state = ref.read(transactionCreateControllerProvider);
    final selected = await showLookupSelectorSheet<String>(
      context: context,
      title: 'Ke dompet',
      searchHint: 'Cari dompet',
      selectedValue: _toWalletId,
      options: [
        for (final wallet in state.wallets)
          if (wallet.id != _walletId)
            LookupSelectorOption<String>(
              value: wallet.id,
              label: wallet.name,
              subtitle: wallet.type.name,
              icon: Icons.swap_horiz_rounded,
            ),
      ],
    );
    if (!mounted || selected == null) return;
    setState(() {
      _toWalletId = selected;
      _clearErrors();
    });
  }

  Future<void> _selectCategory(List<Category> categories) async {
    final selected = await showCategoryTreePicker(
      context: context,
      title: 'Kategori',
      selectedId: _categoryId,
      onMutated: () =>
          ref.read(transactionCreateControllerProvider.notifier).load(),
      categories: [
        for (final category in categories)
          CategoryTreeEntry.fromCategory(category),
      ],
    );
    if (!mounted || selected == null || selected.isEmpty) return;
    setState(() {
      _categoryId = selected;
      _clearErrors();
    });
  }

  Future<void> _submit(TransactionCreateState state) async {
    final error = _validate();
    if (error != null) {
      setState(() => _validationError = error);
      return;
    }

    final note = _noteController.text.trim();
    final amount = _amountMinor!;
    final signed = _isAdjustment && _decrease ? -amount : amount;
    final request = TransactionRequest(
      type: _type,
      walletId: _walletId!,
      toWalletId: _isTransfer ? _toWalletId : null,
      categoryId: _needsCategory ? _categoryId : null,
      amountMinor: signed,
      transactionAt: _transactionAt(_date),
      note: note.isEmpty ? null : note,
      tagIds: _tagId == null ? const [] : [_tagId!],
    );

    final created = await ref
        .read(transactionCreateControllerProvider.notifier)
        .create(request);
    if (!mounted || !created) return;
    context.pop();
  }

  String? _validate() {
    if (_walletId == null) {
      return _isTransfer ? 'Dompet asal wajib diisi.' : 'Dompet wajib diisi.';
    }
    if (!_isAdjustment && (_amountMinor == null || _amountMinor! <= 0)) {
      return 'Masukkan jumlah lebih dari nol.';
    }
    if (_isAdjustment && (_amountMinor == null || _amountMinor! == 0)) {
      return 'Masukkan jumlah lebih dari nol.';
    }
    if (_isTransfer) {
      if (_toWalletId == null) return 'Dompet tujuan wajib diisi.';
      if (_toWalletId == _walletId) {
        return 'Dompet tujuan harus berbeda dari dompet asal.';
      }
    }
    if (_needsCategory && _categoryId == null) {
      return 'Kategori wajib diisi.';
    }
    return null;
  }

  static String _transactionAt(DateTime dateTime) {
    // Preserve the chosen time-of-day; send as a UTC RFC3339 instant.
    return dateTime.toUtc().toIso8601String();
  }
}

class _Intro extends StatelessWidget {
  const _Intro();

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Text(
      'Catat pemasukan, pengeluaran, transfer, atau penyesuaian saldo.',
      style: textTheme.bodySmall,
    );
  }
}

class _TypeChips extends StatelessWidget {
  const _TypeChips({
    required this.selected,
    required this.enabled,
    required this.onChanged,
  });

  final TransactionType selected;
  final bool enabled;
  final ValueChanged<TransactionType> onChanged;

  @override
  Widget build(BuildContext context) {
    return AffluenaChipBar(
      chips: [
        for (final type in TransactionType.values)
          AffluenaChoiceChip(
            key: Key('transaction-create-type-${type.apiValue}'),
            label: _typeLabel(type),
            selected: selected == type,
            onSelected: enabled ? () => onChanged(type) : null,
          ),
      ],
    );
  }
}

class _TagChips extends StatelessWidget {
  const _TagChips({
    required this.tags,
    required this.selectedTagId,
    required this.enabled,
    required this.onChanged,
  });

  final List<Tag> tags;
  final String? selectedTagId;
  final bool enabled;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    return AffluenaChipBar(
      chips: [
        AffluenaChoiceChip(
          key: const Key('transaction-create-tag-none'),
          label: 'Tanpa tag',
          selected: selectedTagId == null,
          onSelected: enabled ? () => onChanged(null) : null,
        ),
        for (final tag in tags)
          AffluenaChoiceChip(
            key: Key('transaction-create-tag-${tag.id}'),
            label: tagLabel(tag.name),
            selected: selectedTagId == tag.id,
            onSelected: enabled ? () => onChanged(tag.id) : null,
          ),
      ],
    );
  }
}

class _TransactionCreateLoading extends StatelessWidget {
  const _TransactionCreateLoading();

  @override
  Widget build(BuildContext context) {
    return DrillInScaffold(
      title: 'Transaksi baru',
      body: ListView(
        padding: AffluenaInsets.screen,
        children: [
          const SizedBox(height: AffluenaSpacing.space5),
          Wrap(
            spacing: AffluenaSpacing.space2,
            runSpacing: AffluenaSpacing.space2,
            children: const [
              AffluenaSkeleton(
                width: 84,
                height: 32,
                radius: AffluenaRadii.pill,
              ),
              AffluenaSkeleton(
                width: 92,
                height: 32,
                radius: AffluenaRadii.pill,
              ),
              AffluenaSkeleton(
                width: 96,
                height: 32,
                radius: AffluenaRadii.pill,
              ),
              AffluenaSkeleton(
                width: 110,
                height: 32,
                radius: AffluenaRadii.pill,
              ),
            ],
          ),
          const SizedBox(height: AffluenaSpacing.space5),
          AffluenaCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: const [
                AffluenaSkeleton(height: 48),
                SizedBox(height: AffluenaSpacing.space4),
                AffluenaSkeleton(height: 48),
                SizedBox(height: AffluenaSpacing.space4),
                AffluenaSkeleton(height: 48),
                SizedBox(height: AffluenaSpacing.space4),
                AffluenaSkeleton(height: 48),
              ],
            ),
          ),
          const SizedBox(height: AffluenaSpacing.space5),
          const AffluenaSkeleton(height: 48),
        ],
      ),
    );
  }
}

class _TransactionCreateLoadError extends StatelessWidget {
  const _TransactionCreateLoadError({required this.onRetry});

  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return DrillInScaffold(
      title: 'Transaksi baru',
      body: ListView(
        padding: AffluenaInsets.screen,
        children: [
          AffluenaBanner.error(
            'Kami tidak dapat memuat dompet dan kategori.',
            onRetry: onRetry,
          ),
        ],
      ),
    );
  }
}

String _typeLabel(TransactionType type) {
  return switch (type) {
    TransactionType.income => 'Pemasukan',
    TransactionType.expense => 'Pengeluaran',
    TransactionType.transfer => 'Transfer',
    TransactionType.adjustment => 'Penyesuaian',
  };
}
