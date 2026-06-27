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
