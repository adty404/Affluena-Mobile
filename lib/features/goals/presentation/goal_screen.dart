import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/affluena_theme.dart';
import '../../../core/formatters/date_formatter.dart';
import '../../../core/formatters/money_formatter.dart';
import '../../auth/application/auth_controller.dart';
import '../../shared/presentation/widgets/affluena_banner.dart';
import '../../shared/presentation/widgets/affluena_card.dart';
import '../../shared/presentation/widgets/affluena_skeleton.dart';
import '../../shared/presentation/widgets/metric_tile.dart';
import '../../shared/presentation/widgets/section_header.dart';
import '../../shared/presentation/widgets/status_badge.dart';
import '../application/goal_controller.dart';
import '../data/goal_models.dart';
import 'goal_contribute_sheet.dart';
import 'goal_form_sheet.dart';
import 'goal_invite_sheet.dart';
import 'goal_members_section.dart';

class GoalScreen extends ConsumerWidget {
  const GoalScreen({super.key});

  static const path = '/goals';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(goalControllerProvider);
    final controller = ref.read(goalControllerProvider.notifier);
    final currentUserId = ref.watch(
      authControllerProvider.select((auth) => auth.user?.id),
    );
    final textTheme = Theme.of(context).textTheme;

    if (state.isLoading && state.goals.isEmpty) {
      return const _GoalLoading();
    }

    if (state.loadError != null && state.goals.isEmpty) {
      return _GoalError(onRetry: controller.load);
    }

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(
          AffluenaSpacing.space5,
          AffluenaSpacing.space4,
          AffluenaSpacing.space5,
          AffluenaSpacing.space8,
        ),
        children: [
          Row(
            children: [
              Expanded(child: Text('Goals', style: textTheme.headlineMedium)),
              IconButton.filledTonal(
                onPressed: state.isSaving
                    ? null
                    : () => showGoalFormSheet(context),
                icon: const Icon(Icons.add),
              ),
            ],
          ),
          const SizedBox(height: AffluenaSpacing.space5),
          _GoalSummaryCard(state: state),
          const SizedBox(height: AffluenaSpacing.space5),
          if (state.actionError != null) ...[
            AffluenaBanner.error(
              state.actionError!,
              onRetry: controller.clearActionError,
            ),
            const SizedBox(height: AffluenaSpacing.space4),
          ],
          SectionHeader(
            title: 'Saving goals',
            actionLabel: state.goals.isEmpty
                ? null
                : '${state.goals.length} total',
          ),
          const SizedBox(height: AffluenaSpacing.space3),
          if (state.goals.isEmpty)
            _GoalEmptyState(onCreate: () => showGoalFormSheet(context))
          else
            for (final goal in state.goals) ...[
              _GoalCard(
                goal: goal,
                currentUserId: currentUserId,
                busy: state.isSaving,
                onContribute: () => showGoalContributeSheet(context, goal),
                onInvite: () => showGoalInviteSheet(context, goal),
                onEdit: () => showGoalFormSheet(context, goal: goal),
                onTransition: (status) =>
                    _confirmTransition(context, ref, goal, status),
                onRespond: (member, status) =>
                    controller.respondInvite(goal, member, status),
              ),
              const SizedBox(height: AffluenaSpacing.space3),
            ],
        ],
      ),
    );
  }

  Future<void> _confirmTransition(
    BuildContext context,
    WidgetRef ref,
    Goal goal,
    GoalStatus status,
  ) async {
    final colors = context.affluenaColors;
    final isCancel = status == GoalStatus.cancelled;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(
          isCancel ? 'Cancel this goal?' : 'Mark goal achieved?',
        ),
        content: Text(
          isCancel
              ? 'Cancelling stops tracking progress for "${goal.name}". '
                    'Collected funds stay in the goal wallet.'
              : 'This marks "${goal.name}" as achieved. You can still view it '
                    'in your list.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Keep active'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            style: isCancel
                ? FilledButton.styleFrom(backgroundColor: colors.coral)
                : null,
            child: Text(isCancel ? 'Cancel goal' : 'Mark achieved'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await ref.read(goalControllerProvider.notifier).transitionStatus(
      goal,
      status,
    );
  }
}

class _GoalSummaryCard extends StatelessWidget {
  const _GoalSummaryCard({required this.state});

  final GoalState state;

  @override
  Widget build(BuildContext context) {
    return AffluenaCard(
      child: Column(
        children: [
          Row(
            children: [
              MetricTile(
                label: 'Saved',
                value: MoneyFormatter.idr(state.totalSavedMinor),
                helper: 'Across goals',
                icon: Icons.savings_outlined,
              ),
              const SizedBox(width: AffluenaSpacing.space3),
              MetricTile(
                label: 'Target',
                value: MoneyFormatter.idr(state.totalTargetMinor),
                helper: 'Planned',
                icon: Icons.flag_outlined,
              ),
            ],
          ),
          const SizedBox(height: AffluenaSpacing.space3),
          Row(
            children: [
              MetricTile(
                label: 'Active goals',
                value: state.activeCount.toString(),
                helper: 'In progress',
                icon: Icons.track_changes_outlined,
              ),
              const SizedBox(width: AffluenaSpacing.space3),
              MetricTile(
                label: 'Shared',
                value: state.sharedCount.toString(),
                helper: 'With members',
                icon: Icons.group_outlined,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _GoalCard extends StatelessWidget {
  const _GoalCard({
    required this.goal,
    required this.currentUserId,
    required this.busy,
    required this.onContribute,
    required this.onInvite,
    required this.onEdit,
    required this.onTransition,
    required this.onRespond,
  });

  final Goal goal;
  final String? currentUserId;
  final bool busy;
  final VoidCallback onContribute;
  final VoidCallback onInvite;
  final VoidCallback onEdit;
  final void Function(GoalStatus status) onTransition;
  final void Function(GoalMember member, GoalMemberStatus status) onRespond;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colors = context.affluenaColors;

    return AffluenaCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(goal.name, style: textTheme.titleMedium),
                    const SizedBox(height: AffluenaSpacing.space2),
                    Wrap(
                      spacing: AffluenaSpacing.space2,
                      runSpacing: AffluenaSpacing.space2,
                      children: [
                        StatusBadge.forStatus(
                          goal.status.apiValue,
                          label: goal.status.label,
                        ),
                        StatusBadge(
                          label: '${goal.members.length} '
                              '${goal.members.length == 1 ? 'member' : 'members'}',
                          tone: StatusTone.neutral,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              _GoalOverflowMenu(
                goal: goal,
                onEdit: onEdit,
                onTransition: onTransition,
              ),
            ],
          ),
          const SizedBox(height: AffluenaSpacing.space3),
          ClipRRect(
            borderRadius: BorderRadius.circular(AffluenaRadii.pill),
            child: LinearProgressIndicator(
              value: goal.progressPercent / 100,
              minHeight: 10,
              color: colors.success,
              backgroundColor: colors.surfaceTintSoft,
            ),
          ),
          const SizedBox(height: AffluenaSpacing.space3),
          Text(
            MoneyFormatter.idr(goal.collectedAmountMinor),
            style: textTheme.headlineSmall,
          ),
          const SizedBox(height: AffluenaSpacing.space1),
          Text('${goal.progressPercent}% saved', style: textTheme.bodySmall),
          const SizedBox(height: AffluenaSpacing.space1),
          Text(
            'Target ${MoneyFormatter.idr(goal.targetAmountMinor)}',
            style: textTheme.bodySmall,
          ),
          const SizedBox(height: AffluenaSpacing.space1),
          Text(
            goal.deadline == null
                ? 'No deadline'
                : 'Deadline ${AffluenaDateFormatter.shortDate(goal.deadline!)}',
            style: textTheme.bodySmall,
          ),
          const SizedBox(height: AffluenaSpacing.space4),
          GoalMembersSection(
            members: goal.members,
            currentUserId: currentUserId,
            busy: busy,
            onRespond: onRespond,
          ),
          const SizedBox(height: AffluenaSpacing.space4),
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: goal.isActive ? onContribute : null,
                  icon: const Icon(Icons.add_card_outlined),
                  label: const Text('Contribute'),
                ),
              ),
              const SizedBox(width: AffluenaSpacing.space2),
              OutlinedButton.icon(
                onPressed: onInvite,
                icon: const Icon(Icons.person_add_alt_1_outlined),
                label: const Text('Invite'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _GoalOverflowMenu extends StatelessWidget {
  const _GoalOverflowMenu({
    required this.goal,
    required this.onEdit,
    required this.onTransition,
  });

  final Goal goal;
  final VoidCallback onEdit;
  final void Function(GoalStatus status) onTransition;

  @override
  Widget build(BuildContext context) {
    final colors = context.affluenaColors;
    return PopupMenuButton<String>(
      onSelected: (value) {
        switch (value) {
          case 'edit':
            onEdit();
          case 'achieved':
            onTransition(GoalStatus.achieved);
          case 'cancelled':
            onTransition(GoalStatus.cancelled);
        }
      },
      itemBuilder: (context) => [
        const PopupMenuItem(value: 'edit', child: Text('Edit goal')),
        if (goal.isActive) ...[
          const PopupMenuItem(
            value: 'achieved',
            child: Text('Mark achieved'),
          ),
          PopupMenuItem(
            value: 'cancelled',
            child: Text(
              'Cancel goal',
              style: TextStyle(color: colors.coral),
            ),
          ),
        ],
      ],
    );
  }
}

class _GoalEmptyState extends StatelessWidget {
  const _GoalEmptyState({required this.onCreate});

  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colors = context.affluenaColors;
    return AffluenaCard(
      backgroundColor: colors.forestSoft,
      borderColor: colors.forestSoft,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.flag_outlined, color: colors.forest),
          const SizedBox(height: AffluenaSpacing.space3),
          Text('No goals yet', style: textTheme.titleMedium),
          const SizedBox(height: AffluenaSpacing.space1),
          Text(
            'Create a saving target and a goal wallet tracks the balance you '
            'collect toward it.',
            style: textTheme.bodySmall,
          ),
          const SizedBox(height: AffluenaSpacing.space4),
          FilledButton.icon(
            onPressed: onCreate,
            icon: const Icon(Icons.add),
            label: const Text('Create goal'),
          ),
        ],
      ),
    );
  }
}

class _GoalLoading extends StatelessWidget {
  const _GoalLoading();

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(
          AffluenaSpacing.space5,
          AffluenaSpacing.space4,
          AffluenaSpacing.space5,
          AffluenaSpacing.space8,
        ),
        children: [
          Text('Goals', style: textTheme.headlineMedium),
          const SizedBox(height: AffluenaSpacing.space5),
          const AffluenaCard(child: _SummarySkeleton()),
          const SizedBox(height: AffluenaSpacing.space5),
          const AffluenaSkeleton.line(width: 140, height: 16),
          const SizedBox(height: AffluenaSpacing.space3),
          const _GoalCardSkeleton(),
          const SizedBox(height: AffluenaSpacing.space3),
          const _GoalCardSkeleton(),
        ],
      ),
    );
  }
}

class _SummarySkeleton extends StatelessWidget {
  const _SummarySkeleton();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: const [
        Row(
          children: [
            Expanded(child: AffluenaSkeleton(height: 56, radius: AffluenaRadii.md)),
            SizedBox(width: AffluenaSpacing.space3),
            Expanded(child: AffluenaSkeleton(height: 56, radius: AffluenaRadii.md)),
          ],
        ),
        SizedBox(height: AffluenaSpacing.space3),
        Row(
          children: [
            Expanded(child: AffluenaSkeleton(height: 56, radius: AffluenaRadii.md)),
            SizedBox(width: AffluenaSpacing.space3),
            Expanded(child: AffluenaSkeleton(height: 56, radius: AffluenaRadii.md)),
          ],
        ),
      ],
    );
  }
}

class _GoalCardSkeleton extends StatelessWidget {
  const _GoalCardSkeleton();

  @override
  Widget build(BuildContext context) {
    return const AffluenaCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AffluenaSkeleton.line(width: 160, height: 16),
          SizedBox(height: AffluenaSpacing.space3),
          AffluenaSkeleton(height: 10, radius: AffluenaRadii.pill),
          SizedBox(height: AffluenaSpacing.space3),
          AffluenaSkeleton.line(width: 120, height: 20),
          SizedBox(height: AffluenaSpacing.space2),
          AffluenaSkeleton.line(width: 90, height: 12),
          SizedBox(height: AffluenaSpacing.space4),
          AffluenaSkeleton(height: 44, radius: AffluenaRadii.control),
        ],
      ),
    );
  }
}

class _GoalError extends StatelessWidget {
  const _GoalError({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(
          AffluenaSpacing.space5,
          AffluenaSpacing.space4,
          AffluenaSpacing.space5,
          AffluenaSpacing.space8,
        ),
        children: [
          Text(
            'Goals unavailable',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: AffluenaSpacing.space5),
          AffluenaBanner.error(
            'We could not load goals.',
            onRetry: onRetry,
          ),
        ],
      ),
    );
  }
}
