import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

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
        loadError: 'Goals could not be loaded.',
      );
    }
  }

  Future<void> createGoal(GoalRequest request) async {
    await _save(() => ref.read(goalRepositoryProvider).createGoal(request));
  }

  Future<void> updateGoal(Goal goal, GoalRequest request) async {
    await _save(
      () => ref.read(goalRepositoryProvider).updateGoal(goal.id, request),
    );
  }

  Future<void> inviteMember(Goal goal, GoalInviteRequest request) async {
    await _save(
      () => ref.read(goalRepositoryProvider).inviteMember(goal.id, request),
      errorMessage: 'Goal invite could not be sent.',
    );
  }

  Future<void> respondInvite(
    Goal goal,
    GoalMember member,
    GoalMemberStatus status,
  ) async {
    await _save(
      () => ref
          .read(goalRepositoryProvider)
          .respondInvite(
            goal.id,
            member.userId,
            GoalInviteResponseRequest(status: status),
          ),
      errorMessage: 'Goal invitation could not be updated.',
    );
  }

  Future<void> _save(
    Future<Object?> Function() action, {
    String errorMessage = 'Goal could not be saved.',
  }) async {
    state = state.copyWith(isSaving: true, actionError: null);
    try {
      await action();
      state = state.copyWith(isSaving: false);
      await load();
    } catch (_) {
      state = state.copyWith(isSaving: false, actionError: errorMessage);
    }
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
