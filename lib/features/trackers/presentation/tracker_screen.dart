import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
import '../application/tracker_controller.dart';
import '../data/tracker_models.dart';

class TrackerScreen extends ConsumerWidget {
  const TrackerScreen({super.key});

  static const path = '/trackers';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(trackerControllerProvider);
    final controller = ref.read(trackerControllerProvider.notifier);

    if (state.isLoading &&
        state.installments.isEmpty &&
        state.subscriptions.isEmpty) {
      return const _TrackerLoading();
    }

    if (state.loadError != null &&
        state.installments.isEmpty &&
        state.subscriptions.isEmpty) {
      return _TrackerError(onRetry: controller.load);
    }

    return DrillInScaffold(
      title: 'Trackers',
      actions: [
        IconButton.filledTonal(
          onPressed:
              state.wallets.isEmpty ||
                  state.categories.isEmpty ||
                  state.isSaving
              ? null
              : () => _showTrackerForm(context, state),
          icon: const Icon(Icons.add),
        ),
      ],
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          AffluenaSpacing.space5,
          AffluenaSpacing.space4,
          AffluenaSpacing.space5,
          AffluenaSpacing.space8,
        ),
        children: [
          _TrackerSummaryCard(state: state),
          const SizedBox(height: AffluenaSpacing.space5),
          if (state.actionError != null) ...[
            AffluenaBanner.error(
              state.actionError!,
              onRetry: controller.load,
            ),
            const SizedBox(height: AffluenaSpacing.space4),
          ],
          _TrackerTabs(selected: state.tab, onChanged: controller.setTab),
          const SizedBox(height: AffluenaSpacing.space5),
          if (state.tab == TrackerTab.installments)
            _InstallmentList(state: state, controller: controller)
          else
            _SubscriptionList(state: state, controller: controller),
        ],
      ),
    );
  }
}

class _TrackerSummaryCard extends StatelessWidget {
  const _TrackerSummaryCard({required this.state});

  final TrackerState state;

  @override
  Widget build(BuildContext context) {
    return AffluenaCard(
      child: Column(
        children: [
          Row(
            children: [
              MetricTile(
                label: 'Installments',
                value: MoneyFormatter.idr(state.installmentMonthlyMinor),
                helper: 'Monthly due',
                icon: Icons.receipt_long_outlined,
              ),
              const SizedBox(width: AffluenaSpacing.space3),
              MetricTile(
                label: 'Subscriptions',
                value: MoneyFormatter.idr(state.subscriptionMonthlyMinor),
                helper: 'Monthly',
                icon: Icons.autorenew,
              ),
            ],
          ),
          const SizedBox(height: AffluenaSpacing.space3),
          Row(
            children: [
              MetricTile(
                label: 'Weekly',
                value: MoneyFormatter.idr(state.weeklySubscriptionMinor),
                helper: 'Subscriptions',
                icon: Icons.view_week_outlined,
              ),
              const SizedBox(width: AffluenaSpacing.space3),
              MetricTile(
                label: 'Due soon',
                value: state.dueSoonCount.toString(),
                helper: 'Next 7 days',
                icon: Icons.event_outlined,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TrackerTabs extends StatelessWidget {
  const _TrackerTabs({required this.selected, required this.onChanged});

  final TrackerTab selected;
  final ValueChanged<TrackerTab> onChanged;

  @override
  Widget build(BuildContext context) {
    return SegmentedButton<TrackerTab>(
      segments: const [
        ButtonSegment(
          value: TrackerTab.installments,
          label: Text('Installments', key: Key('tracker-installments-tab')),
        ),
        ButtonSegment(
          value: TrackerTab.subscriptions,
          label: Text('Subscriptions', key: Key('tracker-subscriptions-tab')),
        ),
      ],
      selected: {selected},
      onSelectionChanged: (values) => onChanged(values.first),
    );
  }
}

class _InstallmentList extends StatelessWidget {
  const _InstallmentList({required this.state, required this.controller});

  final TrackerState state;
  final TrackerController controller;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(
          title: 'Installments',
          actionLabel: state.installmentTotal == 0
              ? null
              : '${state.installmentTotal} total',
        ),
        const SizedBox(height: AffluenaSpacing.space3),
        if (state.installments.isEmpty)
          const _TrackerEmptyState(
            title: 'No installments yet',
            body: 'Track tenor, monthly due amount, and remaining payments.',
            icon: Icons.receipt_long_outlined,
          )
        else
          for (final item in state.installments) ...[
            _InstallmentCard(
              item: item,
              walletName: state.walletName(item.walletId),
              categoryName: state.categoryName(item.categoryId),
              onPay: item.canPay
                  ? () => _showTrackerPaymentSheet(
                      context,
                      title: 'Pay installment',
                      subtitle:
                          '${item.name} · ${MoneyFormatter.idr(item.monthlyAmountMinor)}',
                      onSave: (request) =>
                          controller.payInstallment(item, request),
                    )
                  : null,
              onEdit: () => _showTrackerForm(context, state, installment: item),
              onCancel: item.status == InstallmentStatus.cancelled
                  ? null
                  : () => _confirm(
                      context,
                      title: 'Cancel installment?',
                      body:
                          'This keeps the record and marks the installment cancelled.',
                      actionLabel: 'Cancel installment',
                      onConfirm: () => controller.cancelInstallment(item),
                    ),
              onDelete: () => _confirm(
                context,
                title: 'Delete installment?',
                body:
                    'This permanently removes the installment and its schedule. This cannot be undone.',
                actionLabel: 'Delete installment',
                onConfirm: () => controller.deleteInstallment(item),
              ),
            ),
            const SizedBox(height: AffluenaSpacing.space3),
          ],
      ],
    );
  }
}

class _SubscriptionList extends StatelessWidget {
  const _SubscriptionList({required this.state, required this.controller});

  final TrackerState state;
  final TrackerController controller;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(
          title: 'Subscriptions',
          actionLabel: state.subscriptionTotal == 0
              ? null
              : '${state.subscriptionTotal} total',
        ),
        const SizedBox(height: AffluenaSpacing.space3),
        if (state.subscriptions.isEmpty)
          const _TrackerEmptyState(
            title: 'No subscriptions yet',
            body: 'Track app, service, and recurring subscription payments.',
            icon: Icons.autorenew,
          )
        else
          for (final item in state.subscriptions) ...[
            _SubscriptionCard(
              item: item,
              walletName: state.walletName(item.walletId),
              categoryName: state.categoryName(item.categoryId),
              onPay: item.canPay
                  ? () => _showTrackerPaymentSheet(
                      context,
                      title: 'Pay subscription',
                      subtitle:
                          '${item.name} · ${MoneyFormatter.idr(item.amountMinor)}',
                      onSave: (request) =>
                          controller.paySubscription(item, request),
                    )
                  : null,
              onEdit: () =>
                  _showTrackerForm(context, state, subscription: item),
              onPause: item.status == SubscriptionStatus.active
                  ? () => controller.setSubscriptionStatus(
                      item,
                      SubscriptionStatus.paused,
                    )
                  : null,
              onResume: item.status == SubscriptionStatus.paused
                  ? () => controller.setSubscriptionStatus(
                      item,
                      SubscriptionStatus.active,
                    )
                  : null,
              onCancel: item.status == SubscriptionStatus.cancelled
                  ? null
                  : () => _confirm(
                      context,
                      title: 'Cancel subscription?',
                      body:
                          'This keeps the record and marks the subscription cancelled.',
                      actionLabel: 'Cancel subscription',
                      onConfirm: () => controller.setSubscriptionStatus(
                        item,
                        SubscriptionStatus.cancelled,
                      ),
                    ),
              onDelete: () => _confirm(
                context,
                title: 'Delete subscription?',
                body:
                    'This permanently removes the subscription. This cannot be undone.',
                actionLabel: 'Delete subscription',
                onConfirm: () => controller.deleteSubscription(item),
              ),
            ),
            const SizedBox(height: AffluenaSpacing.space3),
          ],
      ],
    );
  }
}

class _InstallmentCard extends StatelessWidget {
  const _InstallmentCard({
    required this.item,
    required this.walletName,
    required this.categoryName,
    required this.onEdit,
    required this.onDelete,
    this.onPay,
    this.onCancel,
  });

  final Installment item;
  final String walletName;
  final String categoryName;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback? onPay;
  final VoidCallback? onCancel;

  @override
  Widget build(BuildContext context) {
    return _TrackerCard(
      title: item.name,
      statusApiValue: item.status.apiValue,
      statusLabel: item.status.label,
      amount: MoneyFormatter.idr(item.monthlyAmountMinor),
      progress: item.paidPercent / 100,
      meta:
          '${item.remainingMonths}/${item.tenorMonths} months left · due day ${item.dueDay}',
      detail: '$walletName · $categoryName',
      note: item.note,
      actionLabel: 'Pay installment',
      onAction: onPay,
      menuItems: [
        _TrackerMenuItem(label: 'Edit', onTap: onEdit),
        if (onCancel != null)
          _TrackerMenuItem(
            label: 'Cancel installment',
            onTap: onCancel!,
            destructive: true,
          ),
        _TrackerMenuItem(
          label: 'Delete installment',
          onTap: onDelete,
          destructive: true,
        ),
      ],
    );
  }
}

class _SubscriptionCard extends StatelessWidget {
  const _SubscriptionCard({
    required this.item,
    required this.walletName,
    required this.categoryName,
    required this.onEdit,
    required this.onDelete,
    this.onPay,
    this.onPause,
    this.onResume,
    this.onCancel,
  });

  final Subscription item;
  final String walletName;
  final String categoryName;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback? onPay;
  final VoidCallback? onPause;
  final VoidCallback? onResume;
  final VoidCallback? onCancel;

  @override
  Widget build(BuildContext context) {
    return _TrackerCard(
      title: item.name,
      statusApiValue: item.status.apiValue,
      statusLabel: item.status.label,
      amount: MoneyFormatter.idr(item.amountMinor),
      progress: item.status == SubscriptionStatus.active ? 1 : 0,
      meta:
          '${item.billingCycle.label} · due ${AffluenaDateFormatter.shortDate(item.nextDueDate)}',
      detail: '$walletName · $categoryName',
      note: item.accountDetail.isNotEmpty ? item.accountDetail : item.note,
      actionLabel: 'Pay subscription',
      onAction: onPay,
      menuItems: [
        _TrackerMenuItem(label: 'Edit', onTap: onEdit),
        if (onPause != null) _TrackerMenuItem(label: 'Pause', onTap: onPause!),
        if (onResume != null)
          _TrackerMenuItem(label: 'Resume', onTap: onResume!),
        if (onCancel != null)
          _TrackerMenuItem(
            label: 'Cancel subscription',
            onTap: onCancel!,
            destructive: true,
          ),
        _TrackerMenuItem(
          label: 'Delete subscription',
          onTap: onDelete,
          destructive: true,
        ),
      ],
    );
  }
}

class _TrackerCard extends StatelessWidget {
  const _TrackerCard({
    required this.title,
    required this.statusApiValue,
    required this.statusLabel,
    required this.amount,
    required this.progress,
    required this.meta,
    required this.detail,
    required this.menuItems,
    this.note = '',
    this.actionLabel,
    this.onAction,
  });

  final String title;
  final String statusApiValue;
  final String statusLabel;
  final String amount;
  final double progress;
  final String meta;
  final String detail;
  final String note;
  final String? actionLabel;
  final VoidCallback? onAction;
  final List<_TrackerMenuItem> menuItems;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colors = context.affluenaColors;
    final normalizedStatus = statusApiValue.trim().toLowerCase();
    final progressColor = switch (normalizedStatus) {
      'paused' => colors.amber,
      'cancelled' || 'canceled' => colors.inkMuted,
      _ => colors.success,
    };

    return AffluenaCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text(title, style: textTheme.titleMedium)),
              StatusBadge.forStatus(statusApiValue, label: statusLabel),
              PopupMenuButton<int>(
                onSelected: (index) => menuItems[index].onTap(),
                itemBuilder: (context) => [
                  for (var i = 0; i < menuItems.length; i++)
                    PopupMenuItem(
                      value: i,
                      child: Text(
                        menuItems[i].label,
                        style: menuItems[i].destructive
                            ? TextStyle(color: colors.coral)
                            : null,
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
              value: progress.clamp(0, 1),
              minHeight: 10,
              color: progressColor,
              backgroundColor: colors.surfaceTintSoft,
            ),
          ),
          const SizedBox(height: AffluenaSpacing.space3),
          Text(amount, style: textTheme.headlineSmall),
          const SizedBox(height: AffluenaSpacing.space1),
          Text(meta, style: textTheme.bodySmall),
          const SizedBox(height: AffluenaSpacing.space1),
          Text(detail, style: textTheme.bodySmall),
          if (note.isNotEmpty) ...[
            const SizedBox(height: AffluenaSpacing.space2),
            Text(note, style: textTheme.bodySmall),
          ],
          if (onAction != null && actionLabel != null) ...[
            const SizedBox(height: AffluenaSpacing.space4),
            FilledButton.icon(
              onPressed: onAction,
              icon: const Icon(Icons.payments_outlined),
              label: Text(actionLabel!),
            ),
          ],
        ],
      ),
    );
  }
}

class _TrackerMenuItem {
  const _TrackerMenuItem({
    required this.label,
    required this.onTap,
    this.destructive = false,
  });

  final String label;
  final VoidCallback onTap;
  final bool destructive;
}

class _TrackerEmptyState extends StatelessWidget {
  const _TrackerEmptyState({
    required this.title,
    required this.body,
    required this.icon,
  });

  final String title;
  final String body;
  final IconData icon;

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
          Icon(icon, color: colors.forest),
          const SizedBox(height: AffluenaSpacing.space3),
          Text(title, style: textTheme.titleMedium),
          const SizedBox(height: AffluenaSpacing.space1),
          Text(body, style: textTheme.bodySmall),
        ],
      ),
    );
  }
}

class _TrackerLoading extends StatelessWidget {
  const _TrackerLoading();

  @override
  Widget build(BuildContext context) {
    return DrillInScaffold(
      title: 'Trackers',
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          AffluenaSpacing.space5,
          AffluenaSpacing.space4,
          AffluenaSpacing.space5,
          AffluenaSpacing.space8,
        ),
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

class _TrackerError extends StatelessWidget {
  const _TrackerError({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return DrillInScaffold(
      title: 'Trackers',
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          AffluenaSpacing.space5,
          AffluenaSpacing.space4,
          AffluenaSpacing.space5,
          AffluenaSpacing.space8,
        ),
        children: [
          AffluenaBanner.error(
            'We could not load your trackers.',
            onRetry: onRetry,
          ),
        ],
      ),
    );
  }
}

Future<void> _showTrackerForm(
  BuildContext context,
  TrackerState state, {
  Installment? installment,
  Subscription? subscription,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => _TrackerFormSheet(
      state: state,
      installment: installment,
      subscription: subscription,
    ),
  );
}

class _TrackerFormSheet extends ConsumerStatefulWidget {
  const _TrackerFormSheet({
    required this.state,
    this.installment,
    this.subscription,
  });

  final TrackerState state;
  final Installment? installment;
  final Subscription? subscription;

  @override
  ConsumerState<_TrackerFormSheet> createState() => _TrackerFormSheetState();
}

class _TrackerFormSheetState extends ConsumerState<_TrackerFormSheet> {
  late TrackerTab _tab;
  late final TextEditingController _nameController;
  late final TextEditingController _tenorController;
  late final TextEditingController _dueDayController;
  late final TextEditingController _accountController;
  late final TextEditingController _noteController;
  int? _amountMinor;
  int? _monthlyMinor;
  DateTime? _date;
  Wallet? _wallet;
  Category? _category;
  InstallmentStatus? _installmentStatus;
  SubscriptionStatus? _subscriptionStatus;
  BillingCycle _billingCycle = BillingCycle.monthly;

  bool get _isEditing =>
      widget.installment != null || widget.subscription != null;

  @override
  void initState() {
    super.initState();
    final installment = widget.installment;
    final subscription = widget.subscription;
    _tab = installment != null
        ? TrackerTab.installments
        : subscription != null
        ? TrackerTab.subscriptions
        : widget.state.tab;
    _nameController = TextEditingController(
      text: installment?.name ?? subscription?.name ?? '',
    );
    _amountMinor = installment?.totalAmountMinor ?? subscription?.amountMinor;
    _monthlyMinor = installment?.monthlyAmountMinor;
    _tenorController = TextEditingController(
      text: installment?.tenorMonths.toString() ?? '',
    );
    _date = _parseDate(installment?.startDate ?? subscription?.nextDueDate);
    _dueDayController = TextEditingController(
      text: installment?.dueDay.toString() ?? '',
    );
    _accountController = TextEditingController(
      text: subscription?.accountDetail ?? '',
    );
    _noteController = TextEditingController(
      text: installment?.note ?? subscription?.note ?? '',
    );
    _installmentStatus = installment?.status;
    _subscriptionStatus = subscription?.status;
    _billingCycle = subscription?.billingCycle ?? BillingCycle.monthly;
    _wallet = _findById(
      widget.state.wallets,
      installment?.walletId ?? subscription?.walletId,
    );
    _category = _findById(
      widget.state.categories,
      installment?.categoryId ?? subscription?.categoryId,
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _tenorController.dispose();
    _dueDayController.dispose();
    _accountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(trackerControllerProvider);
    final title = _isEditing
        ? 'Edit tracker'
        : _tab == TrackerTab.installments
        ? 'Create installment'
        : 'Create subscription';
    final canSave =
        _nameController.text.trim().isNotEmpty &&
        _wallet != null &&
        _category != null &&
        (_amountMinor ?? 0) > 0 &&
        _date != null &&
        (_tab == TrackerTab.subscriptions ||
            ((_monthlyMinor ?? 0) > 0 &&
                _intValue(_tenorController.text) > 0 &&
                _intValue(_dueDayController.text) >= 1 &&
                _intValue(_dueDayController.text) <= 31)) &&
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
              Text(title, style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: AffluenaSpacing.space4),
              if (state.actionError != null) ...[
                AffluenaBanner.error(state.actionError!),
                const SizedBox(height: AffluenaSpacing.space4),
              ],
              if (!_isEditing)
                SegmentedButton<TrackerTab>(
                  segments: const [
                    ButtonSegment(
                      value: TrackerTab.installments,
                      label: Text('Installment'),
                    ),
                    ButtonSegment(
                      value: TrackerTab.subscriptions,
                      label: Text('Subscription'),
                    ),
                  ],
                  selected: {_tab},
                  onSelectionChanged: (values) =>
                      setState(() => _tab = values.first),
                ),
              const SizedBox(height: AffluenaSpacing.space3),
              TextField(
                controller: _nameController,
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.label_outline),
                  labelText: 'Name',
                ),
                onChanged: (_) => setState(() {}),
              ),
              if (_tab == TrackerTab.subscriptions) ...[
                const SizedBox(height: AffluenaSpacing.space2),
                TextField(
                  controller: _accountController,
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.badge_outlined),
                    labelText: 'Account detail',
                  ),
                ),
              ],
              const SizedBox(height: AffluenaSpacing.space2),
              SelectorRow(
                label: 'Wallet',
                value: _wallet?.name ?? 'Choose wallet',
                icon: Icons.account_balance_wallet_outlined,
                onTap: () => _selectWallet(widget.state.wallets),
              ),
              const Divider(height: 1),
              SelectorRow(
                label: 'Expense category',
                value: _category?.name ?? 'Choose category',
                icon: Icons.category_outlined,
                onTap: () => _selectCategory(widget.state.categories),
              ),
              const Divider(height: 1),
              const SizedBox(height: AffluenaSpacing.space2),
              MoneyInput(
                key: const Key('tracker-amount-field'),
                label: _tab == TrackerTab.installments
                    ? 'Total amount'
                    : 'Amount',
                initialValue: _amountMinor,
                onChanged: (value) => setState(() => _amountMinor = value),
              ),
              if (_tab == TrackerTab.installments) ...[
                const SizedBox(height: AffluenaSpacing.space2),
                MoneyInput(
                  label: 'Monthly amount',
                  initialValue: _monthlyMinor,
                  onChanged: (value) => setState(() => _monthlyMinor = value),
                ),
                const SizedBox(height: AffluenaSpacing.space2),
                TextField(
                  controller: _tenorController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.timelapse_outlined),
                    labelText: 'Tenor months',
                  ),
                  onChanged: (_) => setState(() {}),
                ),
                const SizedBox(height: AffluenaSpacing.space2),
                TextField(
                  controller: _dueDayController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.event_outlined),
                    labelText: 'Due day',
                    hintText: '1-31',
                  ),
                  onChanged: (_) => setState(() {}),
                ),
              ] else ...[
                const SizedBox(height: AffluenaSpacing.space2),
                DropdownButtonFormField<BillingCycle>(
                  initialValue: _billingCycle,
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.repeat),
                    labelText: 'Billing cycle',
                  ),
                  items: BillingCycle.values
                      .map(
                        (cycle) => DropdownMenuItem(
                          value: cycle,
                          child: Text(cycle.label),
                        ),
                      )
                      .toList(growable: false),
                  onChanged: (cycle) {
                    if (cycle == null) return;
                    setState(() => _billingCycle = cycle);
                  },
                ),
              ],
              const SizedBox(height: AffluenaSpacing.space2),
              DatePickerField(
                key: const Key('tracker-date-field'),
                label: _tab == TrackerTab.installments
                    ? 'Start date'
                    : 'Next due date',
                value: _date,
                icon: Icons.today_outlined,
                placeholder: 'Choose date',
                onChanged: (value) => setState(() => _date = value),
              ),
              if (_isEditing && _tab == TrackerTab.installments) ...[
                const SizedBox(height: AffluenaSpacing.space2),
                DropdownButtonFormField<InstallmentStatus>(
                  initialValue: _installmentStatus,
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.flag_outlined),
                    labelText: 'Status',
                  ),
                  items: InstallmentStatus.values
                      .map(
                        (status) => DropdownMenuItem(
                          value: status,
                          child: Text(status.label),
                        ),
                      )
                      .toList(growable: false),
                  onChanged: (status) =>
                      setState(() => _installmentStatus = status),
                ),
              ],
              if (_isEditing && _tab == TrackerTab.subscriptions) ...[
                const SizedBox(height: AffluenaSpacing.space2),
                DropdownButtonFormField<SubscriptionStatus>(
                  initialValue: _subscriptionStatus,
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.flag_outlined),
                    labelText: 'Status',
                  ),
                  items: SubscriptionStatus.values
                      .map(
                        (status) => DropdownMenuItem(
                          value: status,
                          child: Text(status.label),
                        ),
                      )
                      .toList(growable: false),
                  onChanged: (status) =>
                      setState(() => _subscriptionStatus = status),
                ),
              ],
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
                key: const Key('tracker-save-button'),
                onPressed: canSave ? _save : null,
                child: Text(state.isSaving ? 'Saving...' : 'Save tracker'),
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
      title: 'Tracker wallet',
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

  Future<void> _selectCategory(List<Category> categories) async {
    final selected = await showLookupSelectorSheet<Category>(
      context: context,
      title: 'Expense category',
      selectedValue: _category,
      options: [
        for (final category in categories)
          LookupSelectorOption<Category>(
            value: category,
            label: category.name,
            subtitle: category.type.apiValue,
            icon: Icons.category_outlined,
          ),
      ],
    );
    if (selected == null) return;
    setState(() => _category = selected);
  }

  Future<void> _save() async {
    final controller = ref.read(trackerControllerProvider.notifier);
    final note = _noteController.text.trim();
    final dateValue = _formatDate(_date)!;

    if (_tab == TrackerTab.installments) {
      final request = InstallmentRequest(
        name: _nameController.text.trim(),
        walletId: _wallet!.id,
        categoryId: _category!.id,
        totalAmountMinor: _amountMinor ?? 0,
        monthlyAmountMinor: _monthlyMinor ?? 0,
        tenorMonths: _intValue(_tenorController.text),
        remainingMonths: widget.installment?.remainingMonths,
        startDate: dateValue,
        dueDay: _intValue(_dueDayController.text),
        status: _installmentStatus,
        note: note,
      );
      if (widget.installment == null) {
        await controller.createInstallment(request);
      } else {
        await controller.updateInstallment(widget.installment!, request);
      }
    } else {
      final request = SubscriptionRequest(
        name: _nameController.text.trim(),
        accountDetail: _accountController.text.trim(),
        walletId: _wallet!.id,
        categoryId: _category!.id,
        amountMinor: _amountMinor ?? 0,
        billingCycle: _billingCycle,
        nextDueDate: dateValue,
        status: _subscriptionStatus,
        note: note,
      );
      if (widget.subscription == null) {
        await controller.createSubscription(request);
      } else {
        await controller.updateSubscription(widget.subscription!, request);
      }
    }
    if (!mounted) return;
    if (ref.read(trackerControllerProvider).actionError == null) {
      Navigator.of(context).pop();
    }
  }
}

Future<void> _showTrackerPaymentSheet(
  BuildContext context, {
  required String title,
  required String subtitle,
  required Future<void> Function(TrackerPaymentRequest request) onSave,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) =>
        _TrackerPaymentSheet(title: title, subtitle: subtitle, onSave: onSave),
  );
}

class _TrackerPaymentSheet extends ConsumerStatefulWidget {
  const _TrackerPaymentSheet({
    required this.title,
    required this.subtitle,
    required this.onSave,
  });

  final String title;
  final String subtitle;
  final Future<void> Function(TrackerPaymentRequest request) onSave;

  @override
  ConsumerState<_TrackerPaymentSheet> createState() =>
      _TrackerPaymentSheetState();
}

class _TrackerPaymentSheetState extends ConsumerState<_TrackerPaymentSheet> {
  final _noteController = TextEditingController();
  DateTime? _paidAt;

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(trackerControllerProvider);
    final canSave = !state.isSaving;

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
              Text(widget.title, style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: AffluenaSpacing.space2),
              Text(widget.subtitle),
              const SizedBox(height: AffluenaSpacing.space4),
              if (state.actionError != null) ...[
                AffluenaBanner.error(state.actionError!),
                const SizedBox(height: AffluenaSpacing.space4),
              ],
              DatePickerField(
                key: const Key('tracker-payment-date-field'),
                label: 'Paid at',
                value: _paidAt,
                icon: Icons.today_outlined,
                placeholder: 'Optional · defaults to today',
                onChanged: (value) => setState(() => _paidAt = value),
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
                key: const Key('tracker-payment-save-button'),
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
    await widget.onSave(
      TrackerPaymentRequest(
        paidAt: _formatDateTime(_paidAt),
        note: _noteController.text.trim(),
      ),
    );
    if (!mounted) return;
    if (ref.read(trackerControllerProvider).actionError == null) {
      Navigator.of(context).pop();
    }
  }
}

Future<void> _confirm(
  BuildContext context, {
  required String title,
  required String body,
  required String actionLabel,
  required Future<void> Function() onConfirm,
}) async {
  final colors = context.affluenaColors;
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(title),
      content: Text(body),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Keep'),
        ),
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: colors.coral),
          onPressed: () => Navigator.of(context).pop(true),
          child: Text(actionLabel),
        ),
      ],
    ),
  );
  if (confirmed == true) {
    await onConfirm();
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

int _intValue(String value) {
  final normalized = value.replaceAll(RegExp(r'[^0-9]'), '');
  return int.tryParse(normalized) ?? 0;
}

DateTime? _parseDate(String? value) {
  if (value == null || value.isEmpty) return null;
  return DateTime.tryParse(value)?.toLocal();
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
