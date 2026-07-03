import 'package:affluena_mobile/app/provider_retry.dart';
import 'package:affluena_mobile/features/auth/application/auth_controller.dart';
import 'package:affluena_mobile/features/auth/data/auth_models.dart';
import 'package:affluena_mobile/features/goals/application/goal_controller.dart';
import 'package:affluena_mobile/features/goals/data/goal_models.dart';
import 'package:affluena_mobile/features/goals/data/goal_repository.dart';
import 'package:affluena_mobile/features/goals/presentation/goal_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

void main() {
  setUpAll(() async {
    // DatePickerField formats the chosen date with the 'id_ID' locale, mirroring
    // main(); without this the create flow throws on locale data.
    await initializeDateFormatting('id_ID');
  });

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

    expect(find.text('Target tabungan'), findsWidgets);
    await tester.scrollUntilVisible(
      find.text('Emergency fund'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('25% tersimpan'), findsOneWidget);

    await tester.ensureVisible(find.text('Undang'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Undang'));
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

    // Two add affordances exist on the empty list (header button + empty-state
    // CTA); open the create sheet from the header IconButton.
    await tester.tap(find.widgetWithIcon(IconButton, Icons.add));
    await tester.pumpAndSettle();
    expect(find.text('Buat target'), findsWidgets);

    await tester.enterText(find.byKey(const Key('goal-name-field')), 'Holiday');
    // The amount is now a MoneyInput: typed digits become minor units and are
    // shown grouped as "Rp 8.000.000".
    await tester.enterText(
      find.byKey(const Key('goal-target-field')),
      '8000000',
    );
    await tester.pump();
    expect(find.text('8.000.000'), findsOneWidget);

    // The deadline is now a tappable DatePickerField backed by the native date
    // picker instead of a hand-typed RFC3339 field. It carries a required
    // marker because saving is blocked until it is picked.
    await tester.tap(find.text('Tenggat (Wajib)'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();

    // The form exposes the shared color swatches; the chosen color rides
    // along on the create request.
    await tester.ensureVisible(find.byKey(const Key('goal-color-#2E8B57')));
    await tester.tap(find.byKey(const Key('goal-color-#2E8B57')));
    await tester.pump();

    await tester.ensureVisible(find.byKey(const Key('goal-save-button')));
    await tester.tap(find.byKey(const Key('goal-save-button')));
    await tester.pumpAndSettle();

    expect(repository.createdRequests.single.name, 'Holiday');
    expect(repository.createdRequests.single.targetAmountMinor, 8000000);
    expect(repository.createdRequests.single.color, '#2E8B57');
  });

  testWidgets('goal with a chosen color renders a solid colored card', (
    tester,
  ) async {
    await tester.pumpWidget(
      goalTestApp(TestGoalRepository(goals: const [coloredGoal])),
    );
    await tester.pumpGoalState();

    await tester.scrollUntilVisible(
      find.text('Dana Liburan'),
      300,
      scrollable: find.byType(Scrollable).first,
    );

    // The colored goal paints its whole row solid with a white title — the
    // same treatment as Beranda's dashboard cards.
    const green = Color(0xFF2E8B57);
    expect(_solidCard(green), findsOneWidget);
    final title = tester.widget<Text>(find.text('Dana Liburan'));
    expect(title.style?.color, Colors.white);
  });

  testWidgets('responds to a pending goal invite and refreshes actions', (
    tester,
  ) async {
    final repository = TestGoalRepository();

    // The accept/reject controls only render for the signed-in member, so seed
    // the auth user id to match the pending member on the seed goal.
    await tester.pumpWidget(goalTestApp(repository, currentUserId: 'member-1'));
    await tester.pumpGoalState();

    await tester.scrollUntilVisible(
      find.text('Terima'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    // The pending invite is actionable from the member row, not an overflow
    // menu: tapping Accept joins the goal.
    expect(find.text('Tolak'), findsOneWidget);
    await tester.ensureVisible(find.text('Terima'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Terima'));
    await tester.pumpGoalState();

    expect(repository.responseRequests.single.status, GoalMemberStatus.joined);
    expect(
      repository.goals.single.members.single.status,
      GoalMemberStatus.joined,
    );

    // Once joined the row drops its accept/reject controls and shows the
    // "Joined" status badge instead.
    expect(find.text('Terima'), findsNothing);
    expect(find.text('Tolak'), findsNothing);
    expect(find.text('Bergabung'), findsOneWidget);

    // The overflow menu still exposes the goal-management actions.
    await tester.ensureVisible(find.byType(PopupMenuButton<String>));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(PopupMenuButton<String>));
    await tester.pumpAndSettle();
    expect(find.text('Ubah target'), findsOneWidget);
    expect(find.text('Tandai tercapai'), findsOneWidget);
  });
}

extension on WidgetTester {
  Future<void> pumpGoalState() async {
    await pump();
    await pump();
    await pumpAndSettle();
  }
}

Widget goalTestApp(TestGoalRepository repository, {String? currentUserId}) {
  return ProviderScope(
    retry: noProviderRetry,
    overrides: [
      goalRepositoryProvider.overrideWithValue(repository),
      authControllerProvider.overrideWith(
        () => _SignedInAuthController(currentUserId),
      ),
    ],
    child: const MaterialApp(home: Scaffold(body: GoalScreen())),
  );
}

/// A signed-in [AuthController] that skips the token store / network so the
/// goal screen can resolve `auth.user?.id`. The member-row accept/reject
/// controls only render for the current user, so tests that exercise the invite
/// response must seed the matching id here.
class _SignedInAuthController extends AuthController {
  _SignedInAuthController(this.userId);

  final String? userId;

  @override
  AuthState build() {
    if (userId == null) return const AuthState.unauthenticated();
    return AuthState.authenticated(
      AuthUser(
        id: userId!,
        email: 'me@example.com',
        name: 'Me',
        avatarUrl: '',
        createdAt: '2026-06-01T00:00:00Z',
        updatedAt: '2026-06-01T00:00:00Z',
      ),
    );
  }
}

class TestGoalRepository implements GoalRepository {
  TestGoalRepository({List<Goal> goals = const [seedGoal]})
    : _goals = List<Goal>.of(goals);

  final List<Goal> _goals;
  final createdRequests = <GoalRequest>[];
  final inviteRequests = <GoalInviteRequest>[];
  final responseRequests = <GoalInviteResponseRequest>[];
  final statusRequests = <GoalStatusRequest>[];

  List<Goal> get goals => List<Goal>.unmodifiable(_goals);

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
  Future<Goal> updateGoalStatus(String id, GoalStatusRequest request) async {
    statusRequests.add(request);
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
    final index = _goals.indexWhere((goal) => goal.id == id);
    final goal = _goals[index];
    _goals[index] = goal.copyWithMembers(
      goal.members
          .map((member) {
            if (member.userId != userId) return member;
            return member.copyWith(status: request.status);
          })
          .toList(growable: false),
    );
  }
}

extension on Goal {
  Goal copyWithMembers(List<GoalMember> members) {
    return Goal(
      id: id,
      userId: userId,
      name: name,
      targetAmountMinor: targetAmountMinor,
      collectedAmountMinor: collectedAmountMinor,
      deadline: deadline,
      status: status,
      createdAt: createdAt,
      updatedAt: updatedAt,
      members: members,
    );
  }
}

extension on GoalMember {
  GoalMember copyWith({required GoalMemberStatus status}) {
    return GoalMember(
      goalId: goalId,
      userId: userId,
      status: status,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }
}

/// Finds a card painted solid in [color] (the AffluenaCard DecoratedBox whose
/// BoxDecoration carries the item's chosen color as its fill).
Finder _solidCard(Color color) {
  return find.byWidgetPredicate(
    (widget) =>
        widget is DecoratedBox &&
        widget.decoration is BoxDecoration &&
        (widget.decoration as BoxDecoration).color == color,
  );
}

/// A goal with a user-chosen color, so its row renders the solid colored
/// treatment.
const coloredGoal = Goal(
  id: 'goal-colored',
  userId: 'user-1',
  name: 'Dana Liburan',
  targetAmountMinor: 8000000,
  collectedAmountMinor: 2000000,
  deadline: null,
  status: GoalStatus.active,
  color: '#2E8B57',
  createdAt: '2026-06-01T00:00:00Z',
  updatedAt: '2026-06-01T00:00:00Z',
);

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
