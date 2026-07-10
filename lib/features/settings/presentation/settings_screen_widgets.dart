import 'package:flutter/material.dart';

import '../../../app/theme/affluena_theme.dart';
import '../../auth/data/auth_models.dart';
import '../../shared/presentation/widgets/affluena_card.dart';
import '../../shared/presentation/widgets/affluena_skeleton.dart';
import '../../shared/presentation/widgets/avatar_image.dart';

class SettingsProfileCard extends StatelessWidget {
  const SettingsProfileCard({
    required this.user,
    required this.isLoading,
    super.key,
  });

  final AuthUser? user;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    // First load with no cached user yet: show a skeleton mirroring the card
    // layout instead of placeholder text + a progress bar.
    if (user == null && isLoading) {
      return const _SettingsProfileCardSkeleton();
    }

    final textTheme = Theme.of(context).textTheme;
    final colors = context.affluenaColors;
    // A brand-new account has an empty name — never render the brand
    // "Affluena" as if it were the user's name; show a muted placeholder and
    // derive the avatar initial from the email's local part instead.
    final hasName = user?.name.trim().isNotEmpty == true;
    final displayName = hasName ? user!.name : 'Atur nama kamu';
    final email = user?.email;
    final initialSource = hasName
        ? user!.name.trim()
        : (email?.split('@').first ?? '');
    final initial = initialSource.isEmpty
        ? 'A'
        : initialSource.characters.first.toUpperCase();
    // Uploaded avatars are stored as data:image base64 URLs; legacy http(s)
    // URLs still resolve. Either way the initial stays as the fallback while
    // (or if) the image can't render.
    final avatarImage = user == null
        ? null
        : avatarImageProvider(user!.avatarUrl);

    return Semantics(
      container: true,
      child: AffluenaCard(
        child: Column(
          children: [
            Row(
              children: [
                ExcludeSemantics(
                  child: CircleAvatar(
                    radius: 28,
                    backgroundColor: colors.forest,
                    foregroundImage: avatarImage,
                    child: Text(
                      initial,
                      style: textTheme.titleLarge?.copyWith(
                        color: colors.surfaceCanvas,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: AffluenaSpacing.space4),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        displayName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: hasName
                            ? textTheme.titleMedium
                            : textTheme.titleMedium?.copyWith(
                                color: colors.inkMuted,
                              ),
                      ),
                      if (email != null) ...[
                        const SizedBox(height: AffluenaSpacing.space1),
                        Text(
                          email,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: textTheme.bodySmall,
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SettingsProfileCardSkeleton extends StatelessWidget {
  const _SettingsProfileCardSkeleton();

  @override
  Widget build(BuildContext context) {
    return AffluenaCard(
      child: Row(
        children: const [
          AffluenaSkeleton.circle(size: 56),
          SizedBox(width: AffluenaSpacing.space4),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AffluenaSkeleton.line(width: 140, height: 16),
                SizedBox(height: AffluenaSpacing.space2),
                AffluenaSkeleton.line(width: 200),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class SettingsRow extends StatelessWidget {
  const SettingsRow({
    required this.icon,
    required this.title,
    required this.value,
    required this.onTap,
    super.key,
  });

  final IconData icon;
  final String title;
  final String value;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colors = context.affluenaColors;
    final enabled = onTap != null;

    return Semantics(
      button: true,
      enabled: enabled,
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AffluenaRadii.md),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 64),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                vertical: AffluenaSpacing.space2,
              ),
              child: Row(
                children: [
                  DecoratedBox(
                    decoration: BoxDecoration(
                      color: enabled
                          ? colors.forestSoft
                          : colors.surfaceTintSoft,
                      borderRadius: BorderRadius.circular(AffluenaRadii.md),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(AffluenaSpacing.space2),
                      child: Icon(
                        icon,
                        color: enabled ? colors.forest : colors.inkMuted,
                        size: 18,
                      ),
                    ),
                  ),
                  const SizedBox(width: AffluenaSpacing.space3),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: textTheme.bodyLarge?.copyWith(
                            color: enabled ? colors.ink : colors.inkMuted,
                          ),
                        ),
                        const SizedBox(height: AffluenaSpacing.space1),
                        Text(
                          value,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  if (enabled)
                    Icon(Icons.chevron_right, color: colors.inkMuted),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// Device-lock / biometric rows removed with the security-preferences feature.
