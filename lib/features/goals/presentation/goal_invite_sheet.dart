import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/affluena_theme.dart';
import '../../shared/presentation/widgets/affluena_banner.dart';
import '../application/goal_controller.dart';
import '../data/goal_models.dart';

/// Opens the invite-member sheet. Stays OPEN on failure with an inline retry
/// banner; pops only after the invite is sent.
Future<void> showGoalInviteSheet(BuildContext context, Goal goal) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    useSafeArea: true,
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
  String? _error;
  bool _isSaving = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colors = context.affluenaColors;

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
              Text('Invite member', style: textTheme.titleLarge),
              const SizedBox(height: AffluenaSpacing.space1),
              Text(
                widget.goal.name,
                style: textTheme.bodyMedium?.copyWith(color: colors.inkMuted),
              ),
              const SizedBox(height: AffluenaSpacing.space4),
              TextField(
                key: const Key('goal-invite-email-field'),
                controller: _emailController,
                enabled: !_isSaving,
                keyboardType: TextInputType.emailAddress,
                autocorrect: false,
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.mail_outline),
                  labelText: 'Email',
                ),
                onChanged: (_) => _clearError(),
              ),
              if (_error != null) ...[
                const SizedBox(height: AffluenaSpacing.space4),
                AffluenaBanner.error(_error!, onRetry: _save),
              ],
              const SizedBox(height: AffluenaSpacing.space5),
              FilledButton(
                key: const Key('goal-invite-save-button'),
                onPressed: _isSaving ? null : _save,
                child: Text(_isSaving ? 'Sending...' : 'Send invite'),
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
    final email = _emailController.text.trim();
    if (!_isValidEmail(email)) {
      setState(() => _error = 'Enter a valid email address.');
      return;
    }

    setState(() {
      _isSaving = true;
      _error = null;
    });

    final success = await ref
        .read(goalControllerProvider.notifier)
        .inviteMember(widget.goal, GoalInviteRequest(email: email));

    if (!mounted) return;
    if (success) {
      Navigator.of(context).pop();
      return;
    }
    setState(() {
      _isSaving = false;
      _error = 'Invite could not be sent. Check the email and try again.';
    });
  }

  bool _isValidEmail(String value) {
    return RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(value);
  }
}
