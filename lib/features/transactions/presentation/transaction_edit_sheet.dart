import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/affluena_theme.dart';
import '../application/transactions_controller.dart';
import '../data/transaction_models.dart';

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
  late final TextEditingController _amountController;
  late final TextEditingController _noteController;
  late String? _walletId;
  late String? _toWalletId;
  late String? _categoryId;
  String? _error;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final transaction = widget.transaction;
    _amountController = TextEditingController(
      text: transaction.amountMinor.toString(),
    );
    _noteController = TextEditingController(text: transaction.note);
    _walletId = transaction.walletId;
    _toWalletId = transaction.toWalletId;
    _categoryId = transaction.categoryId;
  }

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final transaction = widget.transaction;
    final isTransfer = transaction.type == TransactionType.transfer;
    final needsCategory =
        transaction.type == TransactionType.income ||
        transaction.type == TransactionType.expense;
    final walletOptions = _walletOptions(widget.state, _walletId, _toWalletId);
    final categoryOptions = _categoryOptions(
      widget.state,
      transaction,
      _categoryId,
    );

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
              Text('Edit transaction', style: textTheme.titleLarge),
              const SizedBox(height: AffluenaSpacing.space4),
              _TransactionEditFields(
                amountController: _amountController,
                noteController: _noteController,
                walletId: _walletId,
                toWalletId: _toWalletId,
                categoryId: _categoryId,
                walletOptions: walletOptions,
                categoryOptions: categoryOptions,
                isTransfer: isTransfer,
                needsCategory: needsCategory,
                isSaving: _isSaving,
                error: _error,
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
                onCategoryChanged: (value) => setState(() {
                  _categoryId = value;
                  _error = null;
                }),
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

  Future<void> _save() async {
    final transaction = widget.transaction;
    final amountMinor = _parseTransactionAmount(_amountController.text);
    final error = _validationError(transaction, amountMinor);
    if (error != null) {
      setState(() => _error = error);
      return;
    }

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
      amountMinor: amountMinor,
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
      _error = 'Transaction could not be updated.';
    });
  }

  String? _validationError(Transaction transaction, int amountMinor) {
    if (_walletId == null) return 'Wallet is required.';
    if (transaction.type != TransactionType.adjustment && amountMinor <= 0) {
      return 'Amount must be greater than 0.';
    }
    if (transaction.type == TransactionType.transfer) {
      if (_toWalletId == null) return 'Destination wallet is required.';
      if (_toWalletId == _walletId) {
        return 'Destination wallet must be different from source wallet.';
      }
    }
    if ((transaction.type == TransactionType.income ||
            transaction.type == TransactionType.expense) &&
        _categoryId == null) {
      return 'Category is required.';
    }
    return null;
  }
}
