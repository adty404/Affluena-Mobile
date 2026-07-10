import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/affluena_theme.dart';
import '../../../app/theme/sky_palette.dart';
import '../../../core/formatters/date_formatter.dart';
import '../../../core/formatters/money_formatter.dart';
import '../../shared/presentation/widgets/sky_detail.dart';
import '../../transactions/application/transactions_controller.dart';
import '../../transactions/data/transaction_repository.dart';
import '../../transactions/presentation/transaction_detail_sheet.dart';

/// One rendered row in a "Riwayat pembayaran" list — a view over
/// `InstallmentPayment`/`SubscriptionPayment` so the section widget is shared
/// by both tracker detail screens.
typedef TrackerPaymentEntry = ({
  String id,
  int amountMinor,
  String paidAt,
  String transactionId,
  String note,
});

/// "Riwayat pembayaran" — the payment history section on the installment and
/// subscription detail screens, fed by the `/…/:id/payments` endpoints
/// (newest first). Each row shows the paid amount + date (+ optional note)
/// and taps through to the backing transaction's detail sheet.
class TrackerPaymentHistorySection extends ConsumerWidget {
  const TrackerPaymentHistorySection({required this.payments, super.key});

  final AsyncValue<List<TrackerPaymentEntry>> payments;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Riwayat pembayaran',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: context.sky.ink,
          ),
        ),
        const SizedBox(height: AffluenaSpacing.space3),
        payments.when(
          loading: () => const _PaymentsSkeleton(),
          error: (_, _) => Text(
            'Tidak bisa memuat riwayat pembayaran.',
            style: TextStyle(fontSize: 12.5, color: context.sky.muted),
          ),
          data: (entries) => entries.isEmpty
              ? Text(
                  'Belum ada pembayaran.',
                  style: TextStyle(fontSize: 12.5, color: context.sky.muted),
                )
              : SkyDetailCard(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AffluenaSpacing.space2,
                    vertical: AffluenaSpacing.space2,
                  ),
                  child: Column(
                    children: [
                      for (var i = 0; i < entries.length; i++) ...[
                        if (i > 0) Divider(height: 1, color: context.sky.line),
                        _PaymentRow(entry: entries[i]),
                      ],
                    ],
                  ),
                ),
        ),
      ],
    );
  }
}

class _PaymentRow extends ConsumerWidget {
  const _PaymentRow({required this.entry});

  final TrackerPaymentEntry entry;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final canOpen = entry.transactionId.isNotEmpty;
    return InkWell(
      key: Key('payment-row-${entry.id}'),
      borderRadius: BorderRadius.circular(AffluenaRadii.md),
      onTap: canOpen ? () => _openTransaction(context, ref) : null,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AffluenaSpacing.space2,
          vertical: AffluenaSpacing.space3,
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    MoneyFormatter.idr(entry.amountMinor),
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w600,
                      color: context.sky.ink,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                  const SizedBox(height: 1),
                  Text(
                    AffluenaDateFormatter.shortDate(entry.paidAt),
                    style: TextStyle(fontSize: 11, color: context.sky.faint),
                  ),
                  if (entry.note.isNotEmpty) ...[
                    const SizedBox(height: 1),
                    Text(
                      entry.note,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 11, color: context.sky.muted),
                    ),
                  ],
                ],
              ),
            ),
            if (canOpen) ...[
              const SizedBox(width: AffluenaSpacing.space2),
              Icon(Icons.chevron_right, size: 18, color: context.sky.faint),
            ],
          ],
        ),
      ),
    );
  }

  /// Fetches the payment's backing transaction and opens the shared detail
  /// sheet, passing the global ledger state per the app convention (it powers
  /// name resolution + edit/delete without coupling this screen to the main
  /// transactions filter).
  Future<void> _openTransaction(BuildContext context, WidgetRef ref) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      final tx = await ref
          .read(transactionRepositoryProvider)
          .getTransaction(entry.transactionId);
      if (!context.mounted) return;
      showTransactionDetail(
        context,
        ref,
        ref.read(transactionsControllerProvider),
        tx,
      );
    } catch (_) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Transaksi tidak dapat dimuat.')),
      );
    }
  }
}

class _PaymentsSkeleton extends StatelessWidget {
  const _PaymentsSkeleton();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (var i = 0; i < 2; i++)
          Container(
            height: 44,
            margin: const EdgeInsets.only(bottom: AffluenaSpacing.space2),
            decoration: BoxDecoration(
              color: context.sky.sheet,
              borderRadius: BorderRadius.circular(AffluenaRadii.md),
            ),
          ),
      ],
    );
  }
}
