import 'package:flutter/material.dart';

import '../../../../app/theme/affluena_theme.dart';
import '../../../../app/theme/sky_palette.dart';

/// The app-wide empty state: an icon over a short title, an optional
/// subtitle, and an optional call-to-action so an empty list always says what
/// to do next.
///
/// Colours default to the Tinta `context.sky.*` tokens (which resolve to the
/// same monochrome palette the `affluenaColors` feature screens use); a
/// feature screen may pass `affluenaColors`-derived overrides when it needs a
/// different emphasis.
class EmptyState extends StatelessWidget {
  const EmptyState({
    required this.icon,
    required this.title,
    this.subtitle,
    this.actionLabel,
    this.onAction,
    this.actionIcon = Icons.add,
    this.iconColor,
    this.titleColor,
    this.subtitleColor,
    super.key,
  }) : onTap = null,
       _compact = false;

  /// Compact single-row variant for inline dashboard sections: a slim
  /// tappable tile (icon · label · chevron) that keeps dense layouts calm.
  /// Tapping it opens the screen where the first item can be created.
  const EmptyState.compact({
    required this.title,
    required VoidCallback this.onTap,
    this.icon = Icons.add_circle_outline,
    super.key,
  }) : subtitle = null,
       actionLabel = null,
       onAction = null,
       actionIcon = Icons.add,
       iconColor = null,
       titleColor = null,
       subtitleColor = null,
       _compact = true;

  final IconData icon;
  final String title;
  final String? subtitle;

  /// CTA shown under the text (full variant only). Rendered only when both
  /// [actionLabel] and [onAction] are provided.
  final String? actionLabel;
  final VoidCallback? onAction;
  final IconData actionIcon;

  /// Compact-variant tap target (the whole tile).
  final VoidCallback? onTap;

  final Color? iconColor;
  final Color? titleColor;
  final Color? subtitleColor;

  final bool _compact;

  @override
  Widget build(BuildContext context) {
    return _compact ? _buildCompact(context) : _buildFull(context);
  }

  Widget _buildFull(BuildContext context) {
    final sky = context.sky;
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AffluenaSpacing.space4,
        vertical: AffluenaSpacing.space6,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 40, color: iconColor ?? sky.faint),
          const SizedBox(height: AffluenaSpacing.space3),
          Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: titleColor ?? sky.ink,
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: AffluenaSpacing.space1),
            Text(
              subtitle!,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12.5,
                color: subtitleColor ?? sky.muted,
              ),
            ),
          ],
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(height: AffluenaSpacing.space4),
            FilledButton.icon(
              onPressed: onAction,
              icon: Icon(actionIcon, size: 18),
              label: Text(actionLabel!),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCompact(BuildContext context) {
    final sky = context.sky;
    return Material(
      color: sky.sheet,
      borderRadius: BorderRadius.circular(AffluenaRadii.control),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AffluenaRadii.control),
        child: Container(
          decoration: BoxDecoration(
            border: Border.all(color: sky.line),
            borderRadius: BorderRadius.circular(AffluenaRadii.control),
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: AffluenaSpacing.space4,
          ),
          child: Row(
            children: [
              Icon(icon, size: 18, color: sky.faint),
              const SizedBox(width: AffluenaSpacing.space2),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(fontSize: 12.5, color: sky.muted),
                ),
              ),
              Icon(Icons.chevron_right, size: 16, color: sky.faint),
            ],
          ),
        ),
      ),
    );
  }
}
