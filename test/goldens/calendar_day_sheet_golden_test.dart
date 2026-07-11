@Tags(['golden'])
library;

import 'package:affluena_mobile/app/theme/affluena_theme.dart';
import 'package:affluena_mobile/core/api/pagination.dart';
import 'package:affluena_mobile/core/formatters/money_formatter.dart';
import 'package:affluena_mobile/features/calendar/presentation/calendar_screen.dart';
import 'package:affluena_mobile/features/categories/application/category_tag_management_controller.dart';
import 'package:affluena_mobile/features/categories/data/category_models.dart';
import 'package:affluena_mobile/features/categories/data/category_repository.dart';
import 'package:affluena_mobile/features/tags/data/tag_repository.dart';
import 'package:affluena_mobile/features/transactions/data/transaction_models.dart';
import 'package:affluena_mobile/features/transactions/data/transaction_repository.dart';
import 'package:affluena_mobile/features/wallets/application/wallets_controller.dart';
import 'package:affluena_mobile/features/wallets/data/wallet_models.dart';
import 'package:affluena_mobile/features/wallets/data/wallet_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../features/transactions/transactions_test_helpers.dart'
    show StaticCategoryRepository, StaticTransactionsTagRepository;

/// Golden (design-snapshot) of the calendar day sheet — the sheet that opens
/// when a day is tapped. Locks the tidy header: title, a 3-column
/// masuk/keluar/selisih summary that never collides, a prominent full-width
/// "Tambah transaksi" button, then the day's transactions. Text renders as the
/// placeholder test font, so this is a layout drift detector, not a pixel match.
const _wallet = Wallet(
  id: 'w1',
  userId: 'u1',
  name: 'GoPay',
  type: WalletType.eWallet,
  currencyCode: 'IDR',
  balanceMinor: 0,
  color: '',
  description: '',
  createdAt: '2026-06-01T00:00:00Z',
  updatedAt: '2026-06-01T00:00:00Z',
);

const _food = Category(
  id: 'c-food',
  userId: 'u1',
  name: 'Makanan',
  type: CategoryType.expense,
  icon: 'food',
  color: '#2E8B57',
  createdAt: '2026-06-01T00:00:00Z',
  updatedAt: '2026-06-01T00:00:00Z',
);

class _StubCategoriesController extends CategoryTagManagementController {
  @override
  CategoryTagManagementState build() =>
      const CategoryTagManagementState(categories: [_food]);
}

/// Minimal wallet repo so the transactions controller's wallet lookup (used for
/// the day sheet's tap-to-edit) resolves without a real Dio call.
class _StaticWalletRepo implements WalletRepository {
  const _StaticWalletRepo(this._wallets);
  final List<Wallet> _wallets;

  @override
  Future<WalletListResponse> listWallets({
    int? limit,
    int? offset,
    String? sort,
  }) async {
    return WalletListResponse(
      wallets: _wallets,
      pagination: Pagination(
        total: _wallets.length,
        limit: limit ?? _wallets.length,
        offset: offset ?? 0,
      ),
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeRepo extends Fake implements TransactionRepository {
  _FakeRepo(this.transactions);
  final List<Transaction> transactions;

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
    return TransactionListResponse(
      transactions: transactions,
      pagination: Pagination(
        total: transactions.length,
        limit: limit ?? 200,
        offset: offset ?? 0,
      ),
    );
  }
}

Transaction _tx(String id, TransactionType type, int amount, String at) {
  return Transaction(
    id: id,
    userId: 'u1',
    type: type,
    walletId: 'w1',
    categoryId: 'c-food',
    amountMinor: amount,
    tagIds: const [],
    transactionAt: at,
    note: '',
    createdAt: at,
    updatedAt: at,
  );
}

void main() {
  setUp(() {
    // The day sheet watches the transactions controller (for tap-to-edit),
    // whose load reads secure storage + Dio. Stub the secure-storage channel so
    // it doesn't throw a MissingPluginException in the test harness.
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('plugins.it_nomads.com/flutter_secure_storage'),
          (call) async => null,
        );
  });

  testWidgets('calendar day sheet golden', (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final now = DateTime.now();
    String at(int day) {
      final m = now.month.toString().padLeft(2, '0');
      final d = day.toString().padLeft(2, '0');
      return '${now.year}-$m-${d}T04:00:00Z';
    }

    // Large amounts stress the 3-column summary — they must stay tidy.
    final repo = _FakeRepo([
      _tx('t1', TransactionType.income, 8500000, at(1)),
      _tx('t2', TransactionType.expense, 1250000, at(1)),
      _tx('t3', TransactionType.expense, 320000, at(1)),
    ]);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          transactionRepositoryProvider.overrideWithValue(repo),
          walletListProvider.overrideWith((ref) async => const [_wallet]),
          walletRepositoryProvider.overrideWithValue(
            const _StaticWalletRepo([_wallet]),
          ),
          categoryRepositoryProvider.overrideWithValue(
            const StaticCategoryRepository(categories: [_food]),
          ),
          tagRepositoryProvider.overrideWithValue(
            const StaticTransactionsTagRepository(tags: []),
          ),
          categoryTagManagementControllerProvider.overrideWith(
            _StubCategoriesController.new,
          ),
        ],
        child: MaterialApp(
          theme: AffluenaTheme.light,
          home: const Scaffold(body: CalendarView()),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Open the day sheet for the 1st — compact cells show only the NET
    // (8.500.000 − 1.250.000 − 320.000 = 6.930.000).
    await tester.tap(find.text(MoneyFormatter.compactIdr(6930000)));
    await tester.pumpAndSettle();

    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/calendar_day_sheet.png'),
    );
  });
}
