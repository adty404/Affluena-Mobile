import 'package:flutter/material.dart';

import '../../../app/theme/affluena_theme.dart';
import '../../shared/presentation/widgets/status_badge.dart';
import '../data/goal_models.dart';

/// Renders the real member list for a goal: every member with their identity
/// and status. The current user's pending invite gets accept/reject controls;
/// each member is handled independently so every pending invite is actionable.
class GoalMembersSection extends StatelessWidget {
  const GoalMembersSection({
    required this.members,
    required this.currentUserId,
    required this.busy,
    required this.onRespond,
    super.key,
  });

  final List<GoalMember> members;
  final String? currentUserId;
  final bool busy;
  final void Function(GoalMember member, GoalMemberStatus status) onRespond;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colors = context.affluenaColors;

    if (members.isEmpty) {
      return Text(
        'Just you so far. Invite people to save together.',
        style: textTheme.bodySmall?.copyWith(color: colors.inkMuted),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < members.length; i++) ...[
          if (i > 0) const SizedBox(height: AffluenaSpacing.space2),
          _MemberRow(
            member: members[i],
            isCurrentUser: members[i].userId == currentUserId,
            busy: busy,
            onRespond: onRespond,
          ),
        ],
      ],
    );
  }
}

class _MemberRow extends StatelessWidget {
  const _MemberRow({
    required this.member,
    required this.isCurrentUser,
    required this.busy,
    required this.onRespond,
  });

  final GoalMember member;
  final bool isCurrentUser;
  final bool busy;
  final void Function(GoalMember member, GoalMemberStatus status) onRespond;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colors = context.affluenaColors;
    final canRespond =
        isCurrentUser && member.status == GoalMemberStatus.pending;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.surfaceTintSoft,
        borderRadius: BorderRadius.circular(AffluenaRadii.md),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AffluenaSpacing.space3,
          vertical: AffluenaSpacing.space3,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.person_outline, size: 18, color: colors.inkMuted),
                const SizedBox(width: AffluenaSpacing.space2),
                Expanded(
                  child: Text(
                    isCurrentUser ? 'You' : member.identityLabel,
                    style: textTheme.bodyMedium,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: AffluenaSpacing.space2),
                StatusBadge.forStatus(
                  member.status.apiValue,
                  label: member.status.label,
                ),
              ],
            ),
            if (canRespond) ...[
              const SizedBox(height: AffluenaSpacing.space3),
              Row(
                children: [
                  Expanded(
                    child: FilledButton(
                      onPressed: busy
                          ? null
                          : () => onRespond(member, GoalMemberStatus.joined),
                      child: const Text('Accept'),
                    ),
                  ),
                  const SizedBox(width: AffluenaSpacing.space2),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: busy
                          ? null
                          : () => onRespond(member, GoalMemberStatus.rejected),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: colors.coral,
                        side: BorderSide(color: colors.coral),
                      ),
                      child: const Text('Reject'),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
