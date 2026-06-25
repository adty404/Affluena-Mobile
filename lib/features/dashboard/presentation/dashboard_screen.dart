import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/affluena_theme.dart';
import '../../../core/api/api_error.dart';
import '../../../core/formatters/date_formatter.dart';
import '../../../core/formatters/money_formatter.dart';
import '../../auth/application/auth_controller.dart';
import '../../budgets/presentation/budget_screen.dart';
import '../../debts/presentation/debt_detail_screen.dart';
import '../../insights/presentation/insights_screen.dart';
import '../../quick_entry/presentation/quick_entry_screen.dart';
import '../../shared/presentation/widgets/affluena_banner.dart';
import '../../shared/presentation/widgets/affluena_card.dart';
import '../../shared/presentation/widgets/affluena_skeleton.dart';
import '../../shared/presentation/widgets/metric_tile.dart';
import '../../shared/presentation/widgets/section_header.dart';
import '../../shared/presentation/widgets/transaction_tile.dart';
import '../../trackers/presentation/tracker_screen.dart';
import '../../transactions/application/transactions_controller.dart';
import '../../transactions/data/transaction_models.dart';
import '../../transactions/presentation/transaction_detail_sheet.dart';
import '../../transactions/presentation/transactions_screen.dart';
import '../../wallets/presentation/wallets_screen.dart';
import '../application/dashboard_home_controller.dart';
import '../data/dashboard_models.dart';
import 'cashflow_trend_chart.dart';
import 'category_month_transactions_sheet.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  static const path = '/';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final home = ref.watch(dashboardHomeProvider);

    return home.when(
      skipLoadingOnReload: true,
      loading: () => const _DashboardLoading(),
      error: (error, stackTrace) => _DashboardError(
        message: _dashboardErrorMessage(error),
        onRetry: () => ref.invalidate(dashboardHomeProvider),
      ),
      data: (home) => _DashboardContent(home: home),
    );
  }
}

class _DashboardContent extends ConsumerWidget {
  const _DashboardContent({required this.home});

  final DashboardHome home;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summary = home.summary;
    final user = ref.watch(authControllerProvider).user;

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(
          AffluenaSpacing.space5,
          AffluenaSpacing.space4,
          AffluenaSpacing.space5,
          AffluenaSpacing.space8,
        ),
        children: [
          _DashboardHeader(
            greeting: _greetingForNow(DateTime.now()),
            initial: _avatarInitial(user?.name, user?.email),
          ),
          const SizedBox(height: AffluenaSpacing.space6),
          _BalanceCard(summary: summary),
          const SizedBox(height: AffluenaSpacing.space5),
          const _QuickActions(),
          const SizedBox(height: AffluenaSpacing.space6),
          const _ForecastSection(),
          home.isEmpty
              ? const _EmptyDashboardState()
              : _BudgetCard(summary: summary),
          if (summary.hasUpcoming) ...[
            const SizedBox(height: AffluenaSpacing.space6),
            _UpcomingSection(summary: summary),
          ],
          const SizedBox(height: AffluenaSpacing.space6),
          const _CashflowTrendBlock(),
          const SizedBox(height: AffluenaSpacing.space6),
          _ExpenseDistributionBlock(walletNames: home.walletNames),
          const SizedBox(height: AffluenaSpacing.space6),
          SectionHeader(
            title: 'Recent transactions',
            actionLabel: 'See all',
            onAction: () => context.go(TransactionsScreen.path),
          ),
          const SizedBox(height: AffluenaSpacing.space2),
          _RecentTransactions(home: home),
        ],
      ),
    );
  }
}

class _DashboardHeader extends StatelessWidget {
  const _DashboardHeader({required this.greeting, required this.initial});

  final String greeting;
  final String initial;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colors = context.affluenaColors;

    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Affluena', style: textTheme.labelMedium),
              const SizedBox(height: AffluenaSpacing.space1),
              Text(greeting, style: textTheme.headlineMedium),
            ],
          ),
        ),
        CircleAvatar(
          backgroundColor: colors.forest,
          child: Text(
            initial,
            style: textTheme.bodyLarge?.copyWith(color: colors.surfaceCanvas),
          ),
        ),
      ],
    );
  }
}

class _BalanceCard extends StatelessWidget {
  const _BalanceCard({required this.summary});

  final DashboardSummary summary;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colors = context.affluenaColors;
    final cashflow = summary.monthlyCashflowMinor;
    final isPositive = cashflow >= 0;
    final cashflowColor = isPositive ? colors.success : colors.coral;

    return AffluenaCard(
      backgroundColor: colors.surfaceSoft,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Total balance', style: textTheme.bodySmall),
          const SizedBox(height: AffluenaSpacing.space2),
          Text(
            MoneyFormatter.idr(summary.netWorthMinor),
            style: textTheme.displaySmall,
          ),
          const SizedBox(height: AffluenaSpacing.space2),
          Row(
            children: [
              Icon(
                isPositive
                    ? Icons.trending_up_rounded
                    : Icons.trending_down_rounded,
                size: 16,
                color: cashflowColor,
              ),
              const SizedBox(width: AffluenaSpacing.space1),
              Flexible(
                child: Text(
                  '${MoneyFormatter.signedIdr(cashflow)} this month',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: textTheme.bodySmall?.copyWith(
                    color: cashflowColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AffluenaSpacing.space4),
          Row(
            children: [
              MetricTile(
                label: 'Income',
                value: MoneyFormatter.idr(summary.monthlyIncomeMinor),
                helper: 'This month',
                icon: Icons.arrow_downward_rounded,
              ),
              const SizedBox(width: AffluenaSpacing.space3),
              MetricTile(
                label: 'Expense',
                value: MoneyFormatter.idr(summary.monthlyExpenseMinor),
                helper: _budgetUsageLabel(summary.budget.usagePercent),
                icon: Icons.arrow_upward_rounded,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _QuickActions extends StatelessWidget {
  const _QuickActions();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _QuickAction(
          icon: Icons.add_rounded,
          label: 'Add',
          onTap: () => context.go(QuickEntryScreen.path),
        ),
        const SizedBox(width: AffluenaSpacing.space3),
        _QuickAction(
          icon: Icons.swap_horiz_rounded,
          label: 'Transfer',
          onTap: () => context.go('${QuickEntryScreen.path}?type=transfer'),
        ),
        const SizedBox(width: AffluenaSpacing.space3),
        _QuickAction(
          icon: Icons.pie_chart_outline,
          label: 'Budget',
          onTap: () => context.go(BudgetScreen.path),
        ),
        const SizedBox(width: AffluenaSpacing.space3),
        _QuickAction(
          icon: Icons.wallet_outlined,
          label: 'Wallets',
          onTap: () => context.go(WalletsScreen.path),
        ),
      ],
    );
  }
}

class _QuickAction extends StatelessWidget {
  const _QuickAction({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colors = context.affluenaColors;

    return Expanded(
      child: Semantics(
        button: true,
        label: label,
        child: GestureDetector(
          onTap: onTap,
          child: AffluenaCard(
            padding: const EdgeInsets.symmetric(
              horizontal: AffluenaSpacing.space2,
              vertical: AffluenaSpacing.space3,
            ),
            child: Column(
              children: [
                Icon(icon, color: colors.forest),
                const SizedBox(height: AffluenaSpacing.space2),
                Text(label, style: textTheme.labelMedium),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _BudgetCard extends StatelessWidget {
  const _BudgetCard({required this.summary});

  final DashboardSummary summary;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colors = context.affluenaColors;
    final hasBudget = summary.budget.limitMinor > 0;

    return AffluenaCard(
      backgroundColor: colors.forestSoft,
      borderColor: colors.forestSoft,
      child: Row(
        children: [
          Icon(Icons.pie_chart_outline, color: colors.forest),
          const SizedBox(width: AffluenaSpacing.space3),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  hasBudget
                      ? 'Budget ${summary.budget.usagePercent.round()}% used'
                      : 'Budget not set',
                  style: textTheme.bodyLarge,
                ),
                Text(
                  hasBudget
                      ? '${MoneyFormatter.idr(summary.budget.remainingMinor)} left for this month'
                      : 'Track spending once budgets exist.',
                  style: textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ForecastSection extends ConsumerWidget {
  const _ForecastSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final forecast = ref.watch(dashboardForecastProvider);

    return forecast.when(
      skipLoadingOnReload: true,
      loading: () => const Padding(
        padding: EdgeInsets.only(bottom: AffluenaSpacing.space6),
        child: AffluenaSkeleton(height: 64, radius: AffluenaRadii.lg),
      ),
      // Forecast is a supplementary nudge — if it fails, stay silent rather
      // than pushing an error banner above the budget card.
      error: (error, stackTrace) => const SizedBox.shrink(),
      data: (forecast) {
        if (forecast.status != ForecastStatus.overbudget) {
          return const SizedBox.shrink();
        }
        final projected = MoneyFormatter.idr(forecast.forecastedExpenseMinor);
        final limit = MoneyFormatter.idr(forecast.budgetLimitMinor);
        return Padding(
          padding: const EdgeInsets.only(bottom: AffluenaSpacing.space6),
          child: AffluenaBanner(
            tone: AffluenaBannerTone.warning,
            message:
                'At this pace you are on track to spend $projected this month, '
                'over your $limit budget.',
          ),
        );
      },
    );
  }
}

class _UpcomingSection extends StatelessWidget {
  const _UpcomingSection({required this.summary});

  final DashboardSummary summary;

  @override
  Widget build(BuildContext context) {
    final items = <_UpcomingItem>[
      for (final sub in summary.upcomingSubscriptions)
        _UpcomingItem(
          icon: Icons.autorenew_rounded,
          title: sub.name,
          subtitle: 'Due ${AffluenaDateFormatter.shortDate(sub.nextDueDate)}',
          amountMinor: sub.amountMinor,
          onTap: () => context.push(TrackerScreen.path),
        ),
      for (final inst in summary.upcomingInstallments)
        _UpcomingItem(
          icon: Icons.calendar_month_rounded,
          title: inst.name,
          subtitle:
              '${inst.remainingMonths} payments left · '
              'Due ${AffluenaDateFormatter.shortDate(inst.dueDate)}',
          amountMinor: inst.monthlyAmountMinor,
          onTap: () => context.push(TrackerScreen.path),
        ),
      for (final debt in summary.upcomingDebts)
        _UpcomingItem(
          icon: Icons.handshake_outlined,
          title: debt.counterpartyName,
          subtitle:
              '${_debtTypeLabel(debt.type)} · '
              'Due ${AffluenaDateFormatter.shortDate(debt.dueDate)}',
          amountMinor: debt.remainingAmountMinor,
          onTap: () => context.push(DebtDetailScreen.location(debt.id)),
        ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(title: 'Upcoming'),
        const SizedBox(height: AffluenaSpacing.space2),
        AffluenaCard(
          child: Column(
            children: [
              for (final entry in items.indexed) ...[
                _UpcomingRow(item: entry.$2),
                if (entry.$1 < items.length - 1) const Divider(height: 1),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _UpcomingItem {
  const _UpcomingItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.amountMinor,
    this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final int amountMinor;
  final VoidCallback? onTap;
}

class _UpcomingRow extends StatelessWidget {
  const _UpcomingRow({required this.item});

  final _UpcomingItem item;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colors = context.affluenaColors;

    return InkWell(
      onTap: item.onTap,
      borderRadius: BorderRadius.circular(AffluenaRadii.md),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AffluenaSpacing.space2),
        child: Row(
          children: [
            DecoratedBox(
              decoration: BoxDecoration(
                color: colors.surfaceTintSoft,
                borderRadius: BorderRadius.circular(AffluenaRadii.md),
              ),
              child: Padding(
                padding: const EdgeInsets.all(AffluenaSpacing.space2),
                child: Icon(item.icon, color: colors.forest, size: 20),
              ),
            ),
            const SizedBox(width: AffluenaSpacing.space3),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title,
                    style: textTheme.bodyLarge,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: AffluenaSpacing.space1),
                  Text(
                    item.subtitle,
                    style: textTheme.bodySmall,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: AffluenaSpacing.space3),
            Text(
              MoneyFormatter.idr(item.amountMinor),
              style: textTheme.titleMedium,
            ),
            if (item.onTap != null) ...[
              const SizedBox(width: AffluenaSpacing.space1),
              Icon(Icons.chevron_right, size: 18, color: colors.inkMuted),
            ],
          ],
        ),
      ),
    );
  }
}

class _CashflowTrendBlock extends ConsumerWidget {
  const _CashflowTrendBlock();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final granularity = ref.watch(dashboardCashflowGranularityProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(
          title: 'Cashflow trend',
          actionLabel: 'Details',
          onAction: () => context.push(InsightsScreen.path),
        ),
        const SizedBox(height: AffluenaSpacing.space3),
        SegmentedButton<CashflowGranularity>(
          showSelectedIcon: false,
          segments: const [
            ButtonSegment(
              value: CashflowGranularity.month,
              label: Text('Monthly'),
            ),
            ButtonSegment(
              value: CashflowGranularity.week,
              label: Text('Weekly'),
            ),
          ],
          selected: {granularity},
          onSelectionChanged: (selection) => ref
              .read(dashboardCashflowGranularityProvider.notifier)
              .set(selection.first),
        ),
        const SizedBox(height: AffluenaSpacing.space3),
        const _CashflowTrendSection(),
      ],
    );
  }
}

class _CashflowTrendSection extends ConsumerWidget {
  const _CashflowTrendSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final trend = ref.watch(dashboardCashflowTrendProvider);

    return trend.when(
      skipLoadingOnReload: true,
      loading: () => const AffluenaCard(
        child: AffluenaSkeleton(height: 132, radius: AffluenaRadii.lg),
      ),
      error: (error, stackTrace) => AffluenaCard(
        child: AffluenaBanner.error(
          _dashboardErrorMessage(error),
          onRetry: () => ref.invalidate(dashboardCashflowTrendProvider),
        ),
      ),
      data: (response) {
        final points = response.trend;
        final hasData = points.any(
          (p) => p.incomeMinor > 0 || p.expenseMinor > 0,
        );
        if (!hasData) {
          return const _DashboardEmptyCard(
            icon: Icons.show_chart_rounded,
            title: 'No trend yet',
            message:
                'Record income and expenses across a few periods to see how '
                'your cashflow moves.',
          );
        }
        return InkWell(
          onTap: () => context.push(InsightsScreen.path),
          borderRadius: BorderRadius.circular(AffluenaRadii.card),
          child: AffluenaCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const _TrendLegend(),
                const SizedBox(height: AffluenaSpacing.space4),
                CashflowTrendChart(points: points),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _TrendLegend extends StatelessWidget {
  const _TrendLegend();

  @override
  Widget build(BuildContext context) {
    final colors = context.affluenaColors;

    return Row(
      children: [
        _LegendDot(color: colors.forest, label: 'Income'),
        const SizedBox(width: AffluenaSpacing.space4),
        _LegendDot(color: colors.coral, label: 'Expense'),
      ],
    );
  }
}

class _LegendDot extends StatelessWidget {
  const _LegendDot({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: AffluenaSpacing.space2),
        Text(label, style: textTheme.labelMedium),
      ],
    );
  }
}

class _ExpenseDistributionBlock extends ConsumerWidget {
  const _ExpenseDistributionBlock({required this.walletNames});

  final Map<String, String> walletNames;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textTheme = Theme.of(context).textTheme;
    final colors = context.affluenaColors;
    final month = ref.watch(dashboardDistributionMonthProvider);
    final now = DateTime.now();
    final isCurrentMonth = month.year == now.year && month.month == now.month;

    void shift(int delta) {
      ref
          .read(dashboardDistributionMonthProvider.notifier)
          .set(DateTime(month.year, month.month + delta));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Where money went', style: textTheme.titleMedium),
                  Text(
                    AffluenaDateFormatter.monthLabel(month),
                    style: textTheme.bodySmall?.copyWith(color: colors.inkMuted),
                  ),
                ],
              ),
            ),
            IconButton(
              key: const Key('distribution-prev-month'),
              visualDensity: VisualDensity.compact,
              onPressed: () => shift(-1),
              icon: const Icon(Icons.chevron_left),
              tooltip: 'Previous month',
            ),
            IconButton(
              key: const Key('distribution-next-month'),
              visualDensity: VisualDensity.compact,
              // Don't let the user page into the future.
              onPressed: isCurrentMonth ? null : () => shift(1),
              icon: const Icon(Icons.chevron_right),
              tooltip: 'Next month',
            ),
          ],
        ),
        const SizedBox(height: AffluenaSpacing.space2),
        _ExpenseDistributionSection(month: month, walletNames: walletNames),
      ],
    );
  }
}

class _ExpenseDistributionSection extends ConsumerWidget {
  const _ExpenseDistributionSection({
    required this.month,
    required this.walletNames,
  });

  final DateTime month;
  final Map<String, String> walletNames;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final distribution = ref.watch(dashboardExpenseDistributionProvider);

    return distribution.when(
      skipLoadingOnReload: true,
      loading: () => const AffluenaCard(child: _DistributionSkeleton()),
      error: (error, stackTrace) => AffluenaCard(
        child: AffluenaBanner.error(
          _dashboardErrorMessage(error),
          onRetry: () => ref.invalidate(dashboardExpenseDistributionProvider),
        ),
      ),
      data: (response) {
        final rows = response.distribution
            .where((d) => d.amountMinor > 0)
            .toList(growable: false);
        if (rows.isEmpty) {
          return const _DashboardEmptyCard(
            icon: Icons.donut_large_rounded,
            title: 'No spending yet',
            message:
                'Once you log expenses this month, your top categories show '
                'up here.',
          );
        }
        final maxPercentage = rows
            .map((d) => d.percentage)
            .fold<double>(0, (a, b) => a > b ? a : b);
        return AffluenaCard(
          child: Column(
            children: [
              for (final entry in rows.indexed) ...[
                _DistributionRow(
                  item: entry.$2,
                  maxPercentage: maxPercentage,
                  onTap: entry.$2.categoryId.isEmpty
                      ? null
                      : () => showCategoryMonthTransactionsSheet(
                          context: context,
                          categoryId: entry.$2.categoryId,
                          categoryName: entry.$2.categoryName,
                          month: month,
                          walletNames: walletNames,
                        ),
                ),
                if (entry.$1 < rows.length - 1)
                  const SizedBox(height: AffluenaSpacing.space4),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _DistributionRow extends StatelessWidget {
  const _DistributionRow({
    required this.item,
    required this.maxPercentage,
    this.onTap,
  });

  final ExpenseDistribution item;
  final double maxPercentage;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colors = context.affluenaColors;
    final fraction = maxPercentage <= 0
        ? 0.0
        : (item.percentage / maxPercentage).clamp(0.0, 1.0);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AffluenaRadii.md),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AffluenaSpacing.space1),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    item.categoryName,
                    style: textTheme.bodyLarge,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: AffluenaSpacing.space3),
                Text('${item.percentage.round()}%', style: textTheme.labelMedium),
                const SizedBox(width: AffluenaSpacing.space2),
                Text(
                  MoneyFormatter.idr(item.amountMinor),
                  style: textTheme.titleMedium,
                ),
                if (onTap != null) ...[
                  const SizedBox(width: AffluenaSpacing.space1),
                  Icon(Icons.chevron_right, size: 18, color: colors.inkMuted),
                ],
              ],
            ),
            const SizedBox(height: AffluenaSpacing.space2),
            ClipRRect(
              borderRadius: BorderRadius.circular(AffluenaRadii.pill),
              child: LinearProgressIndicator(
                value: fraction,
                minHeight: 6,
                backgroundColor: colors.surfaceTintSoft,
                valueColor: AlwaysStoppedAnimation<Color>(colors.forest),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DistributionSkeleton extends StatelessWidget {
  const _DistributionSkeleton();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (var i = 0; i < 3; i++) ...[
          Row(
            children: const [
              Expanded(child: AffluenaSkeleton.line(width: 120)),
              SizedBox(width: AffluenaSpacing.space3),
              AffluenaSkeleton.line(width: 64),
            ],
          ),
          const SizedBox(height: AffluenaSpacing.space2),
          const AffluenaSkeleton(height: 6, radius: AffluenaRadii.pill),
          if (i < 2) const SizedBox(height: AffluenaSpacing.space4),
        ],
      ],
    );
  }
}

class _DashboardEmptyCard extends StatelessWidget {
  const _DashboardEmptyCard({
    required this.icon,
    required this.title,
    required this.message,
  });

  final IconData icon;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colors = context.affluenaColors;

    return AffluenaCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: colors.forest),
          const SizedBox(height: AffluenaSpacing.space3),
          Text(title, style: textTheme.titleMedium),
          const SizedBox(height: AffluenaSpacing.space1),
          Text(message, style: textTheme.bodySmall),
        ],
      ),
    );
  }
}

class _RecentTransactions extends StatelessWidget {
  const _RecentTransactions({required this.home});

  final DashboardHome home;

  @override
  Widget build(BuildContext context) {
    if (home.recentTransactions.isEmpty) {
      return const AffluenaCard(child: Text('No recent transactions yet.'));
    }

    return AffluenaCard(
      child: Column(
        children: [
          for (final entry in home.recentTransactions.indexed) ...[
            _TransactionRow(home: home, transaction: entry.$2),
            if (entry.$1 < home.recentTransactions.length - 1)
              const Divider(height: 1),
          ],
        ],
      ),
    );
  }
}

class _TransactionRow extends ConsumerWidget {
  const _TransactionRow({required this.home, required this.transaction});

  final DashboardHome home;
  final Transaction transaction;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categoryName = home.categoryName(transaction);
    final walletName = home.walletName(transaction.walletId);
    final toWalletName = transaction.toWalletId == null
        ? null
        : home.walletName(transaction.toWalletId!);
    final date = AffluenaDateFormatter.shortDate(transaction.transactionAt);

    return InkWell(
      onTap: () {
        // The detail sheet resolves names/edit-permissions from the
        // transactions controller state; reading it also kicks off its load.
        final state = ref.read(transactionsControllerProvider);
        showTransactionDetail(context, ref, state, transaction);
      },
      borderRadius: BorderRadius.circular(AffluenaRadii.md),
      child: TransactionTile(
        title: transaction.note.isEmpty ? categoryName : transaction.note,
        metadata: _transactionMetadata(
          transaction,
          categoryName,
          walletName,
          toWalletName,
          date,
        ),
        amount: _transactionAmount(transaction),
        icon: _transactionIcon(transaction, categoryName),
        isIncome: transaction.type == TransactionType.income,
      ),
    );
  }
}

class _EmptyDashboardState extends StatelessWidget {
  const _EmptyDashboardState();

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
          const Icon(Icons.account_balance_wallet_outlined),
          const SizedBox(height: AffluenaSpacing.space3),
          Text('No activity yet', style: textTheme.titleMedium),
          const SizedBox(height: AffluenaSpacing.space1),
          Text(
            'Add your first wallet or transaction to start filling this dashboard.',
            style: textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}

class _DashboardLoading extends StatelessWidget {
  const _DashboardLoading();

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
        children: const [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AffluenaSkeleton.line(width: 64),
                    SizedBox(height: AffluenaSpacing.space2),
                    AffluenaSkeleton.line(width: 180, height: 22),
                  ],
                ),
              ),
              AffluenaSkeleton.circle(size: 40),
            ],
          ),
          SizedBox(height: AffluenaSpacing.space6),
          AffluenaCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AffluenaSkeleton.line(width: 96),
                SizedBox(height: AffluenaSpacing.space3),
                AffluenaSkeleton(width: 200, height: 34, radius: AffluenaRadii.md),
                SizedBox(height: AffluenaSpacing.space4),
                Row(
                  children: [
                    Expanded(
                      child: AffluenaSkeleton(
                        height: 84,
                        radius: AffluenaRadii.lg,
                      ),
                    ),
                    SizedBox(width: AffluenaSpacing.space3),
                    Expanded(
                      child: AffluenaSkeleton(
                        height: 84,
                        radius: AffluenaRadii.lg,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          SizedBox(height: AffluenaSpacing.space5),
          Row(
            children: [
              Expanded(
                child: AffluenaSkeleton(height: 72, radius: AffluenaRadii.card),
              ),
              SizedBox(width: AffluenaSpacing.space3),
              Expanded(
                child: AffluenaSkeleton(height: 72, radius: AffluenaRadii.card),
              ),
              SizedBox(width: AffluenaSpacing.space3),
              Expanded(
                child: AffluenaSkeleton(height: 72, radius: AffluenaRadii.card),
              ),
              SizedBox(width: AffluenaSpacing.space3),
              Expanded(
                child: AffluenaSkeleton(height: 72, radius: AffluenaRadii.card),
              ),
            ],
          ),
          SizedBox(height: AffluenaSpacing.space6),
          AffluenaSkeleton(height: 72, radius: AffluenaRadii.card),
        ],
      ),
    );
  }
}

class _DashboardError extends StatelessWidget {
  const _DashboardError({required this.message, required this.onRetry});

  final String message;
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
          Text('Affluena', style: textTheme.labelMedium),
          const SizedBox(height: AffluenaSpacing.space1),
          Text('Dashboard unavailable', style: textTheme.headlineMedium),
          const SizedBox(height: AffluenaSpacing.space5),
          AffluenaCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(message, style: textTheme.bodyMedium),
                const SizedBox(height: AffluenaSpacing.space4),
                FilledButton.icon(
                  key: const Key('dashboard-retry-button'),
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

String _budgetUsageLabel(double usagePercent) {
  if (usagePercent <= 0) return 'No budget yet';
  return '${usagePercent.round()}% planned';
}

String _greetingForNow(DateTime now) {
  final hour = now.hour;
  if (hour < 12) return 'Good morning';
  if (hour < 17) return 'Good afternoon';
  return 'Good evening';
}

String _avatarInitial(String? name, String? email) {
  final source = (name != null && name.trim().isNotEmpty)
      ? name.trim()
      : (email ?? '').trim();
  if (source.isEmpty) return 'A';
  return source.characters.first.toUpperCase();
}

String _debtTypeLabel(String type) {
  return switch (type.trim().toLowerCase()) {
    'payable' => 'You owe',
    'receivable' => 'Owed to you',
    _ => 'Debt',
  };
}

String _transactionMetadata(
  Transaction transaction,
  String categoryName,
  String walletName,
  String? toWalletName,
  String date,
) {
  if (transaction.type == TransactionType.transfer) {
    return '$walletName to ${toWalletName ?? 'another wallet'} · $date';
  }
  return '$categoryName · $walletName · $date';
}

String _transactionAmount(Transaction transaction) {
  return switch (transaction.type) {
    TransactionType.income => MoneyFormatter.signedIdr(transaction.amountMinor),
    TransactionType.expense => MoneyFormatter.signedIdr(
      -transaction.amountMinor,
    ),
    TransactionType.transfer ||
    TransactionType.adjustment => MoneyFormatter.idr(transaction.amountMinor),
  };
}

IconData _transactionIcon(Transaction transaction, String categoryName) {
  return switch (transaction.type) {
    TransactionType.income => Icons.work_outline,
    TransactionType.transfer => Icons.swap_horiz_rounded,
    TransactionType.adjustment => Icons.tune,
    TransactionType.expense =>
      categoryName.toLowerCase().contains('food')
          ? Icons.restaurant_outlined
          : Icons.receipt_long_outlined,
  };
}

String _dashboardErrorMessage(Object error) {
  if (error is ApiException) return error.message;
  if (error is DioException && error.error is ApiException) {
    return (error.error! as ApiException).message;
  }
  return 'We could not load your dashboard. Please try again.';
}
