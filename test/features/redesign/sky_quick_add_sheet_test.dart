import 'package:affluena_mobile/features/categories/data/category_models.dart';
import 'package:affluena_mobile/features/redesign/presentation/sky_quick_add_sheet.dart';
import 'package:affluena_mobile/features/transactions/application/transaction_create_controller.dart';
import 'package:affluena_mobile/features/transactions/data/transaction_models.dart';
import 'package:affluena_mobile/features/transactions/presentation/transaction_create_screen.dart';
import 'package:affluena_mobile/features/wallets/data/wallet_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

const _wallet = Wallet(
  id: 'w1',
  userId: 'u1',
  name: 'GoPay',
  type: WalletType.eWallet,
  currencyCode: 'IDR',
  balanceMinor: 1300000,
  color: 'blue',
  description: '',
  createdAt: '2026-06-01T00:00:00Z',
  updatedAt: '2026-06-01T00:00:00Z',
);

const _wallet2 = Wallet(
  id: 'w2',
  userId: 'u1',
  name: 'BCA Primary',
  type: WalletType.bank,
  currencyCode: 'IDR',
  balanceMinor: 5000000,
  color: 'green',
  description: '',
  createdAt: '2026-06-01T00:00:00Z',
  updatedAt: '2026-06-01T00:00:00Z',
);

const _category = Category(
  id: 'c1',
  userId: 'u1',
  name: 'Makan',
  type: CategoryType.expense,
  createdAt: '2026-06-01T00:00:00Z',
  updatedAt: '2026-06-01T00:00:00Z',
);

class _StubCreateController extends TransactionCreateController {
  _StubCreateController(this._initial);

  final TransactionCreateState _initial;
  TransactionRequest? lastRequest;

  @override
  TransactionCreateState build() => _initial;

  @override
  Future<bool> create(TransactionRequest request) async {
    lastRequest = request;
    return true;
  }
}

Future<_StubCreateController> _openSheet(WidgetTester tester) async {
  await tester.binding.setSurfaceSize(const Size(390, 844));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  final stub = _StubCreateController(
    const TransactionCreateState(
      wallets: [_wallet, _wallet2],
      categories: [_category],
    ),
  );
  await tester.pumpWidget(
    ProviderScope(
      overrides: [transactionCreateControllerProvider.overrideWith(() => stub)],
      child: MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => Center(
              child: ElevatedButton(
                onPressed: () => showSkyQuickAddSheet(context, wallet: _wallet),
                child: const Text('open'),
              ),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('open'));
  await tester.pumpAndSettle();
  return stub;
}

/// Opens the quick-add sheet inside a two-route GoRouter so the "Opsi lengkap"
/// link has a real navigator + create route to push. Opened from the FAB path
/// (no pre-set wallet).
Future<_StubCreateController> _openSheetWithRouter(WidgetTester tester) async {
  await tester.binding.setSurfaceSize(const Size(390, 844));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  final stub = _StubCreateController(
    const TransactionCreateState(
      wallets: [_wallet, _wallet2],
      categories: [_category],
    ),
  );
  final router = GoRouter(
    initialLocation: '/home',
    routes: [
      GoRoute(
        path: '/home',
        builder: (context, _) => Scaffold(
          body: Center(
            child: ElevatedButton(
              onPressed: () => showSkyQuickAddSheet(context),
              child: const Text('open'),
            ),
          ),
        ),
      ),
      GoRoute(
        path: TransactionCreateScreen.path,
        builder: (_, _) => const TransactionCreateScreen(),
      ),
    ],
  );
  await tester.pumpWidget(
    ProviderScope(
      overrides: [transactionCreateControllerProvider.overrideWith(() => stub)],
      child: MaterialApp.router(routerConfig: router),
    ),
  );
  await tester.tap(find.text('open'));
  await tester.pumpAndSettle();
  return stub;
}

void main() {
  testWidgets('keypad builds the amount and validation blocks empty saves', (
    tester,
  ) async {
    final stub = await _openSheet(tester);

    // Opened scoped to a wallet, so the title reads "Catat cepat · <wallet>".
    expect(find.textContaining('Catat cepat'), findsOneWidget);
    expect(find.text('Rp 0'), findsOneWidget);

    // Saving with no amount is blocked.
    await tester.tap(find.byKey(const Key('sky-calc-confirm')));
    await tester.pumpAndSettle();
    expect(find.text('Masukkan jumlah lebih dari nol.'), findsOneWidget);
    expect(stub.lastRequest, isNull);

    // Type 50000 via the keypad.
    await tester.tap(find.text('5'));
    for (var i = 0; i < 4; i++) {
      await tester.tap(find.text('0'));
    }
    await tester.pump();
    expect(find.text('Rp 50.000'), findsOneWidget);

    // Amount set but no category -> still blocked.
    await tester.tap(find.byKey(const Key('sky-calc-confirm')));
    await tester.pumpAndSettle();
    expect(find.text('Pilih kategori dulu.'), findsOneWidget);
    expect(stub.lastRequest, isNull);
  });

  testWidgets('saves a transaction with the typed amount + picked category', (
    tester,
  ) async {
    final stub = await _openSheet(tester);

    await tester.tap(find.text('5'));
    for (var i = 0; i < 4; i++) {
      await tester.tap(find.text('0'));
    }
    await tester.pump();

    // Open the category picker and choose "Makan".
    await tester.tap(find.text('Pilih kategori'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Makan'));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('sky-calc-confirm')));
    await tester.pumpAndSettle();

    expect(stub.lastRequest, isNotNull);
    expect(stub.lastRequest!.amountMinor, 50000);
    expect(stub.lastRequest!.walletId, 'w1');
    expect(stub.lastRequest!.categoryId, 'c1');
    expect(stub.lastRequest!.type, TransactionType.expense);
  });

  testWidgets('Transfer hides the category picker and shows Dari/Ke selectors', (
    tester,
  ) async {
    await _openSheet(tester);

    // Switch to Transfer.
    await tester.tap(find.text('Transfer'));
    await tester.pumpAndSettle();

    // Category selector is gone; the "Ke dompet" destination selector appears.
    expect(find.text('Pilih kategori'), findsNothing);
    expect(find.text('Ke dompet'), findsOneWidget);
    // The optional admin-fee field is present.
    expect(find.byKey(const Key('quick-add-fee-field')), findsOneWidget);
  });

  testWidgets('a transfer with a distinct destination + fee submits a transfer '
      'request', (tester) async {
    final stub = await _openSheet(tester);

    await tester.tap(find.text('Transfer'));
    await tester.pumpAndSettle();

    // Amount 100000 via the keypad.
    await tester.tap(find.text('1'));
    for (var i = 0; i < 5; i++) {
      await tester.tap(find.text('0'));
    }
    await tester.pump();

    // Pick the destination wallet from the "Ke dompet" lookup.
    await tester.tap(find.text('Ke dompet'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('BCA Primary').last);
    await tester.pumpAndSettle();

    // Optional admin fee.
    await tester.enterText(
      find.byKey(const Key('quick-add-fee-field')),
      '2500',
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('sky-calc-confirm')));
    await tester.pumpAndSettle();

    expect(stub.lastRequest, isNotNull);
    expect(stub.lastRequest!.type, TransactionType.transfer);
    expect(stub.lastRequest!.walletId, 'w1');
    expect(stub.lastRequest!.toWalletId, 'w2');
    expect(stub.lastRequest!.feeMinor, 2500);
    expect(stub.lastRequest!.categoryId, isNull);
  });

  testWidgets('a transfer without a distinct destination is blocked', (
    tester,
  ) async {
    final stub = await _openSheet(tester);

    await tester.tap(find.text('Transfer'));
    await tester.pumpAndSettle();

    // Amount set, but no destination chosen yet.
    await tester.tap(find.text('1'));
    for (var i = 0; i < 5; i++) {
      await tester.tap(find.text('0'));
    }
    await tester.pump();

    await tester.tap(find.byKey(const Key('sky-calc-confirm')));
    await tester.pumpAndSettle();

    expect(find.text('Pilih dompet tujuan dulu.'), findsOneWidget);
    expect(stub.lastRequest, isNull);
  });

  testWidgets('"Opsi lengkap" closes the sheet and opens the full form', (
    tester,
  ) async {
    await _openSheetWithRouter(tester);

    expect(find.text('Catat cepat'), findsOneWidget);

    await tester.tap(find.byKey(const Key('quick-add-full-form-link')));
    await tester.pumpAndSettle();

    // The sheet is gone and the full transaction form is on screen.
    expect(find.text('Catat cepat'), findsNothing);
    expect(find.text('Transaksi baru'), findsOneWidget);
  });
}
