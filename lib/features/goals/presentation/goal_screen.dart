import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/affluena_theme.dart';
import '../../../core/formatters/date_formatter.dart';
import '../../../core/formatters/money_formatter.dart';
import '../../shared/presentation/widgets/affluena_card.dart';
import '../../shared/presentation/widgets/metric_tile.dart';
import '../../shared/presentation/widgets/section_header.dart';
import '../application/goal_controller.dart';
import '../data/goal_models.dart';

class GoalScreen extends ConsumerWidget {
  const GoalScreen({super.key});

  static const path = '/goals';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(goalControllerProvider);
    final controller = ref.read(goalControllerProvider.notifier);
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
                onPressed: state.isSaving ? null : () => _showGoalForm(context),
                icon: const Icon(Icons.add),
              ),
            ],
          ),
          const SizedBox(height: AffluenaSpacing.space5),
          _GoalSummaryCard(state: state),
          const SizedBox(height: AffluenaSpacing.space5),
          if (state.actionError != null) ...[
            AffluenaCard(
              backgroundColor: context.affluenaColors.surfaceTintSoft,
              child: Text(state.actionError!),
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
            const _GoalEmptyState()
          else
            for (final goal in state.goals) ...[
              _GoalCard(
                goal: goal,
                onInvite: () => _showInviteSheet(context, goal),
                onEdit: () => _showGoalForm(context, goal: goal),
                onRespond: (member, status) =>
                    controller.respondInvite(goal, member, status),
              ),
              const SizedBox(height: AffluenaSpacing.space3),
            ],
        ],
      ),
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
    required this.onInvite,
    required this.onEdit,
    required this.onRespond,
  });

  final Goal goal;
  final VoidCallback onInvite;
  final VoidCallback onEdit;
  final Future<void> Function(GoalMember member, GoalMemberStatus status)
  onRespond;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colors = context.affluenaColors;
    final pendingMember = goal.members.where((member) {
      return member.status == GoalMemberStatus.pending;
    }).firstOrNull;

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
                    const SizedBox(height: AffluenaSpacing.space1),
                    Wrap(
                      spacing: AffluenaSpacing.space2,
                      runSpacing: AffluenaSpacing.space2,
                      children: [
                        _GoalBadge(label: goal.status.label),
                        _GoalBadge(label: '${goal.members.length} members'),
                      ],
                    ),
                  ],
                ),
              ),
              PopupMenuButton<String>(
                onSelected: (value) {
                  if (value == 'edit') onEdit();
                  if (pendingMember != null && value == 'join') {
                    onRespond(pendingMember, GoalMemberStatus.joined);
                  }
                  if (pendingMember != null && value == 'reject') {
                    onRespond(pendingMember, GoalMemberStatus.rejected);
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(value: 'edit', child: Text('Edit')),
                  if (pendingMember != null)
                    const PopupMenuItem(
                      value: 'join',
                      child: Text('Join goal'),
                    ),
                  if (pendingMember != null)
                    const PopupMenuItem(
                      value: 'reject',
                      child: Text('Reject invite'),
                    ),
                ],
              ),
            ],
          ),
          const SizedBox(height: AffluenaSpacing.space3),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
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
          FilledButton.icon(
            onPressed: onInvite,
            icon: const Icon(Icons.person_add_alt_1_outlined),
            label: const Text('Invite'),
          ),
        ],
      ),
    );
  }
}

class _GoalBadge extends StatelessWidget {
  const _GoalBadge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final colors = context.affluenaColors;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.forestSoft,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AffluenaSpacing.space3,
          vertical: AffluenaSpacing.space1,
        ),
        child: Text(
          label,
          style: Theme.of(
            context,
          ).textTheme.labelSmall?.copyWith(color: colors.forest),
        ),
      ),
    );
  }
}

class _GoalEmptyState extends StatelessWidget {
  const _GoalEmptyState();

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
            'Create saving targets and let goal wallets track collected balance.',
            style: textTheme.bodySmall,
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
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(
          AffluenaSpacing.space5,
          AffluenaSpacing.space4,
          AffluenaSpacing.space5,
          AffluenaSpacing.space8,
        ),
        children: [
          Text('Goals', style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: AffluenaSpacing.space5),
          const AffluenaCard(
            child: SizedBox(
              height: 144,
              child: Center(child: Text('Loading goals')),
            ),
          ),
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
          AffluenaCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('We could not load goals.'),
                const SizedBox(height: AffluenaSpacing.space4),
                FilledButton.icon(
                  onPressed: onRetry,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Retry'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

Future<void> _showGoalForm(BuildContext context, {Goal? goal}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => _GoalFormSheet(goal: goal),
  );
}

class _GoalFormSheet extends ConsumerStatefulWidget {
  const _GoalFormSheet({this.goal});

  final Goal? goal;

  @override
  ConsumerState<_GoalFormSheet> createState() => _GoalFormSheetState();
}

class _GoalFormSheetState extends ConsumerState<_GoalFormSheet> {
  late final TextEditingController _nameController;
  late final TextEditingController _targetController;
  late final TextEditingController _deadlineController;

  bool get _isEditing => widget.goal != null;

  @override
  void initState() {
    super.initState();
    final goal = widget.goal;
    _nameController = TextEditingController(text: goal?.name ?? '');
    _targetController = TextEditingController(
      text: goal?.targetAmountMinor.toString() ?? '',
    );
    _deadlineController = TextEditingController(text: goal?.deadline ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _targetController.dispose();
    _deadlineController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(goalControllerProvider);
    final canSave =
        _nameController.text.trim().isNotEmpty &&
        _moneyMinor(_targetController.text) > 0 &&
        _validDateTime(_deadlineController.text) &&
        !state.isSaving;

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          AffluenaSpacing.space5,
          AffluenaSpacing.space2,
          AffluenaSpacing.space5,
          MediaQuery.viewInsetsOf(context).bottom + AffluenaSpacing.space5,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                _isEditing ? 'Edit goal' : 'Create goal',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: AffluenaSpacing.space4),
              TextField(
                key: const Key('goal-name-field'),
                controller: _nameController,
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.label_outline),
                  labelText: 'Name',
                ),
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: AffluenaSpacing.space2),
              TextField(
                key: const Key('goal-target-field'),
                controller: _targetController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.flag_outlined),
                  labelText: 'Target amount',
                ),
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: AffluenaSpacing.space2),
              TextField(
                key: const Key('goal-deadline-field'),
                controller: _deadlineController,
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.event_outlined),
                  labelText: 'Deadline',
                  hintText: '2026-12-31T00:00:00Z',
                ),
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: AffluenaSpacing.space5),
              FilledButton(
                key: const Key('goal-save-button'),
                onPressed: canSave ? _save : null,
                child: Text(state.isSaving ? 'Saving...' : 'Save goal'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _save() async {
    final controller = ref.read(goalControllerProvider.notifier);
    final request = GoalRequest(
      name: _nameController.text.trim(),
      targetAmountMinor: _moneyMinor(_targetController.text),
      deadline: _deadlineController.text.trim(),
    );
    if (widget.goal == null) {
      await controller.createGoal(request);
    } else {
      await controller.updateGoal(widget.goal!, request);
    }
    if (mounted) Navigator.of(context).pop();
  }
}

Future<void> _showInviteSheet(BuildContext context, Goal goal) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => _GoalInviteSheet(goal: goal),
  );
}

class _GoalInviteSheet extends ConsumerStatefulWidget {
  const _GoalInviteSheet({required this.goal});

  final Goal goal;

  @override
  ConsumerState<_GoalInviteSheet> createState() => _GoalInviteSheetState();
}

class _GoalInviteSheetState extends ConsumerState<_GoalInviteSheet> {
  final _emailController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(goalControllerProvider);
    final canSave = _validEmail(_emailController.text) && !state.isSaving;

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          AffluenaSpacing.space5,
          AffluenaSpacing.space2,
          AffluenaSpacing.space5,
          MediaQuery.viewInsetsOf(context).bottom + AffluenaSpacing.space5,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Invite member',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: AffluenaSpacing.space2),
            Text(widget.goal.name),
            const SizedBox(height: AffluenaSpacing.space4),
            TextField(
              key: const Key('goal-invite-email-field'),
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.mail_outline),
                labelText: 'Email',
              ),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: AffluenaSpacing.space5),
            FilledButton(
              key: const Key('goal-invite-save-button'),
              onPressed: canSave ? _save : null,
              child: Text(state.isSaving ? 'Sending...' : 'Send invite'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _save() async {
    await ref
        .read(goalControllerProvider.notifier)
        .inviteMember(
          widget.goal,
          GoalInviteRequest(email: _emailController.text.trim()),
        );
    if (mounted) Navigator.of(context).pop();
  }
}

int _moneyMinor(String value) {
  final normalized = value.replaceAll(RegExp(r'[^0-9]'), '');
  return int.tryParse(normalized) ?? 0;
}

bool _validDateTime(String value) {
  return DateTime.tryParse(value.trim()) != null;
}

bool _validEmail(String value) {
  return RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(value.trim());
}
