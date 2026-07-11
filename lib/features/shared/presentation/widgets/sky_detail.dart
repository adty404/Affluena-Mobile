import 'package:flutter/material.dart';

import '../../../../app/theme/affluena_theme.dart';
import '../../../../app/theme/sky_palette.dart';
import '../../../../core/haptics.dart';

/// Shared building blocks for the Sky & Denim per-item **detail** screens
/// (budget / goal / installment / subscription / recurring). They give every
/// detail page the same hero + status treatment shown in the design guide.

/// The big money hero at the top of a detail screen: an optional eyebrow label,
/// a heavy tabular amount, and an optional sub line.
class SkyDetailHero extends StatelessWidget {
  const SkyDetailHero({
    required this.amount,
    this.label,
    this.sub,
    this.amountColor,
    this.accent,
    super.key,
  });

  final String amount;
  final String? label;
  final String? sub;
  final Color? amountColor;

  /// Optional item accent (a user-chosen colour): shown as a small swatch
  /// beside the eyebrow label. The amount itself stays ink/white so the hero
  /// remains legible in both brightnesses.
  final Color? accent;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label != null) ...[
          Row(
            children: [
              if (accent != null) ...[
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: accent,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
                const SizedBox(width: 6),
              ],
              Text(
                label!,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: context.sky.muted,
                ),
              ),
            ],
          ),
          const SizedBox(height: 3),
        ],
        Text(
          amount,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.5,
            color: amountColor ?? context.sky.ink,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
        if (sub != null) ...[
          const SizedBox(height: 5),
          Text(
            sub!,
            style: TextStyle(fontSize: 12.5, color: context.sky.muted),
          ),
        ],
      ],
    );
  }
}

/// The app-wide confirmation surface: a Tinta-style modal bottom sheet
/// (rounded top + drag handle from the app's sheet theme) with a soft-tinted
/// leading icon tile, a heavy title, a muted message, and stacked full-width
/// confirm-over-cancel actions. Returns `true` when the user confirms;
/// dismissing the sheet counts as cancel.
///
/// Pass [danger] for destructive confirmations (delete / cancel / revoke /
/// sign-out): the icon tile and the confirm button switch to the coral danger
/// colour. [icon] overrides the default glyph (a question mark, or a warning
/// triangle when [danger]). Every confirmation in the app must route through
/// this — never hand-roll an `AlertDialog` confirm.
Future<bool> skyConfirm(
  BuildContext context, {
  required String title,
  required String message,
  String confirmLabel = 'Lanjut',
  String cancelLabel = 'Batal',
  bool danger = false,
  IconData? icon,
}) async {
  final ok = await showModalBottomSheet<bool>(
    context: context,
    useSafeArea: true,
    // Size to the content (short viewports would otherwise clamp the sheet to
    // a fraction of the screen and overflow); the body scrolls as a fallback.
    isScrollControlled: true,
    builder: (context) => _SkyConfirmSheet(
      title: title,
      message: message,
      confirmLabel: confirmLabel,
      cancelLabel: cancelLabel,
      danger: danger,
      icon: icon,
    ),
  );
  return ok ?? false;
}

class _SkyConfirmSheet extends StatelessWidget {
  const _SkyConfirmSheet({
    required this.title,
    required this.message,
    required this.confirmLabel,
    required this.cancelLabel,
    required this.danger,
    required this.icon,
  });

  final String title;
  final String message;
  final String confirmLabel;
  final String cancelLabel;
  final bool danger;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final sky = context.sky;
    final tone = danger ? sky.danger : sky.accent;
    return SafeArea(
      top: false,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(
          AffluenaSpacing.space5,
          AffluenaSpacing.space2,
          AffluenaSpacing.space5,
          AffluenaSpacing.space5,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 48,
              height: 48,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: tone.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(AffluenaRadii.lg),
              ),
              child: Icon(
                icon ??
                    (danger ? Icons.warning_amber_rounded : Icons.help_outline),
                size: 24,
                color: tone,
              ),
            ),
            const SizedBox(height: AffluenaSpacing.space4),
            Text(
              title,
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: sky.ink,
              ),
            ),
            const SizedBox(height: AffluenaSpacing.space2),
            Text(
              message,
              style: TextStyle(fontSize: 14, height: 1.4, color: sky.muted),
            ),
            const SizedBox(height: AffluenaSpacing.space6),
            FilledButton(
              key: const Key('sky-confirm-accept'),
              // The danger fill keeps the theme's foreground (never a
              // hardcoded white — that would break dark mode).
              style: danger
                  ? FilledButton.styleFrom(backgroundColor: sky.danger)
                  : null,
              onPressed: () {
                hapticTap();
                Navigator.of(context).pop(true);
              },
              child: Text(confirmLabel),
            ),
            const SizedBox(height: AffluenaSpacing.space2),
            SizedBox(
              width: double.infinity,
              child: TextButton(
                key: const Key('sky-confirm-cancel'),
                onPressed: () => Navigator.of(context).pop(false),
                child: Text(cancelLabel),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Loading / not-found body for a detail screen while the owning controller is
/// still fetching (or when the item id can't be resolved).
class SkyDetailPlaceholder extends StatelessWidget {
  const SkyDetailPlaceholder({
    required this.loading,
    required this.message,
    super.key,
  });

  final bool loading;
  final String message;

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return Center(
        child: CircularProgressIndicator(color: context.sky.accent),
      );
    }
    return Center(
      child: Padding(
        padding: AffluenaInsets.screen,
        child: Text(
          message,
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 14, color: context.sky.muted),
        ),
      ),
    );
  }
}

/// A compact status pill colored by semantic meaning (not the brand accent).
class SkyStatusPill extends StatelessWidget {
  const SkyStatusPill({required this.label, required this.color, super.key});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AffluenaRadii.pill),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }
}

/// A bordered card section used to group detail content (e.g. a meta panel or a
/// list) on the cool ground.
class SkyDetailCard extends StatelessWidget {
  const SkyDetailCard({required this.child, this.padding, super.key});

  final Widget child;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: padding ?? const EdgeInsets.all(AffluenaSpacing.space4),
      decoration: BoxDecoration(
        color: context.sky.surface,
        border: Border.all(color: context.sky.line),
        borderRadius: BorderRadius.circular(AffluenaRadii.card),
      ),
      child: child,
    );
  }
}

/// A label/value row inside a [SkyDetailCard].
class SkyDetailRow extends StatelessWidget {
  const SkyDetailRow({
    required this.label,
    required this.value,
    this.valueColor,
    super.key,
  });

  final String label;
  final String value;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Text(
            label,
            style: TextStyle(fontSize: 13, color: context.sky.muted),
          ),
        ),
        const SizedBox(width: AffluenaSpacing.space3),
        Text(
          value,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: valueColor ?? context.sky.ink,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
      ],
    );
  }
}
