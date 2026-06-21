import 'package:affluena_mobile/features/debts/data/debt_models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('parses debt list and payment payloads', () {
    final response = DebtListResponse.fromJson({
      'debts': [
        {
          'id': 'debt-1',
          'user_id': 'user-1',
          'type': 'payable',
          'counterparty_name': 'Alya',
          'wallet_id': 'wallet-1',
          'disbursement_category_id': 'category-income',
          'payment_category_id': 'category-expense',
          'origination_transaction_id': 'transaction-1',
          'principal_amount_minor': 1500000,
          'paid_amount_minor': 500000,
          'remaining_amount_minor': 1000000,
          'opened_at': '2026-06-01T00:00:00Z',
          'due_date': '2026-06-30',
          'status': 'partial',
          'note': 'Laptop advance',
          'created_at': '2026-06-01T00:00:00Z',
          'updated_at': '2026-06-02T00:00:00Z',
          'payments': [
            {
              'id': 'payment-1',
              'user_id': 'user-1',
              'debt_id': 'debt-1',
              'transaction_id': 'transaction-2',
              'amount_minor': 500000,
              'paid_at': '2026-06-02T00:00:00Z',
              'note': 'First payment',
              'created_at': '2026-06-02T00:00:00Z',
            },
          ],
        },
      ],
      'pagination': {'total': 1, 'limit': 20, 'offset': 0},
    });

    final debt = response.debts.single;
    expect(debt.type, DebtType.payable);
    expect(debt.status, DebtStatus.partial);
    expect(debt.canPay, isTrue);
    expect(debt.paidPercent, closeTo(33.3, 0.1));
    expect(debt.payments.single.amountMinor, 500000);
  });

  test('serializes create, update, and payment requests', () {
    expect(
      const DebtRequest(
        type: DebtType.receivable,
        counterpartyName: 'Bima',
        walletId: 'wallet-1',
        disbursementCategoryId: 'category-expense',
        paymentCategoryId: 'category-income',
        principalAmountMinor: 2000000,
        dueDate: '2026-07-01',
        note: 'Short loan',
      ).toJson(),
      containsPair('type', 'receivable'),
    );

    expect(
      const DebtUpdateRequest(
        counterpartyName: 'Bima',
        status: DebtStatus.paidOff,
      ).toJson(),
      containsPair('status', 'paid_off'),
    );

    expect(
      const DebtPaymentRequest(
        amountMinor: 250000,
        paidAt: '2026-06-22T10:00:00Z',
      ).toJson(),
      containsPair('amount_minor', 250000),
    );
  });
}
