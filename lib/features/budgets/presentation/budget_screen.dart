import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/affluena_theme.dart';
import '../../../core/formatters/money_formatter.dart';
import '../../categories/data/category_models.dart';
import '../../shared/presentation/widgets/affluena_card.dart';
import '../../shared/presentation/widgets/lookup_selector_sheet.dart';
import '../../shared/presentation/widgets/metric_tile.dart';
import '../../shared/presentation/widgets/section_header.dart';
import '../../shared/presentation/widgets/selector_row.dart';
import '../application/budget_controller.dart';
import '../data/budget_models.dart';

class BudgetScreen extends ConsumerWidget {
  const BudgetScreen({super.key});

  static const path = '/budgets';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(budgetControllerProvider);
    final controller = ref.read(budgetControllerProvider.notifier);
    final textTheme = Theme.of(context).textTheme;

    if (state.isLoading && state.budgets.isEmpty) {
      return const _BudgetLoading();
    }

    if (state.loadError != null && state.budgets.isEmpty) {
      return _BudgetError(onRetry: () => controller.load());
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
              Expanded(child: Text('Budgets', style: textTheme.headlineMedium)),
              IconButton.filledTonal(
                onPressed: state.categories.isEmpty || state.isSaving
                    ? null
                    : () => _showBudgetForm(context, ref, state: state),
                icon: const Icon(Icons.add),
              ),
            ],
          ),
          const SizedBox(height: AffluenaSpacing.space3),
          _MonthControl(
            month: state.month,
            onChanged: controller.setMonth,
            isLoading: state.isLoading,
          ),
          const SizedBox(height: AffluenaSpacing.space5),
          if (state.reportSummary != null) ...[
            _BudgetSummaryCard(summary: state.reportSummary!),
            const SizedBox(height: AffluenaSpacing.space5),
          ],
          if (state.actionError != null) ...[
            AffluenaCard(
              backgroundColor: context.affluenaColors.surfaceTintSoft,
              child: Text(state.actionError!),
            ),
            const SizedBox(height: AffluenaSpacing.space4),
          ],
          _BudgetAlerts(alerts: state.alerts),
          const SizedBox(height: AffluenaSpacing.space6),
          SectionHeader(
            title: 'Category budgets',
            actionLabel: state.total == 0 ? null : '${state.total} total',
          ),
          const SizedBox(height: AffluenaSpacing.space3),
          if (state.budgets.isEmpty)
            const _EmptyBudgetState()
          else
            for (final budget in state.budgets) ...[
              _BudgetCard(
                budget: budget,
                report: state.reportFor(budget),
                categoryName: state.categoryName(budget.categoryId),
                onEdit: () =>
                    _showBudgetForm(context, ref, state: state, budget: budget),
                onDelete: () => _confirmDelete(context, controller, budget),
              ),
              const SizedBox(height: AffluenaSpacing.space3),
            ],
        ],
      ),
    );
  }
}

class _MonthControl extends StatelessWidget {
  const _MonthControl({
    required this.month,
    required this.onChanged,
    required this.isLoading,
  });

  final String month;
  final ValueChanged<String> onChanged;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return AffluenaCard(
      padding: const EdgeInsets.symmetric(
        horizontal: AffluenaSpacing.space3,
        vertical: AffluenaSpacing.space2,
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: isLoading ? null : () => onChanged(_shiftMonth(-1)),
            icon: const Icon(Icons.chevron_left),
          ),
          Expanded(
            child: Text(
              month,
              textAlign: TextAlign.center,
              style: textTheme.titleMedium,
            ),
          ),
          IconButton(
            onPressed: isLoading ? null : () => onChanged(_shiftMonth(1)),
            icon: const Icon(Icons.chevron_right),
          ),
        ],
      ),
    );
  }

  String _shiftMonth(int delta) {
    final date = DateTime.parse('$month-01');
    final shifted = DateTime(date.year, date.month + delta);
    return '${shifted.year.toString().padLeft(4, '0')}-${shifted.month.toString().padLeft(2, '0')}';
  }
}

class _BudgetSummaryCard extends StatelessWidget {
  const _BudgetSummaryCard({required this.summary});

  final BudgetReportSummary summary;

  @override
  Widget build(BuildContext context) {
    return AffluenaCard(
      child: Column(
        children: [
          Row(
            children: [
              MetricTile(
                label: 'Limit',
                value: MoneyFormatter.idr(summary.totalLimitMinor),
                helper: '${summary.safeCount} safe',
                icon: Icons.account_balance_wallet_outlined,
              ),
              const SizedBox(width: AffluenaSpacing.space3),
              MetricTile(
                label: 'Spent',
                value: MoneyFormatter.idr(summary.totalSpentMinor),
                helper: '${summary.warningCount + summary.exceededCount} risky',
                icon: Icons.trending_up,
              ),
            ],
          ),
          const SizedBox(height: AffluenaSpacing.space3),
          Row(
            children: [
              MetricTile(
                label: 'Remaining',
                value: MoneyFormatter.idr(summary.totalRemainingMinor),
                helper: 'Available cap',
                icon: Icons.savings_outlined,
              ),
              const SizedBox(width: AffluenaSpacing.space3),
              MetricTile(
                label: 'Daily',
                value: MoneyFormatter.idr(summary.dailyAllowanceMinor),
                helper: 'Allowance',
                icon: Icons.today_outlined,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _BudgetAlerts extends StatelessWidget {
  const _BudgetAlerts({required this.alerts});

  final List<BudgetAlert> alerts;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colors = context.affluenaColors;

    if (alerts.isEmpty) {
      return AffluenaCard(
        backgroundColor: colors.forestSoft,
        borderColor: colors.forestSoft,
        child: Row(
          children: [
            Icon(Icons.check_circle_outline, color: colors.success),
            const SizedBox(width: AffluenaSpacing.space3),
            Expanded(
              child: Text(
                'No budget alerts for this month.',
                style: textTheme.bodyLarge,
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(title: 'Alerts'),
        const SizedBox(height: AffluenaSpacing.space3),
        for (final alert in alerts.take(2)) ...[
          AffluenaCard(
            backgroundColor: colors.surfaceTintSoft,
            child: Row(
              children: [
                Icon(
                  alert.severity == BudgetSeverity.danger
                      ? Icons.warning_amber_rounded
                      : Icons.error_outline,
                  color: alert.severity == BudgetSeverity.danger
                      ? colors.coral
                      : colors.amber,
                ),
                const SizedBox(width: AffluenaSpacing.space3),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(alert.title, style: textTheme.bodyLarge),
                      const SizedBox(height: AffluenaSpacing.space1),
                      Text(alert.message, style: textTheme.bodySmall),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AffluenaSpacing.space2),
        ],
      ],
    );
  }
}

class _BudgetCard extends StatelessWidget {
  const _BudgetCard({
    required this.budget,
    required this.categoryName,
    required this.onEdit,
    required this.onDelete,
    this.report,
  });

  final BudgetSummary budget;
  final BudgetReportItem? report;
  final String categoryName;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colors = context.affluenaColors;
    final percent = (budget.usagePercent / 100).clamp(0.0, 1.0);
    final statusColor = budget.usagePercent >= 100
        ? colors.coral
        : budget.usagePercent >= 80
        ? colors.amber
        : colors.success;

    return AffluenaCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text(categoryName, style: textTheme.titleMedium)),
              PopupMenuButton<String>(
                onSelected: (value) {
                  if (value == 'edit') onEdit();
                  if (value == 'delete') onDelete();
                },
                itemBuilder: (context) => const [
                  PopupMenuItem(value: 'edit', child: Text('Edit')),
                  PopupMenuItem(value: 'delete', child: Text('Delete')),
                ],
              ),
            ],
          ),
          const SizedBox(height: AffluenaSpacing.space2),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: percent,
              minHeight: 10,
              color: statusColor,
              backgroundColor: colors.surfaceTintSoft,
            ),
          ),
          const SizedBox(height: AffluenaSpacing.space3),
          Text(
            '${budget.usagePercent.round()}% used',
            style: textTheme.bodyLarge?.copyWith(color: statusColor),
          ),
          const SizedBox(height: AffluenaSpacing.space1),
          Text(
            '${MoneyFormatter.idr(budget.spentMinor)} spent from ${MoneyFormatter.idr(budget.limitMinor)}',
            style: textTheme.bodySmall,
          ),
          const SizedBox(height: AffluenaSpacing.space2),
          Text(
            '${MoneyFormatter.idr(budget.remainingMinor)} remaining',
            style: textTheme.bodyLarge,
          ),
          if (report?.recommendation.isNotEmpty == true) ...[
            const SizedBox(height: AffluenaSpacing.space2),
            Text(report!.recommendation, style: textTheme.bodySmall),
          ],
        ],
      ),
    );
  }
}

class _EmptyBudgetState extends StatelessWidget {
  const _EmptyBudgetState();

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
          Icon(Icons.pie_chart_outline, color: colors.forest),
          const SizedBox(height: AffluenaSpacing.space3),
          Text('No budgets yet', style: textTheme.titleMedium),
          const SizedBox(height: AffluenaSpacing.space1),
          Text(
            'Create category budgets to monitor monthly spending.',
            style: textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}

class _BudgetLoading extends StatelessWidget {
  const _BudgetLoading();

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(
          AffluenaSpacing.space5,
          AffluenaSpacing.space4,
          AffluenaSpacing.space5,
          AffluenaSpacing.space8,
        ),
        children: [
          Text('Budgets', style: textTheme.headlineMedium),
          const SizedBox(height: AffluenaSpacing.space5),
          const AffluenaCard(
            child: SizedBox(
              height: 144,
              child: Center(child: Text('Loading budgets')),
            ),
          ),
        ],
      ),
    );
  }
}

class _BudgetError extends StatelessWidget {
  const _BudgetError({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(
          AffluenaSpacing.space5,
          AffluenaSpacing.space4,
          AffluenaSpacing.space5,
          AffluenaSpacing.space8,
        ),
        children: [
          Text('Budgets unavailable', style: textTheme.headlineMedium),
          const SizedBox(height: AffluenaSpacing.space5),
          AffluenaCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('We could not load your budgets.'),
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

Future<void> _showBudgetForm(
  BuildContext context,
  WidgetRef ref, {
  required BudgetState state,
  BudgetSummary? budget,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (context) => _BudgetFormSheet(state: state, budget: budget),
  );
}

class _BudgetFormSheet extends ConsumerStatefulWidget {
  const _BudgetFormSheet({required this.state, this.budget});

  final BudgetState state;
  final BudgetSummary? budget;

  @override
  ConsumerState<_BudgetFormSheet> createState() => _BudgetFormSheetState();
}

class _BudgetFormSheetState extends ConsumerState<_BudgetFormSheet> {
  late final TextEditingController _limitController;
  Category? _category;

  bool get _isEditing => widget.budget != null;

  @override
  void initState() {
    super.initState();
    _limitController = TextEditingController(
      text: widget.budget?.limitMinor.toString() ?? '',
    );
    if (widget.budget != null) {
      for (final category in widget.state.categories) {
        if (category.id == widget.budget!.categoryId) {
          _category = category;
          break;
        }
      }
    }
  }

  @override
  void dispose() {
    _limitController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final state = ref.watch(budgetControllerProvider);
    final selectedLabel = _category?.name ?? 'Choose expense category';
    final canSave =
        (_isEditing || _category != null) &&
        _limitMinor(_limitController.text) > 0 &&
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
                _isEditing ? 'Edit budget' : 'Create budget',
                style: textTheme.titleLarge,
              ),
              const SizedBox(height: AffluenaSpacing.space4),
              SelectorRow(
                label: 'Category',
                value: selectedLabel,
                icon: Icons.category_outlined,
                enabled: !_isEditing && widget.state.categories.isNotEmpty,
                onTap: _isEditing || widget.state.categories.isEmpty
                    ? null
                    : _selectCategory,
              ),
              const Divider(height: 1),
              TextField(
                key: const Key('budget-limit-field'),
                controller: _limitController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.payments_outlined),
                  labelText: 'Monthly limit',
                  hintText: '1500000',
                ),
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: AffluenaSpacing.space5),
              FilledButton(
                key: const Key('budget-save-button'),
                onPressed: canSave ? _save : null,
                child: Text(state.isSaving ? 'Saving...' : 'Save budget'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _selectCategory() async {
    final selected = await showLookupSelectorSheet<Category>(
      context: context,
      title: 'Budget category',
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
    final limitMinor = _limitMinor(_limitController.text);
    if (_isEditing) {
      await ref
          .read(budgetControllerProvider.notifier)
          .updateBudget(widget.budget!, limitMinor: limitMinor);
    } else {
      await ref
          .read(budgetControllerProvider.notifier)
          .createBudget(categoryId: _category!.id, limitMinor: limitMinor);
    }
    if (mounted) Navigator.of(context).pop();
  }
}

Future<void> _confirmDelete(
  BuildContext context,
  BudgetController controller,
  BudgetSummary budget,
) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Delete budget?'),
      content: const Text('This removes the category budget for this month.'),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: const Text('Delete'),
        ),
      ],
    ),
  );
  if (confirmed == true) {
    await controller.deleteBudget(budget);
  }
}

int _limitMinor(String value) {
  final normalized = value.replaceAll(RegExp(r'[^0-9]'), '');
  return int.tryParse(normalized) ?? 0;
}
