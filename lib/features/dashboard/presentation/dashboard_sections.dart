part of 'dashboard_screen.dart';

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
    final now = clock.now();
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
                    style: textTheme.bodySmall?.copyWith(
                      color: colors.inkMuted,
                    ),
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
                Text(
                  '${item.percentage.round()}%',
                  style: textTheme.labelMedium,
                ),
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
