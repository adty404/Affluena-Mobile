import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/affluena_theme.dart';
import '../../tags/data/tag_models.dart';
import '../../wallets/data/wallet_models.dart';
import '../application/quick_entry_lookup_controller.dart';
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
  String? _selectedWalletId;
  String? _selectedCategoryId;
  String? _selectedTagId;

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
          selectedWalletId: _selectedWalletId,
          selectedCategoryId: _selectedCategoryId,
          selectedTagId: _selectedTagId,
          onSelectWallet: _selectWallet,
          onSelectCategory: _selectCategory,
          onSelectTag: _selectTag,
        );
      },
    );
  }

  void _syncDefaults(QuickEntryLookup lookup) {
    if (lookup.walletById(_selectedWalletId) == null) {
      _selectedWalletId = lookup.defaultWallet?.id;
    }
    if (lookup.categoryById(_selectedCategoryId) == null) {
      _selectedCategoryId = lookup.defaultExpenseCategory?.id;
    }
    if (lookup.tagById(_selectedTagId) == null) {
      _selectedTagId = lookup.defaultTag?.id;
    }
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

  Future<void> _selectCategory(QuickEntryLookup lookup) async {
    final selected = await showLookupSelectorSheet<String>(
      context: context,
      title: 'Select category',
      selectedValue: _selectedCategoryId,
      options: [
        for (final category in lookup.expenseCategories)
          LookupSelectorOption(
            value: category.id,
            label: category.name,
            subtitle: 'Expense',
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
}

class _QuickEntryContent extends StatelessWidget {
  const _QuickEntryContent({
    required this.lookup,
    required this.selectedWalletId,
    required this.selectedCategoryId,
    required this.selectedTagId,
    required this.onSelectWallet,
    required this.onSelectCategory,
    required this.onSelectTag,
  });

  final QuickEntryLookup lookup;
  final String? selectedWalletId;
  final String? selectedCategoryId;
  final String? selectedTagId;
  final ValueChanged<QuickEntryLookup> onSelectWallet;
  final ValueChanged<QuickEntryLookup> onSelectCategory;
  final ValueChanged<QuickEntryLookup> onSelectTag;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final selectedWallet = lookup.walletById(selectedWalletId);
    final selectedCategory = lookup.categoryById(selectedCategoryId);
    final selectedTag = lookup.tagById(selectedTagId);
    final canSave = lookup.canSaveExpense;

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
          SegmentedButton<String>(
            segments: const [
              ButtonSegment(value: 'expense', label: Text('Expense')),
              ButtonSegment(value: 'income', label: Text('Income')),
              ButtonSegment(value: 'transfer', label: Text('Transfer')),
            ],
            selected: const {'expense'},
            onSelectionChanged: (_) {},
          ),
          const SizedBox(height: AffluenaSpacing.space5),
          AffluenaCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Amount', style: textTheme.bodySmall),
                const SizedBox(height: AffluenaSpacing.space2),
                Text('Rp 125.000', style: textTheme.displaySmall),
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
                SelectorRow(
                  key: const Key('quick-entry-category-row'),
                  label: 'Category',
                  value:
                      selectedCategory?.name ??
                      'Add an expense category before saving.',
                  icon: Icons.restaurant_outlined,
                  enabled: lookup.expenseCategories.isNotEmpty,
                  onTap: lookup.expenseCategories.isEmpty
                      ? null
                      : () => onSelectCategory(lookup),
                ),
                const Divider(height: 1),
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
                const SelectorRow(
                  label: 'Date',
                  value: 'Today',
                  icon: Icons.calendar_today_outlined,
                ),
                const Divider(height: 1),
                const SelectorRow(
                  label: 'Note',
                  value: 'Lunch meeting',
                  icon: Icons.notes_outlined,
                ),
              ],
            ),
          ),
          const SizedBox(height: AffluenaSpacing.space6),
          Text('Saved templates', style: textTheme.titleMedium),
          const SizedBox(height: AffluenaSpacing.space3),
          Wrap(
            spacing: AffluenaSpacing.space3,
            runSpacing: AffluenaSpacing.space3,
            children: const [
              _TemplateChip(label: 'Coffee', amount: 'Rp 35.000'),
              _TemplateChip(label: 'Lunch', amount: 'Rp 125.000'),
              _TemplateChip(label: 'Top up', amount: 'Rp 500.000'),
            ],
          ),
          const SizedBox(height: AffluenaSpacing.space6),
          FilledButton(
            key: const Key('quick-entry-save-button'),
            onPressed: canSave ? () {} : null,
            child: const Text('Save transaction'),
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
  const _TemplateChip({required this.label, required this.amount});

  final String label;
  final String amount;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return AffluenaCard(
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
    );
  }
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
