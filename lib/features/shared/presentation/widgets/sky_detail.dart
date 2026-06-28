import 'package:flutter/material.dart';

import '../../../../app/theme/affluena_theme.dart';
import '../../../../app/theme/sky_palette.dart';

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
    super.key,
  });

  final String amount;
  final String? label;
  final String? sub;
  final Color? amountColor;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label != null) ...[
          Text(
            label!,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: context.sky.muted,
            ),
          ),
          const SizedBox(height: 3),
        ],
        Text(
          amount,
          style: TextStyle(
            fontSize: 30,
            fontWeight: FontWeight.w800,
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

/// A simple confirm dialog for a detail-screen action (pay / run). Returns
/// `true` when the user confirms.
Future<bool> skyConfirm(
  BuildContext context, {
  required String title,
  required String message,
  String confirmLabel = 'Lanjut',
}) async {
  final ok = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(title),
      content: Text(message),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Batal'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: Text(confirmLabel),
        ),
      ],
    ),
  );
  return ok ?? false;
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
