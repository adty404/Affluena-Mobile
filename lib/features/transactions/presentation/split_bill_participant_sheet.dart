import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/affluena_theme.dart';
import '../../shared/presentation/widgets/affluena_banner.dart';
import '../../shared/presentation/widgets/category_tree_picker_sheet.dart';
import '../../shared/presentation/widgets/money_input.dart';
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

class _SplitBillParticipantSheet extends ConsumerStatefulWidget {
  const _SplitBillParticipantSheet({required this.state});

  final SplitBillState state;

  @override
  ConsumerState<_SplitBillParticipantSheet> createState() =>
      _SplitBillParticipantSheetState();
}

class _SplitBillParticipantSheetState
    extends ConsumerState<_SplitBillParticipantSheet> {
  late final TextEditingController _nameController;
  // Focus target for the amount field so the name field's "next" action lands
  // somewhere instead of stranding the keyboard focus.
  final _amountFocus = FocusNode();
  int? _amountMinor;
  String? _disbursementCategoryId;
  String? _paymentCategoryId;
  String? _error;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _disbursementCategoryId = widget.state.expenseCategories.firstOrNull?.id;
    _paymentCategoryId = widget.state.incomeCategories.firstOrNull?.id;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _amountFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    // Watch the live controller state (not just the snapshot the sheet opened
    // with) so a category created inline from the picker resolves immediately.
    final state = ref.watch(splitBillControllerProvider);
    final amount = _amountMinor ?? 0;
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
                      Text('Tambah peserta', style: textTheme.titleLarge),
                      const SizedBox(height: AffluenaSpacing.space4),
                      TextFormField(
                        key: const Key('participant-name-field'),
                        controller: _nameController,
                        textInputAction: TextInputAction.next,
                        onFieldSubmitted: (_) => _amountFocus.requestFocus(),
                        decoration: const InputDecoration(
                          prefixIcon: Icon(Icons.person_outline),
                          labelText: 'Nama (Wajib)',
                        ),
                        // Surface the blocker under the field as the user
                        // types instead of only after a failed save.
                        autovalidateMode: AutovalidateMode.onUserInteraction,
                        validator: (value) => (value ?? '').trim().isEmpty
                            ? 'Nama peserta wajib diisi.'
                            : null,
                        onChanged: (_) => setState(() => _error = null),
                      ),
                      const SizedBox(height: AffluenaSpacing.space3),
                      MoneyInput(
                        key: const Key('participant-amount-field'),
                        label: 'Jumlah bagian (Wajib)',
                        initialValue: _amountMinor,
                        focusNode: _amountFocus,
                        autovalidateMode: AutovalidateMode.onUserInteraction,
                        validator: (value) => (value ?? 0) > 0
                            ? null
                            : 'Masukkan jumlah lebih dari nol.',
                        onChanged: (value) => setState(() {
                          _amountMinor = value;
                          _error = null;
                        }),
                      ),
                      const SizedBox(height: AffluenaSpacing.space3),
                      SelectorRow(
                        key: const Key(
                          'participant-disbursement-category-selector',
                        ),
                        label: 'Kategori pencairan',
                        value: state.expenseCategoryName(
                          _disbursementCategoryId,
                        ),
                        isPlaceholder: _disbursementCategoryId == null,
                        icon: Icons.category_outlined,
                        enabled: state.expenseCategories.isNotEmpty,
                        onTap: state.expenseCategories.isEmpty
                            ? null
                            : _selectDisbursementCategory,
                      ),
                      const Divider(height: 1),
                      SelectorRow(
                        key: const Key('participant-payment-category-selector'),
                        label: 'Kategori pembayaran',
                        value: state.incomeCategoryName(_paymentCategoryId),
                        isPlaceholder: _paymentCategoryId == null,
                        icon: Icons.savings_outlined,
                        enabled: state.incomeCategories.isNotEmpty,
                        onTap: state.incomeCategories.isEmpty
                            ? null
                            : _selectPaymentCategory,
                      ),
                    ],
                  ),
                ),
              ),
              if (_error != null) ...[
                const SizedBox(height: AffluenaSpacing.space3),
                AffluenaBanner.error(_error!),
              ],
              const SizedBox(height: AffluenaSpacing.space4),
              FilledButton(
                key: const Key('participant-save-button'),
                onPressed: canSave ? _save : _showValidation,
                child: const Text('Tambah peserta'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _selectDisbursementCategory() async {
    // Categories are a hierarchy: use the tree-aware picker, not a flat list.
    final selected = await showCategoryTreePicker(
      context: context,
      title: 'Kategori pencairan',
      selectedId: _disbursementCategoryId,
      onMutated: () => ref.read(splitBillControllerProvider.notifier).load(),
      categories: [
        for (final category
            in ref.read(splitBillControllerProvider).expenseCategories)
          CategoryTreeEntry.fromCategory(category),
      ],
    );
    if (!mounted || selected == null || selected.isEmpty) return;
    setState(() => _disbursementCategoryId = selected);
  }

  Future<void> _selectPaymentCategory() async {
    // Categories are a hierarchy: use the tree-aware picker, not a flat list.
    final selected = await showCategoryTreePicker(
      context: context,
      title: 'Kategori pembayaran',
      selectedId: _paymentCategoryId,
      onMutated: () => ref.read(splitBillControllerProvider.notifier).load(),
      categories: [
        for (final category
            in ref.read(splitBillControllerProvider).incomeCategories)
          CategoryTreeEntry.fromCategory(category),
      ],
    );
    if (!mounted || selected == null || selected.isEmpty) return;
    setState(() => _paymentCategoryId = selected);
  }

  void _showValidation() {
    setState(() => _error = 'Lengkapi nama, jumlah, dan kategori peserta.');
  }

  void _save() {
    Navigator.of(context).pop(
      SplitBillParticipantDraft(
        counterpartyName: _nameController.text.trim(),
        amountMinor: _amountMinor ?? 0,
        disbursementCategoryId: _disbursementCategoryId!,
        paymentCategoryId: _paymentCategoryId!,
      ),
    );
  }
}
