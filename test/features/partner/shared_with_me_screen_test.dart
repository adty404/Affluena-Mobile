import 'package:affluena_mobile/app/theme/affluena_theme.dart';
import 'package:affluena_mobile/features/partner/application/partner_controller.dart';
import 'package:affluena_mobile/features/partner/data/partner_models.dart';
import 'package:affluena_mobile/features/partner/presentation/shared_with_me_screen.dart';
import 'package:affluena_mobile/features/wallets/application/wallets_controller.dart';
import 'package:affluena_mobile/features/wallets/data/wallet_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _StubPartnerController extends PartnerController {
  @override
  PartnerState build() => const PartnerState(
    links: [
      PartnerLink(
        id: 'l1',
        direction: 'incoming',
        status: 'joined',
        userId: 'owner-budi',
        email: 'budi@example.com',
        name: 'Budi',
      ),
      PartnerLink(
        id: 'l2',
        direction: 'incoming',
        status: 'joined',
        userId: 'owner-sari',
        email: 'sari@example.com',
        name: 'Sari',
      ),
    ],
  );
}

Wallet _viewerWallet({
  required String id,
  required String ownerId,
  required String name,
  required WalletType type,
}) => Wallet(
  id: id,
  userId: ownerId,
  name: name,
  type: type,
  currencyCode: 'IDR',
  balanceMinor: 5000000,
  color: 'blue',
  description: '',
  role: 'viewer',
  createdAt: '2026-06-01T00:00:00Z',
  updatedAt: '2026-06-01T00:00:00Z',
);

void main() {
  testWidgets('groups shared wallets by the person who shared them', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final wallets = [
      _viewerWallet(
        id: 'w-b1',
        ownerId: 'owner-budi',
        name: 'BCA Budi',
        type: WalletType.bank,
      ),
      _viewerWallet(
        id: 'w-s1',
        ownerId: 'owner-sari',
        name: 'GoPay Sari',
        type: WalletType.eWallet,
      ),
    ];

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          partnerControllerProvider.overrideWith(_StubPartnerController.new),
          walletListProvider.overrideWith((ref) async => wallets),
        ],
        child: MaterialApp(
          theme: AffluenaTheme.light,
          home: const SharedWithMeScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // One "Dari <name>" group header per sharer, with their wallet under it.
    expect(find.text('Dari Budi'), findsOneWidget);
    expect(find.text('Dari Sari'), findsOneWidget);
    expect(find.text('BCA Budi'), findsOneWidget);
    expect(find.text('GoPay Sari'), findsOneWidget);
  });
}
