import 'package:affluena_mobile/core/api/pagination.dart';
import 'package:affluena_mobile/features/wallets/data/wallet_models.dart';
import 'package:affluena_mobile/features/wallets/data/wallet_repository.dart';
import 'package:affluena_mobile/features/wallets/presentation/wallets_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('renders repository wallets and marks goal wallets read-only', (
    tester,
  ) async {
    await tester.pumpWidget(
      walletsTestApp(
        const TestWalletRepository(
          wallets: [cashWallet, bankWallet, goPayWallet, goalWallet],
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Cash Wallet'), findsOneWidget);
    expect(find.text('BCA Primary'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('GoPay'),
      240,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('GoPay'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Europe Trip Fund'),
      240,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Europe Trip Fund'), findsOneWidget);
    expect(find.textContaining('Read-only goal wallet'), findsOneWidget);
    expect(find.byKey(const Key('edit-wallet-goal-wallet')), findsNothing);
  });

  testWidgets('empty wallet list shows helpful state', (tester) async {
    await tester.pumpWidget(
      walletsTestApp(const TestWalletRepository(wallets: [])),
    );
    await tester.pumpAndSettle();

    expect(find.text('No wallets yet'), findsOneWidget);
    expect(
      find.text('Create a wallet before recording transactions.'),
      findsOneWidget,
    );
  });
}

Widget walletsTestApp(WalletRepository walletRepository) {
  return ProviderScope(
    overrides: [walletRepositoryProvider.overrideWithValue(walletRepository)],
    child: const MaterialApp(home: Scaffold(body: WalletsScreen())),
  );
}

class TestWalletRepository implements WalletRepository {
  const TestWalletRepository({required this.wallets});

  final List<Wallet> wallets;

  @override
  Future<WalletListResponse> listWallets({
    int? limit,
    int? offset,
    String? sort,
  }) async {
    return WalletListResponse(
      wallets: wallets,
      pagination: Pagination(
        total: wallets.length,
        limit: limit ?? wallets.length,
        offset: offset ?? 0,
      ),
    );
  }

  @override
  Future<Wallet> createWallet(WalletRequest request) async => wallets.first;

  @override
  Future<Wallet> updateWallet(String id, WalletRequest request) async {
    return wallets.firstWhere((wallet) => wallet.id == id);
  }
}

const cashWallet = Wallet(
  id: '22222222-2222-2222-2222-222222220001',
  userId: '11111111-1111-1111-1111-111111111111',
  name: 'Cash Wallet',
  type: WalletType.cash,
  currencyCode: 'IDR',
  balanceMinor: 850000,
  color: 'gray',
  description: 'Pocket cash',
  createdAt: '2026-06-01T00:00:00Z',
  updatedAt: '2026-06-01T00:00:00Z',
);

const bankWallet = Wallet(
  id: '22222222-2222-2222-2222-222222220002',
  userId: '11111111-1111-1111-1111-111111111111',
  name: 'BCA Primary',
  type: WalletType.bank,
  currencyCode: 'IDR',
  balanceMinor: 15200000,
  color: 'blue',
  description: 'Main account',
  role: 'owner',
  createdAt: '2026-06-01T00:00:00Z',
  updatedAt: '2026-06-01T00:00:00Z',
);

const goPayWallet = Wallet(
  id: '22222222-2222-2222-2222-222222220003',
  userId: '11111111-1111-1111-1111-111111111111',
  name: 'GoPay',
  type: WalletType.eWallet,
  currencyCode: 'IDR',
  balanceMinor: 320000,
  color: 'green',
  description: 'Daily wallet',
  createdAt: '2026-06-01T00:00:00Z',
  updatedAt: '2026-06-01T00:00:00Z',
);

const goalWallet = Wallet(
  id: '22222222-2222-2222-2222-222222220099',
  userId: '11111111-1111-1111-1111-111111111111',
  name: 'Europe Trip Fund',
  type: WalletType.goal,
  currencyCode: 'IDR',
  balanceMinor: 8500000,
  color: 'purple',
  description: '17% of Rp 50.000.000 target',
  goalId: 'goal-wallet',
  createdAt: '2026-06-01T00:00:00Z',
  updatedAt: '2026-06-01T00:00:00Z',
);
