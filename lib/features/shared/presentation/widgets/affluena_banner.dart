import 'package:flutter/material.dart';

import '../../../../app/theme/affluena_theme.dart';

enum AffluenaBannerTone { error, success, warning, info }

/// Inline status banner using the semantic tone tokens. Errors read as errors
/// (coral), not as a neutral tint, and can carry an actionable retry/dismiss.
class AffluenaBanner extends StatelessWidget {
  const AffluenaBanner({
    required this.message,
    this.tone = AffluenaBannerTone.error,
    this.onRetry,
    this.onDismiss,
    this.retryLabel = 'Coba lagi',
    super.key,
  });

  const AffluenaBanner.error(String message, {VoidCallback? onRetry, Key? key})
    : this(message: message, tone: AffluenaBannerTone.error, onRetry: onRetry, key: key);

  const AffluenaBanner.success(String message, {VoidCallback? onDismiss, Key? key})
    : this(message: message, tone: AffluenaBannerTone.success, onDismiss: onDismiss, key: key);

  final String message;
  final AffluenaBannerTone tone;
  final VoidCallback? onRetry;
  final VoidCallback? onDismiss;
  final String retryLabel;

  ({Color accent, IconData icon}) _resolve(AffluenaSemanticColors c) {
    switch (tone) {
      case AffluenaBannerTone.error:
        return (accent: c.coral, icon: Icons.error_outline);
      case AffluenaBannerTone.success:
        return (accent: c.success, icon: Icons.check_circle_outline);
      case AffluenaBannerTone.warning:
        return (accent: c.amber, icon: Icons.warning_amber_outlined);
      case AffluenaBannerTone.info:
        return (accent: c.forest, icon: Icons.info_outline);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.affluenaColors;
    final textTheme = Theme.of(context).textTheme;
    final spec = _resolve(colors);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: Color.alphaBlend(spec.accent.withAlpha(28), colors.surfaceSoft),
        borderRadius: BorderRadius.circular(AffluenaRadii.lg),
        border: Border.all(color: spec.accent.withAlpha(90)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AffluenaSpacing.space3),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(spec.icon, color: spec.accent, size: 20),
            const SizedBox(width: AffluenaSpacing.space3),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 1),
                    child: Text(
                      message,
                      style: textTheme.bodyMedium?.copyWith(color: colors.ink),
                    ),
                  ),
                  if (onRetry != null) ...[
                    const SizedBox(height: AffluenaSpacing.space2),
                    InkWell(
                      onTap: onRetry,
                      borderRadius: BorderRadius.circular(AffluenaRadii.md),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          vertical: AffluenaSpacing.space1,
                        ),
                        child: Text(
                          retryLabel,
                          style: textTheme.labelMedium?.copyWith(
                            color: spec.accent,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (onDismiss != null)
              GestureDetector(
                onTap: onDismiss,
                behavior: HitTestBehavior.opaque,
                child: Padding(
                  padding: const EdgeInsets.only(left: AffluenaSpacing.space2),
                  child: Icon(Icons.close, color: colors.inkMuted, size: 18),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
