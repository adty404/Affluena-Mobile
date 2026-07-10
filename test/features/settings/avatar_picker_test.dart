import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:affluena_mobile/app/provider_retry.dart';
import 'package:affluena_mobile/app/theme/affluena_theme.dart';
import 'package:affluena_mobile/core/storage/secure_token_store.dart';
import 'package:affluena_mobile/features/auth/data/auth_models.dart';
import 'package:affluena_mobile/features/auth/data/auth_repository.dart';
import 'package:affluena_mobile/features/settings/application/avatar_picker.dart';
import 'package:affluena_mobile/features/settings/presentation/account_settings_sheet.dart';
import 'package:affluena_mobile/features/shared/presentation/widgets/avatar_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';

import '../../helpers/auth_test_helpers.dart';

/// Renders a solid-colored [width]x[height] PNG in-memory — a deterministic
/// stand-in for a picked photo.
Future<Uint8List> _pngBytes(int width, int height) async {
  final recorder = ui.PictureRecorder();
  ui.Canvas(recorder).drawRect(
    ui.Rect.fromLTWH(0, 0, width.toDouble(), height.toDouble()),
    ui.Paint()..color = const ui.Color(0xFF3E72B8),
  );
  final image = await recorder.endRecording().toImage(width, height);
  final data = await image.toByteData(format: ui.ImageByteFormat.png);
  image.dispose();
  return data!.buffer.asUint8List();
}

Future<(int, int)> _decodedSize(String dataUrl) async {
  final base64Payload = dataUrl.substring(dataUrl.indexOf(';base64,') + 8);
  final codec = await ui.instantiateImageCodec(base64Decode(base64Payload));
  final frame = await codec.getNextFrame();
  final size = (frame.image.width, frame.image.height);
  frame.image.dispose();
  codec.dispose();
  return size;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('encodeAvatarDataUrl', () {
    test('passes small images through with their detected mime', () async {
      final bytes = await _pngBytes(64, 48);
      final dataUrl = await encodeAvatarDataUrl(bytes);

      expect(dataUrl, isNotNull);
      expect(dataUrl, startsWith('data:image/png;base64,'));
      // Small enough already: the exact bytes survive round-trip.
      expect(
        base64Decode(dataUrl!.substring(dataUrl.indexOf(';base64,') + 8)),
        bytes,
      );
    });

    test('downscales oversized images to at most 256px, keeping aspect '
        'ratio and staying under the byte cap', () async {
      final bytes = await _pngBytes(1024, 512);
      final dataUrl = await encodeAvatarDataUrl(bytes);

      expect(dataUrl, isNotNull);
      expect(dataUrl, startsWith('data:image/'));
      final (width, height) = await _decodedSize(dataUrl!);
      expect(width, kAvatarMaxDimension);
      expect(height, kAvatarMaxDimension ~/ 2); // 2:1 aspect preserved.
      // The data-URL payload respects the transport cap.
      final payloadBytes = base64Decode(
        dataUrl.substring(dataUrl.indexOf(';base64,') + 8),
      );
      expect(payloadBytes.length, lessThanOrEqualTo(kAvatarMaxBytes));
    });

    test('rejects undecodable bytes', () async {
      expect(
        await encodeAvatarDataUrl(Uint8List.fromList([1, 2, 3, 4])),
        isNull,
      );
      expect(await encodeAvatarDataUrl(Uint8List(0)), isNull);
    });
  });

  group('avatarImageProvider', () {
    test('resolves data URLs, http(s) URLs, and rejects the rest', () async {
      final bytes = await _pngBytes(8, 8);
      final dataUrl = 'data:image/png;base64,${base64Encode(bytes)}';

      expect(avatarImageProvider(dataUrl), isA<MemoryImage>());
      // Memoized: the same url yields the identical provider instance so the
      // image cache isn't re-primed on rebuilds.
      expect(
        identical(avatarImageProvider(dataUrl), avatarImageProvider(dataUrl)),
        isTrue,
      );
      expect(
        avatarImageProvider('https://contoh.com/foto.jpg'),
        isA<NetworkImage>(),
      );
      expect(avatarImageProvider(''), isNull);
      expect(avatarImageProvider('bukan-url'), isNull);
      expect(avatarImageProvider('data:image/png;base64,%%%'), isNull);
    });
  });

  group('account sheet avatar picking', () {
    testWidgets('picking a photo stores the encoded data URL into avatar_url', (
      tester,
    ) async {
      // Pure-Dart picked bytes + encoder: the REAL encoder awaits engine
      // image codecs, which never complete inside a widget test's FakeAsync
      // zone — its behavior is covered by the plain unit tests above; this
      // test proves the pick → encode → save WIRING.
      final authRepository = FakeAuthRepository();
      final pickedBytes = Uint8List.fromList(List.generate(16, (i) => i));
      final encoded = <Uint8List>[];
      // A decodable payload: the sheet preview renders the returned data URL
      // through a MemoryImage, so it must be a real image.
      final encodedDataUrl = _userWithLegacyAvatar.avatarUrl;

      await _pumpSheet(
        tester,
        authRepository: authRepository,
        picker: _FakeImagePicker(pickedBytes),
        encoder: (bytes) async {
          encoded.add(bytes);
          return encodedDataUrl;
        },
      );

      await tester.tap(find.byKey(const Key('settings-avatar-pick-button')));
      await tester.pumpAndSettle();
      expect(find.text('Memproses...'), findsNothing);

      await tester.tap(find.byKey(const Key('settings-account-save-button')));
      await tester.pumpAndSettle();

      // The picker's bytes went through the encoder and the resulting data
      // URL was saved into the existing avatar_url field.
      expect(encoded.single, pickedBytes);
      final request = authRepository.updateAccountRequests.single;
      expect(request.avatarUrl, encodedDataUrl);
    });

    testWidgets('an unprocessable photo shows an error and saves nothing', (
      tester,
    ) async {
      final authRepository = FakeAuthRepository();

      await _pumpSheet(
        tester,
        authRepository: authRepository,
        picker: _FakeImagePicker(Uint8List.fromList([1, 2, 3])),
        encoder: (_) async => null,
      );

      await tester.tap(find.byKey(const Key('settings-avatar-pick-button')));
      await tester.pumpAndSettle();

      expect(
        find.text('Foto tidak dapat diproses. Coba foto yang lain.'),
        findsOneWidget,
      );
      await tester.tap(find.byKey(const Key('settings-account-save-button')));
      await tester.pumpAndSettle();
      expect(authRepository.updateAccountRequests.single.avatarUrl, isEmpty);
    });

    testWidgets('Hapus foto clears the stored avatar', (tester) async {
      final authRepository = FakeAuthRepository(meUser: _userWithLegacyAvatar);

      await _pumpSheet(
        tester,
        authRepository: authRepository,
        picker: _FakeImagePicker(Uint8List(0)),
        user: _userWithLegacyAvatar,
      );

      await tester.tap(find.byKey(const Key('settings-avatar-remove-button')));
      await tester.pump();
      await tester.tap(find.byKey(const Key('settings-account-save-button')));
      await tester.pumpAndSettle();

      expect(authRepository.updateAccountRequests.single.avatarUrl, isEmpty);
    });

    testWidgets('a dismissed picker leaves the avatar untouched', (
      tester,
    ) async {
      final authRepository = FakeAuthRepository();

      await _pumpSheet(
        tester,
        authRepository: authRepository,
        picker: _FakeImagePicker(null),
      );

      await tester.tap(find.byKey(const Key('settings-avatar-pick-button')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('settings-account-save-button')));
      await tester.pumpAndSettle();

      expect(authRepository.updateAccountRequests.single.avatarUrl, isEmpty);
    });
  });
}

/// An account that already has a stored avatar (a 1x1 PNG data URL — a
/// NetworkImage here would hit the test binding's blocked HTTP client).
const _userWithLegacyAvatar = AuthUser(
  id: '11111111-1111-1111-1111-111111111111',
  email: 'demo@affluena.com',
  name: 'Demo User',
  avatarUrl:
      'data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJ'
      'AAAADUlEQVR42mP8z8BQDwAEhQGAhKmMIQAAAABJRU5ErkJggg==',
  createdAt: '2026-06-01T00:00:00Z',
  updatedAt: '2026-06-01T00:00:00Z',
);

Future<void> _pumpSheet(
  WidgetTester tester, {
  required FakeAuthRepository authRepository,
  required ImagePicker picker,
  Future<String?> Function(Uint8List bytes)? encoder,
  AuthUser? user,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      retry: noProviderRetry,
      overrides: [
        authRepositoryProvider.overrideWithValue(authRepository),
        secureTokenStoreProvider.overrideWithValue(MemoryTokenStore()),
        imagePickerProvider.overrideWithValue(picker),
        if (encoder != null) avatarEncoderProvider.overrideWithValue(encoder),
      ],
      child: MaterialApp(
        theme: AffluenaTheme.light,
        home: Scaffold(
          body: Builder(
            builder: (context) => Center(
              child: FilledButton(
                onPressed: () =>
                    showAccountSettingsSheet(context, user ?? demoUser),
                child: const Text('Buka'),
              ),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('Buka'));
  await tester.pumpAndSettle();
}

/// A hermetic [ImagePicker]: returns [bytes] as the picked file (or null for
/// a dismissed picker) without touching the platform channel.
class _FakeImagePicker extends ImagePicker {
  _FakeImagePicker(this.bytes);

  final Uint8List? bytes;
  final pickCalls = <({double? maxWidth, double? maxHeight, int? quality})>[];

  @override
  Future<XFile?> pickImage({
    required ImageSource source,
    double? maxWidth,
    double? maxHeight,
    int? imageQuality,
    CameraDevice preferredCameraDevice = CameraDevice.rear,
    bool requestFullMetadata = true,
  }) async {
    pickCalls.add((
      maxWidth: maxWidth,
      maxHeight: maxHeight,
      quality: imageQuality,
    ));
    final data = bytes;
    if (data == null || data.isEmpty) return null;
    return XFile.fromData(data, name: 'avatar.png', mimeType: 'image/png');
  }
}
