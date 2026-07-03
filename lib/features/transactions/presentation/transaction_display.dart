import 'package:flutter/material.dart';

import '../../../core/formatters/date_formatter.dart';
import '../../../core/formatters/money_formatter.dart';
import '../../shared/presentation/appearance/item_appearance.dart';
import '../application/transactions_controller.dart';
import '../data/transaction_models.dart';

String transactionTitle(TransactionsState state, Transaction transaction) {
  return transaction.note.isEmpty
      ? state.categoryName(transaction)
      : transaction.note;
}

String transactionMetadata(TransactionsState state, Transaction transaction) {
  final date = AffluenaDateFormatter.shortDate(transaction.transactionAt);
  final walletName = state.walletName(transaction.walletId);
  if (transaction.type == TransactionType.transfer) {
    final toWalletName = transaction.toWalletId == null
        ? 'Dompet tidak dikenal'
        : state.walletName(transaction.toWalletId!);
    return 'Transfer · $walletName ke $toWalletName · $date';
  }
  return '${state.categoryName(transaction)} · $walletName · $date';
}

/// Metadata for the day-grouped Activity list: the day is the section header,
/// so each row shows the time-of-day instead of the full date.
String transactionGroupedMetadata(
  TransactionsState state,
  Transaction transaction,
) {
  final time = AffluenaDateFormatter.time(transaction.transactionAt);
  final walletName = state.walletName(transaction.walletId);
  if (transaction.type == TransactionType.transfer) {
    final toWalletName = transaction.toWalletId == null
        ? 'Dompet tidak dikenal'
        : state.walletName(transaction.toWalletId!);
    return 'Transfer · $walletName ke $toWalletName · $time';
  }
  return '${state.categoryName(transaction)} · $walletName · $time';
}

String transactionAmount(Transaction transaction) {
  return switch (transaction.type) {
    TransactionType.income => MoneyFormatter.signedIdr(transaction.amountMinor),
    TransactionType.expense => MoneyFormatter.signedIdr(
      -transaction.amountMinor.abs(),
    ),
    TransactionType.transfer => MoneyFormatter.idr(transaction.amountMinor),
    TransactionType.adjustment => MoneyFormatter.idr(transaction.amountMinor),
  };
}

IconData transactionIcon(TransactionsState state, Transaction transaction) {
  if (transaction.type == TransactionType.transfer) {
    return Icons.swap_horiz_rounded;
  }
  // The category's chosen icon wins over any generic glyph.
  final category = state.categoryOf(transaction);
  if (category != null) {
    final chosen = categoryIconFor(category.icon);
    if (chosen != null) return chosen;
  }
  if (transaction.type == TransactionType.income) return Icons.work_outline;
  final categoryName = state.categoryName(transaction).toLowerCase();
  if (categoryName.contains('food')) return Icons.restaurant_outlined;
  if (categoryName.contains('transport')) {
    return Icons.local_gas_station_outlined;
  }
  if (categoryName.contains('bill')) return Icons.bolt_outlined;
  return Icons.receipt_long_outlined;
}

/// The category's chosen accent for [transaction]'s tile icon, or null to
/// keep the default theming.
Color? transactionIconColor(TransactionsState state, Transaction transaction) {
  final category = state.categoryOf(transaction);
  if (category == null) return null;
  return parseItemColor(category.color);
}
