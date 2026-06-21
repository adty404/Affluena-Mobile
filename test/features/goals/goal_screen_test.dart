import 'package:affluena_mobile/app/provider_retry.dart';
import 'package:affluena_mobile/features/goals/application/goal_controller.dart';
import 'package:affluena_mobile/features/goals/data/goal_models.dart';
import 'package:affluena_mobile/features/goals/data/goal_repository.dart';
import 'package:affluena_mobile/features/goals/presentation/goal_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('loads goal state from repository', () async {
    final container = ProviderContainer(
      retry: noProviderRetry,
      overrides: [
        goalRepositoryProvider.overrideWithValue(TestGoalRepository()),
      ],
    );
    addTearDown(container.dispose);

    container.read(goalControllerProvider);
    await Future<void>.delayed(Duration.zero);
    await Future<void>.delayed(Duration.zero);

    final state = container.read(goalControllerProvider);
    expect(state.goals.single.name, 'Emergency fund');
    expect(state.totalTargetMinor, 10000000);
    expect(state.activeCount, 1);
  });

  testWidgets('renders goal progress and invites a member', (tester) async {
    final repository = TestGoalRepository();

    await tester.pumpWidget(goalTestApp(repository));
    await tester.pumpGoalState();

    expect(find.text('Goals'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Emergency fund'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('25% saved'), findsOneWidget);

    await tester.ensureVisible(find.text('Invite'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Invite'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('goal-invite-email-field')),
      'friend@example.com',
    );
    await tester.pump();
    await tester.tap(find.byKey(const Key('goal-invite-save-button')));
    await tester.pumpAndSettle();

    expect(repository.inviteRequests.single.email, 'friend@example.com');
  });

  testWidgets('creates a goal from the form', (tester) async {
    final repository = TestGoalRepository(goals: const []);

    await tester.pumpWidget(goalTestApp(repository));
    await tester.pumpGoalState();

    await tester.tap(find.byIcon(Icons.add));
    await tester.pumpAndSettle();
    expect(find.text('Create goal'), findsOneWidget);

    await tester.enterText(find.byKey(const Key('goal-name-field')), 'Holiday');
    await tester.enterText(
      find.byKey(const Key('goal-target-field')),
      '8000000',
    );
    await tester.enterText(
      find.byKey(const Key('goal-deadline-field')),
      '2026-11-01T00:00:00Z',
    );
    await tester.pump();
    await tester.tap(find.byKey(const Key('goal-save-button')));
    await tester.pumpAndSettle();

    expect(repository.createdRequests.single.name, 'Holiday');
    expect(repository.createdRequests.single.targetAmountMinor, 8000000);
  });
}

extension on WidgetTester {
  Future<void> pumpGoalState() async {
    await pump();
    await pump();
    await pumpAndSettle();
  }
}

Widget goalTestApp(TestGoalRepository repository) {
  return ProviderScope(
    retry: noProviderRetry,
    overrides: [goalRepositoryProvider.overrideWithValue(repository)],
    child: const MaterialApp(home: Scaffold(body: GoalScreen())),
  );
}

class TestGoalRepository implements GoalRepository {
  TestGoalRepository({List<Goal> goals = const [seedGoal]})
    : _goals = List<Goal>.of(goals);

  final List<Goal> _goals;
  final createdRequests = <GoalRequest>[];
  final inviteRequests = <GoalInviteRequest>[];
  final responseRequests = <GoalInviteResponseRequest>[];

  @override
  Future<GoalListResponse> listGoals() async {
    return GoalListResponse(goals: _goals);
  }

  @override
  Future<Goal> getGoal(String id) async {
    return _goals.firstWhere((goal) => goal.id == id);
  }

  @override
  Future<Goal> createGoal(GoalRequest request) async {
    createdRequests.add(request);
    final goal = seedGoal.copyForRequest(
      id: 'goal-${request.name}',
      name: request.name,
      targetAmountMinor: request.targetAmountMinor,
      deadline: request.deadline,
    );
    _goals.add(goal);
    return goal;
  }

  @override
  Future<Goal> updateGoal(String id, GoalRequest request) async {
    return _goals.firstWhere((goal) => goal.id == id);
  }

  @override
  Future<void> inviteMember(String id, GoalInviteRequest request) async {
    inviteRequests.add(request);
  }

  @override
  Future<void> respondInvite(
    String id,
    String userId,
    GoalInviteResponseRequest request,
  ) async {
    responseRequests.add(request);
  }
}

const seedGoal = Goal(
  id: 'goal-1',
  userId: 'user-1',
  name: 'Emergency fund',
  targetAmountMinor: 10000000,
  collectedAmountMinor: 2500000,
  deadline: '2026-12-31T00:00:00Z',
  status: GoalStatus.active,
  createdAt: '2026-06-01T00:00:00Z',
  updatedAt: '2026-06-01T00:00:00Z',
  members: [
    GoalMember(
      goalId: 'goal-1',
      userId: 'member-1',
      status: GoalMemberStatus.pending,
      createdAt: '2026-06-01T00:00:00Z',
      updatedAt: '2026-06-01T00:00:00Z',
    ),
  ],
);
