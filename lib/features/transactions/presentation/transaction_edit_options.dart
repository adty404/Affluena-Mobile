part of 'transaction_edit_sheet.dart';

List<_NamedOption> _walletOptions(
  TransactionsState state,
  String? walletId,
  String? toWalletId,
) {
  final options = [
    for (final entry in state.walletNames.entries)
      _NamedOption(entry.key, entry.value),
  ];
  _addMissingOption(options, walletId, state.walletName(walletId ?? ''));
  if (toWalletId != null) {
    _addMissingOption(options, toWalletId, state.walletName(toWalletId));
  }
  return options;
}

List<_NamedOption> _categoryOptions(
  TransactionsState state,
  Transaction transaction,
  String? categoryId,
) {
  final options = [
    for (final entry in state.categoryNames.entries)
      _NamedOption(entry.key, entry.value),
  ];
  if (categoryId != null) {
    _addMissingOption(options, categoryId, state.categoryName(transaction));
  }
  return options;
}

void _addMissingOption(List<_NamedOption> options, String? id, String label) {
  if (id == null || options.any((option) => option.id == id)) return;
  options.add(_NamedOption(id, label));
}

class _NamedOption {
  const _NamedOption(this.id, this.label);

  final String id;
  final String label;
}

int _parseTransactionAmount(String value) {
  final digits = value.replaceAll(RegExp(r'[^0-9]'), '');
  if (digits.isEmpty) return 0;
  return int.tryParse(digits) ?? 0;
}
