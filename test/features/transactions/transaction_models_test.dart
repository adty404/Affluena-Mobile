import 'package:affluena_mobile/features/transactions/data/transaction_models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('TransactionRequest.toJson fee_minor', () {
    test('a transfer with a fee emits fee_minor', () {
      final json = const TransactionRequest(
        type: TransactionType.transfer,
        walletId: 'from',
        toWalletId: 'to',
        amountMinor: 100000,
        feeMinor: 2500,
        transactionAt: '2026-07-11T09:00:00Z',
      ).toJson();

      expect(json['fee_minor'], 2500);
      expect(json['to_wallet_id'], 'to');
    });

    test('a transfer with a zero fee omits fee_minor', () {
      final json = const TransactionRequest(
        type: TransactionType.transfer,
        walletId: 'from',
        toWalletId: 'to',
        amountMinor: 100000,
        transactionAt: '2026-07-11T09:00:00Z',
      ).toJson();

      expect(json.containsKey('fee_minor'), isFalse);
    });

    test('an expense never emits fee_minor, even if one is set', () {
      final json = const TransactionRequest(
        type: TransactionType.expense,
        walletId: 'w1',
        categoryId: 'c1',
        amountMinor: 50000,
        feeMinor: 2500,
        transactionAt: '2026-07-11T09:00:00Z',
      ).toJson();

      expect(json.containsKey('fee_minor'), isFalse);
    });
  });

  group('Transaction.fromJson fee_minor', () {
    Map<String, dynamic> baseJson() => <String, dynamic>{
      'id': 't1',
      'user_id': 'u1',
      'type': 'transfer',
      'wallet_id': 'from',
      'to_wallet_id': 'to',
      'amount_minor': 100000,
      'tag_ids': <String>[],
      'transaction_at': '2026-07-11T09:00:00Z',
      'created_at': '2026-07-11T09:00:00Z',
      'updated_at': '2026-07-11T09:00:00Z',
    };

    test('parses a present fee_minor', () {
      final transaction = Transaction.fromJson(
        baseJson()..['fee_minor'] = 3000,
      );
      expect(transaction.feeMinor, 3000);
    });

    test('defaults fee_minor to 0 when absent', () {
      final transaction = Transaction.fromJson(baseJson());
      expect(transaction.feeMinor, 0);
    });
  });
}
