import 'package:affluena_mobile/app/provider_retry.dart';
import 'package:affluena_mobile/core/api/pagination.dart';
import 'package:affluena_mobile/features/categories/data/category_models.dart';
import 'package:affluena_mobile/features/categories/data/category_repository.dart';
import 'package:affluena_mobile/features/recurring/data/recurring_models.dart';
import 'package:affluena_mobile/features/recurring/data/recurring_repository.dart';
import 'package:affluena_mobile/features/recurring/presentation/recurring_detail_screen.dart';
import 'package:affluena_mobile/features/wallets/data/wallet_models.dart';
import 'package:affluena_mobile/features/wallets/data/wallet_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

const _rule = RecurringRule(
  id: 'rule-1',
  userId: 'user-1',
  name: 'Transfer ke Tabungan',
  type: RecurringType.expense,
  walletId: 'wallet-main',
  toWalletId: '',
  categoryId: 'category-fun',
  amountMinor: 500000,
  frequency: RecurringFrequency.monthly,
  intervalCount: 1,
  nextRunAt: '2026-08-01T00:00:00Z',
  endAt: '',
  lastRunAt: '',
  status: RecurringStatus.active,
  note: '',
  createdAt: '2026-06-01T00:00:00Z',
  updatedAt: '2026-06-01T00:00:00Z',
);

void main() {
  setUpAll(() async {
    await initializeDateFormatting('id_ID');
  });

  testWidgets('Jalankan sekarang books the run and confirms with a SnackBar', (
    tester,
  ) async {
    final repository = _RecordingRecurringRepository();
    await _pumpDetail(tester, repository);

    await tester.tap(find.text('Jalankan sekarang'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('sky-confirm-accept')));
    await tester.pumpAndSettle();

    expect(repository.runRuleIds, ['rule-1']);
    expect(find.text('Transaksi dicatat.'), findsOneWidget);
  });

  testWidgets('a failed run surfaces the error instead of failing silently', (
    tester,
  ) async {
    final repository = _RecordingRecurringRepository(
      runError: Exception('offline'),
    );
    await _pumpDetail(tester, repository);

    await tester.tap(find.text('Jalankan sekarang'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('sky-confirm-accept')));
    await tester.pumpAndSettle();

    expect(repository.runRuleIds, ['rule-1']);
    // The controller folds the failure into state.actionError; the screen
    // must surface it — the user would otherwise believe money was booked.
    expect(find.byType(SnackBar), findsOneWidget);
    expect(find.text('Aturan berulang gagal dijalankan.'), findsOneWidget);
  });
}

Future<void> _pumpDetail(
  WidgetTester tester,
  _RecordingRecurringRepository repository,
) async {
  await tester.pumpWidget(
    ProviderScope(
      retry: noProviderRetry,
      overrides: [
        recurringRepositoryProvider.overrideWithValue(repository),
        walletRepositoryProvider.overrideWithValue(
          const _StubWalletRepository(),
        ),
        categoryRepositoryProvider.overrideWithValue(
          const _StubCategoryRepository(),
        ),
      ],
      child: const MaterialApp(home: RecurringDetailScreen(id: 'rule-1')),
    ),
  );
  await tester.pump();
  await tester.pump();
  await tester.pumpAndSettle();
}

class _RecordingRecurringRepository implements RecurringRepository {
  _RecordingRecurringRepository({this.runError});

  /// When set, [runRule] throws instead of booking the run.
  final Object? runError;

  final runRuleIds = <String>[];

  @override
  Future<RecurringRuleListResponse> listRules({
    int? limit,
    int? offset,
    String? sort,
  }) async {
    return const RecurringRuleListResponse(
      rules: [_rule],
      pagination: Pagination(total: 1, limit: 20, offset: 0),
    );
  }

  @override
  Future<RecurringRun> runRule(String id) async {
    runRuleIds.add(id);
    final error = runError;
    if (error != null) throw error;
    return const RecurringRun(
      id: 'run-1',
      ruleId: 'rule-1',
      userId: 'user-1',
      scheduledFor: '2026-08-01T00:00:00Z',
      transactionId: 'transaction-1',
      runType: RecurringRunType.manual,
      createdAt: '2026-07-05T00:00:00Z',
    );
  }

  @override
  Future<RecurringRule> getRule(String id) async => _rule;

  @override
  Future<RecurringRule> createRule(RecurringRuleRequest request) =>
      throw UnimplementedError();

  @override
  Future<RecurringRule> updateRule(String id, RecurringRuleRequest request) =>
      throw UnimplementedError();

  @override
  Future<void> deleteRule(String id) => throw UnimplementedError();
}

class _StubWalletRepository implements WalletRepository {
  const _StubWalletRepository();

  @override
  Future<WalletListResponse> listWallets({
    int? limit,
    int? offset,
    String? sort,
  }) async {
    return const WalletListResponse(
      wallets: [
        Wallet(
          id: 'wallet-main',
          userId: 'user-1',
          name: 'Main Wallet',
          type: WalletType.bank,
          currencyCode: 'IDR',
          balanceMinor: 5000000,
          color: 'green',
          description: '',
          createdAt: '2026-06-01T00:00:00Z',
          updatedAt: '2026-06-01T00:00:00Z',
        ),
      ],
      pagination: Pagination(total: 1, limit: 100, offset: 0),
    );
  }

  @override
  Future<Wallet> createWallet(WalletRequest request) =>
      throw UnimplementedError();

  @override
  Future<Wallet> getWallet(String id) => throw UnimplementedError();

  @override
  Future<Wallet> updateWallet(String id, WalletRequest request) =>
      throw UnimplementedError();

  @override
  Future<void> deleteWallet(String id) => throw UnimplementedError();

  @override
  Future<WalletInviteResponse> inviteMember(
    String id,
    WalletInviteRequest request,
  ) => throw UnimplementedError();

  @override
  Future<WalletInviteResponse> respondInvite(
    String id,
    String memberId,
    WalletInviteResponse response,
  ) => throw UnimplementedError();

  @override
  Future<WalletMembersResponse> listMembers(String id) =>
      throw UnimplementedError();

  @override
  Future<WalletAnalytics> getAnalytics(String id, {String? month}) =>
      throw UnimplementedError();
}

class _StubCategoryRepository implements CategoryRepository {
  const _StubCategoryRepository();

  @override
  Future<CategoryListResponse> listCategories({
    CategoryType? type,
    int? limit,
    int? offset,
    String? sort,
  }) async {
    return const CategoryListResponse(
      categories: [
        Category(
          id: 'category-fun',
          userId: 'user-1',
          name: 'Hiburan',
          type: CategoryType.expense,
          createdAt: '2026-06-01T00:00:00Z',
          updatedAt: '2026-06-01T00:00:00Z',
        ),
      ],
      pagination: Pagination(total: 1, limit: 100, offset: 0),
    );
  }

  @override
  Future<Category> createCategory(CategoryRequest request) =>
      throw UnimplementedError();

  @override
  Future<Category> getCategory(String id) => throw UnimplementedError();

  @override
  Future<Category> updateCategory(String id, CategoryRequest request) =>
      throw UnimplementedError();

  @override
  Future<void> deleteCategory(String id) => throw UnimplementedError();

  @override
  Future<void> reorderCategories(List<String> ids) =>
      throw UnimplementedError();
}
