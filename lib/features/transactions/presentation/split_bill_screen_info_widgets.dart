part of 'split_bill_screen.dart';

class _SplitBillInfoSection extends StatelessWidget {
  const _SplitBillInfoSection({
    required this.state,
    required this.walletId,
    required this.categoryId,
    required this.selectedTagId,
    required this.totalAmountMinor,
    required this.date,
    required this.noteController,
    required this.onAmountChanged,
    required this.onDateChanged,
    required this.onWalletChanged,
    required this.onCategoryChanged,
    required this.onTagChanged,
    required this.onTextChanged,
  });

  final SplitBillState state;
  final String? walletId;
  final String? categoryId;
  final String? selectedTagId;
  final int? totalAmountMinor;
  final DateTime date;
  final TextEditingController noteController;
  final ValueChanged<int?> onAmountChanged;
  final ValueChanged<DateTime> onDateChanged;
  final ValueChanged<String> onWalletChanged;
  final ValueChanged<String> onCategoryChanged;
  final ValueChanged<String?> onTagChanged;
  final VoidCallback onTextChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SectionHeader(title: 'Bill information', actionLabel: 'Expense'),
        const SizedBox(height: AffluenaSpacing.space3),
        AffluenaCard(
          child: Column(
            children: [
              SelectorRow(
                key: const Key('split-wallet-selector'),
                label: 'Wallet',
                value: state.walletName(walletId),
                icon: Icons.account_balance_wallet_outlined,
                enabled: state.wallets.isNotEmpty && !state.isSaving,
                onTap: state.wallets.isEmpty
                    ? null
                    : () => _selectWallet(context),
              ),
              const Divider(height: 1),
              SelectorRow(
                key: const Key('split-category-selector'),
                label: 'Category',
                value: state.expenseCategoryName(categoryId),
                icon: Icons.category_outlined,
                enabled: state.expenseCategories.isNotEmpty && !state.isSaving,
                onTap: state.expenseCategories.isEmpty
                    ? null
                    : () => _selectCategory(context),
              ),
              const Divider(height: 1),
              _SplitTagChips(
                tags: state.tags,
                selectedTagId: selectedTagId,
                enabled: !state.isSaving,
                onChanged: onTagChanged,
              ),
              const Divider(height: 1),
              const SizedBox(height: AffluenaSpacing.space3),
              MoneyInput(
                key: const Key('split-total-amount-field'),
                label: 'Total bill',
                initialValue: totalAmountMinor,
                enabled: !state.isSaving,
                onChanged: onAmountChanged,
              ),
              const SizedBox(height: AffluenaSpacing.space3),
              DateTimePickerField(
                key: const Key('split-date-field'),
                label: 'Date & time',
                value: date,
                enabled: !state.isSaving,
                onChanged: onDateChanged,
              ),
              const SizedBox(height: AffluenaSpacing.space3),
              TextField(
                key: const Key('split-note-field'),
                controller: noteController,
                textInputAction: TextInputAction.done,
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.notes_outlined),
                  labelText: 'Note',
                ),
                onChanged: (_) => onTextChanged(),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _selectWallet(BuildContext context) async {
    final selected = await showLookupSelectorSheet<String>(
      context: context,
      title: 'Split wallet',
      selectedValue: walletId,
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
    if (context.mounted && selected != null) onWalletChanged(selected);
  }

  Future<void> _selectCategory(BuildContext context) async {
    // Categories are a hierarchy: use the tree-aware picker, not a flat list.
    final selected = await showCategoryTreePicker(
      context: context,
      title: 'Bill category',
      selectedId: categoryId,
      categories: [
        for (final category in state.expenseCategories)
          CategoryTreeEntry(
            id: category.id,
            name: category.name,
            parentId: category.parentId,
          ),
      ],
    );
    if (context.mounted && selected != null && selected.isNotEmpty) {
      onCategoryChanged(selected);
    }
  }
}
