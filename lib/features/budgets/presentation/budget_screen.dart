import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/affluena_theme.dart';
import '../../../core/formatters/money_formatter.dart';
import '../../categories/data/category_models.dart';
import '../../categories/presentation/category_tag_management_screen.dart';
import '../../shared/presentation/widgets/affluena_banner.dart';
import '../../shared/presentation/widgets/affluena_card.dart';
import '../../shared/presentation/widgets/affluena_skeleton.dart';
import '../../shared/presentation/widgets/drill_in_scaffold.dart';
import '../../shared/presentation/widgets/lookup_selector_sheet.dart';
import '../../shared/presentation/widgets/metric_tile.dart';
import '../../shared/presentation/widgets/money_input.dart';
import '../../shared/presentation/widgets/section_header.dart';
import '../../shared/presentation/widgets/selector_row.dart';
import '../../shared/presentation/widgets/status_badge.dart';
import '../application/budget_controller.dart';
import '../data/budget_models.dart';

class BudgetScreen extends ConsumerWidget {
  const BudgetScreen({super.key});

  static const path = '/budgets';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(budgetControllerProvider);
    final controller = ref.read(budgetControllerProvider.notifier);

    if (state.isLoading && state.budgets.isEmpty) {
      return const _BudgetLoading();
    }

    if (state.loadError != null && state.budgets.isEmpty) {
      return _BudgetError(onRetry: () => controller.load());
    }

    return DrillInScaffold(
      title: 'Budgets',
      actions: [
        IconButton.filledTonal(
          key: const Key('add-budget-button'),
          tooltip: state.hasExpenseCategories
              ? 'Add budget'
              : 'Add an expense category first',
          onPressed: state.isSaving
              ? null
              : state.hasExpenseCategories
              ? () => _showBudgetForm(context, ref, state: state)
              : () => _goToCategories(context),
          icon: const Icon(Icons.add),
        ),
      ],
      body: ListView(
        padding: AffluenaInsets.screen,
        children: [
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
            AffluenaBanner.error(
              state.actionError!,
              onRetry: () => controller.load(),
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
            _EmptyBudgetState(
              hasExpenseCategories: state.hasExpenseCategories,
              onCreate: () => _showBudgetForm(context, ref, state: state),
              onAddCategory: () => _goToCategories(context),
            )
          else ...[
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
            if (state.hasMore) ...[
              const SizedBox(height: AffluenaSpacing.space2),
              OutlinedButton(
                key: const Key('budget-load-more-button'),
                onPressed: state.isLoadingMore ? null : controller.loadMore,
                child: Text(
                  state.isLoadingMore
                      ? 'Loading...'
                      : 'Load more (${state.budgets.length} of ${state.total})',
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }
}

void _goToCategories(BuildContext context) {
  context.push(CategoryTagManagementScreen.path);
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
          AffluenaBanner(
            message: '${alert.title}\n${alert.message}',
            tone: alert.severity == BudgetSeverity.danger
                ? AffluenaBannerTone.error
                : AffluenaBannerTone.warning,
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
    final (statusColor, statusTone, statusLabel) = budget.usagePercent >= 100
        ? (colors.coral, StatusTone.danger, 'Over budget')
        : budget.usagePercent >= 80
        ? (colors.amber, StatusTone.warning, 'Near limit')
        : (colors.success, StatusTone.success, 'On track');

    return AffluenaCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text(categoryName, style: textTheme.titleMedium)),
              StatusBadge(label: statusLabel, tone: statusTone),
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
  const _EmptyBudgetState({
    required this.hasExpenseCategories,
    required this.onCreate,
    required this.onAddCategory,
  });

  final bool hasExpenseCategories;
  final VoidCallback onCreate;
  final VoidCallback onAddCategory;

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
            hasExpenseCategories
                ? 'Set a monthly limit on an expense category to watch your spending.'
                : 'Budgets cap an expense category each month. Add an expense category first, then set its limit here.',
            style: textTheme.bodySmall,
          ),
          const SizedBox(height: AffluenaSpacing.space4),
          if (hasExpenseCategories)
            FilledButton.icon(
              key: const Key('budget-empty-create-button'),
              onPressed: onCreate,
              icon: const Icon(Icons.add),
              label: const Text('Create budget'),
            )
          else
            FilledButton.icon(
              key: const Key('budget-empty-add-category-button'),
              onPressed: onAddCategory,
              icon: const Icon(Icons.account_tree_outlined),
              label: const Text('Add expense category'),
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
    return DrillInScaffold(
      title: 'Budgets',
      body: ListView(
        padding: AffluenaInsets.screen,
        children: [
          const AffluenaCard(
            child: SizedBox(
              height: 56,
              child: Center(
                child: AffluenaSkeleton.line(width: 160, height: 18),
              ),
            ),
          ),
          const SizedBox(height: AffluenaSpacing.space5),
          const AffluenaCard(child: _BudgetSummarySkeleton()),
          const SizedBox(height: AffluenaSpacing.space5),
          for (var i = 0; i < 3; i++) ...[
            const AffluenaCard(child: _BudgetCardSkeleton()),
            const SizedBox(height: AffluenaSpacing.space3),
          ],
        ],
      ),
    );
  }
}

class _BudgetSummarySkeleton extends StatelessWidget {
  const _BudgetSummarySkeleton();

  @override
  Widget build(BuildContext context) {
    return const Column(
      children: [
        Row(
          children: [
            Expanded(child: AffluenaSkeleton(height: 48)),
            SizedBox(width: AffluenaSpacing.space3),
            Expanded(child: AffluenaSkeleton(height: 48)),
          ],
        ),
        SizedBox(height: AffluenaSpacing.space3),
        Row(
          children: [
            Expanded(child: AffluenaSkeleton(height: 48)),
            SizedBox(width: AffluenaSpacing.space3),
            Expanded(child: AffluenaSkeleton(height: 48)),
          ],
        ),
      ],
    );
  }
}

class _BudgetCardSkeleton extends StatelessWidget {
  const _BudgetCardSkeleton();

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AffluenaSkeleton.line(width: 140, height: 16),
        SizedBox(height: AffluenaSpacing.space3),
        AffluenaSkeleton(height: 10, radius: AffluenaRadii.pill),
        SizedBox(height: AffluenaSpacing.space3),
        AffluenaSkeleton.line(width: 100),
        SizedBox(height: AffluenaSpacing.space2),
        AffluenaSkeleton.line(width: 200),
      ],
    );
  }
}

class _BudgetError extends StatelessWidget {
  const _BudgetError({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return DrillInScaffold(
      title: 'Budgets',
      body: ListView(
        padding: AffluenaInsets.screen,
        children: [
          AffluenaBanner.error(
            'We could not load your budgets.',
            onRetry: onRetry,
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
  int? _limitMinorValue;
  Category? _category;

  bool get _isEditing => widget.budget != null;

  @override
  void initState() {
    super.initState();
    _limitMinorValue = widget.budget?.limitMinor;
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
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final state = ref.watch(budgetControllerProvider);
    final selectedLabel = _category?.name ?? 'Choose expense category';
    final canSave =
        (_isEditing || _category != null) &&
        (_limitMinorValue ?? 0) > 0 &&
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
              const SizedBox(height: AffluenaSpacing.space3),
              MoneyInput(
                key: const Key('budget-limit-field'),
                label: 'Monthly limit',
                hint: 'Spending cap for this category',
                initialValue: _limitMinorValue,
                enabled: !state.isSaving,
                onChanged: (value) => setState(() => _limitMinorValue = value),
              ),
              if (state.actionError != null) ...[
                const SizedBox(height: AffluenaSpacing.space4),
                AffluenaBanner.error(state.actionError!),
              ],
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
            subtitle: category.type.label,
            icon: Icons.category_outlined,
          ),
      ],
    );
    if (selected == null) return;
    setState(() => _category = selected);
  }

  Future<void> _save() async {
    final limitMinor = _limitMinorValue ?? 0;
    if (limitMinor <= 0) return;
    final controller = ref.read(budgetControllerProvider.notifier);
    if (_isEditing) {
      await controller.updateBudget(widget.budget!, limitMinor: limitMinor);
    } else {
      await controller.createBudget(
        categoryId: _category!.id,
        limitMinor: limitMinor,
      );
    }
    if (!mounted) return;
    // Keep the sheet open on failure so the inline error stays visible.
    if (ref.read(budgetControllerProvider).actionError == null) {
      Navigator.of(context).pop();
    }
  }
}

Future<void> _confirmDelete(
  BuildContext context,
  BudgetController controller,
  BudgetSummary budget,
) async {
  final colors = context.affluenaColors;
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
          style: FilledButton.styleFrom(backgroundColor: colors.coral),
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
