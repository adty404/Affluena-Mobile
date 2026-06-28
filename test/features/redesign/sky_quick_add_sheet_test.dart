import 'package:affluena_mobile/features/categories/data/category_models.dart';
import 'package:affluena_mobile/features/redesign/presentation/sky_quick_add_sheet.dart';
import 'package:affluena_mobile/features/transactions/application/transaction_create_controller.dart';
import 'package:affluena_mobile/features/transactions/data/transaction_models.dart';
import 'package:affluena_mobile/features/wallets/data/wallet_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

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
    const TransactionCreateState(wallets: [_wallet], categories: [_category]),
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

void main() {
  testWidgets('keypad builds the amount and validation blocks empty saves', (
    tester,
  ) async {
    final stub = await _openSheet(tester);

    expect(find.text('Catat cepat'), findsOneWidget);
    expect(find.text('Rp 0'), findsOneWidget);

    // Saving with no amount is blocked.
    await tester.tap(find.text('Simpan'));
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
    await tester.tap(find.text('Simpan'));
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

    await tester.tap(find.text('Simpan'));
    await tester.pumpAndSettle();

    expect(stub.lastRequest, isNotNull);
    expect(stub.lastRequest!.amountMinor, 50000);
    expect(stub.lastRequest!.walletId, 'w1');
    expect(stub.lastRequest!.categoryId, 'c1');
    expect(stub.lastRequest!.type, TransactionType.expense);
  });
}
