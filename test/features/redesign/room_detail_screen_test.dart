import 'package:affluena_mobile/features/auth/application/auth_controller.dart';
import 'package:affluena_mobile/features/auth/data/auth_models.dart';
import 'package:affluena_mobile/features/redesign/presentation/room_detail_screen.dart';
import 'package:affluena_mobile/features/transactions/data/transaction_models.dart';
import 'package:affluena_mobile/features/wallets/application/wallet_detail_controller.dart';
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

const _wallet = Wallet(
  id: 'w1',
  userId: 'u-me',
  name: 'Dompet Main',
  type: WalletType.eWallet,
  currencyCode: 'IDR',
  balanceMinor: 1250000,
  color: 'blue',
  description: '',
  role: 'member',
  createdAt: '2026-06-01T00:00:00Z',
  updatedAt: '2026-06-01T00:00:00Z',
);

const _sarah = WalletMember(
  walletId: 'w1',
  userId: 'u-sarah',
  email: 'sarah@example.com',
  role: 'member',
  status: WalletShareStatus.joined,
  createdAt: '2026-06-01T00:00:00Z',
  updatedAt: '2026-06-01T00:00:00Z',
);

const _txBySarah = Transaction(
  id: 't1',
  userId: 'u-sarah',
  type: TransactionType.expense,
  walletId: 'w1',
  amountMinor: 100000,
  tagIds: [],
  transactionAt: '2026-06-20T11:00:00Z',
  note: 'Nonton berdua',
  createdAt: '2026-06-20T11:00:00Z',
  updatedAt: '2026-06-20T11:00:00Z',
);

const _txByMe = Transaction(
  id: 't2',
  userId: 'u-me',
  type: TransactionType.income,
  walletId: 'w1',
  amountMinor: 9500000,
  tagIds: [],
  transactionAt: '2026-06-19T09:00:00Z',
  note: 'Top-up',
  createdAt: '2026-06-19T09:00:00Z',
  updatedAt: '2026-06-19T09:00:00Z',
);

class _AuthedController extends AuthController {
  @override
  AuthState build() => AuthState.authenticated(_me);
}

Future<void> _pump(WidgetTester tester) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        authControllerProvider.overrideWith(_AuthedController.new),
        walletDetailProvider.overrideWith(
          (ref, id) async =>
              const WalletDetailState(wallet: _wallet, members: [_sarah]),
        ),
        walletTransactionsProvider.overrideWith(
          (ref, id) async => const [_txBySarah, _txByMe],
        ),
      ],
      child: const MaterialApp(home: RoomDetailScreen(walletId: 'w1')),
    ),
  );
  for (var i = 0; i < 6; i++) {
    await tester.pump(const Duration(milliseconds: 10));
  }
}

void main() {
  testWidgets('shows wallet header, balance, members & access', (tester) async {
    await _pump(tester);

    expect(find.text('Dompet Main'), findsOneWidget);
    expect(find.text('Rp 1.250.000'), findsOneWidget);
    expect(find.text('Anggota & akses'), findsOneWidget);
    expect(find.text('sarah@example.com'), findsOneWidget);
    // Writable (role member) -> in-context capture is offered.
    expect(find.text('Catat di sini'), findsOneWidget);
  });

  testWidgets('lists this wallet transactions with signed amounts', (
    tester,
  ) async {
    await _pump(tester);

    expect(find.text('Nonton berdua'), findsOneWidget);
    expect(find.text('Top-up'), findsOneWidget);
    expect(find.text('-Rp 100.000'), findsOneWidget); // expense
    expect(find.text('+Rp 9.500.000'), findsOneWidget); // income, green
  });
}
