part of 'split_bill_screen.dart';

class _SplitResultCard extends StatelessWidget {
  const _SplitResultCard({required this.result});

  final SplitTransactionResponse result;

  @override
  Widget build(BuildContext context) {
    final debtLabel = result.debtIds.length == 1
        ? '1 debt record created'
        : '${result.debtIds.length} debt records created';

    return AffluenaCard(
      backgroundColor: context.affluenaColors.forestSoft,
      borderColor: context.affluenaColors.forestSoft,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Split bill created',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: AffluenaSpacing.space2),
          const Text('Expense transaction recorded'),
          const SizedBox(height: AffluenaSpacing.space1),
          Text(debtLabel),
          const SizedBox(height: AffluenaSpacing.space4),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => context.go(TransactionsScreen.path),
                  child: const Text('View transactions'),
                ),
              ),
              const SizedBox(width: AffluenaSpacing.space3),
              Expanded(
                child: FilledButton.tonal(
                  onPressed: () => context.go(DebtScreen.path),
                  child: const Text('View debts'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SplitConfirmSheet extends StatelessWidget {
  const _SplitConfirmSheet({
    required this.totalAmount,
    required this.participantTotal,
    required this.participantCount,
  });

  final int totalAmount;
  final int participantTotal;
  final int participantCount;

  @override
  Widget build(BuildContext context) {
    final userShare = totalAmount - participantTotal;

    return SafeArea(
      key: const Key('split-confirm-sheet'),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AffluenaSpacing.space5,
          AffluenaSpacing.space2,
          AffluenaSpacing.space5,
          AffluenaSpacing.space5,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Create split bill',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: AffluenaSpacing.space4),
            _ConfirmRow(
              label: 'Total bill',
              value: MoneyFormatter.idr(totalAmount),
            ),
            _ConfirmRow(
              label: 'Participant share',
              value: MoneyFormatter.idr(participantTotal),
            ),
            _ConfirmRow(
              label: 'Your share',
              value: MoneyFormatter.idr(userShare < 0 ? 0 : userShare),
            ),
            _ConfirmRow(
              label: 'Participants',
              value: '$participantCount people',
            ),
            const SizedBox(height: AffluenaSpacing.space5),
            FilledButton(
              key: const Key('split-confirm-button'),
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Confirm split bill'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ConfirmRow extends StatelessWidget {
  const _ConfirmRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AffluenaSpacing.space2),
      child: Row(
        children: [
          Expanded(child: Text(label)),
          Text(value, style: Theme.of(context).textTheme.titleSmall),
        ],
      ),
    );
  }
}

class _SplitBillLoading extends StatelessWidget {
  const _SplitBillLoading();

  @override
  Widget build(BuildContext context) {
    return DrillInScaffold(
      title: 'Split bill',
      body: ListView(
        padding: AffluenaInsets.screen,
        children: [
          AffluenaCard(
            backgroundColor: context.affluenaColors.forestSoft,
            borderColor: context.affluenaColors.forestSoft,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: const [
                AffluenaSkeleton(height: 44),
                SizedBox(height: AffluenaSpacing.space4),
                AffluenaSkeleton(height: 44),
              ],
            ),
          ),
          const SizedBox(height: AffluenaSpacing.space5),
          AffluenaCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: const [
                AffluenaSkeleton(height: 48),
                SizedBox(height: AffluenaSpacing.space4),
                AffluenaSkeleton(height: 48),
                SizedBox(height: AffluenaSpacing.space4),
                AffluenaSkeleton(height: 48),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SplitBillLoadError extends StatelessWidget {
  const _SplitBillLoadError({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return DrillInScaffold(
      title: 'Split bill',
      body: ListView(
        padding: AffluenaInsets.screen,
        children: [
          AffluenaBanner.error(
            'We could not load split bill data.',
            onRetry: onRetry,
          ),
        ],
      ),
    );
  }
}
