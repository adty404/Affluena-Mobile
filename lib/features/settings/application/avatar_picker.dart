import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

/// The [ImagePicker] behind the avatar "Pilih foto" flow, wrapped in a
/// provider so widget tests can override it with a fake instead of hitting
/// the platform photo-picker channel.
final imagePickerProvider = Provider<ImagePicker>((ref) => ImagePicker());

/// The bytes → data-URL encoder the sheet calls, injectable for the same
/// reason: the real [encodeAvatarDataUrl] awaits engine image codecs, which
/// never complete inside a widget test's FakeAsync zone (they'd need
/// `tester.runAsync`). Hermetic widget tests override this with a pure-Dart
/// fake; the real encoder keeps its own plain unit tests.
final avatarEncoderProvider =
    Provider<Future<String?> Function(Uint8List bytes)>(
      (ref) => encodeAvatarDataUrl,
    );

/// Longest allowed side of a stored avatar, in pixels.
const kAvatarMaxDimension = 256;

/// Upper bound for the encoded avatar bytes (~120KB). The data URL lands in
/// the API's unbounded `avatar_url` text column, but it also rides along on
/// every `/auth/me` response — keep it small.
const kAvatarMaxBytes = 120 * 1024;

/// Turns picked image [bytes] into a base64 `data:image/...;base64,` URL for
/// the `avatar_url` field:
///
/// - bytes already within [kAvatarMaxDimension] px and [kAvatarMaxBytes] (the
///   normal case — `pickImage` is called with `maxWidth`/`maxHeight` 256 and
///   `imageQuality` 80, so the platform returns a small JPEG) pass through
///   unchanged with their detected mime;
/// - anything larger is decoded and downscaled in Dart
///   (`ImageDescriptor.instantiateCodec`, aspect ratio preserved) and
///   re-encoded, shrinking further until it fits under [kAvatarMaxBytes];
/// - undecodable input returns `null` so the caller can show an error.
Future<String?> encodeAvatarDataUrl(Uint8List bytes) async {
  if (bytes.isEmpty) return null;

  ui.ImageDescriptor descriptor;
  try {
    final buffer = await ui.ImmutableBuffer.fromUint8List(bytes);
    descriptor = await ui.ImageDescriptor.encoded(buffer);
  } catch (_) {
    return null; // Not a decodable image.
  }

  final width = descriptor.width;
  final height = descriptor.height;
  final mime = _detectImageMime(bytes);

  // Fast path: the platform picker already delivered a small enough image.
  if (mime != null &&
      bytes.lengthInBytes <= kAvatarMaxBytes &&
      width <= kAvatarMaxDimension &&
      height <= kAvatarMaxDimension) {
    descriptor.dispose();
    return 'data:$mime;base64,${base64Encode(bytes)}';
  }

  // Downscale so the longest side is at most the target, preserving aspect
  // ratio, and re-encode. dart:ui can only encode PNG, so retry at smaller
  // dimensions until the payload fits (real photos fit on the first pass).
  try {
    for (var target = kAvatarMaxDimension; target >= 64; target ~/= 2) {
      final scale = target / (width > height ? width : height);
      final targetWidth = (width * scale).round().clamp(1, target);
      final targetHeight = (height * scale).round().clamp(1, target);
      final codec = await descriptor.instantiateCodec(
        targetWidth: targetWidth,
        targetHeight: targetHeight,
      );
      final frame = await codec.getNextFrame();
      final encoded = await frame.image.toByteData(
        format: ui.ImageByteFormat.png,
      );
      frame.image.dispose();
      codec.dispose();
      if (encoded == null) return null;
      if (encoded.lengthInBytes <= kAvatarMaxBytes) {
        return 'data:image/png;base64,'
            '${base64Encode(encoded.buffer.asUint8List(0, encoded.lengthInBytes))}';
      }
    }
    return null;
  } catch (_) {
    return null;
  } finally {
    descriptor.dispose();
  }
}

/// Best-effort magic-byte sniffing for the formats the photo picker can
/// return. Unknown formats force the downscale/re-encode path so the stored
/// data URL always carries a mime browsers/apps understand.
String? _detectImageMime(Uint8List bytes) {
  if (bytes.length < 12) return null;
  if (bytes[0] == 0xFF && bytes[1] == 0xD8 && bytes[2] == 0xFF) {
    return 'image/jpeg';
  }
  if (bytes[0] == 0x89 && bytes[1] == 0x50 && bytes[2] == 0x4E) {
    return 'image/png';
  }
  if (bytes[0] == 0x47 && bytes[1] == 0x49 && bytes[2] == 0x46) {
    return 'image/gif';
  }
  if (bytes[0] == 0x52 &&
      bytes[1] == 0x49 &&
      bytes[2] == 0x46 &&
      bytes[3] == 0x46 &&
      bytes[8] == 0x57 &&
      bytes[9] == 0x45 &&
      bytes[10] == 0x42 &&
      bytes[11] == 0x50) {
    return 'image/webp';
  }
  return null;
}
