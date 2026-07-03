import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/affluena_theme.dart';
import '../../../app/theme/sky_palette.dart';
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
    final sky = context.sky;
    final isIncome = transaction.type == TransactionType.income;
    final isTransfer = transaction.type == TransactionType.transfer;
    final amountColor = isIncome ? sky.income : sky.ink;
    final note = transaction.note;

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
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Detail transaksi',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.2,
                  color: sky.muted,
                ),
              ),
              const SizedBox(height: AffluenaSpacing.space4),
              // Hero: category icon + title + type pill, with the amount as the
              // focal number (income green, everything else ink).
              Row(
                children: [
                  _CategoryIcon(state: state, transaction: transaction),
                  const SizedBox(width: AffluenaSpacing.space3),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          transactionTitle(state, transaction),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            height: 1.2,
                            color: sky.ink,
                          ),
                        ),
                        const SizedBox(height: 6),
                        _TypePill(type: transaction.type),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AffluenaSpacing.space4),
              Text(
                transactionAmount(transaction),
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                  color: amountColor,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
              const SizedBox(height: AffluenaSpacing.space5),
              // Details card.
              Container(
                decoration: BoxDecoration(
                  color: sky.surface,
                  borderRadius: BorderRadius.circular(AffluenaRadii.card),
                  border: Border.all(color: sky.line),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: AffluenaSpacing.space4,
                ),
                child: Column(
                  children: [
                    _InfoRow(
                      label: isTransfer ? 'Dari dompet' : 'Dompet',
                      value: state.walletName(transaction.walletId),
                    ),
                    if (isTransfer && transaction.toWalletId != null)
                      _InfoRow(
                        label: 'Ke dompet',
                        value: state.walletName(transaction.toWalletId!),
                      ),
                    if (!isTransfer)
                      _InfoRow(
                        label: 'Kategori',
                        value: state.categoryName(transaction),
                      ),
                    _InfoRow(
                      label: 'Tanggal & waktu',
                      value: AffluenaDateFormatter.dateTime(
                        transaction.transactionAt,
                      ),
                    ),
                    if (note.isNotEmpty)
                      _InfoRow(label: 'Catatan', value: note),
                  ],
                ),
              ),
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

/// A small pill naming the transaction type (Pengeluaran / Pemasukan / Transfer
/// / Penyesuaian) in a soft tinted chip.
class _TypePill extends StatelessWidget {
  const _TypePill({required this.type});

  final TransactionType type;

  @override
  Widget build(BuildContext context) {
    final sky = context.sky;
    final (label, color) = switch (type) {
      TransactionType.income => ('Pemasukan', sky.income),
      TransactionType.expense => ('Pengeluaran', sky.ink),
      TransactionType.transfer => ('Transfer', sky.muted),
      TransactionType.adjustment => ('Penyesuaian', sky.muted),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: color,
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
            foregroundColor: context.sky.danger,
            side: BorderSide(color: context.sky.danger),
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
    return AlertDialog(
      icon: Icon(Icons.delete_outline, color: context.sky.danger),
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
          style: FilledButton.styleFrom(backgroundColor: context.sky.danger),
          onPressed: () => Navigator.of(context).pop(true),
          child: const Text('Hapus'),
        ),
      ],
    );
  }
}

/// The transaction's category icon in its chosen color on a soft tinted tile —
/// the same leading treatment used across every transaction-history surface.
class _CategoryIcon extends StatelessWidget {
  const _CategoryIcon({required this.state, required this.transaction});

  final TransactionsState state;
  final Transaction transaction;

  @override
  Widget build(BuildContext context) {
    final sky = context.sky;
    final icon = transactionIcon(state, transaction);
    final custom = transactionIconColor(state, transaction);
    final accent = custom ?? sky.accent;
    final background = custom != null
        ? accent.withValues(alpha: 0.14)
        : sky.sheet;
    return Container(
      width: 48,
      height: 48,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(AffluenaRadii.lg),
        border: custom != null ? null : Border.all(color: sky.line),
      ),
      child: Icon(icon, size: 24, color: accent),
    );
  }
}

/// One label/value row inside the details card: muted label on the left, the
/// value right-aligned in ink. Rows are separated by their own vertical padding
/// (no dividers) for a calm card.
class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final sky = context.sky;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AffluenaSpacing.space3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 104,
            child: Text(
              label,
              style: TextStyle(fontSize: 12.5, color: sky.muted),
            ),
          ),
          const SizedBox(width: AffluenaSpacing.space3),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w600,
                color: sky.ink,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
