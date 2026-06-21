import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/affluena_theme.dart';
import '../../../core/formatters/money_formatter.dart';
import '../../dashboard/application/dashboard_home_controller.dart';
import '../../categories/data/category_models.dart';
import '../../tags/data/tag_models.dart';
import '../../transactions/application/transactions_controller.dart';
import '../../transactions/data/transaction_models.dart';
import '../../transactions/data/transaction_repository.dart';
import '../../wallets/data/wallet_models.dart';
import '../application/quick_entry_lookup_controller.dart';
import '../data/quick_entry_models.dart';
import '../data/quick_entry_repository.dart';
import '../../shared/presentation/widgets/affluena_card.dart';
import '../../shared/presentation/widgets/lookup_selector_sheet.dart';
import '../../shared/presentation/widgets/selector_row.dart';

class QuickEntryScreen extends ConsumerStatefulWidget {
  const QuickEntryScreen({super.key});

  static const path = '/quick-entry';

  @override
  ConsumerState<QuickEntryScreen> createState() => _QuickEntryScreenState();
}

class _QuickEntryScreenState extends ConsumerState<QuickEntryScreen> {
  late final TextEditingController _amountController;
  late final TextEditingController _noteController;
  TransactionType _type = TransactionType.expense;
  String? _selectedWalletId;
  String? _selectedToWalletId;
  String? _selectedCategoryId;
  String? _selectedTagId;
  bool _isSaving = false;
  String? _message;
  String? _error;

  @override
  void initState() {
    super.initState();
    _amountController = TextEditingController(text: '125000');
    _noteController = TextEditingController(text: 'Lunch meeting');
  }

  @override
  void dispose() {
    _amountController.dispose();
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
          amountController: _amountController,
          noteController: _noteController,
          selectedWalletId: _selectedWalletId,
          selectedToWalletId: _selectedToWalletId,
          selectedCategoryId: _selectedCategoryId,
          selectedTagId: _selectedTagId,
          isSaving: _isSaving,
          message: _message,
          error: _error,
          canSave: _canSave(lookup),
          onTypeChanged: _setType,
          onSelectWallet: _selectWallet,
          onSelectToWallet: _selectToWallet,
          onSelectCategory: _selectCategory,
          onSelectTag: _selectTag,
          onChanged: () => setState(() {
            _message = null;
            _error = null;
          }),
          onSave: () => _saveTransaction(lookup),
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
    if (lookup.tagById(_selectedTagId) == null) {
      _selectedTagId = lookup.defaultTag?.id;
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
      title: 'Select wallet',
      selectedValue: _selectedWalletId,
      options: [
        for (final wallet in lookup.wallets)
          LookupSelectorOption(
            value: wallet.id,
            label: wallet.name,
            subtitle: _walletTypeLabel(wallet.type),
            icon: _walletIcon(wallet.type),
          ),
      ],
    );
    if (selected != null) setState(() => _selectedWalletId = selected);
  }

  Future<void> _selectToWallet(QuickEntryLookup lookup) async {
    final selected = await showLookupSelectorSheet<String>(
      context: context,
      title: 'Select destination',
      selectedValue: _selectedToWalletId,
      options: [
        for (final wallet in lookup.wallets)
          if (wallet.id != _selectedWalletId)
            LookupSelectorOption(
              value: wallet.id,
              label: wallet.name,
              subtitle: _walletTypeLabel(wallet.type),
              icon: _walletIcon(wallet.type),
            ),
      ],
    );
    if (selected != null) setState(() => _selectedToWalletId = selected);
  }

  Future<void> _selectCategory(QuickEntryLookup lookup) async {
    final categories = lookup.categoriesFor(_type);
    final selected = await showLookupSelectorSheet<String>(
      context: context,
      title: 'Select category',
      selectedValue: _selectedCategoryId,
      options: [
        for (final category in categories)
          LookupSelectorOption(
            value: category.id,
            label: category.name,
            subtitle: _categoryTypeLabel(category.type),
            icon: Icons.restaurant_outlined,
          ),
      ],
    );
    if (selected != null) setState(() => _selectedCategoryId = selected);
  }

  Future<void> _selectTag(QuickEntryLookup lookup) async {
    final selected = await showLookupSelectorSheet<String>(
      context: context,
      title: 'Select tag',
      selectedValue: _selectedTagId,
      options: [
        for (final tag in lookup.tags)
          LookupSelectorOption(
            value: tag.id,
            label: _tagLabel(tag),
            icon: Icons.sell_outlined,
          ),
      ],
    );
    if (selected != null) setState(() => _selectedTagId = selected);
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

  int get _amountMinor {
    final digits = _amountController.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.isEmpty) return 0;
    return int.tryParse(digits) ?? 0;
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
      transactionAt: DateTime.now().toUtc().toIso8601String(),
      note: _noteController.text.trim().isEmpty
          ? null
          : _noteController.text.trim(),
      tagIds: _selectedTagId == null ? const [] : [_selectedTagId!],
    );

    try {
      await ref.read(transactionRepositoryProvider).createTransaction(request);
      _invalidateMoneySurfaces();
      if (!mounted) return;
      setState(() {
        _isSaving = false;
        _message = 'Transaction saved.';
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isSaving = false;
        _error = 'Transaction could not be saved.';
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
              transactionAt: DateTime.now().toUtc().toIso8601String(),
            ),
          );
      _invalidateMoneySurfaces();
      if (!mounted) return;
      setState(() {
        _isSaving = false;
        _message = '${template.name} recorded.';
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isSaving = false;
        _error = 'Template could not be executed.';
      });
    }
  }

  void _invalidateMoneySurfaces() {
    ref.invalidate(dashboardHomeProvider);
    ref.invalidate(transactionsControllerProvider);
  }
}

class _QuickEntryContent extends StatelessWidget {
  const _QuickEntryContent({
    required this.lookup,
    required this.type,
    required this.amountController,
    required this.noteController,
    required this.selectedWalletId,
    required this.selectedToWalletId,
    required this.selectedCategoryId,
    required this.selectedTagId,
    required this.isSaving,
    required this.message,
    required this.error,
    required this.canSave,
    required this.onTypeChanged,
    required this.onSelectWallet,
    required this.onSelectToWallet,
    required this.onSelectCategory,
    required this.onSelectTag,
    required this.onChanged,
    required this.onSave,
    required this.onExecuteTemplate,
  });

  final QuickEntryLookup lookup;
  final TransactionType type;
  final TextEditingController amountController;
  final TextEditingController noteController;
  final String? selectedWalletId;
  final String? selectedToWalletId;
  final String? selectedCategoryId;
  final String? selectedTagId;
  final bool isSaving;
  final String? message;
  final String? error;
  final bool canSave;
  final ValueChanged<TransactionType> onTypeChanged;
  final ValueChanged<QuickEntryLookup> onSelectWallet;
  final ValueChanged<QuickEntryLookup> onSelectToWallet;
  final ValueChanged<QuickEntryLookup> onSelectCategory;
  final ValueChanged<QuickEntryLookup> onSelectTag;
  final VoidCallback onChanged;
  final VoidCallback onSave;
  final ValueChanged<QuickEntryTemplate> onExecuteTemplate;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final selectedWallet = lookup.walletById(selectedWalletId);
    final selectedToWallet = lookup.walletById(selectedToWalletId);
    final selectedCategory = lookup.categoryById(type, selectedCategoryId);
    final selectedTag = lookup.tagById(selectedTagId);
    final categories = lookup.categoriesFor(type);
    final amountMinor = _parseAmount(amountController.text);

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(
          AffluenaSpacing.space5,
          AffluenaSpacing.space4,
          AffluenaSpacing.space5,
          AffluenaSpacing.space8,
        ),
        children: [
          Text('Quick entry', style: textTheme.headlineMedium),
          const SizedBox(height: AffluenaSpacing.space2),
          Text(
            'Record daily money movement without turning it into paperwork.',
            style: textTheme.bodySmall,
          ),
          const SizedBox(height: AffluenaSpacing.space6),
          SegmentedButton<TransactionType>(
            segments: const [
              ButtonSegment(
                value: TransactionType.expense,
                label: Text('Expense'),
              ),
              ButtonSegment(
                value: TransactionType.income,
                label: Text('Income'),
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
          AffluenaCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  key: const Key('quick-entry-amount-field'),
                  controller: amountController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Amount'),
                  onChanged: (_) => onChanged(),
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
                  label: 'Wallet',
                  value:
                      selectedWallet?.name ??
                      'Add a wallet before recording transactions.',
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
                    label: 'To wallet',
                    value:
                        selectedToWallet?.name ?? 'Choose destination wallet',
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
                    label: 'Category',
                    value:
                        selectedCategory?.name ?? _categoryMissingMessage(type),
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
                  label: 'Tags',
                  value: selectedTag == null
                      ? 'Optional'
                      : _tagLabel(selectedTag),
                  icon: Icons.sell_outlined,
                  enabled: lookup.tags.isNotEmpty,
                  onTap: lookup.tags.isEmpty ? null : () => onSelectTag(lookup),
                ),
                const Divider(height: 1),
                TextField(
                  key: const Key('quick-entry-note-field'),
                  controller: noteController,
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.notes_outlined),
                    labelText: 'Note',
                  ),
                  onChanged: (_) => onChanged(),
                ),
              ],
            ),
          ),
          if (message != null || error != null) ...[
            const SizedBox(height: AffluenaSpacing.space4),
            AffluenaCard(
              backgroundColor: message != null
                  ? AffluenaColors.forestSoft
                  : AffluenaColors.surfaceTintSoft,
              child: Text(message ?? error!),
            ),
          ],
          const SizedBox(height: AffluenaSpacing.space6),
          Text('Saved templates', style: textTheme.titleMedium),
          const SizedBox(height: AffluenaSpacing.space3),
          lookup.templates.isEmpty
              ? const AffluenaCard(child: Text('No saved templates yet.'))
              : Wrap(
                  spacing: AffluenaSpacing.space3,
                  runSpacing: AffluenaSpacing.space3,
                  children: [
                    for (final template in lookup.templates)
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
            child: Text(isSaving ? 'Saving...' : 'Save transaction'),
          ),
        ],
      ),
    );
  }
}

class _QuickEntryLoading extends StatelessWidget {
  const _QuickEntryLoading();

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
          Text('Quick entry', style: textTheme.headlineMedium),
          const SizedBox(height: AffluenaSpacing.space6),
          const AffluenaCard(
            child: SizedBox(
              height: 168,
              child: Center(child: Text('Loading quick entry')),
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickEntryError extends StatelessWidget {
  const _QuickEntryError({required this.onRetry});

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
          Text('Quick entry unavailable', style: textTheme.headlineMedium),
          const SizedBox(height: AffluenaSpacing.space5),
          AffluenaCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('We could not load wallets, categories, and tags.'),
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
      borderRadius: BorderRadius.circular(18),
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

int _parseAmount(String value) {
  final digits = value.replaceAll(RegExp(r'[^0-9]'), '');
  if (digits.isEmpty) return 0;
  return int.tryParse(digits) ?? 0;
}

String _categoryMissingMessage(TransactionType type) {
  return switch (type) {
    TransactionType.income => 'Add an income category before saving.',
    TransactionType.expense => 'Add an expense category before saving.',
    TransactionType.transfer => 'Choose destination wallet',
    TransactionType.adjustment => 'Add a category before saving.',
  };
}

String _categoryTypeLabel(CategoryType type) {
  return switch (type) {
    CategoryType.income => 'Income',
    CategoryType.expense => 'Expense',
  };
}

String _tagLabel(Tag tag) {
  return tag.name.startsWith('#') ? tag.name : '#${tag.name}';
}

String _walletTypeLabel(WalletType type) {
  return switch (type) {
    WalletType.cash => 'Cash',
    WalletType.bank => 'Bank',
    WalletType.eWallet => 'E-wallet',
    WalletType.investment => 'Investment',
    WalletType.goal => 'Goal',
  };
}

IconData _walletIcon(WalletType type) {
  return switch (type) {
    WalletType.cash => Icons.payments_outlined,
    WalletType.bank => Icons.account_balance_outlined,
    WalletType.eWallet => Icons.phone_iphone_outlined,
    WalletType.investment => Icons.trending_up,
    WalletType.goal => Icons.flag_outlined,
  };
}
