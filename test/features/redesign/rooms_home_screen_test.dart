import 'package:affluena_mobile/features/goals/application/goal_controller.dart';
import 'package:affluena_mobile/features/goals/data/goal_models.dart';
import 'package:affluena_mobile/features/redesign/presentation/rooms_home_screen.dart';
import 'package:affluena_mobile/features/shared/presentation/widgets/sky_progress_bar.dart';
import 'package:affluena_mobile/features/wallets/application/wallets_controller.dart';
import 'package:affluena_mobile/features/wallets/data/wallet_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

const _cash = Wallet(
  id: 'w-cash',
  userId: 'u1',
  name: 'Tunai Harian',
  type: WalletType.cash,
  currencyCode: 'IDR',
  balanceMinor: 380000,
  color: 'green',
  description: '',
  createdAt: '2026-06-01T00:00:00Z',
  updatedAt: '2026-06-01T00:00:00Z',
);

const _bca = Wallet(
  id: 'w-bca',
  userId: 'u1',
  name: 'BCA',
  type: WalletType.bank,
  currencyCode: 'IDR',
  balanceMinor: 9520000,
  color: 'blue',
  description: '',
  createdAt: '2026-06-01T00:00:00Z',
  updatedAt: '2026-06-01T00:00:00Z',
);

const _shared = Wallet(
  id: 'w-main',
  userId: 'u2',
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

const _viewer = Wallet(
  id: 'w-ortu',
  userId: 'u3',
  name: 'Dompet Ortu',
  type: WalletType.bank,
  currencyCode: 'IDR',
  balanceMinor: 500000,
  color: 'blue',
  description: '',
  role: 'viewer',
  createdAt: '2026-06-01T00:00:00Z',
  updatedAt: '2026-06-01T00:00:00Z',
);

const _goalWallet = Wallet(
  id: 'w-goal',
  userId: 'u1',
  name: 'Goal Wallet Hidden',
  type: WalletType.goal,
  currencyCode: 'IDR',
  balanceMinor: 6200000,
  color: 'blue',
  description: '',
  goalId: 'g1',
  createdAt: '2026-06-01T00:00:00Z',
  updatedAt: '2026-06-01T00:00:00Z',
);

const _goal = Goal(
  id: 'g1',
  userId: 'u1',
  name: 'Liburan Bali',
  targetAmountMinor: 10000000,
  collectedAmountMinor: 6200000,
  deadline: null,
  status: GoalStatus.active,
  createdAt: '2026-06-01T00:00:00Z',
  updatedAt: '2026-06-01T00:00:00Z',
);

class _StubGoalController extends GoalController {
  @override
  GoalState build() => const GoalState(goals: [_goal]);
}

Future<void> _pump(WidgetTester tester, {required List<Wallet> wallets}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        walletListProvider.overrideWith((ref) async => wallets),
        goalControllerProvider.overrideWith(_StubGoalController.new),
      ],
      child: const MaterialApp(home: RoomsHomeScreen()),
    ),
  );
  // Resolve the FutureProvider (avoid pumpAndSettle: the loading spinner never
  // settles).
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 10));
}

void main() {
  testWidgets('renders wallets as rooms with the summed total', (tester) async {
    await _pump(tester, wallets: const [_cash, _bca, _shared, _viewer, _goalWallet]);

    // Total = sum of non-goal wallet balances (380k + 9.52m + 1.25m + 500k).
    expect(find.text('Rp 11.650.000'), findsOneWidget);
    expect(find.text('Tunai Harian'), findsOneWidget);
    expect(find.text('BCA'), findsOneWidget);
    expect(find.text('Dompet Main'), findsOneWidget);
    expect(find.byType(FloatingActionButton), findsOneWidget);
  });

  testWidgets('flags shared and viewer rooms; hides the goal-type wallet', (
    tester,
  ) async {
    await _pump(tester, wallets: const [_cash, _shared, _viewer, _goalWallet]);

    expect(find.text('BERSAMA'), findsOneWidget); // shared (role member)
    expect(find.text('LIHAT'), findsOneWidget); // viewer (read-only)
    // The goal-type wallet is not a spending room.
    expect(find.text('Goal Wallet Hidden'), findsNothing);
  });

  testWidgets('renders active savings goals as progress rooms', (tester) async {
    await _pump(tester, wallets: const [_cash]);

    expect(find.text('Tabungan'), findsOneWidget);
    expect(find.text('Liburan Bali'), findsOneWidget);
    expect(find.text('62%'), findsOneWidget);
    expect(find.byType(SkyProgressBar), findsOneWidget);
  });
}
