import 'package:affluena_mobile/features/trackers/data/tracker_models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('parses installment and subscription lists', () {
    final installments = InstallmentListResponse.fromJson({
      'installments': [
        {
          'id': 'installment-1',
          'user_id': 'user-1',
          'name': 'Laptop',
          'wallet_id': 'wallet-1',
          'category_id': 'category-1',
          'total_amount_minor': 12000000,
          'monthly_amount_minor': 1000000,
          'tenor_months': 12,
          'remaining_months': 8,
          'start_date': '2026-01-01',
          'due_day': 5,
          'status': 'active',
          'note': 'Office laptop',
          'created_at': '2026-01-01T00:00:00Z',
          'updated_at': '2026-01-01T00:00:00Z',
        },
      ],
      'pagination': {'total': 1, 'limit': 20, 'offset': 0},
    });

    final subscriptions = SubscriptionListResponse.fromJson({
      'subscriptions': [
        {
          'id': 'subscription-1',
          'user_id': 'user-1',
          'name': 'Spotify',
          'account_detail': 'family',
          'wallet_id': 'wallet-1',
          'category_id': 'category-1',
          'amount_minor': 65000,
          'billing_cycle': 'monthly',
          'next_due_date': '2026-07-01',
          'status': 'active',
          'note': '',
          'created_at': '2026-01-01T00:00:00Z',
          'updated_at': '2026-01-01T00:00:00Z',
        },
      ],
      'pagination': {'total': 1, 'limit': 20, 'offset': 0},
    });

    expect(installments.installments.single.paidPercent, closeTo(33.3, 0.1));
    expect(
      subscriptions.subscriptions.single.billingCycle,
      BillingCycle.monthly,
    );
  });

  test('serializes tracker requests', () {
    expect(
      const InstallmentRequest(
        name: 'Phone',
        walletId: 'wallet-1',
        categoryId: 'category-1',
        totalAmountMinor: 6000000,
        monthlyAmountMinor: 500000,
        tenorMonths: 12,
        startDate: '2026-06-01',
        dueDay: 10,
      ).toJson(),
      containsPair('tenor_months', 12),
    );

    expect(
      const SubscriptionRequest(
        name: 'Netflix',
        walletId: 'wallet-1',
        categoryId: 'category-1',
        amountMinor: 120000,
        billingCycle: BillingCycle.weekly,
        nextDueDate: '2026-06-29',
      ).toJson(),
      containsPair('billing_cycle', 'weekly'),
    );
  });
}
