part of 'transaction_edit_sheet.dart';

class _TransactionEditFields extends StatelessWidget {
  const _TransactionEditFields({
    required this.initialAmountMinor,
    required this.noteController,
    required this.walletId,
    required this.toWalletId,
    required this.categoryId,
    required this.walletOptions,
    required this.categoryOptions,
    required this.isTransfer,
    required this.needsCategory,
    required this.isSaving,
    required this.error,
    required this.onAmountChanged,
    required this.onTextChanged,
    required this.onWalletChanged,
    required this.onToWalletChanged,
    required this.onCategoryChanged,
    required this.onSave,
  });

  final int initialAmountMinor;
  final TextEditingController noteController;
  final String? walletId;
  final String? toWalletId;
  final String? categoryId;
  final List<_NamedOption> walletOptions;
  final List<_NamedOption> categoryOptions;
  final bool isTransfer;
  final bool needsCategory;
  final bool isSaving;
  final String? error;
  final ValueChanged<int?> onAmountChanged;
  final VoidCallback onTextChanged;
  final ValueChanged<String?> onWalletChanged;
  final ValueChanged<String?> onToWalletChanged;
  final ValueChanged<String?> onCategoryChanged;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        MoneyInput(
          key: const Key('transaction-edit-amount-field'),
          label: 'Amount',
          initialValue: initialAmountMinor,
          enabled: !isSaving,
          onChanged: onAmountChanged,
        ),
        const SizedBox(height: AffluenaSpacing.space3),
        DropdownButtonFormField<String>(
          initialValue: walletId,
          decoration: const InputDecoration(labelText: 'Wallet'),
          items: [
            for (final option in walletOptions)
              DropdownMenuItem(value: option.id, child: Text(option.label)),
          ],
          onChanged: isSaving ? null : onWalletChanged,
        ),
        if (isTransfer) ...[
          const SizedBox(height: AffluenaSpacing.space3),
          DropdownButtonFormField<String>(
            initialValue: toWalletId,
            decoration: const InputDecoration(labelText: 'Destination wallet'),
            items: [
              for (final option in walletOptions)
                if (option.id != walletId)
                  DropdownMenuItem(value: option.id, child: Text(option.label)),
            ],
            onChanged: isSaving ? null : onToWalletChanged,
          ),
        ],
        if (needsCategory) ...[
          const SizedBox(height: AffluenaSpacing.space3),
          DropdownButtonFormField<String>(
            initialValue: categoryId,
            decoration: const InputDecoration(labelText: 'Category'),
            items: [
              for (final option in categoryOptions)
                DropdownMenuItem(value: option.id, child: Text(option.label)),
            ],
            onChanged: isSaving ? null : onCategoryChanged,
          ),
        ],
        const SizedBox(height: AffluenaSpacing.space3),
        TextField(
          key: const Key('transaction-edit-note-field'),
          controller: noteController,
          decoration: const InputDecoration(labelText: 'Note'),
          textInputAction: TextInputAction.done,
          onChanged: (_) => onTextChanged(),
        ),
        if (error != null) ...[
          const SizedBox(height: AffluenaSpacing.space3),
          AffluenaBanner(message: error!, tone: AffluenaBannerTone.warning),
        ],
        const SizedBox(height: AffluenaSpacing.space5),
        SizedBox(
          width: double.infinity,
          child: FilledButton(
            key: const Key('transaction-edit-save-button'),
            onPressed: isSaving ? null : onSave,
            child: Text(isSaving ? 'Saving...' : 'Save transaction'),
          ),
        ),
      ],
    );
  }
}
