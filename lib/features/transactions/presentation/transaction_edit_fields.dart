part of 'transaction_edit_sheet.dart';

class _TransactionEditFields extends StatelessWidget {
  const _TransactionEditFields({
    required this.initialAmountMinor,
    required this.noteController,
    required this.walletId,
    required this.toWalletId,
    required this.categoryLabel,
    required this.walletOptions,
    required this.isTransfer,
    required this.initialFeeMinor,
    required this.onFeeChanged,
    required this.isAdjustment,
    required this.decrease,
    required this.needsCategory,
    required this.isSaving,
    required this.error,
    required this.onAmountChanged,
    required this.onDirectionChanged,
    required this.onTextChanged,
    required this.onWalletChanged,
    required this.onToWalletChanged,
    required this.onSelectCategory,
    required this.transactionAtLabel,
    required this.onSelectDateTime,
    required this.onSave,
  });

  final int initialAmountMinor;
  final TextEditingController noteController;
  final String? walletId;
  final String? toWalletId;
  final String categoryLabel;
  final List<_NamedOption> walletOptions;
  final bool isTransfer;

  /// The stored admin fee (transfer only; 0 = none) seeding the fee field.
  final int initialFeeMinor;
  final ValueChanged<int?> onFeeChanged;
  final bool isAdjustment;
  final bool decrease;
  final bool needsCategory;
  final bool isSaving;
  final String? error;
  final ValueChanged<int?> onAmountChanged;
  final ValueChanged<bool> onDirectionChanged;
  final VoidCallback onTextChanged;
  final ValueChanged<String?> onWalletChanged;
  final ValueChanged<String?> onToWalletChanged;
  final VoidCallback onSelectCategory;

  /// Formatted current date+time and the callback that opens the date/time
  /// pickers so the transaction can be re-stamped.
  final String transactionAtLabel;
  final VoidCallback onSelectDateTime;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (isAdjustment) ...[
          AdjustmentDirectionControl(
            decrease: decrease,
            enabled: !isSaving,
            onChanged: onDirectionChanged,
          ),
          const SizedBox(height: AffluenaSpacing.space3),
        ],
        MoneyInput(
          key: const Key('transaction-edit-amount-field'),
          label: 'Jumlah',
          // Bare digits: MoneyInput hardcodes the 'Rp ' prefix.
          hint: '50.000',
          initialValue: initialAmountMinor,
          enabled: !isSaving,
          // Quick chips (10rb … 1jt) — same affordance as the create form.
          showQuickAmounts: true,
          onChanged: onAmountChanged,
        ),
        const SizedBox(height: AffluenaSpacing.space3),
        DropdownButtonFormField<String>(
          initialValue: walletId,
          decoration: const InputDecoration(labelText: 'Dompet'),
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
            decoration: const InputDecoration(labelText: 'Dompet tujuan'),
            items: [
              for (final option in walletOptions)
                if (option.id != walletId)
                  DropdownMenuItem(value: option.id, child: Text(option.label)),
            ],
            onChanged: isSaving ? null : onToWalletChanged,
          ),
          const SizedBox(height: AffluenaSpacing.space3),
          // Preserve + edit the stored admin fee: omitting it here would zero
          // the fee on every edit (the API treats an absent fee_minor as 0 and
          // refunds the old fee to the source wallet).
          MoneyInput(
            key: const Key('transaction-edit-fee-field'),
            label: 'Biaya admin (opsional)',
            // Bare digits: MoneyInput hardcodes the 'Rp ' prefix.
            hint: '2.500',
            initialValue: initialFeeMinor > 0 ? initialFeeMinor : null,
            enabled: !isSaving,
            onChanged: onFeeChanged,
          ),
        ],
        if (needsCategory) ...[
          const SizedBox(height: AffluenaSpacing.space3),
          // Categories are a hierarchy: use the tree-aware picker, not a flat
          // dropdown.
          SelectorRow(
            key: const Key('transaction-edit-category-selector'),
            label: 'Kategori',
            value: categoryLabel,
            icon: Icons.category_outlined,
            enabled: !isSaving,
            onTap: isSaving ? null : onSelectCategory,
          ),
        ],
        const SizedBox(height: AffluenaSpacing.space3),
        SelectorRow(
          key: const Key('transaction-edit-datetime-selector'),
          label: 'Tanggal & waktu',
          value: transactionAtLabel,
          icon: Icons.event_outlined,
          enabled: !isSaving,
          onTap: isSaving ? null : onSelectDateTime,
        ),
        const SizedBox(height: AffluenaSpacing.space3),
        TextField(
          key: const Key('transaction-edit-note-field'),
          controller: noteController,
          enabled: !isSaving,
          decoration: const InputDecoration(
            labelText: 'Catatan',
            hintText: 'cth: Makan siang',
          ),
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
            child: Text(isSaving ? 'Menyimpan...' : 'Simpan transaksi'),
          ),
        ),
      ],
    );
  }
}
