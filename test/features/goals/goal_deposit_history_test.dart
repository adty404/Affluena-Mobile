import 'package:affluena_mobile/app/provider_retry.dart';
import 'package:affluena_mobile/features/auth/application/auth_controller.dart';
import 'package:affluena_mobile/features/categories/data/category_repository.dart';
import 'package:affluena_mobile/features/goals/application/goal_controller.dart';
import 'package:affluena_mobile/features/goals/data/goal_models.dart';
import 'package:affluena_mobile/features/goals/presentation/goal_detail_screen.dart';
import 'package:affluena_mobile/features/tags/data/tag_repository.dart';
import 'package:affluena_mobile/features/transactions/data/transaction_models.dart';
import 'package:affluena_mobile/features/transactions/data/transaction_repository.dart';
import 'package:affluena_mobile/features/transactions/presentation/transaction_activity_row.dart';
import 'package:affluena_mobile/features/wallets/application/wallets_controller.dart';
import 'package:affluena_mobile/features/wallets/data/wallet_models.dart';
import 'package:affluena_mobile/features/wallets/data/wallet_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

import '../../helpers/auth_test_helpers.dart';

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

/// The wallet backing the goal — this is where contributions actually land.
const _goalWallet = Wallet(
  id: 'wallet-goal',
  userId: 'u1',
  name: 'Liburan Bali',
  type: WalletType.goal,
  currencyCode: 'IDR',
  balanceMinor: 6200000,
  color: '',
  description: '',
  goalId: 'g1',
  createdAt: '2026-06-01T00:00:00Z',
  updatedAt: '2026-06-01T00:00:00Z',
);

const _deposit = Transaction(
  id: 'tx-setor',
  userId: 'u1',
  type: TransactionType.income,
  walletId: 'wallet-goal',
  categoryId: null,
  amountMinor: 500000,
  tagIds: [],
  transactionAt: '2026-07-01T10:00:00Z',
  note: 'Setoran Juli',
  createdAt: '2026-07-01T10:00:00Z',
  updatedAt: '2026-07-01T10:00:00Z',
);

class _StubGoal extends GoalController {
  @override
  GoalState build() => const GoalState(goals: [_goal]);
}

class _StubAuth extends AuthController {
  @override
  AuthState build() => const AuthState.unauthenticated();
}

void main() {
  setUpAll(() async {
    await initializeDateFormatting('id_ID');
  });

  Future<void> pumpDetail(
    WidgetTester tester, {
    required List<Wallet> wallets,
  }) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      ProviderScope(
        retry: noProviderRetry,
        overrides: [
          goalControllerProvider.overrideWith(_StubGoal.new),
          authControllerProvider.overrideWith(_StubAuth.new),
          walletListProvider.overrideWith((ref) async => wallets),
          transactionRepositoryProvider.overrideWithValue(
            const FakeTransactionRepository(transactions: [_deposit]),
          ),
          walletRepositoryProvider.overrideWithValue(
            const FakeWalletRepository(),
          ),
          categoryRepositoryProvider.overrideWithValue(
            const FakeCategoryRepository(),
          ),
          tagRepositoryProvider.overrideWithValue(const FakeTagRepository()),
        ],
        child: const MaterialApp(home: GoalDetailScreen(id: 'g1')),
      ),
    );
    await tester.pump();
    await tester.pump();
    await tester.pumpAndSettle();
  }

  testWidgets(
    'goal detail lists the backing wallet transactions as Riwayat setoran '
    'and opens the detail sheet on tap',
    (tester) async {
      await pumpDetail(tester, wallets: const [_goalWallet]);

      await tester.scrollUntilVisible(
        find.text('Riwayat setoran'),
        240,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();

      expect(find.text('Riwayat setoran'), findsOneWidget);
      expect(find.byType(TransactionActivityRow), findsOneWidget);
      expect(find.text('Setoran Juli'), findsOneWidget);

      await tester.tap(find.text('Setoran Juli'));
      await tester.pumpAndSettle();
      expect(find.text('Detail transaksi'), findsOneWidget);
    },
  );

  testWidgets('goal detail hides the section when no wallet backs the goal', (
    tester,
  ) async {
    await pumpDetail(tester, wallets: const []);

    expect(find.text('Liburan Bali'), findsOneWidget);
    expect(find.text('Riwayat setoran'), findsNothing);
  });
}
