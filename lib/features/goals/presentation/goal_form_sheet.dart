import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/affluena_theme.dart';
import '../../shared/presentation/widgets/affluena_banner.dart';
import '../../shared/presentation/widgets/date_picker_field.dart';
import '../../shared/presentation/widgets/money_input.dart';
import '../application/goal_controller.dart';
import '../data/goal_models.dart';

/// Opens the create/edit goal sheet. The sheet stays OPEN on save failure and
/// shows an inline retry banner; it pops only on success.
Future<void> showGoalFormSheet(BuildContext context, {Goal? goal}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    useSafeArea: true,
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
  int? _targetMinor;
  DateTime? _deadline;
  String? _error;
  bool _isSaving = false;

  bool get _isEditing => widget.goal != null;

  @override
  void initState() {
    super.initState();
    final goal = widget.goal;
    _nameController = TextEditingController(text: goal?.name ?? '');
    _targetMinor = goal?.targetAmountMinor;
    _deadline = _parseDeadline(goal?.deadline);
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return SafeArea(
      child: SingleChildScrollView(
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
                _isEditing ? 'Edit goal' : 'Create goal',
                style: textTheme.titleLarge,
              ),
              const SizedBox(height: AffluenaSpacing.space4),
              TextField(
                key: const Key('goal-name-field'),
                controller: _nameController,
                enabled: !_isSaving,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.label_outline),
                  labelText: 'Name',
                ),
                onChanged: (_) => _clearError(),
              ),
              const SizedBox(height: AffluenaSpacing.space3),
              MoneyInput(
                key: const Key('goal-target-field'),
                label: 'Target amount',
                initialValue: _targetMinor,
                enabled: !_isSaving,
                onChanged: (value) => setState(() {
                  _targetMinor = value;
                  _error = null;
                }),
              ),
              const SizedBox(height: AffluenaSpacing.space2),
              DatePickerField(
                label: 'Deadline',
                value: _deadline,
                enabled: !_isSaving,
                firstDate: DateTime.now(),
                onChanged: (value) => setState(() {
                  _deadline = value;
                  _error = null;
                }),
              ),
              if (_error != null) ...[
                const SizedBox(height: AffluenaSpacing.space4),
                AffluenaBanner.error(_error!, onRetry: _save),
              ],
              const SizedBox(height: AffluenaSpacing.space5),
              FilledButton(
                key: const Key('goal-save-button'),
                onPressed: _isSaving ? null : _save,
                child: Text(_isSaving ? 'Saving...' : 'Save goal'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _clearError() {
    if (_error == null) return;
    setState(() => _error = null);
  }

  Future<void> _save() async {
    final name = _nameController.text.trim();
    final target = _targetMinor ?? 0;
    final deadline = _deadline;

    if (name.isEmpty) {
      setState(() => _error = 'Give the goal a name.');
      return;
    }
    if (target <= 0) {
      setState(() => _error = 'Set a target amount greater than zero.');
      return;
    }
    if (deadline == null) {
      setState(() => _error = 'Pick a deadline for this goal.');
      return;
    }

    setState(() {
      _isSaving = true;
      _error = null;
    });

    final request = GoalRequest(
      name: name,
      targetAmountMinor: target,
      deadline: deadline.toUtc().toIso8601String(),
    );

    final controller = ref.read(goalControllerProvider.notifier);
    final success = widget.goal == null
        ? await controller.createGoal(request)
        : await controller.updateGoal(widget.goal!, request);

    if (!mounted) return;
    if (success) {
      Navigator.of(context).pop();
      return;
    }
    setState(() {
      _isSaving = false;
      _error = _isEditing
          ? 'Goal could not be updated. Try again.'
          : 'Goal could not be created. Try again.';
    });
  }

  DateTime? _parseDeadline(String? raw) {
    if (raw == null || raw.trim().isEmpty) return null;
    return DateTime.tryParse(raw.trim())?.toLocal();
  }
}
