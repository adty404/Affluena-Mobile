import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/affluena_theme.dart';
import '../../../core/formatters/date_formatter.dart';
import '../../auth/application/auth_controller.dart';
import '../../shared/presentation/widgets/affluena_banner.dart';
import '../application/transactions_controller.dart';
import '../data/transaction_models.dart';
import 'transaction_display.dart';
import 'transaction_edit_sheet.dart';

void showTransactionDetail(
  BuildContext context,
  WidgetRef ref,
  TransactionsState state,
  Transaction transaction,
) {
  final currentUserId = ref.read(authControllerProvider).user?.id;
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (sheetContext) {
      return _TransactionDetailSheet(
        state: state,
        transaction: transaction,
        currentUserId: currentUserId,
      );
    },
  );
}

class _TransactionDetailSheet extends ConsumerWidget {
  const _TransactionDetailSheet({
    required this.state,
    required this.transaction,
    required this.currentUserId,
  });

  final TransactionsState state;
  final Transaction transaction;
  final String? currentUserId;

  bool get _isCreator =>
      currentUserId != null && currentUserId == transaction.userId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textTheme = Theme.of(context).textTheme;

    return SafeArea(
      child: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            AffluenaSpacing.space5,
            AffluenaSpacing.space2,
            AffluenaSpacing.space5,
            MediaQuery.viewInsetsOf(context).bottom + AffluenaSpacing.space6,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Detail transaksi', style: textTheme.titleLarge),
              const SizedBox(height: AffluenaSpacing.space4),
              Text(
                transactionTitle(state, transaction),
                style: textTheme.headlineMedium,
              ),
              const SizedBox(height: AffluenaSpacing.space2),
              Text(transactionAmount(transaction), style: textTheme.titleLarge),
              const SizedBox(height: AffluenaSpacing.space4),
              _DetailLine(
                label: transaction.type == TransactionType.transfer
                    ? 'Dari dompet'
                    : 'Dompet',
                value: state.walletName(transaction.walletId),
              ),
              if (transaction.type == TransactionType.transfer &&
                  transaction.toWalletId != null)
                _DetailLine(
                  label: 'Ke dompet',
                  value: state.walletName(transaction.toWalletId!),
                ),
              _DetailLine(
                label: 'Kategori',
                value: state.categoryName(transaction),
              ),
              _DetailLine(
                label: 'Tanggal & waktu',
                value: AffluenaDateFormatter.dateTime(
                  transaction.transactionAt,
                ),
              ),
              if (transaction.note.isNotEmpty)
                _DetailLine(label: 'Catatan', value: transaction.note),
              const SizedBox(height: AffluenaSpacing.space5),
              if (_isCreator)
                _CreatorActions(state: state, transaction: transaction)
              else
                AffluenaBanner(
                  message:
                      'Hanya orang yang membuat transaksi ini yang dapat '
                      'mengubah atau menghapusnya.',
                  tone: AffluenaBannerTone.info,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CreatorActions extends ConsumerWidget {
  const _CreatorActions({required this.state, required this.transaction});

  final TransactionsState state;
  final Transaction transaction;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.affluenaColors;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        OutlinedButton.icon(
          key: const Key('transaction-detail-edit-button'),
          onPressed: () {
            Navigator.of(context).pop();
            showTransactionEditForm(context, state, transaction);
          },
          icon: const Icon(Icons.edit_outlined),
          label: const Text('Ubah transaksi'),
        ),
        const SizedBox(height: AffluenaSpacing.space3),
        OutlinedButton.icon(
          key: const Key('transaction-detail-delete-button'),
          style: OutlinedButton.styleFrom(
            foregroundColor: colors.coral,
            side: BorderSide(color: colors.coral),
          ),
          onPressed: () => _confirmDelete(context, ref),
          icon: const Icon(Icons.delete_outline),
          label: const Text('Hapus transaksi'),
        ),
      ],
    );
  }

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) =>
          _DeleteConfirmationDialog(transaction: transaction, state: state),
    );
    if (confirmed != true || !context.mounted) return;

    final messenger = ScaffoldMessenger.of(context);
    Navigator.of(context).pop();
    final deleted = await ref
        .read(transactionsControllerProvider.notifier)
        .deleteTransaction(transaction);
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          deleted ? 'Transaksi dihapus.' : 'Transaksi tidak dapat dihapus.',
        ),
      ),
    );
  }
}

class _DeleteConfirmationDialog extends StatelessWidget {
  const _DeleteConfirmationDialog({
    required this.transaction,
    required this.state,
  });

  final Transaction transaction;
  final TransactionsState state;

  @override
  Widget build(BuildContext context) {
    final colors = context.affluenaColors;

    return AlertDialog(
      icon: Icon(Icons.delete_outline, color: colors.coral),
      title: const Text('Hapus transaksi ini?'),
      content: Text(
        'Ini menghapus permanen "${transactionTitle(state, transaction)}" '
        'dan membatalkan pengaruhnya pada saldo dompetmu. Tindakan ini tidak '
        'bisa dibatalkan.',
      ),
      actions: [
        TextButton(
          key: const Key('transaction-delete-cancel'),
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Batal'),
        ),
        FilledButton(
          key: const Key('transaction-delete-confirm'),
          style: FilledButton.styleFrom(backgroundColor: colors.coral),
          onPressed: () => Navigator.of(context).pop(true),
          child: const Text('Hapus'),
        ),
      ],
    );
  }
}

class _DetailLine extends StatelessWidget {
  const _DetailLine({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: AffluenaSpacing.space2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 88, child: Text(label, style: textTheme.bodySmall)),
          Expanded(child: Text(value, style: textTheme.bodyLarge)),
        ],
      ),
    );
  }
}
