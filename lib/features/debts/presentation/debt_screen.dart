import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/affluena_theme.dart';
import '../../../core/formatters/date_formatter.dart';
import '../../../core/formatters/money_formatter.dart';
import '../../categories/data/category_models.dart';
import '../../shared/presentation/widgets/affluena_card.dart';
import '../../shared/presentation/widgets/lookup_selector_sheet.dart';
import '../../shared/presentation/widgets/metric_tile.dart';
import '../../shared/presentation/widgets/section_header.dart';
import '../../shared/presentation/widgets/selector_row.dart';
import '../../wallets/data/wallet_models.dart';
import '../application/debt_controller.dart';
import '../data/debt_models.dart';

class DebtScreen extends ConsumerWidget {
  const DebtScreen({super.key});

  static const path = '/debts';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(debtControllerProvider);
    final controller = ref.read(debtControllerProvider.notifier);
    final textTheme = Theme.of(context).textTheme;

    if (state.isLoading && state.debts.isEmpty) {
      return const _DebtLoading();
    }

    if (state.loadError != null && state.debts.isEmpty) {
      return _DebtError(onRetry: controller.load);
    }

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(
          AffluenaSpacing.space5,
          AffluenaSpacing.space4,
          AffluenaSpacing.space5,
          AffluenaSpacing.space8,
        ),
        children: [
          Row(
            children: [
              Expanded(
                child: Text('Debt & Tracker', style: textTheme.headlineMedium),
              ),
              IconButton.filledTonal(
                onPressed: state.wallets.isEmpty || state.isSaving
                    ? null
                    : () => _showDebtForm(context, state),
                icon: const Icon(Icons.add),
              ),
            ],
          ),
          const SizedBox(height: AffluenaSpacing.space5),
          _DebtSummaryCard(state: state),
          const SizedBox(height: AffluenaSpacing.space5),
          if (state.actionError != null) ...[
            AffluenaCard(
              backgroundColor: context.affluenaColors.surfaceTintSoft,
              child: Text(state.actionError!),
            ),
            const SizedBox(height: AffluenaSpacing.space4),
          ],
          _DebtTypeFilter(
            selected: state.typeFilter,
            onChanged: controller.setTypeFilter,
          ),
          const SizedBox(height: AffluenaSpacing.space5),
          SectionHeader(
            title: 'Debts',
            actionLabel: state.total == 0 ? null : '${state.total} total',
          ),
          const SizedBox(height: AffluenaSpacing.space3),
          if (state.visibleDebts.isEmpty)
            const _EmptyDebtState()
          else
            for (final debt in state.visibleDebts) ...[
              _DebtCard(
                debt: debt,
                walletName: state.walletName(debt.walletId),
                paymentCategoryName: state.categoryName(debt.paymentCategoryId),
                onPay: debt.canPay ? () => _showPaySheet(context, debt) : null,
                onEdit: () => _showDebtForm(context, state, debt: debt),
                onCancel: debt.status == DebtStatus.cancelled
                    ? null
                    : () => _confirmCancel(context, controller, debt),
              ),
              const SizedBox(height: AffluenaSpacing.space3),
            ],
        ],
      ),
    );
  }
}

class _DebtSummaryCard extends StatelessWidget {
  const _DebtSummaryCard({required this.state});

  final DebtState state;

  @override
  Widget build(BuildContext context) {
    return AffluenaCard(
      child: Column(
        children: [
          Row(
            children: [
              MetricTile(
                label: 'Payable',
                value: MoneyFormatter.idr(state.payableMinor),
                helper: 'To pay',
                icon: Icons.arrow_upward,
              ),
              const SizedBox(width: AffluenaSpacing.space3),
              MetricTile(
                label: 'Receivable',
                value: MoneyFormatter.idr(state.receivableMinor),
                helper: 'To collect',
                icon: Icons.arrow_downward,
              ),
            ],
          ),
          const SizedBox(height: AffluenaSpacing.space3),
          Row(
            children: [
              MetricTile(
                label: 'Due soon',
                value: state.dueSoonCount.toString(),
                helper: 'Next 7 days',
                icon: Icons.event_outlined,
              ),
              const SizedBox(width: AffluenaSpacing.space3),
              MetricTile(
                label: 'Paid',
                value: MoneyFormatter.idr(state.paidMinor),
                helper: 'Closed debt',
                icon: Icons.done_all,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DebtTypeFilter extends StatelessWidget {
  const _DebtTypeFilter({required this.selected, required this.onChanged});

  final DebtType? selected;
  final ValueChanged<DebtType?> onChanged;

  @override
  Widget build(BuildContext context) {
    return SegmentedButton<DebtType?>(
      segments: const [
        ButtonSegment(value: null, label: Text('All')),
        ButtonSegment(value: DebtType.payable, label: Text('Payable')),
        ButtonSegment(value: DebtType.receivable, label: Text('Receivable')),
      ],
      selected: {selected},
      onSelectionChanged: (values) => onChanged(values.first),
    );
  }
}

class _DebtCard extends StatelessWidget {
  const _DebtCard({
    required this.debt,
    required this.walletName,
    required this.paymentCategoryName,
    required this.onEdit,
    this.onPay,
    this.onCancel,
  });

  final Debt debt;
  final String walletName;
  final String paymentCategoryName;
  final VoidCallback? onPay;
  final VoidCallback onEdit;
  final VoidCallback? onCancel;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colors = context.affluenaColors;
    final isPayable = debt.type == DebtType.payable;
    final accent = isPayable ? colors.coral : colors.success;

    return AffluenaCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(debt.counterpartyName, style: textTheme.titleMedium),
                    const SizedBox(height: AffluenaSpacing.space1),
                    Wrap(
                      spacing: AffluenaSpacing.space2,
                      runSpacing: AffluenaSpacing.space2,
                      children: [
                        _DebtBadge(
                          label: isPayable ? 'Payable' : 'Receivable',
                          color: accent,
                        ),
                        _DebtBadge(label: debt.status.label, color: accent),
                      ],
                    ),
                  ],
                ),
              ),
              PopupMenuButton<String>(
                onSelected: (value) {
                  if (value == 'edit') onEdit();
                  if (value == 'cancel' && onCancel != null) onCancel!();
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(value: 'edit', child: Text('Edit')),
                  if (onCancel != null)
                    const PopupMenuItem(
                      value: 'cancel',
                      child: Text('Cancel debt'),
                    ),
                ],
              ),
            ],
          ),
          const SizedBox(height: AffluenaSpacing.space3),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: debt.paidPercent / 100,
              minHeight: 10,
              color: accent,
              backgroundColor: colors.surfaceTintSoft,
            ),
          ),
          const SizedBox(height: AffluenaSpacing.space3),
          Text(
            MoneyFormatter.idr(debt.remainingAmountMinor),
            style: textTheme.headlineSmall,
          ),
          const SizedBox(height: AffluenaSpacing.space1),
          Text(
            '${debt.paidPercent.round()}% settled from ${MoneyFormatter.idr(debt.principalAmountMinor)}',
            style: textTheme.bodySmall,
          ),
          const SizedBox(height: AffluenaSpacing.space2),
          Text(
            '${debt.dueDate == null ? 'No due date' : 'Due ${AffluenaDateFormatter.shortDate(debt.dueDate!)}'} · $walletName · $paymentCategoryName',
            style: textTheme.bodySmall,
          ),
          if (debt.note.isNotEmpty) ...[
            const SizedBox(height: AffluenaSpacing.space2),
            Text(debt.note, style: textTheme.bodySmall),
          ],
          if (onPay != null) ...[
            const SizedBox(height: AffluenaSpacing.space4),
            FilledButton.icon(
              onPressed: onPay,
              icon: const Icon(Icons.payments_outlined),
              label: const Text('Record payment'),
            ),
          ],
        ],
      ),
    );
  }
}

class _DebtBadge extends StatelessWidget {
  const _DebtBadge({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AffluenaSpacing.space3,
          vertical: AffluenaSpacing.space1,
        ),
        child: Text(
          label,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(color: color),
        ),
      ),
    );
  }
}

class _EmptyDebtState extends StatelessWidget {
  const _EmptyDebtState();

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colors = context.affluenaColors;
    return AffluenaCard(
      backgroundColor: colors.forestSoft,
      borderColor: colors.forestSoft,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.handshake_outlined, color: colors.forest),
          const SizedBox(height: AffluenaSpacing.space3),
          Text('No debts yet', style: textTheme.titleMedium),
          const SizedBox(height: AffluenaSpacing.space1),
          Text(
            'Track payable and receivable balances with payment history.',
            style: textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}

class _DebtLoading extends StatelessWidget {
  const _DebtLoading();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(
          AffluenaSpacing.space5,
          AffluenaSpacing.space4,
          AffluenaSpacing.space5,
          AffluenaSpacing.space8,
        ),
        children: [
          Text(
            'Debt & Tracker',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: AffluenaSpacing.space5),
          const AffluenaCard(
            child: SizedBox(
              height: 144,
              child: Center(child: Text('Loading debts')),
            ),
          ),
        ],
      ),
    );
  }
}

class _DebtError extends StatelessWidget {
  const _DebtError({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(
          AffluenaSpacing.space5,
          AffluenaSpacing.space4,
          AffluenaSpacing.space5,
          AffluenaSpacing.space8,
        ),
        children: [
          Text(
            'Debts unavailable',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: AffluenaSpacing.space5),
          AffluenaCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('We could not load your debts.'),
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

Future<void> _showDebtForm(
  BuildContext context,
  DebtState state, {
  Debt? debt,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => _DebtFormSheet(state: state, debt: debt),
  );
}

class _DebtFormSheet extends ConsumerStatefulWidget {
  const _DebtFormSheet({required this.state, this.debt});

  final DebtState state;
  final Debt? debt;

  @override
  ConsumerState<_DebtFormSheet> createState() => _DebtFormSheetState();
}

class _DebtFormSheetState extends ConsumerState<_DebtFormSheet> {
  late DebtType _type;
  late final TextEditingController _counterpartyController;
  late final TextEditingController _amountController;
  late final TextEditingController _dueDateController;
  late final TextEditingController _noteController;
  DebtStatus? _status;
  Wallet? _wallet;
  Category? _disbursementCategory;
  Category? _paymentCategory;

  bool get _isEditing => widget.debt != null;

  @override
  void initState() {
    super.initState();
    final debt = widget.debt;
    _type = debt?.type ?? DebtType.payable;
    _counterpartyController = TextEditingController(
      text: debt?.counterpartyName ?? '',
    );
    _amountController = TextEditingController(
      text: debt?.principalAmountMinor.toString() ?? '',
    );
    _dueDateController = TextEditingController(text: debt?.dueDate ?? '');
    _noteController = TextEditingController(text: debt?.note ?? '');
    _status = debt?.status;
    _wallet = _findById(widget.state.wallets, debt?.walletId);
    _disbursementCategory = _findById(
      widget.state.disbursementCategories(_type),
      debt?.disbursementCategoryId,
    );
    _paymentCategory = _findById(
      widget.state.paymentCategories(_type),
      debt?.paymentCategoryId,
    );
  }

  @override
  void dispose() {
    _counterpartyController.dispose();
    _amountController.dispose();
    _dueDateController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final state = ref.watch(debtControllerProvider);
    final amountMinor = _moneyMinor(_amountController.text);
    final canSave =
        _counterpartyController.text.trim().isNotEmpty &&
        _validDate(_dueDateController.text) &&
        (_isEditing ||
            (_wallet != null &&
                _disbursementCategory != null &&
                _paymentCategory != null &&
                amountMinor > 0)) &&
        !state.isSaving;

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          AffluenaSpacing.space5,
          AffluenaSpacing.space2,
          AffluenaSpacing.space5,
          MediaQuery.viewInsetsOf(context).bottom + AffluenaSpacing.space5,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                _isEditing ? 'Edit debt' : 'Create debt',
                style: textTheme.titleLarge,
              ),
              const SizedBox(height: AffluenaSpacing.space4),
              if (!_isEditing) ...[
                SegmentedButton<DebtType>(
                  segments: const [
                    ButtonSegment(
                      value: DebtType.payable,
                      label: Text('Payable'),
                    ),
                    ButtonSegment(
                      value: DebtType.receivable,
                      label: Text('Receivable'),
                    ),
                  ],
                  selected: {_type},
                  onSelectionChanged: (values) {
                    setState(() {
                      _type = values.first;
                      _disbursementCategory = null;
                      _paymentCategory = null;
                    });
                  },
                ),
                const SizedBox(height: AffluenaSpacing.space3),
              ],
              TextField(
                controller: _counterpartyController,
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.person_outline),
                  labelText: 'Counterparty',
                ),
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: AffluenaSpacing.space2),
              if (!_isEditing) ...[
                SelectorRow(
                  label: 'Wallet',
                  value: _wallet?.name ?? 'Choose wallet',
                  icon: Icons.account_balance_wallet_outlined,
                  onTap: () => _selectWallet(widget.state.wallets),
                ),
                const Divider(height: 1),
                SelectorRow(
                  label: _type == DebtType.payable ? 'Borrowed as' : 'Lent as',
                  value: _disbursementCategory?.name ?? 'Choose category',
                  icon: Icons.category_outlined,
                  onTap: () => _selectCategory(
                    title: 'Origination category',
                    options: widget.state.disbursementCategories(_type),
                    selected: _disbursementCategory,
                    onSelected: (category) =>
                        setState(() => _disbursementCategory = category),
                  ),
                ),
                const Divider(height: 1),
                SelectorRow(
                  label: _type == DebtType.payable
                      ? 'Payment expense'
                      : 'Collection income',
                  value: _paymentCategory?.name ?? 'Choose category',
                  icon: Icons.payments_outlined,
                  onTap: () => _selectCategory(
                    title: 'Payment category',
                    options: widget.state.paymentCategories(_type),
                    selected: _paymentCategory,
                    onSelected: (category) =>
                        setState(() => _paymentCategory = category),
                  ),
                ),
                const Divider(height: 1),
                TextField(
                  key: const Key('debt-amount-field'),
                  controller: _amountController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.payments_outlined),
                    labelText: 'Principal amount',
                    hintText: '1500000',
                  ),
                  onChanged: (_) => setState(() {}),
                ),
              ] else ...[
                DropdownButtonFormField<DebtStatus>(
                  initialValue: _status,
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.flag_outlined),
                    labelText: 'Status',
                  ),
                  items: DebtStatus.values
                      .map(
                        (status) => DropdownMenuItem(
                          value: status,
                          child: Text(status.label),
                        ),
                      )
                      .toList(growable: false),
                  onChanged: (status) => setState(() => _status = status),
                ),
              ],
              const SizedBox(height: AffluenaSpacing.space2),
              TextField(
                controller: _dueDateController,
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.event_outlined),
                  labelText: 'Due date',
                  hintText: 'YYYY-MM-DD',
                ),
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: AffluenaSpacing.space2),
              TextField(
                controller: _noteController,
                maxLines: 2,
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.notes_outlined),
                  labelText: 'Note',
                ),
              ),
              const SizedBox(height: AffluenaSpacing.space5),
              FilledButton(
                key: const Key('debt-save-button'),
                onPressed: canSave ? _save : null,
                child: Text(state.isSaving ? 'Saving...' : 'Save debt'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _selectWallet(List<Wallet> wallets) async {
    final selected = await showLookupSelectorSheet<Wallet>(
      context: context,
      title: 'Debt wallet',
      selectedValue: _wallet,
      options: [
        for (final wallet in wallets)
          LookupSelectorOption<Wallet>(
            value: wallet,
            label: wallet.name,
            subtitle: wallet.type.apiValue,
            icon: Icons.account_balance_wallet_outlined,
          ),
      ],
    );
    if (selected == null) return;
    setState(() => _wallet = selected);
  }

  Future<void> _selectCategory({
    required String title,
    required List<Category> options,
    required Category? selected,
    required ValueChanged<Category> onSelected,
  }) async {
    final category = await showLookupSelectorSheet<Category>(
      context: context,
      title: title,
      selectedValue: selected,
      options: [
        for (final category in options)
          LookupSelectorOption<Category>(
            value: category,
            label: category.name,
            subtitle: category.type.apiValue,
            icon: Icons.category_outlined,
          ),
      ],
    );
    if (category == null) return;
    onSelected(category);
  }

  Future<void> _save() async {
    final dueDate = _dueDateController.text.trim();
    final note = _noteController.text.trim();
    final controller = ref.read(debtControllerProvider.notifier);

    if (_isEditing) {
      await controller.updateDebt(
        widget.debt!,
        DebtUpdateRequest(
          counterpartyName: _counterpartyController.text.trim(),
          dueDate: dueDate.isEmpty ? null : dueDate,
          status: _status,
          note: note,
        ),
      );
    } else {
      await controller.createDebt(
        DebtRequest(
          type: _type,
          counterpartyName: _counterpartyController.text.trim(),
          walletId: _wallet!.id,
          disbursementCategoryId: _disbursementCategory!.id,
          paymentCategoryId: _paymentCategory!.id,
          principalAmountMinor: _moneyMinor(_amountController.text),
          dueDate: dueDate.isEmpty ? null : dueDate,
          note: note,
        ),
      );
    }
    if (mounted) Navigator.of(context).pop();
  }
}

Future<void> _showPaySheet(BuildContext context, Debt debt) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => _PayDebtSheet(debt: debt),
  );
}

class _PayDebtSheet extends ConsumerStatefulWidget {
  const _PayDebtSheet({required this.debt});

  final Debt debt;

  @override
  ConsumerState<_PayDebtSheet> createState() => _PayDebtSheetState();
}

class _PayDebtSheetState extends ConsumerState<_PayDebtSheet> {
  late final TextEditingController _amountController;
  late final TextEditingController _paidAtController;
  late final TextEditingController _noteController;

  @override
  void initState() {
    super.initState();
    _amountController = TextEditingController(
      text: widget.debt.remainingAmountMinor.toString(),
    );
    _paidAtController = TextEditingController();
    _noteController = TextEditingController();
  }

  @override
  void dispose() {
    _amountController.dispose();
    _paidAtController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(debtControllerProvider);
    final amount = _moneyMinor(_amountController.text);
    final canSave =
        amount > 0 &&
        amount <= widget.debt.remainingAmountMinor &&
        _validIsoDateTime(_paidAtController.text) &&
        !state.isSaving;

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          AffluenaSpacing.space5,
          AffluenaSpacing.space2,
          AffluenaSpacing.space5,
          MediaQuery.viewInsetsOf(context).bottom + AffluenaSpacing.space5,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Record payment',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: AffluenaSpacing.space2),
              Text(
                '${widget.debt.counterpartyName} · ${MoneyFormatter.idr(widget.debt.remainingAmountMinor)} remaining',
              ),
              const SizedBox(height: AffluenaSpacing.space4),
              TextField(
                key: const Key('debt-payment-amount-field'),
                controller: _amountController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.payments_outlined),
                  labelText: 'Payment amount',
                ),
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: AffluenaSpacing.space2),
              TextField(
                controller: _paidAtController,
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.today_outlined),
                  labelText: 'Paid at',
                  hintText: 'Optional RFC3339 timestamp',
                ),
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: AffluenaSpacing.space2),
              TextField(
                controller: _noteController,
                maxLines: 2,
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.notes_outlined),
                  labelText: 'Note',
                ),
              ),
              const SizedBox(height: AffluenaSpacing.space5),
              FilledButton(
                key: const Key('debt-payment-save-button'),
                onPressed: canSave ? _save : null,
                child: Text(state.isSaving ? 'Saving...' : 'Save payment'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _save() async {
    final paidAt = _paidAtController.text.trim();
    await ref
        .read(debtControllerProvider.notifier)
        .payDebt(
          widget.debt,
          DebtPaymentRequest(
            amountMinor: _moneyMinor(_amountController.text),
            paidAt: paidAt.isEmpty ? null : paidAt,
            note: _noteController.text.trim(),
          ),
        );
    if (mounted) Navigator.of(context).pop();
  }
}

Future<void> _confirmCancel(
  BuildContext context,
  DebtController controller,
  Debt debt,
) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Cancel debt?'),
      content: const Text(
        'This keeps the audit trail and marks the debt cancelled.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Keep'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: const Text('Cancel debt'),
        ),
      ],
    ),
  );
  if (confirmed == true) {
    await controller.cancelDebt(debt);
  }
}

T? _findById<T>(List<T> items, String? id) {
  if (id == null) return null;
  for (final item in items) {
    final value = switch (item) {
      Wallet(:final id) => id,
      Category(:final id) => id,
      _ => null,
    };
    if (value == id) return item;
  }
  return null;
}

int _moneyMinor(String value) {
  final normalized = value.replaceAll(RegExp(r'[^0-9]'), '');
  return int.tryParse(normalized) ?? 0;
}

bool _validDate(String value) {
  if (value.trim().isEmpty) return true;
  return RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(value.trim());
}

bool _validIsoDateTime(String value) {
  if (value.trim().isEmpty) return true;
  return DateTime.tryParse(value.trim()) != null;
}
