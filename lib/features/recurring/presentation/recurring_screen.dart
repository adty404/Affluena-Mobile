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
import '../../shared/presentation/widgets/lookup_selector_sheet.dart';
import '../../shared/presentation/widgets/metric_tile.dart';
import '../../shared/presentation/widgets/money_input.dart';
import '../../shared/presentation/widgets/section_header.dart';
import '../../shared/presentation/widgets/selector_row.dart';
import '../../shared/presentation/widgets/status_badge.dart';
import '../../wallets/data/wallet_models.dart';
import '../application/recurring_controller.dart';
import '../data/recurring_models.dart';

class RecurringScreen extends ConsumerWidget {
  const RecurringScreen({super.key});

  static const path = '/recurring';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(recurringControllerProvider);
    final controller = ref.read(recurringControllerProvider.notifier);
    final textTheme = Theme.of(context).textTheme;

    if (state.isLoading && state.rules.isEmpty) {
      return const _RecurringLoading();
    }

    if (state.loadError != null && state.rules.isEmpty) {
      return _RecurringError(onRetry: controller.load);
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
                child: Text('Recurring', style: textTheme.headlineMedium),
              ),
              IconButton.filledTonal(
                onPressed: state.wallets.isEmpty || state.isSaving
                    ? null
                    : () => _showRecurringForm(context, state),
                icon: const Icon(Icons.add),
              ),
            ],
          ),
          const SizedBox(height: AffluenaSpacing.space5),
          _RecurringSummaryCard(state: state),
          const SizedBox(height: AffluenaSpacing.space5),
          if (state.actionError != null) ...[
            AffluenaBanner.error(
              state.actionError!,
              onRetry: controller.load,
            ),
            const SizedBox(height: AffluenaSpacing.space4),
          ],
          SectionHeader(
            title: 'Rules',
            actionLabel: state.total == 0 ? null : '${state.total} total',
          ),
          const SizedBox(height: AffluenaSpacing.space3),
          if (state.rules.isEmpty)
            const _RecurringEmptyState()
          else
            for (final rule in state.rules) ...[
              _RecurringCard(
                rule: rule,
                walletName: state.walletName(rule.walletId),
                destinationName: rule.toWalletId == null
                    ? null
                    : state.walletName(rule.toWalletId!),
                categoryName: state.categoryName(rule.categoryId),
                onRun: rule.canRun ? () => controller.runRule(rule) : null,
                onEdit: () => _showRecurringForm(context, state, rule: rule),
                onPause: rule.status == RecurringStatus.active
                    ? () => controller.setStatus(rule, RecurringStatus.paused)
                    : null,
                onResume: rule.status == RecurringStatus.paused
                    ? () => controller.setStatus(rule, RecurringStatus.active)
                    : null,
                onCancel: rule.status == RecurringStatus.cancelled
                    ? null
                    : () =>
                          controller.setStatus(rule, RecurringStatus.cancelled),
                onDelete: () => _confirm(
                  context,
                  title: 'Delete recurring rule?',
                  body:
                      'This removes the rule. Existing transactions stay intact.',
                  actionLabel: 'Delete rule',
                  onConfirm: () => controller.deleteRule(rule),
                ),
              ),
              const SizedBox(height: AffluenaSpacing.space3),
            ],
        ],
      ),
    );
  }
}

class _RecurringSummaryCard extends StatelessWidget {
  const _RecurringSummaryCard({required this.state});

  final RecurringState state;

  @override
  Widget build(BuildContext context) {
    return AffluenaCard(
      child: Column(
        children: [
          Row(
            children: [
              MetricTile(
                label: 'Monthly spend',
                value: MoneyFormatter.idr(state.monthlyExpenseMinor),
                helper: 'Active rules',
                icon: Icons.autorenew,
              ),
              const SizedBox(width: AffluenaSpacing.space3),
              MetricTile(
                label: 'Active',
                value: state.activeCount.toString(),
                helper: 'Running rules',
                icon: Icons.play_circle_outline,
              ),
            ],
          ),
          const SizedBox(height: AffluenaSpacing.space3),
          Row(
            children: [
              MetricTile(
                label: 'Due soon',
                value: state.upcomingCount.toString(),
                helper: 'Next 7 days',
                icon: Icons.event_outlined,
              ),
              const SizedBox(width: AffluenaSpacing.space3),
              MetricTile(
                label: 'Total',
                value: state.total.toString(),
                helper: 'Rules',
                icon: Icons.rule_folder_outlined,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _RecurringCard extends StatelessWidget {
  const _RecurringCard({
    required this.rule,
    required this.walletName,
    required this.categoryName,
    required this.onEdit,
    required this.onDelete,
    this.destinationName,
    this.onRun,
    this.onPause,
    this.onResume,
    this.onCancel,
  });

  final RecurringRule rule;
  final String walletName;
  final String? destinationName;
  final String categoryName;
  final VoidCallback? onRun;
  final VoidCallback onEdit;
  final VoidCallback? onPause;
  final VoidCallback? onResume;
  final VoidCallback? onCancel;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colors = context.affluenaColors;
    final detail = rule.type == RecurringType.transfer
        ? '$walletName to ${destinationName ?? 'Unknown wallet'}'
        : '$walletName · $categoryName';

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
                    Text(rule.name, style: textTheme.titleMedium),
                    const SizedBox(height: AffluenaSpacing.space1),
                    Wrap(
                      spacing: AffluenaSpacing.space2,
                      runSpacing: AffluenaSpacing.space2,
                      children: [
                        StatusBadge(
                          label: rule.type.label,
                          tone: StatusTone.neutral,
                        ),
                        StatusBadge.forStatus(
                          rule.status.apiValue,
                          label: rule.status.label,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              PopupMenuButton<String>(
                onSelected: (value) {
                  if (value == 'edit') onEdit();
                  if (value == 'pause' && onPause != null) onPause!();
                  if (value == 'resume' && onResume != null) onResume!();
                  if (value == 'cancel' && onCancel != null) onCancel!();
                  if (value == 'delete') onDelete();
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(value: 'edit', child: Text('Edit')),
                  if (onPause != null)
                    const PopupMenuItem(value: 'pause', child: Text('Pause')),
                  if (onResume != null)
                    const PopupMenuItem(value: 'resume', child: Text('Resume')),
                  if (onCancel != null)
                    PopupMenuItem(
                      value: 'cancel',
                      child: Text(
                        'Cancel rule',
                        style: TextStyle(color: colors.coral),
                      ),
                    ),
                  PopupMenuItem(
                    value: 'delete',
                    child: Text(
                      'Delete',
                      style: TextStyle(color: colors.coral),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: AffluenaSpacing.space3),
          Text(
            MoneyFormatter.idr(rule.amountMinor),
            style: textTheme.headlineSmall,
          ),
          const SizedBox(height: AffluenaSpacing.space1),
          Text(
            '${rule.frequencyLabel} · next ${AffluenaDateFormatter.shortDate(rule.nextRunAt)}',
            style: textTheme.bodySmall,
          ),
          const SizedBox(height: AffluenaSpacing.space1),
          Text(detail, style: textTheme.bodySmall),
          if (rule.lastRunAt != null) ...[
            const SizedBox(height: AffluenaSpacing.space1),
            Text(
              'Last run ${AffluenaDateFormatter.shortDate(rule.lastRunAt!)}',
              style: textTheme.bodySmall,
            ),
          ],
          if (rule.note.isNotEmpty) ...[
            const SizedBox(height: AffluenaSpacing.space2),
            Text(rule.note, style: textTheme.bodySmall),
          ],
          if (onRun != null) ...[
            const SizedBox(height: AffluenaSpacing.space4),
            FilledButton.icon(
              onPressed: onRun,
              icon: const Icon(Icons.play_arrow_outlined),
              label: const Text('Run now'),
            ),
          ],
        ],
      ),
    );
  }
}

class _RecurringEmptyState extends StatelessWidget {
  const _RecurringEmptyState();

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
          Icon(Icons.autorenew, color: colors.forest),
          const SizedBox(height: AffluenaSpacing.space3),
          Text('No recurring rules yet', style: textTheme.titleMedium),
          const SizedBox(height: AffluenaSpacing.space1),
          Text(
            'Automate regular income, expenses, and transfers from the API scheduler.',
            style: textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}

class _RecurringLoading extends StatelessWidget {
  const _RecurringLoading();

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
          Text('Recurring', style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: AffluenaSpacing.space5),
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
          const AffluenaSkeleton.line(width: 120, height: 16),
          const SizedBox(height: AffluenaSpacing.space4),
          for (var i = 0; i < 3; i++) ...[
            AffluenaCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  AffluenaSkeleton.line(width: 160, height: 16),
                  SizedBox(height: AffluenaSpacing.space2),
                  AffluenaSkeleton.line(width: 100, height: 20),
                  SizedBox(height: AffluenaSpacing.space3),
                  AffluenaSkeleton.line(width: 140, height: 22),
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

class _RecurringError extends StatelessWidget {
  const _RecurringError({required this.onRetry});

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
            'Recurring',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: AffluenaSpacing.space5),
          AffluenaBanner.error(
            'We could not load recurring rules.',
            onRetry: onRetry,
          ),
        ],
      ),
    );
  }
}

Future<void> _showRecurringForm(
  BuildContext context,
  RecurringState state, {
  RecurringRule? rule,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => _RecurringFormSheet(state: state, rule: rule),
  );
}

class _RecurringFormSheet extends ConsumerStatefulWidget {
  const _RecurringFormSheet({required this.state, this.rule});

  final RecurringState state;
  final RecurringRule? rule;

  @override
  ConsumerState<_RecurringFormSheet> createState() =>
      _RecurringFormSheetState();
}

class _RecurringFormSheetState extends ConsumerState<_RecurringFormSheet> {
  late RecurringType _type;
  late RecurringFrequency _frequency;
  late RecurringStatus _status;
  late final TextEditingController _nameController;
  late final TextEditingController _intervalController;
  late final TextEditingController _noteController;
  int? _amountMinor;
  DateTime? _nextRunAt;
  DateTime? _endAt;
  Wallet? _wallet;
  Wallet? _toWallet;
  Category? _category;

  bool get _isEditing => widget.rule != null;

  @override
  void initState() {
    super.initState();
    final rule = widget.rule;
    _type = rule?.type ?? RecurringType.expense;
    _frequency = rule?.frequency ?? RecurringFrequency.monthly;
    _status = rule?.status ?? RecurringStatus.active;
    _nameController = TextEditingController(text: rule?.name ?? '');
    _amountMinor = rule?.amountMinor;
    _intervalController = TextEditingController(
      text: rule?.intervalCount.toString() ?? '1',
    );
    _nextRunAt = _parseDateTime(rule?.nextRunAt);
    _endAt = _parseDateTime(rule?.endAt);
    _noteController = TextEditingController(text: rule?.note ?? '');
    _wallet = _findById(widget.state.wallets, rule?.walletId);
    _toWallet = _findById(widget.state.wallets, rule?.toWalletId);
    _category = _findById(widget.state.categories, rule?.categoryId);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _intervalController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(recurringControllerProvider);
    final canSave =
        _nameController.text.trim().isNotEmpty &&
        _wallet != null &&
        (_type != RecurringType.transfer || _toWallet != null) &&
        (_amountMinor ?? 0) > 0 &&
        _intValue(_intervalController.text) > 0 &&
        _nextRunAt != null &&
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
                _isEditing ? 'Edit recurring' : 'Create recurring',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: AffluenaSpacing.space4),
              if (state.actionError != null) ...[
                AffluenaBanner.error(state.actionError!),
                const SizedBox(height: AffluenaSpacing.space4),
              ],
              SegmentedButton<RecurringType>(
                showSelectedIcon: false,
                segments: const [
                  ButtonSegment(
                    value: RecurringType.expense,
                    label: Text(
                      'Expense',
                      maxLines: 1,
                      overflow: TextOverflow.fade,
                      softWrap: false,
                    ),
                  ),
                  ButtonSegment(
                    value: RecurringType.income,
                    label: Text(
                      'Income',
                      maxLines: 1,
                      overflow: TextOverflow.fade,
                      softWrap: false,
                    ),
                  ),
                  ButtonSegment(
                    value: RecurringType.transfer,
                    label: Text(
                      'Transfer',
                      maxLines: 1,
                      overflow: TextOverflow.fade,
                      softWrap: false,
                    ),
                  ),
                  ButtonSegment(
                    value: RecurringType.adjustment,
                    label: Text(
                      'Adjust',
                      maxLines: 1,
                      overflow: TextOverflow.fade,
                      softWrap: false,
                    ),
                  ),
                ],
                selected: {_type},
                onSelectionChanged: (values) {
                  setState(() {
                    _type = values.first;
                    if (_type == RecurringType.transfer) _category = null;
                    if (_type != RecurringType.transfer) _toWallet = null;
                  });
                },
              ),
              const SizedBox(height: AffluenaSpacing.space3),
              TextField(
                key: const Key('recurring-name-field'),
                controller: _nameController,
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.label_outline),
                  labelText: 'Name',
                ),
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: AffluenaSpacing.space2),
              SelectorRow(
                label: 'Wallet',
                value: _wallet?.name ?? 'Choose wallet',
                icon: Icons.account_balance_wallet_outlined,
                onTap: () => _selectWallet(isDestination: false),
              ),
              if (_type == RecurringType.transfer) ...[
                const Divider(height: 1),
                SelectorRow(
                  label: 'Destination wallet',
                  value: _toWallet?.name ?? 'Choose destination',
                  icon: Icons.swap_horiz,
                  onTap: () => _selectWallet(isDestination: true),
                ),
              ] else ...[
                const Divider(height: 1),
                SelectorRow(
                  label: 'Category',
                  value: _category?.name ?? 'Choose category',
                  icon: Icons.category_outlined,
                  onTap: _selectCategory,
                ),
              ],
              const Divider(height: 1),
              const SizedBox(height: AffluenaSpacing.space2),
              MoneyInput(
                key: const Key('recurring-amount-field'),
                label: 'Amount',
                initialValue: _amountMinor,
                onChanged: (value) => setState(() => _amountMinor = value),
              ),
              const SizedBox(height: AffluenaSpacing.space2),
              DropdownButtonFormField<RecurringFrequency>(
                initialValue: _frequency,
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.repeat),
                  labelText: 'Frequency',
                ),
                items: RecurringFrequency.values
                    .map(
                      (frequency) => DropdownMenuItem(
                        value: frequency,
                        child: Text(frequency.label),
                      ),
                    )
                    .toList(growable: false),
                onChanged: (frequency) {
                  if (frequency == null) return;
                  setState(() => _frequency = frequency);
                },
              ),
              const SizedBox(height: AffluenaSpacing.space2),
              TextField(
                controller: _intervalController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.timelapse_outlined),
                  labelText: 'Interval count',
                ),
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: AffluenaSpacing.space2),
              DatePickerField(
                key: const Key('recurring-next-run-field'),
                label: 'Next run date',
                value: _nextRunAt,
                icon: Icons.event_outlined,
                placeholder: 'Choose date',
                onChanged: (value) => setState(() => _nextRunAt = value),
              ),
              const SizedBox(height: AffluenaSpacing.space2),
              DatePickerField(
                label: 'End date',
                value: _endAt,
                icon: Icons.event_busy_outlined,
                placeholder: 'Optional',
                onChanged: (value) => setState(() => _endAt = value),
              ),
              if (_isEditing) ...[
                const SizedBox(height: AffluenaSpacing.space2),
                DropdownButtonFormField<RecurringStatus>(
                  initialValue: _status,
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.flag_outlined),
                    labelText: 'Status',
                  ),
                  items: RecurringStatus.values
                      .map(
                        (status) => DropdownMenuItem(
                          value: status,
                          child: Text(status.label),
                        ),
                      )
                      .toList(growable: false),
                  onChanged: (status) {
                    if (status == null) return;
                    setState(() => _status = status);
                  },
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
                key: const Key('recurring-save-button'),
                onPressed: canSave ? _save : null,
                child: Text(state.isSaving ? 'Saving...' : 'Save recurring'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _selectWallet({required bool isDestination}) async {
    final selected = await showLookupSelectorSheet<Wallet>(
      context: context,
      title: isDestination ? 'Destination wallet' : 'Recurring wallet',
      selectedValue: isDestination ? _toWallet : _wallet,
      options: [
        for (final wallet in widget.state.wallets)
          LookupSelectorOption<Wallet>(
            value: wallet,
            label: wallet.name,
            subtitle: wallet.type.apiValue,
            icon: Icons.account_balance_wallet_outlined,
          ),
      ],
    );
    if (selected == null) return;
    setState(() {
      if (isDestination) {
        _toWallet = selected;
      } else {
        _wallet = selected;
      }
    });
  }

  Future<void> _selectCategory() async {
    final selected = await showLookupSelectorSheet<Category>(
      context: context,
      title: 'Recurring category',
      selectedValue: _category,
      options: [
        for (final category in widget.state.categories)
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
    final controller = ref.read(recurringControllerProvider.notifier);
    final request = RecurringRuleRequest(
      name: _nameController.text.trim(),
      type: _type,
      walletId: _wallet!.id,
      toWalletId: _type == RecurringType.transfer ? _toWallet?.id : null,
      categoryId: _type == RecurringType.transfer ? null : _category?.id,
      amountMinor: _amountMinor ?? 0,
      frequency: _frequency,
      intervalCount: _intValue(_intervalController.text),
      nextRunAt: _formatDateTime(_nextRunAt)!,
      endAt: _formatDateTime(_endAt),
      status: _status,
      note: _noteController.text.trim(),
    );

    if (widget.rule == null) {
      await controller.createRule(request);
    } else {
      await controller.updateRule(widget.rule!, request);
    }
    if (!mounted) return;
    if (ref.read(recurringControllerProvider).actionError == null) {
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
  if (confirmed == true) await onConfirm();
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

DateTime? _parseDateTime(String? value) {
  if (value == null || value.isEmpty) return null;
  return DateTime.tryParse(value)?.toLocal();
}

String? _formatDateTime(DateTime? value) {
  if (value == null) return null;
  return value.toUtc().toIso8601String();
}
