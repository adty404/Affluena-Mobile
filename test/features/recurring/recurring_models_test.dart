import 'package:affluena_mobile/features/recurring/data/recurring_models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('parses recurring list and manual run payloads', () {
    final response = RecurringRuleListResponse.fromJson(const {
      'recurring_transactions': [
        {
          'id': 'rule-1',
          'user_id': 'user-1',
          'name': 'Monthly rent',
          'type': 'expense',
          'wallet_id': 'wallet-main',
          'category_id': 'category-rent',
          'amount_minor': 2500000,
          'frequency': 'monthly',
          'interval_count': 1,
          'next_run_at': '2026-07-01T00:00:00Z',
          'last_run_at': null,
          'end_at': null,
          'status': 'active',
          'note': 'Apartment',
          'created_at': '2026-06-01T00:00:00Z',
          'updated_at': '2026-06-01T00:00:00Z',
        },
      ],
      'pagination': {'total': 1, 'limit': 20, 'offset': 0},
    });

    final rule = response.rules.single;
    expect(rule.type, RecurringType.expense);
    expect(rule.frequency, RecurringFrequency.monthly);
    expect(rule.status, RecurringStatus.active);
    expect(response.pagination.total, 1);

    final run = RecurringRun.fromJson(const {
      'id': 'run-1',
      'rule_id': 'rule-1',
      'user_id': 'user-1',
      'scheduled_for': '2026-07-01T00:00:00Z',
      'transaction_id': 'transaction-1',
      'run_type': 'manual',
      'created_at': '2026-06-22T00:00:00Z',
    });

    expect(run.runType, RecurringRunType.manual);
    expect(run.transactionId, 'transaction-1');
  });

  test('serializes recurring request with optional transfer fields', () {
    final json = const RecurringRuleRequest(
      name: 'Move to savings',
      type: RecurringType.transfer,
      walletId: 'wallet-main',
      toWalletId: 'wallet-save',
      amountMinor: 500000,
      frequency: RecurringFrequency.weekly,
      intervalCount: 2,
      nextRunAt: '2026-06-29T00:00:00Z',
      status: RecurringStatus.paused,
      note: 'Auto saving',
    ).toJson();

    expect(json, containsPair('type', 'transfer'));
    expect(json, containsPair('to_wallet_id', 'wallet-save'));
    expect(json, containsPair('frequency', 'weekly'));
    expect(json, containsPair('status', 'paused'));
  });
}
