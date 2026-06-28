import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/affluena_theme.dart';
import '../../../core/formatters/date_formatter.dart';
import '../../../core/formatters/money_formatter.dart';
import '../../categories/data/category_models.dart';
import '../../shared/presentation/widgets/affluena_banner.dart';
import '../../shared/presentation/widgets/affluena_card.dart';
import '../../shared/presentation/widgets/affluena_skeleton.dart';
import '../../shared/presentation/widgets/date_picker_field.dart';
import '../../shared/presentation/widgets/drill_in_scaffold.dart';
import '../../shared/presentation/widgets/lookup_selector_sheet.dart';
import '../../shared/presentation/widgets/metric_tile.dart';
import '../../shared/presentation/widgets/money_input.dart';
import '../../shared/presentation/widgets/section_header.dart';
import '../../shared/presentation/widgets/selector_row.dart';
import '../../shared/presentation/widgets/status_badge.dart';
import '../../wallets/data/wallet_models.dart';
import '../application/debt_controller.dart';
import '../data/debt_models.dart';
import 'debt_detail_screen.dart';

class DebtScreen extends ConsumerWidget {
  const DebtScreen({super.key});

  static const path = '/debts';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(debtControllerProvider);
    final controller = ref.read(debtControllerProvider.notifier);

    return DrillInScaffold(
      title: 'Utang',
      actions: [
        IconButton(
          tooltip: 'Tambah utang',
          onPressed: state.wallets.isEmpty || state.isSaving
              ? null
              : () => _showDebtForm(context, state),
          icon: const Icon(Icons.add),
        ),
        const SizedBox(width: AffluenaSpacing.space2),
      ],
      body: _DebtBody(state: state, controller: controller),
    );
  }
}

class _DebtBody extends StatelessWidget {
  const _DebtBody({required this.state, required this.controller});

  final DebtState state;
  final DebtController controller;

  @override
  Widget build(BuildContext context) {
    if (state.isLoading && state.debts.isEmpty) {
      return const _DebtSkeleton();
    }

    if (state.loadError != null && state.debts.isEmpty) {
      return _DebtLoadError(onRetry: () => controller.load());
    }

    return RefreshIndicator(
      onRefresh: () => controller.load(),
      child: ListView(
        padding: AffluenaInsets.screen,
        children: [
          _DebtSummaryCard(state: state),
          const SizedBox(height: AffluenaSpacing.space5),
          if (state.actionError != null) ...[
            AffluenaBanner.error(
              state.actionError!,
              onRetry: () => controller.load(),
            ),
            const SizedBox(height: AffluenaSpacing.space4),
          ],
          _DebtTypeFilter(
            selected: state.typeFilter,
            onChanged: controller.setTypeFilter,
          ),
          const SizedBox(height: AffluenaSpacing.space5),
          SectionHeader(
            title: 'Utang',
            actionLabel: state.total == 0 ? null : '${state.total} total',
          ),
          const SizedBox(height: AffluenaSpacing.space3),
          if (state.visibleDebts.isEmpty)
            const _EmptyDebtState()
          else ...[
            for (final debt in state.visibleDebts) ...[
              _DebtCard(
                debt: debt,
                walletName: state.walletName(debt.walletId),
                paymentCategoryName: state.categoryName(debt.paymentCategoryId),
                onOpen: () => context.push(DebtDetailScreen.location(debt.id)),
                onPay: debt.canPay ? () => _showPaySheet(context, debt) : null,
                onEdit: () => _showDebtForm(context, state, debt: debt),
                onCancel: debt.status == DebtStatus.cancelled
                    ? null
                    : () => _confirmCancel(context, controller, debt),
              ),
              const SizedBox(height: AffluenaSpacing.space3),
            ],
            if (state.hasMore) ...[
              const SizedBox(height: AffluenaSpacing.space2),
              _LoadMoreButton(
                isLoading: state.isLoadingMore,
                onPressed: controller.loadMore,
              ),
            ],
          ],
        ],
      ),
    );
  }
}

class _LoadMoreButton extends StatelessWidget {
  const _LoadMoreButton({required this.isLoading, required this.onPressed});

  final bool isLoading;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const AffluenaCard(
        child: Column(
          children: [
            AffluenaSkeleton.line(),
            SizedBox(height: AffluenaSpacing.space3),
            AffluenaSkeleton.line(width: 220),
          ],
        ),
      );
    }
    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: const Icon(Icons.expand_more),
      label: const Text('Muat lebih banyak'),
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
                label: 'Utang',
                value: MoneyFormatter.idr(state.payableMinor),
                helper: 'Harus dibayar',
                icon: Icons.arrow_upward,
              ),
              const SizedBox(width: AffluenaSpacing.space3),
              MetricTile(
                label: 'Piutang',
                value: MoneyFormatter.idr(state.receivableMinor),
                helper: 'Harus ditagih',
                icon: Icons.arrow_downward,
              ),
            ],
          ),
          const SizedBox(height: AffluenaSpacing.space3),
          Row(
            children: [
              MetricTile(
                label: 'Jatuh tempo',
                value: state.dueSoonCount.toString(),
                helper: '7 hari ke depan',
                icon: Icons.event_outlined,
              ),
              const SizedBox(width: AffluenaSpacing.space3),
              MetricTile(
                label: 'Terbayar',
                value: MoneyFormatter.idr(state.paidMinor),
                helper: 'Utang lunas',
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
        ButtonSegment(value: null, label: Text('Semua')),
        ButtonSegment(value: DebtType.payable, label: Text('Utang')),
        ButtonSegment(value: DebtType.receivable, label: Text('Piutang')),
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
    required this.onOpen,
    required this.onEdit,
    this.onPay,
    this.onCancel,
  });

  final Debt debt;
  final String walletName;
  final String paymentCategoryName;
  final VoidCallback onOpen;
  final VoidCallback onEdit;
  final VoidCallback? onPay;
  final VoidCallback? onCancel;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colors = context.affluenaColors;
    final isPayable = debt.type == DebtType.payable;
    final accent = isPayable ? colors.coral : colors.success;

    return InkWell(
      borderRadius: BorderRadius.circular(AffluenaRadii.card),
      onTap: onOpen,
      child: AffluenaCard(
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
                      const SizedBox(height: AffluenaSpacing.space2),
                      Wrap(
                        spacing: AffluenaSpacing.space2,
                        runSpacing: AffluenaSpacing.space2,
                        children: [
                          StatusBadge(
                            label: isPayable ? 'Utang' : 'Piutang',
                            tone: isPayable
                                ? StatusTone.danger
                                : StatusTone.success,
                          ),
                          StatusBadge.forStatus(
                            debt.status.apiValue,
                            label: debt.status.label,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  onSelected: (value) {
                    if (value == 'open') onOpen();
                    if (value == 'edit') onEdit();
                    if (value == 'cancel' && onCancel != null) onCancel!();
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(value: 'open', child: Text('Lihat')),
                    const PopupMenuItem(value: 'edit', child: Text('Ubah')),
                    if (onCancel != null)
                      PopupMenuItem(
                        value: 'cancel',
                        child: Text(
                          'Batalkan utang',
                          style: TextStyle(color: colors.coral),
                        ),
                      ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: AffluenaSpacing.space3),
            ClipRRect(
              borderRadius: BorderRadius.circular(AffluenaRadii.pill),
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
              '${debt.paidPercent.round()}% lunas dari ${MoneyFormatter.idr(debt.principalAmountMinor)}',
              style: textTheme.bodySmall,
            ),
            const SizedBox(height: AffluenaSpacing.space2),
            Text(
              '${debt.dueDate == null || debt.dueDate!.isEmpty ? 'Tanpa jatuh tempo' : 'Jatuh tempo ${AffluenaDateFormatter.shortDate(debt.dueDate!)}'} · $walletName · $paymentCategoryName',
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
                label: const Text('Catat pembayaran'),
              ),
            ],
          ],
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
          Text('Belum ada utang', style: textTheme.titleMedium),
          const SizedBox(height: AffluenaSpacing.space1),
          Text(
            'Lacak saldo utang dan piutang lengkap dengan riwayat pembayaran.',
            style: textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}

class _DebtSkeleton extends StatelessWidget {
  const _DebtSkeleton();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: ListView(
        padding: AffluenaInsets.screen,
        children: [
          const AffluenaCard(
            child: Column(
              children: [
                AffluenaSkeleton(height: 56),
                SizedBox(height: AffluenaSpacing.space3),
                AffluenaSkeleton(height: 56),
              ],
            ),
          ),
          const SizedBox(height: AffluenaSpacing.space5),
          const AffluenaSkeleton(height: 48, radius: AffluenaRadii.control),
          const SizedBox(height: AffluenaSpacing.space5),
          for (var i = 0; i < 3; i++) ...[
            AffluenaCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  AffluenaSkeleton.line(width: 180, height: 16),
                  SizedBox(height: AffluenaSpacing.space3),
                  AffluenaSkeleton(height: 10, radius: AffluenaRadii.pill),
                  SizedBox(height: AffluenaSpacing.space3),
                  AffluenaSkeleton.line(width: 140, height: 20),
                  SizedBox(height: AffluenaSpacing.space2),
                  AffluenaSkeleton.line(width: 240),
                ],
              ),
            ),
            const SizedBox(height: AffluenaSpacing.space3),
          ],
        ],
      ),
    );
  }
}

class _DebtLoadError extends StatelessWidget {
  const _DebtLoadError({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: ListView(
        padding: AffluenaInsets.screen,
        children: [
          AffluenaBanner.error(
            'Kami tidak dapat memuat utang kamu.',
            onRetry: onRetry,
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
  late final TextEditingController _noteController;
  int? _amountMinor;
  DateTime? _dueDate;
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
    _noteController = TextEditingController(text: debt?.note ?? '');
    _amountMinor = debt?.principalAmountMinor;
    _dueDate = _parseDate(debt?.dueDate);
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
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final state = ref.watch(debtControllerProvider);
    final canSave =
        _counterpartyController.text.trim().isNotEmpty &&
        (_isEditing ||
            (_wallet != null &&
                _disbursementCategory != null &&
                _paymentCategory != null &&
                (_amountMinor ?? 0) > 0)) &&
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
                _isEditing ? 'Ubah utang' : 'Buat utang',
                style: textTheme.titleLarge,
              ),
              const SizedBox(height: AffluenaSpacing.space4),
              if (state.actionError != null) ...[
                AffluenaBanner.error(state.actionError!),
                const SizedBox(height: AffluenaSpacing.space4),
              ],
              if (!_isEditing) ...[
                SegmentedButton<DebtType>(
                  segments: const [
                    ButtonSegment(
                      value: DebtType.payable,
                      label: Text('Utang'),
                    ),
                    ButtonSegment(
                      value: DebtType.receivable,
                      label: Text('Piutang'),
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
                  labelText: 'Pihak terkait',
                ),
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: AffluenaSpacing.space2),
              if (!_isEditing) ...[
                SelectorRow(
                  label: 'Dompet',
                  value: _wallet?.name ?? 'Pilih dompet',
                  icon: Icons.account_balance_wallet_outlined,
                  onTap: () => _selectWallet(widget.state.wallets),
                ),
                const Divider(height: 1),
                SelectorRow(
                  label: _type == DebtType.payable
                      ? 'Dicatat sebagai pinjaman'
                      : 'Dicatat sebagai pemberian',
                  value: _disbursementCategory?.name ?? 'Pilih kategori',
                  icon: Icons.category_outlined,
                  onTap: () => _selectCategory(
                    title: 'Kategori awal',
                    options: widget.state.disbursementCategories(_type),
                    selected: _disbursementCategory,
                    onSelected: (category) =>
                        setState(() => _disbursementCategory = category),
                  ),
                ),
                const Divider(height: 1),
                SelectorRow(
                  label: _type == DebtType.payable
                      ? 'Pengeluaran pembayaran'
                      : 'Pemasukan penagihan',
                  value: _paymentCategory?.name ?? 'Pilih kategori',
                  icon: Icons.payments_outlined,
                  onTap: () => _selectCategory(
                    title: 'Kategori pembayaran',
                    options: widget.state.paymentCategories(_type),
                    selected: _paymentCategory,
                    onSelected: (category) =>
                        setState(() => _paymentCategory = category),
                  ),
                ),
                const SizedBox(height: AffluenaSpacing.space2),
                MoneyInput(
                  key: const Key('debt-amount-field'),
                  label: 'Jumlah pokok',
                  initialValue: _amountMinor,
                  onChanged: (value) => setState(() => _amountMinor = value),
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
              DatePickerField(
                label: 'Jatuh tempo',
                value: _dueDate,
                placeholder: 'Opsional',
                onChanged: (value) => setState(() => _dueDate = value),
              ),
              const SizedBox(height: AffluenaSpacing.space2),
              TextField(
                controller: _noteController,
                maxLines: 2,
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.notes_outlined),
                  labelText: 'Catatan',
                ),
              ),
              const SizedBox(height: AffluenaSpacing.space5),
              FilledButton(
                key: const Key('debt-save-button'),
                onPressed: canSave ? _save : null,
                child: Text(state.isSaving ? 'Menyimpan...' : 'Simpan utang'),
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
      title: 'Dompet utang',
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
    final note = _noteController.text.trim();
    final dueDate = _formatDate(_dueDate);
    final controller = ref.read(debtControllerProvider.notifier);

    if (_isEditing) {
      await controller.updateDebt(
        widget.debt!,
        DebtUpdateRequest(
          counterpartyName: _counterpartyController.text.trim(),
          dueDate: dueDate,
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
          principalAmountMinor: _amountMinor ?? 0,
          dueDate: dueDate,
          note: note,
        ),
      );
    }
    if (!mounted) return;
    if (ref.read(debtControllerProvider).actionError == null) {
      Navigator.of(context).pop();
    }
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
  late final TextEditingController _noteController;
  late int? _amountMinor;
  DateTime? _paidAt;

  @override
  void initState() {
    super.initState();
    _amountMinor = widget.debt.remainingAmountMinor;
    _noteController = TextEditingController();
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(debtControllerProvider);
    final amount = _amountMinor ?? 0;
    final canSave =
        amount > 0 &&
        amount <= widget.debt.remainingAmountMinor &&
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
                'Catat pembayaran',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: AffluenaSpacing.space2),
              Text(
                '${widget.debt.counterpartyName} · sisa ${MoneyFormatter.idr(widget.debt.remainingAmountMinor)}',
              ),
              const SizedBox(height: AffluenaSpacing.space4),
              if (state.actionError != null) ...[
                AffluenaBanner.error(state.actionError!),
                const SizedBox(height: AffluenaSpacing.space4),
              ],
              MoneyInput(
                key: const Key('debt-payment-amount-field'),
                label: 'Jumlah pembayaran',
                initialValue: _amountMinor,
                onChanged: (value) => setState(() => _amountMinor = value),
                validator: (value) {
                  final entered = value ?? 0;
                  if (entered <= 0) return 'Masukkan jumlah.';
                  if (entered > widget.debt.remainingAmountMinor) {
                    return 'Tidak boleh melebihi sisa saldo.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: AffluenaSpacing.space2),
              DatePickerField(
                label: 'Dibayar pada',
                value: _paidAt,
                icon: Icons.today_outlined,
                placeholder: 'Opsional',
                onChanged: (value) => setState(() => _paidAt = value),
              ),
              const SizedBox(height: AffluenaSpacing.space2),
              TextField(
                controller: _noteController,
                maxLines: 2,
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.notes_outlined),
                  labelText: 'Catatan',
                ),
              ),
              const SizedBox(height: AffluenaSpacing.space5),
              FilledButton(
                key: const Key('debt-payment-save-button'),
                onPressed: canSave ? _save : null,
                child: Text(
                  state.isSaving ? 'Menyimpan...' : 'Simpan pembayaran',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _save() async {
    await ref
        .read(debtControllerProvider.notifier)
        .payDebt(
          widget.debt,
          DebtPaymentRequest(
            amountMinor: _amountMinor ?? 0,
            paidAt: _formatDateTime(_paidAt),
            note: _noteController.text.trim(),
          ),
        );
    if (!mounted) return;
    if (ref.read(debtControllerProvider).actionError == null) {
      Navigator.of(context).pop();
    }
  }
}

Future<void> _confirmCancel(
  BuildContext context,
  DebtController controller,
  Debt debt,
) async {
  final colors = context.affluenaColors;
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Batalkan utang?'),
      content: const Text(
        'Ini tetap menyimpan jejak audit dan menandai utang sebagai dibatalkan.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Pertahankan'),
        ),
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: colors.coral),
          onPressed: () => Navigator.of(context).pop(true),
          child: const Text('Batalkan utang'),
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

DateTime? _parseDate(String? value) {
  if (value == null || value.isEmpty) return null;
  return DateTime.tryParse(value);
}

String? _formatDate(DateTime? value) {
  if (value == null) return null;
  final y = value.year.toString().padLeft(4, '0');
  final m = value.month.toString().padLeft(2, '0');
  final d = value.day.toString().padLeft(2, '0');
  return '$y-$m-$d';
}

String? _formatDateTime(DateTime? value) {
  if (value == null) return null;
  return value.toUtc().toIso8601String();
}
