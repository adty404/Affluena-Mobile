import 'package:flutter/material.dart';

import '../../../../app/theme/sky_palette.dart';

/// A thin rounded progress track — e.g. a savings goal's completion on a room
/// card. [value] is clamped to 0..1.
class SkyProgressBar extends StatelessWidget {
  const SkyProgressBar({
    required this.value,
    this.height = 6,
    this.trackColor,
    this.fillColor,
    super.key,
  });

  final double value;
  final double height;
  final Color? trackColor;
  final Color? fillColor;

  @override
  Widget build(BuildContext context) {
    final track = trackColor ?? context.sky.ground;
    final fill = fillColor ?? context.sky.accent;
    final clamped = value.clamp(0.0, 1.0);
    final radius = BorderRadius.circular(height);
    return ClipRRect(
      borderRadius: radius,
      child: Stack(
        children: [
          Container(height: height, width: double.infinity, color: track),
          FractionallySizedBox(
            widthFactor: clamped,
            child: Container(
              height: height,
              decoration: BoxDecoration(color: fill, borderRadius: radius),
            ),
          ),
        ],
      ),
    );
  }
}
