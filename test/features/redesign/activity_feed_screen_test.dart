import 'package:affluena_mobile/features/auth/application/auth_controller.dart';
import 'package:affluena_mobile/features/auth/data/auth_models.dart';
import 'package:affluena_mobile/features/redesign/presentation/activity_feed_screen.dart';
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
  amountMinor: 100000,
  tagIds: [],
  transactionAt: '2026-06-20T08:00:00Z',
  note: 'Nonton berdua',
  createdAt: '2026-06-20T08:00:00Z',
  updatedAt: '2026-06-20T08:00:00Z',
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
        walletListProvider.overrideWith((ref) async => const [_gopay]),
        recentActivityProvider.overrideWith((ref) async => const [_byMe, _bySarah]),
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
}
