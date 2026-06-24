import 'package:flutter/material.dart';

import '../../../../app/theme/affluena_theme.dart';

/// A single shimmering placeholder block used while content loads.
///
/// Honors the platform "reduce motion" accessibility setting: when motion is
/// disabled the block renders as a static tonal fill with no animation.
///
/// Prefer skeletons that mirror the shape of the real content over centered
/// spinners — they prevent layout jump and read as "loading this", not "busy".
class AffluenaSkeleton extends StatefulWidget {
  const AffluenaSkeleton({
    this.width,
    this.height = 16,
    this.radius = AffluenaRadii.md,
    super.key,
  });

  /// Convenience constructor for a single text-line placeholder.
  const AffluenaSkeleton.line({double width = double.infinity, double height = 12, Key? key})
    : this(width: width, height: height, radius: 6, key: key);

  /// Convenience constructor for a circular avatar/icon placeholder.
  const AffluenaSkeleton.circle({double size = 40, Key? key})
    : this(width: size, height: size, radius: AffluenaRadii.pill, key: key);

  final double? width;
  final double height;
  final double radius;

  @override
  State<AffluenaSkeleton> createState() => _AffluenaSkeletonState();
}

class _AffluenaSkeletonState extends State<AffluenaSkeleton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1200),
  );

  @override
  void initState() {
    super.initState();
    _controller.repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.affluenaColors;
    final base = colors.surfaceTintSoft;
    final highlight = Color.alphaBlend(
      colors.surfaceElevated.withAlpha(150),
      base,
    );
    final reduceMotion = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    final radius = BorderRadius.circular(widget.radius);

    if (reduceMotion) {
      return SizedBox(
        width: widget.width,
        height: widget.height,
        child: DecoratedBox(
          decoration: BoxDecoration(color: base, borderRadius: radius),
        ),
      );
    }

    return SizedBox(
      width: widget.width,
      height: widget.height,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          return DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: radius,
              gradient: LinearGradient(
                colors: [base, highlight, base],
                stops: const [0.1, 0.5, 0.9],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                transform: _SlideGradient(_controller.value),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _SlideGradient extends GradientTransform {
  const _SlideGradient(this.t);

  final double t;

  @override
  Matrix4 transform(Rect bounds, {TextDirection? textDirection}) {
    // Sweep the highlight from off-screen left to off-screen right.
    final dx = (t * 2 - 1) * bounds.width;
    return Matrix4.translationValues(dx, 0, 0);
  }
}
