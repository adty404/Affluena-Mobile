part of 'dashboard_screen.dart';

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
        padding: AffluenaInsets.screen,
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
                AffluenaSkeleton(
                  width: 200,
                  height: 34,
                  radius: AffluenaRadii.md,
                ),
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
        padding: AffluenaInsets.screen,
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
