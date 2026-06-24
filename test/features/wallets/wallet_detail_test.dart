import 'package:affluena_mobile/app/provider_retry.dart';
import 'package:affluena_mobile/app/theme/affluena_theme.dart';
import 'package:affluena_mobile/features/wallets/data/wallet_models.dart';
import 'package:affluena_mobile/features/wallets/data/wallet_repository.dart';
import 'package:affluena_mobile/features/wallets/presentation/wallet_detail_screen.dart';
import 'package:affluena_mobile/features/wallets/presentation/wallets_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'wallets_test_helpers.dart';

void main() {
  testWidgets('loads wallet detail members analytics and invites a member', (
    tester,
  ) async {
    final repository = TestWalletRepository(
      wallets: [sharedWallet],
      analytics: const WalletAnalytics(
        walletId: sharedWalletId,
        month: '2026-06',
        inflowMinor: 2500000,
        outflowMinor: 700000,
        transactionCount: 3,
        lastActivityAt: '2026-06-20T10:00:00Z',
      ),
    );

    await tester.pumpWidget(
      walletRouteTestApp(
        repository,
        WalletDetailScreen.location(sharedWalletId),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('BCA Primary'), findsOneWidget);
    expect(find.text('Rp 15.200.000'), findsOneWidget);
    expect(find.text('Owner'), findsOneWidget);
    expect(find.text('Rp 2.500.000'), findsOneWidget);
    expect(find.text('Rp 700.000'), findsOneWidget);
    expect(find.text('3 transactions'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('partner@affluena.test'),
      240,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('partner@affluena.test'), findsOneWidget);

    await tester.tap(find.text('Invite member'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.widgetWithText(TextField, 'Email address'),
      'friend@affluena.test',
    );
    await tester.tap(find.text('Send invite'));
    await tester.pumpAndSettle();

    expect(repository.inviteWalletIds, [sharedWalletId]);
    expect(repository.inviteRequests.single.email, 'friend@affluena.test');
    expect(find.text('friend@affluena.test'), findsOneWidget);
    expect(find.text('Pending'), findsAtLeastNWidgets(1));
  });

  testWidgets('invite error keeps the sheet open with feedback', (
    tester,
  ) async {
    final repository = TestWalletRepository(
      wallets: [sharedWallet],
      inviteError: Exception('invalid email'),
    );

    await tester.pumpWidget(
      walletRouteTestApp(
        repository,
        WalletDetailScreen.location(sharedWalletId),
      ),
    );
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.text('partner@affluena.test'),
      240,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('Invite member'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.widgetWithText(TextField, 'Email address'),
      'bad-email',
    );
    await tester.tap(find.text('Send invite'));
    await tester.pumpAndSettle();

    expect(repository.inviteRequests.single.email, 'bad-email');
    // The sheet stays OPEN on failure (its title is still mounted) and shows
    // the coral error banner instead of dismissing.
    expect(find.text('Invite member'), findsWidgets);
    expect(find.text('Invite could not be sent.'), findsOneWidget);
  });

  testWidgets('detail load error is retryable', (tester) async {
    final repository = _FlakyWalletRepository(
      wallets: [sharedWallet],
      analytics: const WalletAnalytics(
        walletId: sharedWalletId,
        month: '2026-06',
        inflowMinor: 100000,
        outflowMinor: 50000,
        transactionCount: 2,
      ),
    );

    await tester.pumpWidget(
      walletRouteTestApp(
        repository,
        WalletDetailScreen.location(sharedWalletId),
      ),
    );
    await tester.pumpAndSettle();

    // The drill-in AppBar shows the title; the error renders as a coral
    // AffluenaBanner with a localized retry action.
    expect(find.text('Wallet'), findsOneWidget);
    expect(find.text('We could not load this wallet.'), findsOneWidget);
    expect(find.text('Coba lagi'), findsOneWidget);

    await tester.tap(find.text('Coba lagi'));
    await tester.pumpAndSettle();

    expect(find.text('BCA Primary'), findsOneWidget);
    expect(repository.getAttempts, greaterThanOrEqualTo(2));
  });

  testWidgets('delete confirmation removes wallet and returns to list', (
    tester,
  ) async {
    final repository = TestWalletRepository(
      wallets: [cashWallet, sharedWallet],
    );

    await tester.pumpWidget(
      walletRouteTestApp(
        repository,
        WalletDetailScreen.location(sharedWalletId),
      ),
    );
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.text('Delete wallet'),
      240,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.drag(find.byType(Scrollable).first, const Offset(0, -120));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete wallet'));
    await tester.pumpAndSettle();
    expect(find.text('Delete BCA Primary?'), findsOneWidget);

    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();

    expect(repository.deletedIds, [sharedWalletId]);
    expect(find.text('Wallets'), findsOneWidget);
    expect(find.text('Cash Wallet'), findsOneWidget);
    expect(find.text('BCA Primary'), findsNothing);
  });
}

Widget walletRouteTestApp(TestWalletRepository repository, String location) {
  final router = GoRouter(
    initialLocation: location,
    routes: [
      GoRoute(
        path: WalletsScreen.path,
        builder: (context, state) => const Scaffold(body: WalletsScreen()),
        routes: [
          // Nested so navigating to the detail builds a [list, detail] stack —
          // matching the real push flow, so the detail's AppBar back / delete
          // pop returns to the wallets list.
          GoRoute(
            path: ':walletId',
            builder: (context, state) => WalletDetailScreen(
              walletId: state.pathParameters['walletId']!,
            ),
          ),
        ],
      ),
    ],
  );

  return ProviderScope(
    retry: noProviderRetry,
    overrides: [walletRepositoryProvider.overrideWithValue(repository)],
    child: MaterialApp.router(
      theme: AffluenaTheme.light,
      darkTheme: AffluenaTheme.dark,
      routerConfig: router,
    ),
  );
}

class _FlakyWalletRepository extends TestWalletRepository {
  _FlakyWalletRepository({required super.wallets, required super.analytics});

  int getAttempts = 0;

  @override
  Future<Wallet> getWallet(String id) async {
    getAttempts += 1;
    if (getAttempts == 1) throw Exception('network');
    return super.getWallet(id);
  }
}

const sharedWalletId = '22222222-2222-2222-2222-222222220002';

const sharedWallet = Wallet(
  id: sharedWalletId,
  userId: '11111111-1111-1111-1111-111111111111',
  name: 'BCA Primary',
  type: WalletType.bank,
  currencyCode: 'IDR',
  balanceMinor: 15200000,
  color: 'blue',
  description: 'Main account',
  role: 'owner',
  shareStatus: WalletShareStatus.joined,
  members: [
    WalletMember(
      walletId: sharedWalletId,
      userId: 'member-1',
      email: 'partner@affluena.test',
      role: 'viewer',
      status: WalletShareStatus.joined,
      createdAt: '2026-06-01T00:00:00Z',
      updatedAt: '2026-06-01T00:00:00Z',
    ),
  ],
  createdAt: '2026-06-01T00:00:00Z',
  updatedAt: '2026-06-01T00:00:00Z',
);
