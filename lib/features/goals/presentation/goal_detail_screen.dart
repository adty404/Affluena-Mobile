import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/affluena_theme.dart';
import '../../../app/theme/sky_palette.dart';
import '../../../core/formatters/money_formatter.dart';
import '../../auth/application/auth_controller.dart';
import '../../categories/application/category_tag_management_controller.dart';
import '../../redesign/presentation/room_detail_screen.dart'
    show walletTransactionsProvider;
import '../../shared/presentation/appearance/item_appearance.dart';
import '../../shared/presentation/widgets/affluena_banner.dart';
import '../../shared/presentation/widgets/drill_in_scaffold.dart';
import '../../shared/presentation/widgets/sky_detail.dart';
import '../../shared/presentation/widgets/sky_progress_bar.dart';
import '../../transactions/application/transactions_controller.dart';
import '../../transactions/presentation/transaction_activity_row.dart';
import '../../transactions/presentation/transaction_detail_sheet.dart';
import '../../wallets/application/wallets_controller.dart';
import '../../wallets/data/wallet_models.dart';
import '../application/goal_controller.dart';
import '../data/goal_models.dart';
import 'goal_contribute_sheet.dart';
import 'goal_members_section.dart';

/// Per-goal detail (Tabungan) in the Sky & Denim language — opened from a
/// Beranda dashboard card or a goal list card. Reads the goal from the
/// already-loaded [goalControllerProvider]; "Setor" reuses the existing
/// contribute sheet, and shared goals list their members. Goals are funded
/// through a goal-backing WALLET, so the "Riwayat setoran" section lists that
/// wallet's transactions (hidden when no backing wallet is found).
class GoalDetailScreen extends ConsumerWidget {
  const GoalDetailScreen({required this.id, super.key});

  final String id;

  static const path = '/goals/:id';
  static String location(String id) => '/goals/$id';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(goalControllerProvider);
    Goal? goal;
    for (final g in state.goals) {
      if (g.id == id) {
        goal = g;
        break;
      }
    }

    if (goal == null) {
      return DrillInScaffold(
        title: 'Tabungan',
        body: SkyDetailPlaceholder(
          loading: state.isLoading,
          message: 'Tabungan tidak ditemukan.',
        ),
      );
    }

    final current = goal;
    final achieved = current.progressPercent >= 100;
    // The item's chosen colour accents the hero + progress; achieved keeps
    // its income-green semantics.
    final itemColor = parseItemColor(current.color);
    final accent = itemColor ?? context.sky.accent;
    final currentUserId = ref.watch(
      authControllerProvider.select((auth) => auth.user?.id),
    );

    return DrillInScaffold(
      title: current.name,
      body: ListView(
        padding: AffluenaInsets.screen,
        children: [
          SkyDetailHero(
            label: 'Terkumpul',
            amount: MoneyFormatter.idr(current.collectedAmountMinor),
            sub: 'dari ${MoneyFormatter.idr(current.targetAmountMinor)}',
            accent: itemColor,
          ),
          const SizedBox(height: AffluenaSpacing.space5),
          SkyProgressBar(
            value: current.progressPercent / 100,
            height: 8,
            fillColor: accent,
          ),
          const SizedBox(height: AffluenaSpacing.space3),
          Row(
            children: [
              Text(
                'Tercapai ${current.progressPercent}%',
                style: TextStyle(fontSize: 13, color: context.sky.muted),
              ),
              const Spacer(),
              SkyStatusPill(
                label: achieved
                    ? 'Tercapai'
                    : (current.isActive ? 'Aktif' : 'Selesai'),
                color: achieved
                    ? context.sky.income
                    : (current.isActive ? accent : context.sky.faint),
              ),
            ],
          ),
          // Action failures (e.g. a shared-goal invite response) are folded
          // into state.actionError by the controller; without this banner a
          // failed Terima/Tolak looks like a dead button.
          if (state.actionError != null) ...[
            const SizedBox(height: AffluenaSpacing.space4),
            AffluenaBanner.error(
              state.actionError!,
              onRetry: () =>
                  ref.read(goalControllerProvider.notifier).clearActionError(),
            ),
          ],
          if (current.isActive) ...[
            const SizedBox(height: AffluenaSpacing.space6),
            FilledButton.icon(
              onPressed: () => showGoalContributeSheet(context, current),
              icon: const Icon(Icons.add_card_outlined),
              label: const Text('Setor'),
            ),
          ],
          if (current.members.isNotEmpty) ...[
            const SizedBox(height: AffluenaSpacing.space6),
            Text(
              'Anggota',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: context.sky.ink,
              ),
            ),
            const SizedBox(height: AffluenaSpacing.space3),
            GoalMembersSection(
              members: current.members,
              currentUserId: currentUserId,
              busy: state.isSaving,
              onRespond: (member, status) => ref
                  .read(goalControllerProvider.notifier)
                  .respondInvite(current, member, status),
            ),
          ],
          _DepositHistorySection(goal: current, currentUserId: currentUserId),
        ],
      ),
    );
  }
}

/// "Riwayat setoran" — the goal's contribution history. Goals are funded via
/// their backing goal WALLET, so this lists that wallet's transactions
/// (via the existing [walletTransactionsProvider]); when no wallet carries
/// this goal's id the whole section stays hidden.
class _DepositHistorySection extends ConsumerWidget {
  const _DepositHistorySection({
    required this.goal,
    required this.currentUserId,
  });

  final Goal goal;
  final String? currentUserId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final wallets =
        ref.watch(walletListProvider).asData?.value ?? const <Wallet>[];
    Wallet? goalWallet;
    for (final wallet in wallets) {
      if (wallet.goalId == goal.id) {
        goalWallet = wallet;
        break;
      }
    }
    if (goalWallet == null) return const SizedBox.shrink();

    final wallet = goalWallet;
    final txAsync = ref.watch(walletTransactionsProvider(wallet.id));
    // Category catalog for the rows' icon+color, per the transaction-row
    // convention on surfaces without a TransactionsState in scope.
    final categories = ref.watch(categoryTagManagementControllerProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: AffluenaSpacing.space6),
        Text(
          'Riwayat setoran',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: context.sky.ink,
          ),
        ),
        const SizedBox(height: AffluenaSpacing.space3),
        txAsync.when(
          loading: () => Column(
            children: [
              for (var i = 0; i < 2; i++)
                Container(
                  height: 56,
                  margin: const EdgeInsets.only(bottom: AffluenaSpacing.space2),
                  decoration: BoxDecoration(
                    color: context.sky.sheet,
                    borderRadius: BorderRadius.circular(AffluenaRadii.md),
                  ),
                ),
            ],
          ),
          error: (_, _) => Text(
            'Tidak bisa memuat riwayat setoran.',
            style: TextStyle(fontSize: 12.5, color: context.sky.muted),
          ),
          data: (txns) => txns.isEmpty
              ? Text(
                  'Belum ada setoran.',
                  style: TextStyle(fontSize: 12.5, color: context.sky.muted),
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (final tx in txns)
                      TransactionActivityRow(
                        tx: tx,
                        walletName: wallet.name,
                        mine:
                            currentUserId != null && tx.userId == currentUserId,
                        category: tx.categoryId == null
                            ? null
                            : categories.categoryById(tx.categoryId!),
                        // Per the app convention, the global ledger state
                        // powers name resolution + edit/delete in the sheet.
                        onTap: () => showTransactionDetail(
                          context,
                          ref,
                          ref.read(transactionsControllerProvider),
                          tx,
                        ),
                      ),
                  ],
                ),
        ),
      ],
    );
  }
}
