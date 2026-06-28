import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../shared/application/financial_refresh.dart';
import '../../transactions/data/transaction_models.dart';
import '../../transactions/data/transaction_repository.dart';
import '../data/goal_models.dart';
import '../data/goal_repository.dart';

final goalControllerProvider = NotifierProvider<GoalController, GoalState>(
  GoalController.new,
);

class GoalController extends Notifier<GoalState> {
  @override
  GoalState build() {
    Future<void>.microtask(load);
    return const GoalState();
  }

  Future<void> load() async {
    state = state.copyWith(isLoading: true, loadError: null, actionError: null);

    try {
      final response = await ref.read(goalRepositoryProvider).listGoals();
      state = state.copyWith(isLoading: false, goals: response.goals);
    } catch (_) {
      state = state.copyWith(
        isLoading: false,
        loadError: 'Target gagal dimuat.',
      );
    }
  }

  /// Creates a goal. Returns `true` on success so the sheet can stay OPEN and
  /// surface an inline error when it fails.
  Future<bool> createGoal(GoalRequest request) {
    return _mutate(() => ref.read(goalRepositoryProvider).createGoal(request));
  }

  Future<bool> updateGoal(Goal goal, GoalRequest request) {
    return _mutate(
      () => ref.read(goalRepositoryProvider).updateGoal(goal.id, request),
    );
  }

  /// Transitions a goal from active to achieved or cancelled.
  Future<bool> transitionStatus(Goal goal, GoalStatus status) {
    return _mutate(
      () => ref
          .read(goalRepositoryProvider)
          .updateGoalStatus(
            goal.id,
            GoalStatusRequest(
              name: goal.name,
              targetAmountMinor: goal.targetAmountMinor,
              deadline: goal.deadline ?? goal.createdAt,
              status: status,
            ),
          ),
    );
  }

  Future<bool> inviteMember(Goal goal, GoalInviteRequest request) {
    return _mutate(
      () => ref.read(goalRepositoryProvider).inviteMember(goal.id, request),
    );
  }

  /// Responds to a single pending invite. Each member is responded to
  /// independently, so callers can handle every pending invite, not just one.
  Future<bool> respondInvite(
    Goal goal,
    GoalMember member,
    GoalMemberStatus status,
  ) {
    return _mutate(
      () => ref
          .read(goalRepositoryProvider)
          .respondInvite(
            goal.id,
            member.userId,
            GoalInviteResponseRequest(status: status),
          ),
    );
  }

  /// Funds a goal by recording a `transfer` transaction from [sourceWalletId]
  /// into the goal's own goal-type wallet. The collected amount is computed
  /// server-side from wallet balances, so we simply reload after the transfer.
  Future<bool> contribute({
    required Goal goal,
    required String sourceWalletId,
    required String goalWalletId,
    required int amountMinor,
    required DateTime contributedAt,
  }) async {
    final success = await _mutate(
      () => ref
          .read(transactionRepositoryProvider)
          .createTransaction(
            TransactionRequest(
              type: TransactionType.transfer,
              walletId: sourceWalletId,
              toWalletId: goalWalletId,
              amountMinor: amountMinor,
              transactionAt: contributedAt.toUtc().toIso8601String(),
              note: 'Kontribusi ke ${goal.name}',
            ),
          ),
    );
    // A contribution moves money between wallets, so refresh the shared
    // financial providers (wallet balances, dashboard, analytics, budgets) on
    // success. _mutate already reloaded the goals list.
    if (success) {
      ref.invalidateFinancialData();
    }
    return success;
  }

  /// Runs a mutation, reloads goals on success, and reports success as a bool.
  /// On failure the surface that triggered the action stays open and renders an
  /// inline error; we also expose a list-level [actionError] for the screen.
  Future<bool> _mutate(Future<Object?> Function() action) async {
    state = state.copyWith(isSaving: true, actionError: null);
    try {
      await action();
      state = state.copyWith(isSaving: false);
      await load();
      return true;
    } catch (_) {
      state = state.copyWith(
        isSaving: false,
        actionError: 'Tindakan itu gagal diselesaikan.',
      );
      return false;
    }
  }

  void clearActionError() {
    if (state.actionError == null) return;
    state = state.copyWith(actionError: null);
  }
}

class GoalState {
  const GoalState({
    this.goals = const [],
    this.isLoading = false,
    this.isSaving = false,
    this.loadError,
    this.actionError,
  });

  final List<Goal> goals;
  final bool isLoading;
  final bool isSaving;
  final String? loadError;
  final String? actionError;

  int get totalTargetMinor =>
      goals.fold(0, (total, goal) => total + goal.targetAmountMinor);

  int get totalSavedMinor =>
      goals.fold(0, (total, goal) => total + goal.collectedAmountMinor);

  int get activeCount => goals.where((goal) => goal.isActive).length;

  int get sharedCount => goals.where((goal) => goal.members.length > 1).length;

  GoalState copyWith({
    List<Goal>? goals,
    bool? isLoading,
    bool? isSaving,
    Object? loadError = _unchanged,
    Object? actionError = _unchanged,
  }) {
    return GoalState(
      goals: goals ?? this.goals,
      isLoading: isLoading ?? this.isLoading,
      isSaving: isSaving ?? this.isSaving,
      loadError: identical(loadError, _unchanged)
          ? this.loadError
          : loadError as String?,
      actionError: identical(actionError, _unchanged)
          ? this.actionError
          : actionError as String?,
    );
  }
}

const _unchanged = Object();
