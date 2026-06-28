import 'package:flutter/material.dart';

import '../../../../app/theme/sky_palette.dart';

/// A small circular avatar showing a person's initial — used for shared-wallet
/// members and transaction authorship ("who logged it") in the redesign.
class SkyAvatar extends StatelessWidget {
  const SkyAvatar({
    required this.initial,
    this.color = SkyPalette.avatarPrimary,
    this.size = 28,
    this.borderColor,
    super.key,
  });

  final String initial;
  final Color color;
  final double size;

  /// Optional ring, used when avatars overlap on a tinted surface.
  final Color? borderColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: borderColor == null
            ? null
            : Border.all(color: borderColor!, width: 2),
      ),
      child: Text(
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
