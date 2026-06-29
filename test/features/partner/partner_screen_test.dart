import 'package:affluena_mobile/app/theme/affluena_theme.dart';
import 'package:affluena_mobile/core/api/api_error.dart';
import 'package:affluena_mobile/features/partner/application/partner_controller.dart';
import 'package:affluena_mobile/features/partner/data/partner_models.dart';
import 'package:affluena_mobile/features/partner/data/partner_repository.dart';
import 'package:affluena_mobile/features/partner/presentation/partner_screen.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakePartnerRepository implements PartnerRepository {
  _FakePartnerRepository(this.links);

  final List<PartnerLink> links;
  String? invitedEmail;

  @override
  Future<PartnerListResponse> list() async =>
      PartnerListResponse(partners: links);

  @override
  Future<void> invite(PartnerInviteRequest request) async {
    invitedEmail = request.email;
  }

  @override
  Future<void> respond(String id, PartnerRespondRequest request) async {}

  @override
  Future<void> revoke(String id) async {}
}

/// Repo whose invite() fails with a mapped ApiException at a given status,
/// mirroring what the Dio client produces from a server error response.
class _ThrowingPartnerRepository implements PartnerRepository {
  _ThrowingPartnerRepository(this.statusCode);

  final int statusCode;

  @override
  Future<PartnerListResponse> list() async =>
      const PartnerListResponse(partners: []);

  @override
  Future<void> invite(PartnerInviteRequest request) async {
    throw DioException(
      requestOptions: RequestOptions(path: '/partners/invites'),
      error: ApiException(message: 'conflict', statusCode: statusCode),
    );
  }

  @override
  Future<void> respond(String id, PartnerRespondRequest request) async {}

  @override
  Future<void> revoke(String id) async {}
}

const _budiJoined = PartnerLink(
  id: '1',
  direction: 'owned',
  status: 'joined',
  userId: 'u2',
  email: 'budi@example.com',
  name: 'Budi',
);

Future<void> _pump(WidgetTester tester, PartnerRepository repo) async {
  await tester.binding.setSurfaceSize(const Size(390, 844));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  await tester.pumpWidget(
    ProviderScope(
      overrides: [partnerRepositoryProvider.overrideWithValue(repo)],
      child: MaterialApp(
        theme: AffluenaTheme.light,
        home: const PartnerScreen(),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('shows the invite field when there is no partner yet', (
    tester,
  ) async {
    await _pump(tester, _FakePartnerRepository(const []));

    expect(find.widgetWithText(FilledButton, 'Undang'), findsOneWidget);
    expect(find.textContaining('Putuskan dulu'), findsNothing);
  });

  testWidgets('hides the invite field once a partner is linked', (
    tester,
  ) async {
    await _pump(tester, _FakePartnerRepository(const [_budiJoined]));

    expect(find.text('Budi'), findsOneWidget); // owned row display name
    expect(find.text('Terhubung'), findsOneWidget); // status pill
    // One-partner rule: cannot invite anyone else while linked.
    expect(find.widgetWithText(FilledButton, 'Undang'), findsNothing);
    expect(find.textContaining('Putuskan dulu'), findsOneWidget);
  });

  testWidgets('invites by email when there is no partner yet', (tester) async {
    final repo = _FakePartnerRepository(const []);

    await _pump(tester, repo);

    await tester.enterText(find.byType(TextField), 'new@example.com');
    await tester.tap(find.widgetWithText(FilledButton, 'Undang'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 5)); // flush success SnackBar
    await tester.pumpAndSettle();

    expect(repo.invitedEmail, 'new@example.com');
  });

  test('invite maps a 409 response to the partner-limit message', () async {
    final container = ProviderContainer(
      overrides: [
        partnerRepositoryProvider.overrideWithValue(
          _ThrowingPartnerRepository(409),
        ),
      ],
    );
    addTearDown(container.dispose);

    final notifier = container.read(partnerControllerProvider.notifier);
    // Let the build() microtask load() settle so it can't clear actionError
    // after the invite below.
    await Future<void>.delayed(Duration.zero);

    final ok = await notifier.invite('someone@example.com');

    expect(ok, isFalse);
    expect(
      container.read(partnerControllerProvider).actionError,
      contains('Putuskan dulu'),
    );
  });
}
