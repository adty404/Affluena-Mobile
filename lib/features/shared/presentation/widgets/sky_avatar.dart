import 'package:flutter/material.dart';

import '../../../../app/theme/sky_palette.dart';
import 'avatar_image.dart';

/// A small circular avatar showing a person's photo (when [imageUrl] resolves
/// — data:image base64 uploads and legacy http(s) URLs both work, see
/// [avatarImageProvider]) or their initial — used for shared-wallet members
/// and transaction authorship ("who logged it") in the redesign.
class SkyAvatar extends StatelessWidget {
  const SkyAvatar({
    required this.initial,
    this.imageUrl,
    this.color,
    this.size = 28,
    this.borderColor,
    super.key,
  });

  final String initial;

  /// Optional avatar source (`avatar_url`): a base64 data URL or http(s) URL.
  /// Falls back to [initial] when null/empty/unresolvable.
  final String? imageUrl;
  final Color? color;
  final double size;

  /// Optional ring, used when avatars overlap on a tinted surface.
  final Color? borderColor;

  @override
  Widget build(BuildContext context) {
    final fill = color ?? context.sky.avatarPrimary;
    final image = imageUrl == null ? null : avatarImageProvider(imageUrl!);
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: fill,
        shape: BoxShape.circle,
        border: borderColor == null
            ? null
            : Border.all(color: borderColor!, width: 2),
        image: image == null
            ? null
            : DecorationImage(image: image, fit: BoxFit.cover),
      ),
      child: image != null
          ? null
          : Text(
              initial,
              style: TextStyle(
                color: Colors.white,
                fontSize: size * 0.4,
                fontWeight: FontWeight.w700,
              ),
            ),
    );
  }
}
