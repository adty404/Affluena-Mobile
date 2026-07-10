import 'dart:convert';

import 'package:flutter/painting.dart';

/// Resolves a stored `avatar_url` value into an [ImageProvider]:
///
/// - `data:image/...;base64,...` → [MemoryImage] (the avatar-upload format —
///   the picked photo is downscaled client-side and stored inline in the
///   existing `avatar_url` text column, no file storage server-side),
/// - absolute `http(s)` → [NetworkImage] (legacy URL avatars keep working),
/// - anything else (empty, malformed) → `null` so callers fall back to the
///   initial-letter avatar.
///
/// Decoded data-URLs are memoized so rebuilds reuse the identical
/// [MemoryImage] instance and the image cache isn't re-primed on every frame.
ImageProvider? avatarImageProvider(String url) {
  final value = url.trim();
  if (value.isEmpty) return null;
  if (value.startsWith('data:image/')) return _memoizedDataUrlImage(value);
  final uri = Uri.tryParse(value);
  if (uri != null &&
      uri.isAbsolute &&
      (uri.scheme == 'http' || uri.scheme == 'https')) {
    return NetworkImage(value);
  }
  return null;
}

const _kDataUrlCacheLimit = 4;
final _dataUrlImageCache = <String, MemoryImage>{};

MemoryImage? _memoizedDataUrlImage(String dataUrl) {
  final cached = _dataUrlImageCache[dataUrl];
  if (cached != null) return cached;

  const marker = ';base64,';
  final markerIndex = dataUrl.indexOf(marker);
  if (markerIndex < 0) return null;
  try {
    final image = MemoryImage(
      base64Decode(dataUrl.substring(markerIndex + marker.length)),
    );
    if (_dataUrlImageCache.length >= _kDataUrlCacheLimit) {
      _dataUrlImageCache.remove(_dataUrlImageCache.keys.first);
    }
    _dataUrlImageCache[dataUrl] = image;
    return image;
  } on FormatException {
    // Corrupt base64 payload: fall back to the initial-letter avatar.
    return null;
  }
}
