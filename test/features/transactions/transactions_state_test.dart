import 'package:affluena_mobile/features/transactions/application/transactions_controller.dart';
import 'package:affluena_mobile/features/transactions/data/transaction_models.dart';
import 'package:flutter_test/flutter_test.dart';

import 'transactions_test_data.dart';

void main() {
  final mine = transactionFixture(
    id: 't-mine',
    type: TransactionType.expense,
    walletId: 'w-own',
    amountMinor: 1000,
    note: 'Kopi',
    transactionAt: '2026-06-20T08:00:00Z',
  );
  final shared = transactionFixture(
    id: 't-shared',
    type: TransactionType.expense,
    walletId: 'w-viewer',
    amountMinor: 2000,
    note: 'Belanja pasangan',
    transactionAt: '2026-06-19T08:00:00Z',
  );

  test(
    'visibleTransactions hides transactions from shared (viewer) wallets',
    () {
      final state = TransactionsState(
        transactions: [mine, shared],
        viewerWalletIds: const {'w-viewer'},
      );

      expect(state.visibleTransactions.map((t) => t.id), ['t-mine']);
    },
  );

  test(
    'visibleTransactions keeps everything when no wallet is shared to me',
    () {
      final state = TransactionsState(transactions: [mine, shared]);

      expect(state.visibleTransactions.length, 2);
    },
  );
}
