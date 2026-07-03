@Tags(['golden'])
library;

import 'package:affluena_mobile/app/provider_retry.dart';
import 'package:affluena_mobile/app/theme/affluena_theme.dart';
import 'package:affluena_mobile/features/wallets/data/wallet_models.dart';
import 'package:affluena_mobile/features/wallets/data/wallet_repository.dart';
import 'package:affluena_mobile/features/wallets/presentation/wallets_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../features/wallets/wallets_test_helpers.dart'
    show TestWalletRepository;

/// Golden of the wallets-screen hero: a prominent Total saldo over a
/// Dompet/Bersama/Pribadi breakdown, replacing the old contradictory
/// "Dibagikan: N dompet / Hanya pribadi" card. Text renders as the placeholder
/// test font — a layout drift detector, not a pixel match.
Wallet _w({
  required String id,
  required String name,
  required WalletType type,
  required int balanceMinor,
  String color = '',
  String? role,
  List<WalletMember> members = const [],
}) {
  return Wallet(
    id: id,
    userId: 'u1',
    name: name,
    type: type,
    currencyCode: 'IDR',
    balanceMinor: balanceMinor,
    color: color,
    description: '',
    role: role,
    members: members,
    createdAt: '2026-06-01T00:00:00Z',
    updatedAt: '2026-06-01T00:00:00Z',
  );
}

void main() {
  testWidgets('wallets header golden', (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final repo = TestWalletRepository(
      wallets: [
        _w(
          id: 'w1',
          name: 'BCA Primary',
          type: WalletType.bank,
          balanceMinor: 15200000,
          color: '#3E72B8',
        ),
        _w(
          id: 'w2',
          name: 'Cash Wallet',
          type: WalletType.cash,
          balanceMinor: 850000,
        ),
        _w(
          id: 'w3',
          name: 'GoPay',
          type: WalletType.eWallet,
          balanceMinor: 320000,
          color: '#2BB3A3',
        ),
        _w(
          id: 'w4',
          name: 'Dompet Bersama',
          type: WalletType.bank,
          balanceMinor: 4100000,
          role: 'viewer',
        ),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(
        retry: noProviderRetry,
        overrides: [walletRepositoryProvider.overrideWithValue(repo)],
        child: MaterialApp(
          theme: AffluenaTheme.light,
          home: const Scaffold(body: WalletsScreen()),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/wallets_header.png'),
    );
  });
}
