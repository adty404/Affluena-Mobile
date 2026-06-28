import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/affluena_theme.dart';
import '../../auth/data/auth_models.dart';
import '../../shared/presentation/widgets/affluena_card.dart';
import '../../shared/presentation/widgets/affluena_skeleton.dart';
import '../application/settings_controller.dart';

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
    final displayName = user?.name.isNotEmpty == true ? user!.name : 'Affluena';
    final email = user?.email ?? 'Sudah masuk';
    final initial = displayName.trim().isEmpty
        ? 'A'
        : displayName.trim().characters.first.toUpperCase();

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
                        style: textTheme.titleMedium,
                      ),
                      const SizedBox(height: AffluenaSpacing.space1),
                      Text(
                        email,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: textTheme.bodySmall,
                      ),
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

class SettingsSwitchRow extends StatelessWidget {
  const SettingsSwitchRow({
    required this.icon,
    required this.title,
    required this.value,
    required this.switchValue,
    required this.onChanged,
    this.isBusy = false,
    super.key,
  });

  final IconData icon;
  final String title;
  final String value;
  final bool switchValue;
  final ValueChanged<bool>? onChanged;
  final bool isBusy;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colors = context.affluenaColors;
    final enabled = onChanged != null && !isBusy;

    return Semantics(
      enabled: enabled,
      toggled: switchValue,
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          onTap: enabled ? () => onChanged!(!switchValue) : null,
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
                  if (isBusy)
                    SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: colors.forest,
                      ),
                    )
                  else
                    Switch.adaptive(
                      value: switchValue,
                      onChanged: enabled ? onChanged : null,
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class SettingsDeviceLockRow extends StatelessWidget {
  const SettingsDeviceLockRow({
    required this.securityPreferences,
    required this.onChanged,
    super.key,
  });

  final AsyncValue<SecurityPreferencesState> securityPreferences;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return switch (securityPreferences) {
      AsyncData(:final value) => SettingsSwitchRow(
        icon: Icons.fingerprint,
        title: 'Kunci perangkat',
        value: value.deviceLockValue,
        switchValue: value.preferences.deviceLockEnabled,
        isBusy: value.isSaving,
        onChanged: value.canConfigureDeviceLock ? onChanged : null,
      ),
      AsyncError() => const SettingsRow(
        icon: Icons.fingerprint,
        title: 'Kunci perangkat',
        value: 'Tidak dapat memuat autentikasi perangkat',
        onTap: null,
      ),
      _ => const SettingsSwitchRow(
        icon: Icons.fingerprint,
        title: 'Kunci perangkat',
        value: 'Memeriksa autentikasi perangkat',
        switchValue: false,
        isBusy: true,
        onChanged: null,
      ),
    };
  }
}
