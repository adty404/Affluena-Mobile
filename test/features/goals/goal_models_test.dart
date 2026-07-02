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
    // Appearance fields are optional server-side; absent means "no color".
    expect(goal.color, '');
    expect(goal.icon, '');
  });

  test('parses goal appearance fields and serializes them on requests', () {
    final goals = GoalListResponse.fromJson(const [
      {
        'id': 'goal-1',
        'user_id': 'user-1',
        'name': 'Emergency fund',
        'target_amount_minor': 10000000,
        'collected_amount_minor': 2500000,
        'deadline': null,
        'status': 'active',
        'color': '#7C5BC2',
        'icon': 'savings',
        'created_at': '2026-06-01T00:00:00Z',
        'updated_at': '2026-06-01T00:00:00Z',
      },
    ]);
    expect(goals.goals.single.color, '#7C5BC2');
    expect(goals.goals.single.icon, 'savings');

    final json = const GoalRequest(
      name: 'Holiday',
      targetAmountMinor: 8000000,
      deadline: '2026-11-01T00:00:00Z',
      color: '#7C5BC2',
      icon: 'savings',
    ).toJson();
    expect(json, containsPair('color', '#7C5BC2'));
    expect(json, containsPair('icon', 'savings'));

    // Omitted appearance fields stay off the wire entirely.
    final bare = const GoalRequest(
      name: 'Holiday',
      targetAmountMinor: 8000000,
      deadline: '2026-11-01T00:00:00Z',
    ).toJson();
    expect(bare.containsKey('color'), isFalse);
    expect(bare.containsKey('icon'), isFalse);

    // Status transitions re-send the appearance so it survives the update.
    expect(
      const GoalStatusRequest(
        name: 'Holiday',
        targetAmountMinor: 8000000,
        deadline: '2026-11-01T00:00:00Z',
        status: GoalStatus.achieved,
        color: '#7C5BC2',
      ).toJson(),
      containsPair('color', '#7C5BC2'),
    );
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
