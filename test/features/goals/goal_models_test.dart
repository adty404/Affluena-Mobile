import 'package:affluena_mobile/features/goals/data/goal_models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('parses goal payloads with members and progress', () {
    final goals = GoalListResponse.fromJson(const [
      {
        'id': 'goal-1',
        'user_id': 'user-1',
        'name': 'Emergency fund',
        'target_amount_minor': 10000000,
        'collected_amount_minor': 2500000,
        'deadline': '2026-12-31T00:00:00Z',
        'status': 'active',
        'created_at': '2026-06-01T00:00:00Z',
        'updated_at': '2026-06-01T00:00:00Z',
        'members': [
          {
            'goal_id': 'goal-1',
            'user_id': 'member-1',
            'status': 'pending',
            'created_at': '2026-06-01T00:00:00Z',
            'updated_at': '2026-06-01T00:00:00Z',
          },
        ],
      },
    ]);

    final goal = goals.goals.single;
    expect(goal.status, GoalStatus.active);
    expect(goal.members.single.status, GoalMemberStatus.pending);
    expect(goal.progressPercent, 25);
  });

  test('serializes goal requests and invite responses', () {
    expect(
      const GoalRequest(
        name: 'Holiday',
        targetAmountMinor: 8000000,
        deadline: '2026-11-01T00:00:00Z',
      ).toJson(),
      containsPair('target_amount_minor', 8000000),
    );

    expect(
      const GoalInviteRequest(email: 'friend@example.com').toJson(),
      containsPair('email', 'friend@example.com'),
    );

    expect(
      const GoalInviteResponseRequest(
        status: GoalMemberStatus.rejected,
      ).toJson(),
      containsPair('status', 'rejected'),
    );
  });
}
