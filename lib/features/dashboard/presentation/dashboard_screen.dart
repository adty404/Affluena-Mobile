import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/affluena_theme.dart';
import '../../../core/api/api_error.dart';
import '../../../core/formatters/date_formatter.dart';
import '../../../core/formatters/money_formatter.dart';
import '../../quick_entry/presentation/quick_entry_screen.dart';
import '../../shared/presentation/widgets/affluena_card.dart';
import '../../shared/presentation/widgets/metric_tile.dart';
import '../../shared/presentation/widgets/section_header.dart';
import '../../shared/presentation/widgets/transaction_tile.dart';
import '../../transactions/data/transaction_models.dart';
import '../../transactions/presentation/transactions_screen.dart';
import '../../wallets/presentation/wallets_screen.dart';
import '../application/dashboard_home_controller.dart';
import '../data/dashboard_models.dart';

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

class _DashboardContent extends StatelessWidget {
  const _DashboardContent({required this.home});

  final DashboardHome home;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colors = context.affluenaColors;
    final summary = home.summary;

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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Affluena', style: textTheme.labelMedium),
                    const SizedBox(height: AffluenaSpacing.space1),
                    Text('Good morning', style: textTheme.headlineMedium),
                  ],
                ),
              ),
              IconButton.filledTonal(
                onPressed: () {},
                icon: const Icon(Icons.notifications_none),
              ),
              const SizedBox(width: AffluenaSpacing.space2),
              CircleAvatar(
                backgroundColor: colors.forest,
                child: Text(
                  'A',
                  style: textTheme.bodyLarge?.copyWith(
                    color: colors.surfaceCanvas,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AffluenaSpacing.space6),
          AffluenaCard(
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
          ),
          const SizedBox(height: AffluenaSpacing.space5),
          _QuickActions(summary: summary),
          const SizedBox(height: AffluenaSpacing.space6),
          home.isEmpty
              ? const _EmptyDashboardState()
              : _BudgetCard(summary: summary),
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

class _QuickActions extends StatelessWidget {
  const _QuickActions({required this.summary});

  final DashboardSummary summary;

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
          onTap: () => context.go(QuickEntryScreen.path),
        ),
        const SizedBox(width: AffluenaSpacing.space3),
        _QuickAction(
          icon: Icons.pie_chart_outline,
          label: 'Budget',
          onTap: () => _showBudgetSheet(context, summary),
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

void _showBudgetSheet(BuildContext context, DashboardSummary summary) {
  final textTheme = Theme.of(context).textTheme;
  final hasBudget = summary.budget.limitMinor > 0;

  showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (context) {
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AffluenaSpacing.space5,
            AffluenaSpacing.space2,
            AffluenaSpacing.space5,
            AffluenaSpacing.space6,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Budget this month', style: textTheme.titleLarge),
              const SizedBox(height: AffluenaSpacing.space4),
              Text(
                hasBudget
                    ? '${summary.budget.usagePercent.round()}% used'
                    : 'No budget set yet',
                style: textTheme.headlineMedium,
              ),
              const SizedBox(height: AffluenaSpacing.space2),
              Text(
                hasBudget
                    ? '${MoneyFormatter.idr(summary.budget.remainingMinor)} remaining from ${MoneyFormatter.idr(summary.budget.limitMinor)}'
                    : 'Budgets will appear here once category budgets are available.',
                style: textTheme.bodyMedium,
              ),
            ],
          ),
        ),
      );
    },
  );
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
          Icon(Icons.pie_chart_outline, color: colors.amber),
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

class _TransactionRow extends StatelessWidget {
  const _TransactionRow({required this.home, required this.transaction});

  final DashboardHome home;
  final Transaction transaction;

  @override
  Widget build(BuildContext context) {
    final categoryName = home.categoryName(transaction);
    final walletName = home.walletName(transaction.walletId);
    final toWalletName = transaction.toWalletId == null
        ? null
        : home.walletName(transaction.toWalletId!);
    final date = AffluenaDateFormatter.shortDate(transaction.transactionAt);

    return TransactionTile(
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
          Text('Good morning', style: textTheme.headlineMedium),
          const SizedBox(height: AffluenaSpacing.space6),
          const AffluenaCard(
            child: SizedBox(
              height: 144,
              child: Center(child: Text('Loading dashboard')),
            ),
          ),
          const SizedBox(height: AffluenaSpacing.space5),
          const AffluenaCard(child: SizedBox(height: 72)),
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
