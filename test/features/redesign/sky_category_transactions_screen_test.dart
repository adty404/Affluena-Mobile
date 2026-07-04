import 'package:affluena_mobile/features/auth/application/auth_controller.dart';
import 'package:affluena_mobile/features/auth/data/auth_models.dart';
import 'package:affluena_mobile/features/categories/data/category_models.dart';
import 'package:affluena_mobile/features/insights/application/category_breakdown_providers.dart';
import 'package:affluena_mobile/features/redesign/presentation/sky_category_transactions_screen.dart';
import 'package:affluena_mobile/features/transactions/application/transactions_controller.dart';
import 'package:affluena_mobile/features/transactions/data/transaction_models.dart';
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

const _food = Category(
  id: 'c-food',
  userId: 'u-me',
  name: 'Makanan',
  type: CategoryType.expense,
  icon: 'food',
  color: '#2E8B57',
  createdAt: '2026-06-01T00:00:00Z',
  updatedAt: '2026-06-01T00:00:00Z',
);

// A row WITH a note, and a note-less row (its title must fall back to the
// category name "Makanan").
const _withNote = Transaction(
  id: 't1',
  userId: 'u-me',
  type: TransactionType.expense,
  walletId: 'w1',
  categoryId: 'c-food',
  amountMinor: 45000,
  tagIds: [],
  transactionAt: '2026-06-20T09:00:00Z',
  note: 'Kopi pagi',
  createdAt: '2026-06-20T09:00:00Z',
  updatedAt: '2026-06-20T09:00:00Z',
);

const _noNote = Transaction(
  id: 't2',
  userId: 'u-me',
  type: TransactionType.expense,
  walletId: 'w1',
  categoryId: 'c-food',
  amountMinor: 30000,
  tagIds: [],
  transactionAt: '2026-06-20T08:00:00Z',
  note: '',
  createdAt: '2026-06-20T08:00:00Z',
  updatedAt: '2026-06-20T08:00:00Z',
);

class _AuthedController extends AuthController {
  @override
  AuthState build() => AuthState.authenticated(_me);
}

class _StubTransactionsController extends TransactionsController {
  @override
  TransactionsState build() => const TransactionsState(
    walletNames: {'w1': 'GoPay'},
    categories: [_food],
    categoryNames: {'c-food': 'Makanan'},
  );
}

Future<void> _pump(
  WidgetTester tester, {
  required List<Transaction> txns,
}) async {
  await tester.binding.setSurfaceSize(const Size(390, 844));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  final range = DateRange(
    from: DateTime(2026, 6, 1),
    to: DateTime(2026, 6, 30),
  );
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        authControllerProvider.overrideWith(_AuthedController.new),
        walletListProvider.overrideWith((ref) async => const [_gopay]),
        transactionsControllerProvider.overrideWith(
          _StubTransactionsController.new,
        ),
        categoryTransactionsInRangeProvider.overrideWith((ref, query) async {
          expect(query.categoryId, 'c-food');
          return txns;
        }),
      ],
      child: MaterialApp(
        home: SkyCategoryTransactionsScreen(
          categoryId: 'c-food',
          categoryName: 'Makanan',
          range: range,
          periodLabel: 'Juni 2026',
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('renders category name, period label, and rows', (tester) async {
    await _pump(tester, txns: const [_withNote, _noNote]);

    // The category name is the app-bar title.
    expect(find.text('Makanan'), findsWidgets);
    // The period label is the subtitle above the rows.
    expect(find.text('Juni 2026'), findsOneWidget);
    // The noted row keeps its note...
    expect(find.text('Kopi pagi'), findsOneWidget);
    // ...and the row amounts render.
    expect(find.text('-Rp 45.000'), findsOneWidget);
    expect(find.text('-Rp 30.000'), findsOneWidget);
  });

  testWidgets('a note-less row shows the category name as its title', (
    tester,
  ) async {
    await _pump(tester, txns: const [_noNote]);

    // The note-less transaction's title falls back to "Makanan" (its category),
    // never the generic "Pengeluaran" type label.
    expect(find.text('Pengeluaran'), findsNothing);
    // "Makanan" appears as both the app-bar title and the note-less row title.
    expect(find.text('Makanan'), findsNWidgets(2));
  });

  testWidgets('shows the empty state (with the period) when there are none', (
    tester,
  ) async {
    await _pump(tester, txns: const []);

    expect(find.text('Belum ada transaksi'), findsOneWidget);
    expect(find.textContaining('Juni 2026'), findsOneWidget);
  });
}
