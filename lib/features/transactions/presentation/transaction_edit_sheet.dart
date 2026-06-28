import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/affluena_theme.dart';
import '../../shared/presentation/widgets/affluena_banner.dart';
import '../../shared/presentation/widgets/category_tree_picker_sheet.dart';
import '../../shared/presentation/widgets/money_input.dart';
import '../../shared/presentation/widgets/selector_row.dart';
import '../application/transactions_controller.dart';
import '../data/transaction_models.dart';
import 'adjustment_direction_control.dart';

part 'transaction_edit_fields.dart';
part 'transaction_edit_options.dart';

Future<void> showTransactionEditForm(
  BuildContext context,
  TransactionsState state,
  Transaction transaction,
) async {
  await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (context) =>
        _TransactionEditSheet(state: state, transaction: transaction),
  );
}

class _TransactionEditSheet extends ConsumerStatefulWidget {
  const _TransactionEditSheet({required this.state, required this.transaction});

  final TransactionsState state;
  final Transaction transaction;

  @override
  ConsumerState<_TransactionEditSheet> createState() =>
      _TransactionEditSheetState();
}

class _TransactionEditSheetState extends ConsumerState<_TransactionEditSheet> {
  late final TextEditingController _noteController;
  late int? _amountMinor;
  late bool _decrease;
  late String? _walletId;
  late String? _toWalletId;
  late String? _categoryId;
  String? _error;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final transaction = widget.transaction;
    // Adjustments may carry a negative amount_minor to decrease a balance. The
    // MoneyInput is positive-only, so we store the magnitude here and recover
    // the sign from the direction control on save.
    _amountMinor = transaction.amountMinor.abs();
    _decrease =
        transaction.type == TransactionType.adjustment &&
        transaction.amountMinor < 0;
    _noteController = TextEditingController(text: transaction.note);
    _walletId = transaction.walletId;
    _toWalletId = transaction.toWalletId;
    _categoryId = transaction.categoryId;
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final transaction = widget.transaction;
    final isTransfer = transaction.type == TransactionType.transfer;
    final isAdjustment = transaction.type == TransactionType.adjustment;
    final needsCategory =
        transaction.type == TransactionType.income ||
        transaction.type == TransactionType.expense;
    final walletOptions = _walletOptions(widget.state, _walletId, _toWalletId);
    final categoryLabel = _categoryId == null
        ? 'Pilih kategori'
        : (widget.state.categoryNames[_categoryId] ?? 'Tanpa kategori');

    return SafeArea(
      child: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            AffluenaSpacing.space5,
            AffluenaSpacing.space2,
            AffluenaSpacing.space5,
            MediaQuery.viewInsetsOf(context).bottom + AffluenaSpacing.space5,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Ubah transaksi', style: textTheme.titleLarge),
              const SizedBox(height: AffluenaSpacing.space4),
              _TransactionEditFields(
                initialAmountMinor: widget.transaction.amountMinor.abs(),
                noteController: _noteController,
                walletId: _walletId,
                toWalletId: _toWalletId,
                categoryLabel: categoryLabel,
                walletOptions: walletOptions,
                isTransfer: isTransfer,
                isAdjustment: isAdjustment,
                decrease: _decrease,
                needsCategory: needsCategory,
                isSaving: _isSaving,
                error: _error,
                onAmountChanged: (value) {
                  _amountMinor = value;
                  _clearError();
                },
                onDirectionChanged: (decrease) => setState(() {
                  _decrease = decrease;
                  _error = null;
                }),
                onTextChanged: _clearError,
                onWalletChanged: (value) => setState(() {
                  _walletId = value;
                  if (_toWalletId == value) _toWalletId = null;
                  _error = null;
                }),
                onToWalletChanged: (value) => setState(() {
                  _toWalletId = value;
                  _error = null;
                }),
                onSelectCategory: _selectCategory,
                onSave: _save,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _clearError() {
    if (_error == null) return;
    setState(() => _error = null);
  }

  Future<void> _selectCategory() async {
    // Categories are a hierarchy: use the tree-aware picker, not a flat list.
    final selectedId = await showCategoryTreePicker(
      context: context,
      title: 'Kategori',
      selectedId: _categoryId,
      categories: [
        for (final category in widget.state.categories)
          CategoryTreeEntry(
            id: category.id,
            name: category.name,
            parentId: category.parentId,
          ),
      ],
    );
    if (!mounted || selectedId == null || selectedId.isEmpty) return;
    setState(() {
      _categoryId = selectedId;
      _error = null;
    });
  }

  Future<void> _save() async {
    final transaction = widget.transaction;
    final amountMinor = _amountMinor ?? 0;
    final error = _validationError(transaction, amountMinor);
    if (error != null) {
      setState(() => _error = error);
      return;
    }

    final signed = transaction.type == TransactionType.adjustment && _decrease
        ? -amountMinor
        : amountMinor;

    setState(() {
      _isSaving = true;
      _error = null;
    });

    final note = _noteController.text.trim();
    final request = TransactionRequest(
      type: transaction.type,
      walletId: _walletId!,
      toWalletId: transaction.type == TransactionType.transfer
          ? _toWalletId
          : null,
      categoryId: transaction.type == TransactionType.transfer
          ? null
          : _categoryId,
      amountMinor: signed,
      transactionAt: transaction.transactionAt,
      note: note.isEmpty ? null : note,
      tagIds: transaction.tagIds,
    );

    final saved = await ref
        .read(transactionsControllerProvider.notifier)
        .updateTransaction(transaction, request);
    if (!mounted) return;
    if (saved) {
      Navigator.of(context).pop(true);
      return;
    }
    setState(() {
      _isSaving = false;
      _error = 'Transaksi tidak dapat diperbarui.';
    });
  }

  String? _validationError(Transaction transaction, int amountMinor) {
    if (_walletId == null) return 'Dompet wajib diisi.';
    if (transaction.type == TransactionType.adjustment) {
      // amountMinor is the magnitude (always non-negative from MoneyInput); a
      // zero adjustment would be a no-op in either direction.
      if (amountMinor == 0) return 'Jumlah harus lebih dari 0.';
    } else if (amountMinor <= 0) {
      return 'Jumlah harus lebih dari 0.';
    }
    if (transaction.type == TransactionType.transfer) {
      if (_toWalletId == null) return 'Dompet tujuan wajib diisi.';
      if (_toWalletId == _walletId) {
        return 'Dompet tujuan harus berbeda dari dompet asal.';
      }
    }
    if ((transaction.type == TransactionType.income ||
            transaction.type == TransactionType.expense) &&
        _categoryId == null) {
      return 'Kategori wajib diisi.';
    }
    return null;
  }
}
