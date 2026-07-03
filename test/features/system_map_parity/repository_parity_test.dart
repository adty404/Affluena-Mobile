import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:affluena_mobile/features/categories/data/category_repository.dart';
import 'package:affluena_mobile/features/insights/data/insights_repository.dart';
import 'package:affluena_mobile/features/quick_entry/data/quick_entry_models.dart';
import 'package:affluena_mobile/features/quick_entry/data/quick_entry_repository.dart';
import 'package:affluena_mobile/features/tags/data/tag_repository.dart';
import 'package:affluena_mobile/features/transactions/data/transaction_models.dart';
import 'package:affluena_mobile/features/transactions/data/transaction_repository.dart';
import 'package:affluena_mobile/features/wallets/data/wallet_models.dart';
import 'package:affluena_mobile/features/wallets/data/wallet_repository.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('system map repository parity', () {
    test(
      'wallet repository covers sharing, analytics, detail, and delete',
      () async {
        final requests = <_CapturedRequest>[];
        final repository = DioWalletRepository(
          _dio((options) {
            requests.add(_CapturedRequest.fromOptions(options));
            return _jsonResponse(switch ((options.method, options.path)) {
              ('GET', '/wallets/wallet-1') => _walletJson,
              ('DELETE', '/wallets/wallet-1') => null,
              ('POST', '/wallets/wallet-1/invites') => {'status': 'pending'},
              ('PATCH', '/wallets/wallet-1/members/member-2') => {
                'status': 'joined',
              },
              ('GET', '/wallets/wallet-1/members') => {
                'members': [_walletMemberJson],
              },
              ('GET', '/wallets/wallet-1/analytics') => _walletAnalyticsJson,
              _ => throw StateError('${options.method} ${options.path}'),
            });
          }),
        );

        final wallet = await repository.getWallet('wallet-1');
        await repository.deleteWallet('wallet-1');
        await repository.inviteMember(
          'wallet-1',
          const WalletInviteRequest(email: 'friend@example.com'),
        );
        await repository.respondInvite(
          'wallet-1',
          'member-2',
          const WalletInviteResponse(status: WalletShareStatus.joined),
        );
        final members = await repository.listMembers('wallet-1');
        final analytics = await repository.getAnalytics(
          'wallet-1',
          month: '2026-06',
        );

        expect(wallet.name, 'Daily Wallet');
        expect(members.members.single.email, 'friend@example.com');
        expect(analytics.inflowMinor, 2500000);
        expect(requests.map((request) => '${request.method} ${request.path}'), [
          'GET /wallets/wallet-1',
          'DELETE /wallets/wallet-1',
          'POST /wallets/wallet-1/invites',
          'PATCH /wallets/wallet-1/members/member-2',
          'GET /wallets/wallet-1/members',
          'GET /wallets/wallet-1/analytics',
        ]);
        expect(requests[2].jsonBody, {
          'email': 'friend@example.com',
          'role': 'member',
        });
        expect(requests[3].jsonBody, {'status': 'joined'});
        expect(requests[5].query, {'month': '2026-06'});
      },
    );

    test('category and tag repositories cover get and delete', () async {
      final requests = <_CapturedRequest>[];
      final categories = DioCategoryRepository(
        _dio((options) {
          requests.add(_CapturedRequest.fromOptions(options));
          return _jsonResponse(switch ((options.method, options.path)) {
            ('GET', '/categories/category-food') => _categoryJson,
            ('DELETE', '/categories/category-food') => null,
            ('PUT', '/categories/reorder') => null,
            _ => throw StateError('${options.method} ${options.path}'),
          });
        }),
      );
      final tags = DioTagRepository(
        _dio((options) {
          requests.add(_CapturedRequest.fromOptions(options));
          return _jsonResponse(switch ((options.method, options.path)) {
            ('GET', '/tags/tag-lunch') => _tagJson,
            ('DELETE', '/tags/tag-lunch') => null,
            _ => throw StateError('${options.method} ${options.path}'),
          });
        }),
      );

      final category = await categories.getCategory('category-food');
      await categories.deleteCategory('category-food');
      await categories.reorderCategories(['category-food', 'category-coffee']);
      final tag = await tags.getTag('tag-lunch');
      await tags.deleteTag('tag-lunch');

      expect(category.name, 'Food & Dining');
      expect(tag.name, 'Lunch');
      expect(requests.map((request) => '${request.method} ${request.path}'), [
        'GET /categories/category-food',
        'DELETE /categories/category-food',
        'PUT /categories/reorder',
        'GET /tags/tag-lunch',
        'DELETE /tags/tag-lunch',
      ]);
      // Reorder body: position = array index, exactly as the contract states.
      expect(requests[2].jsonBody, {
        'ids': ['category-food', 'category-coffee'],
      });
    });

    test('transaction repository covers split bill', () async {
      _CapturedRequest? captured;
      final repository = DioTransactionRepository(
        _dio((options) {
          captured = _CapturedRequest.fromOptions(options);
          return _jsonResponse({
            'transaction_id': 'transaction-split',
            'debt_ids': ['debt-1', 'debt-2'],
          });
        }),
      );

      final response = await repository.splitBill(
        const SplitTransactionRequest(
          walletId: 'wallet-1',
          categoryId: 'category-food',
          totalAmountMinor: 120000,
          transactionAt: '2026-06-22T10:00:00Z',
          note: 'Dinner split',
          tagIds: ['tag-lunch'],
          splits: [
            TransactionSplit(
              counterpartyName: 'Alya',
              amountMinor: 60000,
              disbursementCategoryId: 'category-income',
              paymentCategoryId: 'category-food',
            ),
            TransactionSplit(
              counterpartyName: 'Bima',
              amountMinor: 60000,
              disbursementCategoryId: 'category-income',
              paymentCategoryId: 'category-food',
            ),
          ],
        ),
      );

      expect(response.transactionId, 'transaction-split');
      expect(response.debtIds, ['debt-1', 'debt-2']);
      expect(captured?.method, 'POST');
      expect(captured?.path, '/transactions/split');
      expect(captured?.jsonBody['total_amount_minor'], 120000);
      expect(captured?.jsonBody['splits'], hasLength(2));
    });

    test('quick entry repository covers template CRUD plus execute', () async {
      final requests = <_CapturedRequest>[];
      final repository = DioQuickEntryRepository(
        _dio((options) {
          requests.add(_CapturedRequest.fromOptions(options));
          return _jsonResponse(switch ((options.method, options.path)) {
            ('GET', '/quick-entry-templates/template-1') => _templateJson,
            ('POST', '/quick-entry-templates') => _templateJson,
            ('PUT', '/quick-entry-templates/template-1') => _templateJson,
            ('DELETE', '/quick-entry-templates/template-1') => null,
            ('POST', '/quick-entry-templates/template-1/execute') => {
              'transaction': _transactionJson,
            },
            _ => throw StateError('${options.method} ${options.path}'),
          });
        }),
      );

      final template = await repository.getTemplate('template-1');
      await repository.createTemplate(_templateRequest);
      await repository.updateTemplate('template-1', _templateRequest);
      await repository.deleteTemplate('template-1');
      final execution = await repository.executeTemplate(
        'template-1',
        const ExecuteQuickEntryRequest(note: 'Override note'),
      );

      expect(template.name, 'Lunch shortcut');
      expect(execution.transaction.id, 'transaction-1');
      expect(requests.map((request) => '${request.method} ${request.path}'), [
        'GET /quick-entry-templates/template-1',
        'POST /quick-entry-templates',
        'PUT /quick-entry-templates/template-1',
        'DELETE /quick-entry-templates/template-1',
        'POST /quick-entry-templates/template-1/execute',
      ]);
      expect(requests[1].jsonBody['name'], 'Lunch shortcut');
      expect(requests[4].jsonBody, {'note': 'Override note'});
    });

    test('insights repository covers system logs', () async {
      final requests = <_CapturedRequest>[];
      final repository = DioInsightsRepository(
        _dio((options) {
          requests.add(_CapturedRequest.fromOptions(options));
          return _jsonResponse(switch ((options.method, options.path)) {
            ('GET', '/system-logs') => {
              'logs': [_systemLogJson],
            },
            ('GET', '/system-logs/log-1') => _systemLogJson,
            _ => throw StateError('${options.method} ${options.path}'),
          });
        }),
      );

      final logs = await repository.listSystemLogs(limit: 25);
      final log = await repository.getSystemLog('log-1');

      expect(logs.logs.single.path, '/api/v1/wallets');
      expect(log.statusCode, 200);
      expect(requests.map((request) => '${request.method} ${request.path}'), [
        'GET /system-logs',
        'GET /system-logs/log-1',
      ]);
      expect(requests.first.query, {'limit': 25});
    });
  });
}

Dio _dio(FutureOr<ResponseBody> Function(RequestOptions options) handler) {
  final dio = Dio(BaseOptions(baseUrl: 'http://api.test'));
  dio.httpClientAdapter = _HandlerAdapter(handler);
  return dio;
}

class _HandlerAdapter implements HttpClientAdapter {
  const _HandlerAdapter(this._handler);

  final FutureOr<ResponseBody> Function(RequestOptions options) _handler;

  @override
  void close({bool force = false}) {}

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    return _handler(options);
  }
}

ResponseBody _jsonResponse(Object? body, {int statusCode = 200}) {
  if (body == null) return ResponseBody.fromString('', statusCode);
  return ResponseBody.fromString(
    jsonEncode(body),
    statusCode,
    headers: {
      Headers.contentTypeHeader: [Headers.jsonContentType],
    },
  );
}

class _CapturedRequest {
  const _CapturedRequest({
    required this.method,
    required this.path,
    required this.query,
    required this.jsonBody,
  });

  factory _CapturedRequest.fromOptions(RequestOptions options) {
    return _CapturedRequest(
      method: options.method,
      path: options.path,
      query: Map<String, Object?>.from(options.queryParameters),
      jsonBody: options.data is Map
          ? Map<String, Object?>.from(options.data as Map)
          : const {},
    );
  }

  final String method;
  final String path;
  final Map<String, Object?> query;
  final Map<String, Object?> jsonBody;
}

const _walletJson = {
  'id': 'wallet-1',
  'user_id': 'user-1',
  'name': 'Daily Wallet',
  'type': 'bank',
  'currency_code': 'IDR',
  'balance_minor': 2500000,
  'color': 'green',
  'description': 'Main daily wallet',
  'role': 'owner',
  'share_status': 'joined',
  'created_at': '2026-06-01T00:00:00Z',
  'updated_at': '2026-06-22T00:00:00Z',
  'members': [_walletMemberJson],
};

const _walletMemberJson = {
  'wallet_id': 'wallet-1',
  'user_id': 'member-2',
  'email': 'friend@example.com',
  'role': 'viewer',
  'status': 'pending',
  'created_at': '2026-06-20T00:00:00Z',
  'updated_at': '2026-06-20T00:00:00Z',
};

const _walletAnalyticsJson = {
  'wallet_id': 'wallet-1',
  'month': '2026-06',
  'inflow_minor': 2500000,
  'outflow_minor': 1200000,
  'transaction_count': 12,
  'last_activity_at': '2026-06-22T10:00:00Z',
};

const _categoryJson = {
  'id': 'category-food',
  'user_id': 'user-1',
  'parent_id': null,
  'name': 'Food & Dining',
  'type': 'expense',
  'created_at': '2026-06-01T00:00:00Z',
  'updated_at': '2026-06-01T00:00:00Z',
};

const _tagJson = {
  'id': 'tag-lunch',
  'user_id': 'user-1',
  'name': 'Lunch',
  'created_at': '2026-06-01T00:00:00Z',
  'updated_at': '2026-06-01T00:00:00Z',
};

const _templateJson = {
  'id': 'template-1',
  'user_id': 'user-1',
  'name': 'Lunch shortcut',
  'type': 'expense',
  'wallet_id': 'wallet-1',
  'category_id': 'category-food',
  'amount_minor': 35000,
  'note': 'Lunch',
  'tag_ids': ['tag-lunch'],
  'created_at': '2026-06-01T00:00:00Z',
  'updated_at': '2026-06-01T00:00:00Z',
};

const _templateRequest = QuickEntryTemplateRequest(
  name: 'Lunch shortcut',
  type: TransactionType.expense,
  walletId: 'wallet-1',
  categoryId: 'category-food',
  amountMinor: 35000,
  note: 'Lunch',
  tagIds: ['tag-lunch'],
);

const _transactionJson = {
  'id': 'transaction-1',
  'user_id': 'user-1',
  'type': 'expense',
  'wallet_id': 'wallet-1',
  'category_id': 'category-food',
  'amount_minor': 35000,
  'tag_ids': ['tag-lunch'],
  'transaction_at': '2026-06-22T10:00:00Z',
  'note': 'Lunch',
  'created_at': '2026-06-22T10:00:00Z',
  'updated_at': '2026-06-22T10:00:00Z',
};

const _systemLogJson = {
  'id': 'log-1',
  'method': 'GET',
  'path': '/api/v1/wallets',
  'status_code': 200,
  'latency_ms': 12,
  'client_ip': '127.0.0.1',
  'user_agent': 'Flutter test',
  'user_id': 'user-1',
  'request_payload': null,
  'response_payload': '{"ok":true}',
  'created_at': '2026-06-22T10:00:00Z',
};
