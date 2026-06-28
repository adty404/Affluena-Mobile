import 'package:flutter/material.dart';

import '../../../../app/theme/affluena_theme.dart';
import '../../../../app/theme/sky_palette.dart';

/// A wallet "room" card — the core building block of the redesign Home.
///
/// [leading] is composed by the caller (an icon tile, or an overlapping avatar
/// stack for a shared room). When [shared] is true the card uses the accent
/// tint + border. [footer] holds optional below-the-row content such as a
/// savings progress bar. Presentational: behaviour comes from [onTap] /
/// [onLongPress] (long-press is how quick-add opens in this wallet's context).
class SkyRoomCard extends StatelessWidget {
  const SkyRoomCard({
    required this.leading,
    required this.title,
    this.subtitle,
    this.badge,
    this.trailing,
    this.footer,
    this.shared = false,
    this.onTap,
    this.onLongPress,
    super.key,
  });

  final Widget leading;
  final String title;
  final String? subtitle;

  /// Small pill next to the title, e.g. "BERSAMA" on a shared room.
  final Widget? badge;
  final Widget? trailing;
  final Widget? footer;
  final bool shared;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(16);
    final titleRow = Row(
      children: [
        leading,
        const SizedBox(width: AffluenaSpacing.space3),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Flexible(
                    child: Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: context.sky.ink,
                      ),
                    ),
                  ),
                  if (badge != null) ...[
                    const SizedBox(width: AffluenaSpacing.space2),
                    badge!,
                  ],
                ],
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 2),
                Text(
                  subtitle!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 10.5, color: context.sky.faint),
                ),
              ],
            ],
          ),
        ),
        if (trailing != null) ...[
          const SizedBox(width: AffluenaSpacing.space2),
          trailing!,
        ],
      ],
    );

    return Material(
      color: shared ? context.sky.accentSoft : context.sky.surface,
      borderRadius: radius,
      child: InkWell(
        borderRadius: radius,
        onTap: onTap,
        onLongPress: onLongPress,
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AffluenaSpacing.space3,
            vertical: AffluenaSpacing.space3,
          ),
          decoration: BoxDecoration(
            borderRadius: radius,
            border: Border.all(
              color: shared ? context.sky.accentSoftBorder : context.sky.line,
            ),
          ),
          child: footer == null
              ? titleRow
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    titleRow,
                    const SizedBox(height: AffluenaSpacing.space3),
                    footer!,
                  ],
                ),
        ),
      ),
    );
  }
}
