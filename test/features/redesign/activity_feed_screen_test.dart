import 'package:affluena_mobile/core/api/pagination.dart';
import 'package:affluena_mobile/features/auth/application/auth_controller.dart';
import 'package:affluena_mobile/features/auth/data/auth_models.dart';
import 'package:affluena_mobile/features/categories/data/category_models.dart';
import 'package:affluena_mobile/features/redesign/presentation/activity_feed_screen.dart';
import 'package:affluena_mobile/features/shared/presentation/appearance/item_appearance.dart';
import 'package:affluena_mobile/features/shared/presentation/widgets/affluena_choice_chip.dart';
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

// A note-less, category-less transfer: its rendered row title is the type
// label ("Transfer"), which the server-side `search=` can never match — the
// client-side title-parity pass must keep it findable.
const _transfer = Transaction(
  id: 't3',
  userId: 'u-me',
  type: TransactionType.transfer,
  walletId: 'w1',
  amountMinor: 250000,
  tagIds: [],
  transactionAt: '2026-06-19T10:00:00Z',
  note: '',
  createdAt: '2026-06-19T10:00:00Z',
  updatedAt: '2026-06-19T10:00:00Z',
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
// assert the feed's server-side filter/search maps to the right query — and
// returns only matching rows (emulating the API's walletId/categoryId filters
// and its `search=` note/category-name/wallet-name matcher) so the shown list
// reflects the query.
class _RecordingRepository implements TransactionRepository {
  String? lastWalletId;
  String? lastCategoryId;
  String? lastFrom;
  String? lastTo;
  String? lastSearch;

  // The server resolves names itself; mirror that here.
  static const _walletNames = {'w1': 'GoPay'};
  static const _categoryNames = {'c-food': 'Makanan'};

  @override
  Future<TransactionListResponse> listTransactions({
    TransactionType? type,
    String? walletId,
    String? categoryId,
    String? tagId,
    String? from,
    String? to,
    String? search,
    int? limit,
    int? offset,
    String? sort,
  }) async {
    lastWalletId = walletId;
    lastCategoryId = categoryId;
    lastFrom = from;
    lastTo = to;
    lastSearch = search;
    final query = search?.toLowerCase();
    final rows = <Transaction>[_byMe, _bySarah, _transfer].where((t) {
      if (walletId != null && t.walletId != walletId) return false;
      if (categoryId != null && t.categoryId != categoryId) return false;
      if (query != null && query.isNotEmpty) {
        final haystack = [
          t.note,
          _walletNames[t.walletId] ?? '',
          _categoryNames[t.categoryId] ?? '',
        ].join(' ').toLowerCase();
        if (!haystack.contains(query)) return false;
      }
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

/// Search hides behind the Aktivitas header icon — expand it before typing.
Future<void> _openSearch(WidgetTester tester) async {
  await tester.tap(find.byKey(const Key('activity-search-button')));
  await tester.pump();
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

  testWidgets(
    'search debounces into a server-side query and narrows the rows',
    (tester) async {
      final repo = _RecordingRepository();
      await _pumpWithRepo(tester, repo);
      // Both rows show before searching, with no search param sent.
      expect(find.text('Top-up'), findsOneWidget);
      expect(find.text('Nonton berdua'), findsOneWidget);
      expect(repo.lastSearch, isNull);

      await _openSearch(tester);
      await tester.enterText(
        find.byKey(const Key('activity-search-field')),
        'nonton',
      );
      // Inside the debounce window nothing has been sent yet.
      await tester.pump(const Duration(milliseconds: 100));
      expect(repo.lastSearch, isNull);

      // Past the ~350ms debounce the provider re-fetches with `search=`.
      await tester.pump(const Duration(milliseconds: 400));
      for (var i = 0; i < 4; i++) {
        await tester.pump(const Duration(milliseconds: 10));
      }
      expect(repo.lastSearch, 'nonton');

      // Only the (server-)matching row remains.
      expect(find.text('Nonton berdua'), findsOneWidget);
      expect(find.text('Top-up'), findsNothing);

      // Clearing the search is instant (no debounce) and restores both rows.
      await tester.tap(find.byKey(const Key('activity-search-clear')));
      for (var i = 0; i < 4; i++) {
        await tester.pump(const Duration(milliseconds: 10));
      }
      expect(repo.lastSearch, isNull);
      expect(find.text('Top-up'), findsOneWidget);
      expect(find.text('Nonton berdua'), findsOneWidget);
    },
  );

  testWidgets('a search with no matches shows the no-results empty state', (
    tester,
  ) async {
    final repo = _RecordingRepository();
    await _pumpWithRepo(tester, repo);

    await _openSearch(tester);
    await tester.enterText(
      find.byKey(const Key('activity-search-field')),
      'zzz-nope',
    );
    await tester.pump(const Duration(milliseconds: 400));
    for (var i = 0; i < 4; i++) {
      await tester.pump(const Duration(milliseconds: 10));
    }

    expect(repo.lastSearch, 'zzz-nope');
    expect(find.text('Tidak ada transaksi yang cocok'), findsOneWidget);
    expect(find.text('Top-up'), findsNothing);
    expect(find.text('Nonton berdua'), findsNothing);

    // The empty state's clear action restores the feed.
    await tester.tap(find.text('Hapus filter & pencarian'));
    for (var i = 0; i < 4; i++) {
      await tester.pump(const Duration(milliseconds: 10));
    }
    expect(repo.lastSearch, isNull);
    expect(find.text('Top-up'), findsOneWidget);
  });

  testWidgets('a note-less transfer stays findable by its visible type label', (
    tester,
  ) async {
    final repo = _RecordingRepository();
    await _pumpWithRepo(tester, repo);
    // The transfer renders with its type-label title.
    expect(find.text('Transfer'), findsOneWidget);

    await _openSearch(tester);
    await tester.enterText(
      find.byKey(const Key('activity-search-field')),
      'transfer',
    );
    await tester.pump(const Duration(milliseconds: 400));
    for (var i = 0; i < 4; i++) {
      await tester.pump(const Duration(milliseconds: 10));
    }

    // The server search matches nothing (it only sees note/category/wallet
    // names), but the client-side title-parity pass unions the row back in
    // — same behavior as the ledger tab's client search.
    expect(find.text('Transfer'), findsOneWidget);
    expect(find.text('Top-up'), findsNothing);
    expect(find.text('Nonton berdua'), findsNothing);
  });

  testWidgets('the search query is capped at the API\'s 100-character limit', (
    tester,
  ) async {
    final repo = _RecordingRepository();
    await _pumpWithRepo(tester, repo);

    await _openSearch(tester);
    await tester.enterText(
      find.byKey(const Key('activity-search-field')),
      'a' * 150,
    );
    await tester.pump(const Duration(milliseconds: 400));
    for (var i = 0; i < 4; i++) {
      await tester.pump(const Duration(milliseconds: 10));
    }

    // The API 400s on >100 runes; the field/debounce clamp means the
    // provider can never send such a query.
    expect(repo.lastSearch, isNotNull);
    expect(repo.lastSearch!.runes.length, 100);
  });

  testWidgets(
    'backspacing a no-match search to empty never flashes the onboarding '
    'empty state',
    (tester) async {
      final repo = _RecordingRepository();
      await _pumpWithRepo(tester, repo);

      await _openSearch(tester);
      await tester.enterText(
        find.byKey(const Key('activity-search-field')),
        'zzz-nope',
      );
      await tester.pump(const Duration(milliseconds: 400));
      for (var i = 0; i < 4; i++) {
        await tester.pump(const Duration(milliseconds: 10));
      }
      expect(find.text('Tidak ada transaksi yang cocok'), findsOneWidget);

      // Backspace the query away (no clear-button tap): the empty field is
      // applied instantly, so the genuinely-empty onboarding state must never
      // show to a user who has transactions.
      await tester.enterText(
        find.byKey(const Key('activity-search-field')),
        '',
      );
      await tester.pump();
      expect(find.text('Belum ada transaksi'), findsNothing);
      for (var i = 0; i < 4; i++) {
        await tester.pump(const Duration(milliseconds: 10));
        expect(find.text('Belum ada transaksi'), findsNothing);
      }
      expect(repo.lastSearch, isNull);
      expect(find.text('Top-up'), findsOneWidget);
    },
  );

  testWidgets(
    'search lives behind the header icon; collapsing clears the query',
    (tester) async {
      final repo = _RecordingRepository();
      await _pumpWithRepo(tester, repo);

      // Hidden by default — only the header icon shows.
      expect(find.byKey(const Key('activity-search-field')), findsNothing);
      expect(find.byKey(const Key('activity-search-button')), findsOneWidget);

      // Expand, search, and narrow the rows.
      await _openSearch(tester);
      expect(find.byKey(const Key('activity-search-field')), findsOneWidget);
      await tester.enterText(
        find.byKey(const Key('activity-search-field')),
        'nonton',
      );
      await tester.pump(const Duration(milliseconds: 400));
      for (var i = 0; i < 4; i++) {
        await tester.pump(const Duration(milliseconds: 10));
      }
      expect(repo.lastSearch, 'nonton');
      expect(find.text('Top-up'), findsNothing);

      // Collapsing via the header icon clears the query instantly and
      // restores the unsearched feed.
      await tester.tap(find.byKey(const Key('activity-search-button')));
      await tester.pump();
      expect(find.byKey(const Key('activity-search-field')), findsNothing);
      for (var i = 0; i < 4; i++) {
        await tester.pump(const Duration(milliseconds: 10));
      }
      expect(repo.lastSearch, isNull);
      expect(find.text('Top-up'), findsOneWidget);
      expect(find.text('Nonton berdua'), findsOneWidget);
    },
  );

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

  testWidgets('tapping an active-filter chip removes only that filter', (
    tester,
  ) async {
    final repo = _RecordingRepository();
    await _pumpWithRepo(tester, repo);

    // Apply BOTH a wallet and a category filter through the sheet.
    await tester.tap(find.byKey(const Key('activity-filter-button')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('filter-wallet-selector')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('GoPay').last);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('filter-category-selector')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Makanan').last);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('filter-apply-button')));
    await tester.pumpAndSettle();

    expect(repo.lastWalletId, 'w1');
    expect(repo.lastCategoryId, 'c-food');

    // Tapping the wallet chip removes exactly the wallet filter — the
    // category filter (and its chip) must survive.
    await tester.tap(find.widgetWithText(AffluenaChoiceChip, 'GoPay'));
    for (var i = 0; i < 4; i++) {
      await tester.pump(const Duration(milliseconds: 10));
    }
    expect(repo.lastWalletId, isNull);
    expect(repo.lastCategoryId, 'c-food');
    expect(find.widgetWithText(AffluenaChoiceChip, 'Makanan'), findsOneWidget);
    expect(find.byKey(const Key('activity-clear-filters')), findsOneWidget);
  });
}
