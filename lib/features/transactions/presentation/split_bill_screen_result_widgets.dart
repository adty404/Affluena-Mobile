part of 'split_bill_screen.dart';

class _SplitResultCard extends StatelessWidget {
  const _SplitResultCard({required this.result});

  final SplitTransactionResponse result;

  @override
  Widget build(BuildContext context) {
    final debtLabel = result.debtIds.length == 1
        ? '1 catatan utang dibuat'
        : '${result.debtIds.length} catatan utang dibuat';

    return AffluenaCard(
      backgroundColor: context.affluenaColors.forestSoft,
      borderColor: context.affluenaColors.forestSoft,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Bagi tagihan dibuat',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: AffluenaSpacing.space2),
          const Text('Transaksi pengeluaran tercatat'),
          const SizedBox(height: AffluenaSpacing.space1),
          Text(debtLabel),
          const SizedBox(height: AffluenaSpacing.space4),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () => context.push(TransactionsScreen.path),
              child: const Text('Lihat transaksi'),
            ),
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
              'Buat bagi tagihan',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: AffluenaSpacing.space4),
            _ConfirmRow(
              label: 'Total tagihan',
              value: MoneyFormatter.idr(totalAmount),
            ),
            _ConfirmRow(
              label: 'Bagian peserta',
              value: MoneyFormatter.idr(participantTotal),
            ),
            _ConfirmRow(
              label: 'Bagianmu',
              value: MoneyFormatter.idr(userShare < 0 ? 0 : userShare),
            ),
            _ConfirmRow(label: 'Peserta', value: '$participantCount orang'),
            const SizedBox(height: AffluenaSpacing.space5),
            FilledButton(
              key: const Key('split-confirm-button'),
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Konfirmasi bagi tagihan'),
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
      title: 'Bagi tagihan',
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
      title: 'Bagi tagihan',
      body: ListView(
        padding: AffluenaInsets.screen,
        children: [
          AffluenaBanner.error(
            'Kami tidak dapat memuat data bagi tagihan.',
            onRetry: onRetry,
          ),
        ],
      ),
    );
  }
}
