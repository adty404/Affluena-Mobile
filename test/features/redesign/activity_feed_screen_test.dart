import 'package:affluena_mobile/core/api/pagination.dart';
import 'package:affluena_mobile/features/auth/application/auth_controller.dart';
import 'package:affluena_mobile/features/auth/data/auth_models.dart';
import 'package:affluena_mobile/features/categories/data/category_models.dart';
import 'package:affluena_mobile/features/redesign/presentation/activity_feed_screen.dart';
import 'package:affluena_mobile/features/shared/presentation/appearance/item_appearance.dart';
import 'package:affluena_mobile/features/transactions/application/transactions_controller.dart';
import 'package:affluena_mobile/features/transactions/data/split_bill_models.dart';
import 'package:affluena_mobile/features/transactions/data/transaction_models.dart';
import 'package:affluena_mobile/features/transactions/data/transaction_repository.dart';
import 'package:affluena_mobile/features/wallets/application/wallets_controller.dart';
import 'package:affluena_mobile/features/wallets/data/wallet_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

const _me = AuthUser(
  id: 'u-me',
  email: 'aditya@example.com',
  name: 'Aditya',
  avatarUrl: '',
  createdAt: '2026-06-01T00:00:00Z',
  updatedAt: '2026-06-01T00:00:00Z',
);

const _gopay = Wallet(
  id: 'w1',
  userId: 'u-me',
  name: 'GoPay',
  type: WalletType.eWallet,
  currencyCode: 'IDR',
  balanceMinor: 1300000,
  color: 'blue',
  description: '',
  createdAt: '2026-06-01T00:00:00Z',
  updatedAt: '2026-06-01T00:00:00Z',
);

const _byMe = Transaction(
  id: 't1',
  userId: 'u-me',
  type: TransactionType.income,
  walletId: 'w1',
  amountMinor: 9500000,
  tagIds: [],
  transactionAt: '2026-06-20T09:00:00Z',
  note: 'Top-up',
  createdAt: '2026-06-20T09:00:00Z',
  updatedAt: '2026-06-20T09:00:00Z',
);

const _bySarah = Transaction(
  id: 't2',
  userId: 'u-sarah',
  type: TransactionType.expense,
  walletId: 'w1',
  categoryId: 'c-food',
  amountMinor: 100000,
  tagIds: [],
  transactionAt: '2026-06-20T08:00:00Z',
  note: 'Nonton berdua',
  createdAt: '2026-06-20T08:00:00Z',
  updatedAt: '2026-06-20T08:00:00Z',
);

// A category with a chosen icon (food -> restaurant) and color (green) so the
// feed row must render that glyph in that color.
const _foodColor = '#2E8B57';
const _food = Category(
  id: 'c-food',
  userId: 'u-me',
  name: 'Makanan',
  type: CategoryType.expense,
  icon: 'food',
  color: _foodColor,
  createdAt: '2026-06-01T00:00:00Z',
  updatedAt: '2026-06-01T00:00:00Z',
);

class _AuthedController extends AuthController {
  @override
  AuthState build() => AuthState.authenticated(_me);
}

// The feed watches the transactions controller for the shared detail sheet and
// for category resolution; stub it (no microtask load) so the test stays
// hermetic.
class _StubTransactionsController extends TransactionsController {
  @override
  TransactionsState build() => const TransactionsState(
    walletNames: {'w1': 'GoPay'},
    categories: [_food],
    categoryNames: {'c-food': 'Makanan'},
  );
}

// A fake repository that records the last listTransactions params so a test can
// assert the feed's server-side filter maps to the right query — and returns
// only rows matching walletId/categoryId so the shown list reflects the filter.
class _RecordingRepository implements TransactionRepository {
  String? lastWalletId;
  String? lastCategoryId;
  String? lastFrom;
  String? lastTo;

  @override
  Future<TransactionListResponse> listTransactions({
    TransactionType? type,
    String? walletId,
    String? categoryId,
    String? tagId,
    String? from,
    String? to,
    int? limit,
    int? offset,
    String? sort,
  }) async {
    lastWalletId = walletId;
    lastCategoryId = categoryId;
    lastFrom = from;
    lastTo = to;
    final rows = <Transaction>[_byMe, _bySarah].where((t) {
      if (walletId != null && t.walletId != walletId) return false;
      if (categoryId != null && t.categoryId != categoryId) return false;
      return true;
    }).toList();
    return TransactionListResponse(
      transactions: rows,
      pagination: Pagination(
        total: rows.length,
        limit: limit ?? 100,
        offset: 0,
      ),
    );
  }

  @override
  Future<void> deleteTransaction(String id) async {}

  @override
  Future<Transaction> getTransaction(String id) => throw UnimplementedError();

  @override
  Future<Transaction> createTransaction(TransactionRequest request) =>
      throw UnimplementedError();

  @override
  Future<SplitTransactionResponse> splitBill(SplitTransactionRequest request) =>
      throw UnimplementedError();

  @override
  Future<SplitBillListResponse> listSplitBills({String? status}) =>
      throw UnimplementedError();

  @override
  Future<SplitBillDetail> getSplitBill(String transactionId) =>
      throw UnimplementedError();
}

// Seeds the transactions controller state with the wallet + category the filter
// sheet selectors need to render an option to pick.
class _FilterableTransactionsController extends TransactionsController {
  @override
  TransactionsState build() => const TransactionsState(
    wallets: [_gopay],
    walletNames: {'w1': 'GoPay'},
    categories: [_food],
    categoryNames: {'c-food': 'Makanan'},
  );
}

Future<void> _pump(WidgetTester tester) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        authControllerProvider.overrideWith(_AuthedController.new),
        walletListProvider.overrideWith((ref) async => const [_gopay]),
        transactionsControllerProvider.overrideWith(
          _StubTransactionsController.new,
        ),
        recentActivityProvider.overrideWith(
          (ref, q) async => const [_byMe, _bySarah],
        ),
      ],
      child: const MaterialApp(home: ActivityFeedScreen()),
    ),
  );
  for (var i = 0; i < 6; i++) {
    await tester.pump(const Duration(milliseconds: 10));
  }
}

// Pumps the feed against the real family provider (backed by [repo]) so the
// filter query round-trips through the repository the way it does in prod.
Future<void> _pumpWithRepo(
  WidgetTester tester,
  _RecordingRepository repo,
) async {
  await tester.binding.setSurfaceSize(const Size(390, 844));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        authControllerProvider.overrideWith(_AuthedController.new),
        walletListProvider.overrideWith((ref) async => const [_gopay]),
        transactionsControllerProvider.overrideWith(
          _FilterableTransactionsController.new,
        ),
        transactionRepositoryProvider.overrideWithValue(repo),
      ],
      child: const MaterialApp(home: ActivityFeedScreen()),
    ),
  );
  for (var i = 0; i < 6; i++) {
    await tester.pump(const Duration(milliseconds: 10));
  }
}

void main() {
  testWidgets('renders the merged cross-wallet feed with signed amounts', (
    tester,
  ) async {
    await _pump(tester);

    expect(find.text('Aktivitas'), findsOneWidget);
    expect(find.text('Top-up'), findsOneWidget);
    expect(find.text('Nonton berdua'), findsOneWidget);
    expect(find.text('+Rp 9.500.000'), findsOneWidget);
    expect(find.text('-Rp 100.000'), findsOneWidget);
  });

  testWidgets('tags the current user own entries with "kamu"', (tester) async {
    await _pump(tester);
    // Only my own transaction (Top-up) carries the "kamu" attribution.
    expect(find.textContaining('kamu'), findsOneWidget);
    // Wallet name shows in the row metadata.
    expect(find.textContaining('GoPay'), findsWidgets);
  });

  testWidgets('renders the category icon in its chosen color on each row', (
    tester,
  ) async {
    await _pump(tester);

    // The categorized expense (Makanan) shows its chosen glyph...
    final icon = tester.widget<Icon>(
      find.descendant(
        of: find.byKey(const Key('activity-row-category-icon')).at(1),
        matching: find.byType(Icon),
      ),
    );
    expect(icon.icon, Icons.restaurant_outlined);
    // ...in the category's chosen color, not a monochrome avatar.
    expect(icon.color, parseItemColor(_foodColor));

    // Every row carries a category-icon tile (no initial-letter avatar).
    expect(
      find.byKey(const Key('activity-row-category-icon')),
      findsNWidgets(2),
    );
    expect(find.text('K'), findsNothing);
  });

  testWidgets('tapping a row opens the shared transaction detail sheet', (
    tester,
  ) async {
    await _pump(tester);

    await tester.tap(find.text('Top-up'));
    await tester.pumpAndSettle();

    expect(find.text('Detail transaksi'), findsOneWidget);
    // My own transaction exposes the creator actions inside the sheet.
    expect(find.text('Ubah transaksi'), findsOneWidget);
    expect(find.text('Hapus transaksi'), findsOneWidget);
  });

  testWidgets('search narrows the shown rows by note/wallet/category', (
    tester,
  ) async {
    await _pump(tester);
    // Both rows show before searching.
    expect(find.text('Top-up'), findsOneWidget);
    expect(find.text('Nonton berdua'), findsOneWidget);

    await tester.enterText(
      find.byKey(const Key('activity-search-field')),
      'nonton',
    );
    for (var i = 0; i < 4; i++) {
      await tester.pump(const Duration(milliseconds: 10));
    }

    // Only the matching row remains.
    expect(find.text('Nonton berdua'), findsOneWidget);
    expect(find.text('Top-up'), findsNothing);

    // Clearing the search restores both rows.
    await tester.tap(find.byKey(const Key('activity-search-clear')));
    for (var i = 0; i < 4; i++) {
      await tester.pump(const Duration(milliseconds: 10));
    }
    expect(find.text('Top-up'), findsOneWidget);
    expect(find.text('Nonton berdua'), findsOneWidget);
  });

  testWidgets('a search with no matches shows the no-results empty state', (
    tester,
  ) async {
    await _pump(tester);

    await tester.enterText(
      find.byKey(const Key('activity-search-field')),
      'zzz-nope',
    );
    for (var i = 0; i < 4; i++) {
      await tester.pump(const Duration(milliseconds: 10));
    }

    expect(find.text('Tidak ada transaksi yang cocok'), findsOneWidget);
    expect(find.text('Top-up'), findsNothing);
    expect(find.text('Nonton berdua'), findsNothing);

    // The empty state's clear action restores the feed.
    await tester.tap(find.text('Hapus filter & pencarian'));
    for (var i = 0; i < 4; i++) {
      await tester.pump(const Duration(milliseconds: 10));
    }
    expect(find.text('Top-up'), findsOneWidget);
  });

  testWidgets(
    'applying a category filter passes the query to the repo and narrows rows',
    (tester) async {
      final repo = _RecordingRepository();
      await _pumpWithRepo(tester, repo);

      // Unfiltered: both rows and an all-null query.
      expect(find.text('Top-up'), findsOneWidget);
      expect(find.text('Nonton berdua'), findsOneWidget);
      expect(repo.lastCategoryId, isNull);

      // Open the filter sheet.
      await tester.tap(find.byKey(const Key('activity-filter-button')));
      await tester.pumpAndSettle();

      // The Tag selector is hidden for Aktivitas (includeTag: false).
      expect(find.byKey(const Key('filter-tag-selector')), findsNothing);

      // Pick the Makanan category.
      await tester.tap(find.byKey(const Key('filter-category-selector')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Makanan').last);
      await tester.pumpAndSettle();

      // Apply.
      await tester.tap(find.byKey(const Key('filter-apply-button')));
      await tester.pumpAndSettle();

      // The provider re-fetched with the category id...
      expect(repo.lastCategoryId, 'c-food');
      // ...and the feed now shows only the categorized (Makanan) row.
      expect(find.text('Nonton berdua'), findsOneWidget);
      expect(find.text('Top-up'), findsNothing);

      // The active-filter chip strip + reset chip are shown.
      expect(find.byKey(const Key('activity-clear-filters')), findsOneWidget);

      // Reset clears the filter and re-fetches unfiltered.
      await tester.tap(find.byKey(const Key('activity-clear-filters')));
      for (var i = 0; i < 4; i++) {
        await tester.pump(const Duration(milliseconds: 10));
      }
      expect(repo.lastCategoryId, isNull);
      expect(find.text('Top-up'), findsOneWidget);
    },
  );
}
