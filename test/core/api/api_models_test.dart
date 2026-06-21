import 'dart:convert';

import 'package:affluena_mobile/core/api/api_json.dart';
import 'package:affluena_mobile/core/formatters/money_formatter.dart';
import 'package:affluena_mobile/features/auth/data/auth_models.dart';
import 'package:affluena_mobile/features/categories/data/category_models.dart';
import 'package:affluena_mobile/features/dashboard/data/dashboard_models.dart';
import 'package:affluena_mobile/features/quick_entry/data/quick_entry_models.dart';
import 'package:affluena_mobile/features/tags/data/tag_models.dart';
import 'package:affluena_mobile/features/transactions/data/transaction_models.dart';
import 'package:affluena_mobile/features/wallets/data/wallet_models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('parses auth session payload', () {
    final session = AuthSession.fromJson(
      jsonMap({
        'user': userJson,
        'tokens': {
          'access_token': 'access-token',
          'refresh_token': 'refresh-token',
        },
      }),
    );

    expect(session.user.email, 'demo@affluena.com');
    expect(session.tokens.accessToken, 'access-token');
  });

  test(
    'parses wallet, category, tag, transaction, and quick entry payloads',
    () {
      final wallets = WalletListResponse.fromJson(
        jsonMap({
          'wallets': [walletJson],
          'pagination': paginationJson,
        }),
      );
      final categories = CategoryListResponse.fromJson(
        jsonMap({
          'categories': [categoryJson],
          'pagination': paginationJson,
        }),
      );
      final tags = TagListResponse.fromJson(
        jsonMap({
          'tags': [tagJson],
          'pagination': paginationJson,
        }),
      );
      final transactions = TransactionListResponse.fromJson(
        jsonMap({
          'transactions': [transactionJson],
          'pagination': paginationJson,
        }),
      );
      final templates = QuickEntryTemplateListResponse.fromJson(
        jsonMap({
          'templates': [quickEntryJson],
          'pagination': paginationJson,
        }),
      );

      expect(wallets.wallets.single.name, 'GoPay');
      expect(wallets.wallets.single.type, WalletType.eWallet);
      expect(categories.categories.single.name, 'Food & Dining');
      expect(categories.categories.single.type, CategoryType.expense);
      expect(tags.tags.single.name, '#MonthlyBill');
      expect(transactions.transactions.single.categoryId, categoryJson['id']);
      expect(templates.templates.single.walletId, walletJson['id']);
    },
  );

  test('parses dashboard summary and formats money from minor units', () {
    final summary = DashboardSummary.fromJson(
      jsonMap({
        'month': '2026-06',
        'net_worth_minor': 16370000,
        'monthly_income_minor': 21000000,
        'monthly_expense_minor': 3300000,
        'monthly_cashflow_minor': 17700000,
        'budget': {
          'limit_minor': 1000000,
          'spent_minor': 720000,
          'remaining_minor': 280000,
          'usage_percent': 72.0,
        },
        'upcoming_subscriptions': [],
        'upcoming_installments': [],
        'upcoming_debts': [],
      }),
    );

    expect(summary.budget.usagePercent, 72);
    expect(MoneyFormatter.idr(summary.netWorthMinor), 'Rp 16.370.000');
    expect(MoneyFormatter.signedIdr(-125000), '-Rp 125.000');
  });

  test('parses nullable empty dashboard collections from API payloads', () {
    final summary = DashboardSummary.fromJson(
      jsonMap({
        'month': '2026-06',
        'net_worth_minor': 0,
        'monthly_income_minor': 0,
        'monthly_expense_minor': 0,
        'monthly_cashflow_minor': 0,
        'budget': {
          'limit_minor': 0,
          'spent_minor': 0,
          'remaining_minor': 0,
          'usage_percent': 0,
        },
        'upcoming_subscriptions': null,
        'upcoming_installments': null,
        'upcoming_debts': null,
      }),
    );

    expect(summary.upcomingSubscriptions, isEmpty);
    expect(summary.upcomingInstallments, isEmpty);
    expect(summary.upcomingDebts, isEmpty);
  });

  test('throws deterministic parse failure for malformed fields', () {
    expect(
      () =>
          Wallet.fromJson(jsonMap({...walletJson, 'balance_minor': '320000'})),
      throwsFormatException,
    );
  });
}

JsonMap jsonMap(Object value) {
  return Map<String, Object?>.from(jsonDecode(jsonEncode(value)) as Map);
}

const paginationJson = {'total': 1, 'limit': 20, 'offset': 0};

const userJson = {
  'id': '11111111-1111-1111-1111-111111111111',
  'email': 'demo@affluena.com',
  'name': 'Demo User',
  'avatar_url': '',
  'created_at': '2026-06-01T00:00:00Z',
  'updated_at': '2026-06-01T00:00:00Z',
};

const walletJson = {
  'id': '22222222-2222-2222-2222-222222220003',
  'user_id': '11111111-1111-1111-1111-111111111111',
  'name': 'GoPay',
  'type': 'e_wallet',
  'currency_code': 'IDR',
  'balance_minor': 320000,
  'color': 'green',
  'description': 'Daily meals and transport',
  'created_at': '2026-06-01T00:00:00Z',
  'updated_at': '2026-06-01T00:00:00Z',
};

const categoryJson = {
  'id': '44444444-4444-4444-4444-444444440001',
  'user_id': '11111111-1111-1111-1111-111111111111',
  'parent_id': null,
  'name': 'Food & Dining',
  'type': 'expense',
  'created_at': '2026-06-01T00:00:00Z',
  'updated_at': '2026-06-01T00:00:00Z',
};

const tagJson = {
  'id': '55555555-5555-5555-5555-555555550002',
  'user_id': '11111111-1111-1111-1111-111111111111',
  'name': '#MonthlyBill',
  'created_at': '2026-06-01T00:00:00Z',
  'updated_at': '2026-06-01T00:00:00Z',
};

const transactionJson = {
  'id': '66666666-6666-6666-6666-666666660001',
  'user_id': '11111111-1111-1111-1111-111111111111',
  'type': 'expense',
  'wallet_id': '22222222-2222-2222-2222-222222220003',
  'category_id': '44444444-4444-4444-4444-444444440001',
  'amount_minor': 125000,
  'tag_ids': ['55555555-5555-5555-5555-555555550002'],
  'transaction_at': '2026-06-21T10:00:00Z',
  'note': 'Lunch meeting',
  'created_at': '2026-06-21T10:00:00Z',
  'updated_at': '2026-06-21T10:00:00Z',
};

const quickEntryJson = {
  'id': '77777777-7777-7777-7777-777777770001',
  'user_id': '11111111-1111-1111-1111-111111111111',
  'name': 'Daily Coffee',
  'type': 'expense',
  'wallet_id': '22222222-2222-2222-2222-222222220003',
  'category_id': '44444444-4444-4444-4444-444444440001',
  'amount_minor': 35000,
  'note': 'Morning coffee',
  'tag_ids': ['55555555-5555-5555-5555-555555550002'],
  'created_at': '2026-06-01T00:00:00Z',
  'updated_at': '2026-06-01T00:00:00Z',
};
