import 'package:affluena_mobile/app/theme/affluena_theme.dart';
import 'package:affluena_mobile/features/partner/data/partner_models.dart';
import 'package:affluena_mobile/features/partner/data/partner_repository.dart';
import 'package:affluena_mobile/features/partner/presentation/partner_screen.dart';
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
  testWidgets('lists my partners and the invite field', (tester) async {
    final repo = _FakePartnerRepository(const [
      PartnerLink(
        id: '1',
        direction: 'owned',
        status: 'joined',
        userId: 'u2',
        email: 'budi@example.com',
        name: 'Budi',
      ),
    ]);

    await _pump(tester, repo);

    expect(find.text('Pasangan'), findsOneWidget); // app bar title
    expect(find.text('Budi'), findsOneWidget); // owned row display name
    expect(find.text('Terhubung'), findsOneWidget); // status pill
    expect(find.widgetWithText(FilledButton, 'Undang'), findsOneWidget);
  });

  testWidgets('invites by email', (tester) async {
    final repo = _FakePartnerRepository(const []);

    await _pump(tester, repo);

    await tester.enterText(find.byType(TextField), 'new@example.com');
    await tester.tap(find.widgetWithText(FilledButton, 'Undang'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 5)); // flush success SnackBar
    await tester.pumpAndSettle();

    expect(repo.invitedEmail, 'new@example.com');
  });
}
