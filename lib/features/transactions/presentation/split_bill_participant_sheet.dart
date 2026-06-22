import 'package:flutter/material.dart';

import '../../../app/theme/affluena_theme.dart';
import '../../shared/presentation/widgets/lookup_selector_sheet.dart';
import '../../shared/presentation/widgets/selector_row.dart';
import '../application/split_bill_controller.dart';
import '../data/transaction_models.dart';

class SplitBillParticipantDraft {
  const SplitBillParticipantDraft({
    required this.counterpartyName,
    required this.amountMinor,
    required this.disbursementCategoryId,
    required this.paymentCategoryId,
  });

  final String counterpartyName;
  final int amountMinor;
  final String disbursementCategoryId;
  final String paymentCategoryId;

  TransactionSplit toSplit() {
    return TransactionSplit(
      counterpartyName: counterpartyName,
      amountMinor: amountMinor,
      disbursementCategoryId: disbursementCategoryId,
      paymentCategoryId: paymentCategoryId,
    );
  }
}

Future<SplitBillParticipantDraft?> showSplitBillParticipantSheet({
  required BuildContext context,
  required SplitBillState state,
}) {
  return showModalBottomSheet<SplitBillParticipantDraft>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    useSafeArea: true,
    builder: (context) => _SplitBillParticipantSheet(state: state),
  );
}

class _SplitBillParticipantSheet extends StatefulWidget {
  const _SplitBillParticipantSheet({required this.state});

  final SplitBillState state;

  @override
  State<_SplitBillParticipantSheet> createState() =>
      _SplitBillParticipantSheetState();
}

class _SplitBillParticipantSheetState
    extends State<_SplitBillParticipantSheet> {
  late final TextEditingController _nameController;
  late final TextEditingController _amountController;
  String? _disbursementCategoryId;
  String? _paymentCategoryId;
  String? _error;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _amountController = TextEditingController();
    _disbursementCategoryId = widget.state.expenseCategories.firstOrNull?.id;
    _paymentCategoryId = widget.state.incomeCategories.firstOrNull?.id;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final amount = _parseAmount(_amountController.text);
    final canSave =
        _nameController.text.trim().isNotEmpty &&
        amount > 0 &&
        _disbursementCategoryId != null &&
        _paymentCategoryId != null;

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          AffluenaSpacing.space5,
          AffluenaSpacing.space2,
          AffluenaSpacing.space5,
          MediaQuery.viewInsetsOf(context).bottom + AffluenaSpacing.space4,
        ),
        child: SizedBox(
          height: MediaQuery.sizeOf(context).height * 0.68,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text('Add participant', style: textTheme.titleLarge),
                      const SizedBox(height: AffluenaSpacing.space4),
                      TextField(
                        key: const Key('participant-name-field'),
                        controller: _nameController,
                        textInputAction: TextInputAction.next,
                        decoration: const InputDecoration(
                          prefixIcon: Icon(Icons.person_outline),
                          labelText: 'Name',
                        ),
                        onChanged: (_) => setState(() => _error = null),
                      ),
                      const SizedBox(height: AffluenaSpacing.space3),
                      TextField(
                        key: const Key('participant-amount-field'),
                        controller: _amountController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          prefixIcon: Icon(Icons.payments_outlined),
                          labelText: 'Share amount',
                        ),
                        onChanged: (_) => setState(() => _error = null),
                      ),
                      const SizedBox(height: AffluenaSpacing.space3),
                      SelectorRow(
                        key: const Key(
                          'participant-disbursement-category-selector',
                        ),
                        label: 'Disbursement category',
                        value: widget.state.expenseCategoryName(
                          _disbursementCategoryId,
                        ),
                        icon: Icons.category_outlined,
                        enabled: widget.state.expenseCategories.isNotEmpty,
                        onTap: widget.state.expenseCategories.isEmpty
                            ? null
                            : _selectDisbursementCategory,
                      ),
                      const Divider(height: 1),
                      SelectorRow(
                        key: const Key('participant-payment-category-selector'),
                        label: 'Payment category',
                        value: widget.state.incomeCategoryName(
                          _paymentCategoryId,
                        ),
                        icon: Icons.savings_outlined,
                        enabled: widget.state.incomeCategories.isNotEmpty,
                        onTap: widget.state.incomeCategories.isEmpty
                            ? null
                            : _selectPaymentCategory,
                      ),
                    ],
                  ),
                ),
              ),
              if (_error != null) ...[
                const SizedBox(height: AffluenaSpacing.space3),
                Text(
                  _error!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ],
              const SizedBox(height: AffluenaSpacing.space4),
              FilledButton(
                key: const Key('participant-save-button'),
                onPressed: canSave ? _save : _showValidation,
                child: const Text('Add participant'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _selectDisbursementCategory() async {
    final selected = await showLookupSelectorSheet<String>(
      context: context,
      title: 'Disbursement category',
      selectedValue: _disbursementCategoryId,
      options: [
        for (final category in widget.state.expenseCategories)
          LookupSelectorOption<String>(
            value: category.id,
            label: category.name,
            icon: Icons.category_outlined,
          ),
      ],
    );
    if (!mounted || selected == null) return;
    setState(() => _disbursementCategoryId = selected);
  }

  Future<void> _selectPaymentCategory() async {
    final selected = await showLookupSelectorSheet<String>(
      context: context,
      title: 'Payment category',
      selectedValue: _paymentCategoryId,
      options: [
        for (final category in widget.state.incomeCategories)
          LookupSelectorOption<String>(
            value: category.id,
            label: category.name,
            icon: Icons.savings_outlined,
          ),
      ],
    );
    if (!mounted || selected == null) return;
    setState(() => _paymentCategoryId = selected);
  }

  void _showValidation() {
    setState(
      () => _error = 'Complete participant name, amount, and categories.',
    );
  }

  void _save() {
    Navigator.of(context).pop(
      SplitBillParticipantDraft(
        counterpartyName: _nameController.text.trim(),
        amountMinor: _parseAmount(_amountController.text),
        disbursementCategoryId: _disbursementCategoryId!,
        paymentCategoryId: _paymentCategoryId!,
      ),
    );
  }
}

int _parseAmount(String raw) {
  return int.tryParse(raw.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
}
