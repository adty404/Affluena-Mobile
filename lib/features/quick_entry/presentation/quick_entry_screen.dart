import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/affluena_theme.dart';
import '../../../core/formatters/money_formatter.dart';
import '../../../core/formatters/tag_formatter.dart';
import '../../shared/presentation/widgets/affluena_banner.dart';
import '../../shared/presentation/widgets/affluena_card.dart';
import '../../shared/presentation/widgets/affluena_skeleton.dart';
import '../../shared/presentation/widgets/category_tree_picker_sheet.dart';
import '../../shared/presentation/widgets/date_time_picker_field.dart';
import '../../shared/presentation/widgets/drill_in_scaffold.dart';
import '../../shared/presentation/widgets/lookup_selector_sheet.dart';
import '../../shared/presentation/widgets/money_input.dart';
import '../../shared/presentation/widgets/selector_row.dart';
import '../../tags/data/tag_models.dart';
import '../../transactions/application/transactions_controller.dart';
import '../../transactions/data/transaction_models.dart';
import '../../transactions/data/transaction_repository.dart';
import '../../wallets/presentation/wallet_format.dart';
import '../application/quick_entry_lookup_controller.dart';
import '../data/quick_entry_models.dart';
import '../data/quick_entry_repository.dart';
import 'quick_entry_templates_screen.dart';
import 'tag_multi_select_sheet.dart';

class QuickEntryScreen extends ConsumerStatefulWidget {
  const QuickEntryScreen({super.key});

  static const path = '/quick-entry';

  @override
  ConsumerState<QuickEntryScreen> createState() => _QuickEntryScreenState();
}

class _QuickEntryScreenState extends ConsumerState<QuickEntryScreen> {
  late final TextEditingController _noteController;
  int _amountMinor = 0;
  TransactionType _type = TransactionType.expense;
  String? _selectedWalletId;
  String? _selectedToWalletId;
  String? _selectedCategoryId;
  List<String> _selectedTagIds = const [];
  DateTime _dateTime = DateTime.now();
  bool _isSaving = false;
  String? _message;
  String? _error;

  @override
  void initState() {
    super.initState();
    _noteController = TextEditingController();
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final lookup = ref.watch(quickEntryLookupProvider);

    return lookup.when(
      skipLoadingOnReload: true,
      loading: () => const _QuickEntryLoading(),
      error: (error, stackTrace) => _QuickEntryError(
        onRetry: () => ref.invalidate(quickEntryLookupProvider),
      ),
      data: (lookup) {
        _syncDefaults(lookup);
        return _QuickEntryContent(
          lookup: lookup,
          type: _type,
          amountMinor: _amountMinor,
          noteController: _noteController,
          selectedWalletId: _selectedWalletId,
          selectedToWalletId: _selectedToWalletId,
          selectedCategoryId: _selectedCategoryId,
          selectedTagIds: _selectedTagIds,
          dateTime: _dateTime,
          isSaving: _isSaving,
          message: _message,
          error: _error,
          canSave: _canSave(lookup),
          onTypeChanged: _setType,
          onDateTimeChanged: (value) => setState(() {
            _dateTime = value;
            _message = null;
            _error = null;
          }),
          onAmountChanged: (value) => setState(() {
            _amountMinor = value ?? 0;
            _message = null;
            _error = null;
          }),
          onSelectWallet: _selectWallet,
          onSelectToWallet: _selectToWallet,
          onSelectCategory: _selectCategory,
          onSelectTags: _selectTags,
          onChanged: () => setState(() {
            _message = null;
            _error = null;
          }),
          onSave: () => _saveTransaction(lookup),
          onDismissMessage: () => setState(() => _message = null),
          onRetrySave: () => _saveTransaction(lookup),
          onExecuteTemplate: _executeTemplate,
        );
      },
    );
  }

  void _syncDefaults(QuickEntryLookup lookup) {
    if (lookup.walletById(_selectedWalletId) == null) {
      _selectedWalletId = lookup.defaultWallet?.id;
    }
    if (_type == TransactionType.transfer) {
      if (_selectedToWalletId == _selectedWalletId ||
          lookup.walletById(_selectedToWalletId) == null) {
        _selectedToWalletId = null;
      }
      _selectedCategoryId = null;
    } else {
      if (lookup.categoryById(_type, _selectedCategoryId) == null) {
        _selectedCategoryId = lookup.defaultCategoryFor(_type)?.id;
      }
      _selectedToWalletId = null;
    }
    // Tags are optional — never auto-select one. Just drop any ids that no
    // longer exist in the available tag list.
    final validTagIds = _selectedTagIds
        .where((id) => lookup.tagById(id) != null)
        .toList(growable: false);
    if (validTagIds.length != _selectedTagIds.length) {
      _selectedTagIds = validTagIds;
    }
  }

  void _setType(TransactionType type) {
    setState(() {
      _type = type;
      _selectedCategoryId = null;
      _selectedToWalletId = null;
      _message = null;
      _error = null;
    });
  }

  Future<void> _selectWallet(QuickEntryLookup lookup) async {
    final selected = await showLookupSelectorSheet<String>(
      context: context,
      title: 'Pilih dompet',
      searchHint: 'Cari dompet',
      selectedValue: _selectedWalletId,
      options: [
        for (final wallet in lookup.wallets)
          LookupSelectorOption(
            value: wallet.id,
            label: wallet.name,
            subtitle: walletTypeLabel(wallet.type),
            icon: walletIcon(wallet.type),
          ),
      ],
    );
    if (selected != null) setState(() => _selectedWalletId = selected);
  }

  Future<void> _selectToWallet(QuickEntryLookup lookup) async {
    final selected = await showLookupSelectorSheet<String>(
      context: context,
      title: 'Pilih tujuan',
      searchHint: 'Cari dompet',
      selectedValue: _selectedToWalletId,
      options: [
        for (final wallet in lookup.wallets)
          if (wallet.id != _selectedWalletId)
            LookupSelectorOption(
              value: wallet.id,
              label: wallet.name,
              subtitle: walletTypeLabel(wallet.type),
              icon: walletIcon(wallet.type),
            ),
      ],
    );
    if (selected != null) setState(() => _selectedToWalletId = selected);
  }

  Future<void> _selectCategory(QuickEntryLookup lookup) async {
    final categories = lookup.categoriesFor(_type);
    final selected = await showCategoryTreePicker(
      context: context,
      title: 'Pilih kategori',
      selectedId: _selectedCategoryId,
      onMutated: () => ref.refresh(quickEntryLookupProvider.future),
      categories: [
        for (final category in categories)
          CategoryTreeEntry.fromCategory(category),
      ],
    );
    if (selected != null && selected.isNotEmpty) {
      setState(() => _selectedCategoryId = selected);
    }
  }

  Future<void> _selectTags(QuickEntryLookup lookup) async {
    final selected = await showTagMultiSelectSheet(
      context: context,
      tags: lookup.tags,
      selectedIds: _selectedTagIds,
    );
    if (selected != null) {
      setState(() => _selectedTagIds = selected);
    }
  }

  bool _canSave(QuickEntryLookup lookup) {
    if (_isSaving || _amountMinor <= 0 || _selectedWalletId == null) {
      return false;
    }
    if (_type == TransactionType.transfer) {
      return _selectedToWalletId != null &&
          _selectedToWalletId != _selectedWalletId;
    }
    return _selectedCategoryId != null;
  }

  Future<void> _saveTransaction(QuickEntryLookup lookup) async {
    if (!_canSave(lookup)) return;
    setState(() {
      _isSaving = true;
      _message = null;
      _error = null;
    });

    final request = TransactionRequest(
      type: _type,
      walletId: _selectedWalletId!,
      toWalletId: _type == TransactionType.transfer
          ? _selectedToWalletId
          : null,
      categoryId: _type == TransactionType.transfer
          ? null
          : _selectedCategoryId,
      amountMinor: _amountMinor,
      transactionAt: _dateTime.toUtc().toIso8601String(),
      note: _noteController.text.trim().isEmpty
          ? null
          : _noteController.text.trim(),
      tagIds: _selectedTagIds,
    );

    try {
      await ref.read(transactionRepositoryProvider).createTransaction(request);
      _invalidateMoneySurfaces();
      if (!mounted) return;
      setState(() {
        _isSaving = false;
        _message = 'Transaksi tersimpan.';
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isSaving = false;
        _error = 'Transaksi tidak bisa disimpan.';
      });
    }
  }

  Future<void> _executeTemplate(QuickEntryTemplate template) async {
    if (_isSaving) return;
    setState(() {
      _isSaving = true;
      _message = null;
      _error = null;
    });

    try {
      await ref
          .read(quickEntryRepositoryProvider)
          .executeTemplate(
            template.id,
            ExecuteQuickEntryRequest(
              transactionAt: _dateTime.toUtc().toIso8601String(),
            ),
          );
      _invalidateMoneySurfaces();
      if (!mounted) return;
      setState(() {
        _isSaving = false;
        _message = '${template.name} tercatat.';
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isSaving = false;
        _error = 'Template tidak bisa dijalankan.';
      });
    }
  }

  void _invalidateMoneySurfaces() {
    ref.invalidate(transactionsControllerProvider);
  }
}

class _QuickEntryContent extends StatelessWidget {
  const _QuickEntryContent({
    required this.lookup,
    required this.type,
    required this.amountMinor,
    required this.noteController,
    required this.selectedWalletId,
    required this.selectedToWalletId,
    required this.selectedCategoryId,
    required this.selectedTagIds,
    required this.dateTime,
    required this.isSaving,
    required this.message,
    required this.error,
    required this.canSave,
    required this.onTypeChanged,
    required this.onDateTimeChanged,
    required this.onAmountChanged,
    required this.onSelectWallet,
    required this.onSelectToWallet,
    required this.onSelectCategory,
    required this.onSelectTags,
    required this.onChanged,
    required this.onSave,
    required this.onDismissMessage,
    required this.onRetrySave,
    required this.onExecuteTemplate,
  });

  final QuickEntryLookup lookup;
  final TransactionType type;
  final int amountMinor;
  final TextEditingController noteController;
  final String? selectedWalletId;
  final String? selectedToWalletId;
  final String? selectedCategoryId;
  final List<String> selectedTagIds;
  final DateTime dateTime;
  final bool isSaving;
  final String? message;
  final String? error;
  final bool canSave;
  final ValueChanged<TransactionType> onTypeChanged;
  final ValueChanged<DateTime> onDateTimeChanged;
  final ValueChanged<int?> onAmountChanged;
  final ValueChanged<QuickEntryLookup> onSelectWallet;
  final ValueChanged<QuickEntryLookup> onSelectToWallet;
  final ValueChanged<QuickEntryLookup> onSelectCategory;
  final ValueChanged<QuickEntryLookup> onSelectTags;
  final VoidCallback onChanged;
  final VoidCallback onSave;
  final VoidCallback onDismissMessage;
  final VoidCallback onRetrySave;
  final ValueChanged<QuickEntryTemplate> onExecuteTemplate;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colors = context.affluenaColors;
    final selectedWallet = lookup.walletById(selectedWalletId);
    final selectedToWallet = lookup.walletById(selectedToWalletId);
    final selectedCategory = lookup.categoryById(type, selectedCategoryId);
    final selectedTags = [
      for (final id in selectedTagIds) lookup.tagById(id),
    ].whereType<Tag>().toList(growable: false);
    final tagSummary = selectedTags.isEmpty
        ? 'Opsional — ketuk untuk menambah'
        : selectedTags.map((t) => tagLabel(t.name)).join('  ');
    final categories = lookup.categoriesFor(type);
    // Templates are scoped to the active tab so an expense template never shows
    // (or fires) while the Income/Transfer tab is selected.
    final typeTemplates = lookup.templates
        .where((template) => template.type == type)
        .toList(growable: false);
    final setupGuidance = _lookupGuidanceMessage(lookup, type);

    return DrillInScaffold(
      title: 'Catat cepat',
      body: SafeArea(
        child: ListView(
          padding: AffluenaInsets.screen,
          children: [
            Text(
              'Catat pergerakan uang harian tanpa ribet.',
              style: textTheme.bodySmall,
            ),
            const SizedBox(height: AffluenaSpacing.space6),
            SegmentedButton<TransactionType>(
              segments: const [
                ButtonSegment(
                  value: TransactionType.expense,
                  label: Text('Pengeluaran'),
                ),
                ButtonSegment(
                  value: TransactionType.income,
                  label: Text('Pemasukan'),
                ),
                ButtonSegment(
                  value: TransactionType.transfer,
                  label: Text('Transfer'),
                ),
              ],
              selected: {type},
              onSelectionChanged: (selection) => onTypeChanged(selection.first),
            ),
            const SizedBox(height: AffluenaSpacing.space5),
            if (setupGuidance != null) ...[
              AffluenaCard(
                backgroundColor: colors.surfaceTintSoft,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.info_outline, color: colors.forest, size: 20),
                    const SizedBox(width: AffluenaSpacing.space3),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Selesaikan persiapan dulu',
                            style: textTheme.titleSmall,
                          ),
                          const SizedBox(height: AffluenaSpacing.space1),
                          Text(setupGuidance, style: textTheme.bodySmall),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AffluenaSpacing.space3),
            ],
            AffluenaCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  MoneyInput(
                    key: const Key('quick-entry-amount-field'),
                    label: 'Jumlah',
                    initialValue: amountMinor,
                    enabled: !isSaving,
                    onChanged: onAmountChanged,
                  ),
                  const SizedBox(height: AffluenaSpacing.space2),
                  Text(
                    MoneyFormatter.idr(amountMinor),
                    style: textTheme.displaySmall,
                  ),
                  const SizedBox(height: AffluenaSpacing.space4),
                  const Divider(height: 1),
                  SelectorRow(
                    key: const Key('quick-entry-wallet-row'),
                    label: 'Dompet',
                    value:
                        selectedWallet?.name ??
                        'Tambah dompet dulu sebelum mencatat transaksi.',
                    icon: Icons.account_balance_wallet_outlined,
                    enabled: lookup.wallets.isNotEmpty,
                    onTap: lookup.wallets.isEmpty
                        ? null
                        : () => onSelectWallet(lookup),
                  ),
                  const Divider(height: 1),
                  if (type == TransactionType.transfer) ...[
                    SelectorRow(
                      key: const Key('quick-entry-to-wallet-row'),
                      label: 'Ke dompet',
                      value: selectedToWallet?.name ?? 'Pilih dompet tujuan',
                      icon: Icons.swap_horiz_rounded,
                      enabled: lookup.wallets.length > 1,
                      onTap: lookup.wallets.length <= 1
                          ? null
                          : () => onSelectToWallet(lookup),
                    ),
                    const Divider(height: 1),
                  ] else ...[
                    SelectorRow(
                      key: const Key('quick-entry-category-row'),
                      label: 'Kategori',
                      value:
                          selectedCategory?.name ??
                          _categoryMissingMessage(type),
                      icon: Icons.restaurant_outlined,
                      enabled: categories.isNotEmpty,
                      onTap: categories.isEmpty
                          ? null
                          : () => onSelectCategory(lookup),
                    ),
                    const Divider(height: 1),
                  ],
                  SelectorRow(
                    key: const Key('quick-entry-tags-row'),
                    label: 'Tag',
                    value: tagSummary,
                    icon: Icons.sell_outlined,
                    enabled: lookup.tags.isNotEmpty,
                    onTap: lookup.tags.isEmpty
                        ? null
                        : () => onSelectTags(lookup),
                  ),
                  const Divider(height: 1),
                  DateTimePickerField(
                    key: const Key('quick-entry-datetime-field'),
                    label: 'Tanggal & waktu',
                    value: dateTime,
                    enabled: !isSaving,
                    onChanged: onDateTimeChanged,
                  ),
                  const SizedBox(height: AffluenaSpacing.space4),
                  TextField(
                    key: const Key('quick-entry-note-field'),
                    controller: noteController,
                    decoration: const InputDecoration(
                      prefixIcon: Icon(Icons.notes_outlined),
                      labelText: 'Catatan',
                      helperText: 'Opsional',
                    ),
                    onChanged: (_) => onChanged(),
                  ),
                ],
              ),
            ),
            if (error != null) ...[
              const SizedBox(height: AffluenaSpacing.space4),
              AffluenaBanner.error(
                error!,
                onRetry: isSaving ? null : onRetrySave,
              ),
            ] else if (message != null) ...[
              const SizedBox(height: AffluenaSpacing.space4),
              AffluenaBanner.success(message!, onDismiss: onDismissMessage),
            ],
            const SizedBox(height: AffluenaSpacing.space6),
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Template ${_typeLabel(type)} tersimpan',
                    style: textTheme.titleMedium,
                  ),
                ),
                TextButton(
                  onPressed: () => context.push(QuickEntryTemplatesScreen.path),
                  child: const Text('Kelola'),
                ),
              ],
            ),
            const SizedBox(height: AffluenaSpacing.space3),
            typeTemplates.isEmpty
                ? _SavedTemplatesEmpty(
                    type: type,
                    onCreate: () =>
                        context.push(QuickEntryTemplatesScreen.path),
                  )
                : Wrap(
                    spacing: AffluenaSpacing.space3,
                    runSpacing: AffluenaSpacing.space3,
                    children: [
                      for (final template in typeTemplates)
                        _TemplateChip(
                          label: template.name,
                          amount: MoneyFormatter.idr(template.amountMinor),
                          onTap: isSaving
                              ? null
                              : () => onExecuteTemplate(template),
                        ),
                    ],
                  ),
            const SizedBox(height: AffluenaSpacing.space6),
            FilledButton(
              key: const Key('quick-entry-save-button'),
              onPressed: canSave ? onSave : null,
              child: Text(isSaving ? 'Menyimpan...' : 'Simpan transaksi'),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickEntryLoading extends StatelessWidget {
  const _QuickEntryLoading();

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return DrillInScaffold(
      title: 'Catat cepat',
      body: SafeArea(
        child: ListView(
          padding: AffluenaInsets.screen,
          children: [
            Text(
              'Catat pergerakan uang harian tanpa ribet.',
              style: textTheme.bodySmall,
            ),
            const SizedBox(height: AffluenaSpacing.space6),
            const AffluenaSkeleton(height: 40, radius: AffluenaRadii.pill),
            const SizedBox(height: AffluenaSpacing.space5),
            AffluenaCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  AffluenaSkeleton(height: 56, radius: AffluenaRadii.control),
                  SizedBox(height: AffluenaSpacing.space3),
                  AffluenaSkeleton.line(width: 160, height: 28),
                  SizedBox(height: AffluenaSpacing.space4),
                  AffluenaSkeleton(height: 52),
                  SizedBox(height: AffluenaSpacing.space3),
                  AffluenaSkeleton(height: 52),
                  SizedBox(height: AffluenaSpacing.space3),
                  AffluenaSkeleton(height: 52),
                ],
              ),
            ),
            const SizedBox(height: AffluenaSpacing.space6),
            const AffluenaSkeleton.line(width: 140, height: 16),
            const SizedBox(height: AffluenaSpacing.space3),
            Wrap(
              spacing: AffluenaSpacing.space3,
              runSpacing: AffluenaSpacing.space3,
              children: const [
                AffluenaSkeleton(
                  width: 120,
                  height: 64,
                  radius: AffluenaRadii.card,
                ),
                AffluenaSkeleton(
                  width: 120,
                  height: 64,
                  radius: AffluenaRadii.card,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickEntryError extends StatelessWidget {
  const _QuickEntryError({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return DrillInScaffold(
      title: 'Catat cepat',
      body: SafeArea(
        child: ListView(
          padding: AffluenaInsets.screen,
          children: [
            AffluenaBanner.error(
              'Kami tidak bisa memuat dompet, kategori, dan tag.',
              onRetry: onRetry,
            ),
          ],
        ),
      ),
    );
  }
}

class _SavedTemplatesEmpty extends StatelessWidget {
  const _SavedTemplatesEmpty({required this.type, required this.onCreate});

  final TransactionType type;
  final VoidCallback onCreate;

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
          Icon(Icons.bolt_outlined, color: colors.forest),
          const SizedBox(height: AffluenaSpacing.space3),
          Text(
            'Belum ada template ${_typeLabel(type)}',
            style: textTheme.titleMedium,
          ),
          const SizedBox(height: AffluenaSpacing.space1),
          Text(
            'Simpan entri ${_typeLabel(type)} berulang sekali — lalu catat di '
            'sini cukup dengan satu ketukan.',
            style: textTheme.bodySmall,
          ),
          const SizedBox(height: AffluenaSpacing.space4),
          FilledButton.icon(
            key: const Key('quick-entry-create-template-button'),
            onPressed: onCreate,
            icon: const Icon(Icons.add),
            label: const Text('Buat template'),
          ),
        ],
      ),
    );
  }
}

class _TemplateChip extends StatelessWidget {
  const _TemplateChip({required this.label, required this.amount, this.onTap});

  final String label;
  final String amount;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AffluenaRadii.control),
      child: AffluenaCard(
        padding: const EdgeInsets.symmetric(
          horizontal: AffluenaSpacing.space4,
          vertical: AffluenaSpacing.space3,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(label, style: textTheme.bodyLarge),
            const SizedBox(height: AffluenaSpacing.space1),
            Text(amount, style: textTheme.bodySmall),
          ],
        ),
      ),
    );
  }
}

String _categoryMissingMessage(TransactionType type) {
  return switch (type) {
    TransactionType.income =>
      'Tambah kategori pemasukan dulu sebelum menyimpan.',
    TransactionType.expense =>
      'Tambah kategori pengeluaran dulu sebelum menyimpan.',
    TransactionType.transfer => 'Pilih dompet tujuan',
    TransactionType.adjustment => 'Tambah kategori dulu sebelum menyimpan.',
  };
}

String? _lookupGuidanceMessage(QuickEntryLookup lookup, TransactionType type) {
  final needsWallet = lookup.wallets.isEmpty;
  final needsCategory =
      type != TransactionType.transfer && lookup.categoriesFor(type).isEmpty;
  final needsSecondWallet =
      type == TransactionType.transfer && lookup.wallets.length < 2;

  if (needsWallet && needsCategory) {
    final category = type == TransactionType.income
        ? 'pemasukan'
        : 'pengeluaran';
    return 'Tambah minimal satu dompet dan satu kategori $category dulu '
        'sebelum menyimpan.';
  }
  if (needsWallet) {
    return 'Tambah minimal satu dompet dulu sebelum menyimpan.';
  }
  if (needsCategory) {
    return _categoryMissingMessage(type);
  }
  if (needsSecondWallet) {
    return 'Tambah dompet lain dulu sebelum mencatat transfer.';
  }
  return null;
}

String _typeLabel(TransactionType type) {
  return switch (type) {
    TransactionType.income => 'pemasukan',
    TransactionType.expense => 'pengeluaran',
    TransactionType.transfer => 'transfer',
    TransactionType.adjustment => 'penyesuaian',
  };
}
