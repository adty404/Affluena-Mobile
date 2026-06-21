import 'package:flutter/material.dart';

import '../../../app/theme/affluena_theme.dart';
import '../../auth/data/auth_models.dart';
import '../../shared/presentation/widgets/affluena_card.dart';

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
    final textTheme = Theme.of(context).textTheme;
    final colors = context.affluenaColors;
    final displayName = user?.name.isNotEmpty == true ? user!.name : 'Affluena';
    final email = user?.email ?? 'Signed in';
    final initial = displayName.trim().isEmpty
        ? 'A'
        : displayName.trim().characters.first.toUpperCase();

    return AffluenaCard(
      child: Column(
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 28,
                backgroundColor: colors.forest,
                child: Text(
                  initial,
                  style: textTheme.titleLarge?.copyWith(
                    color: colors.surfaceCanvas,
                  ),
                ),
              ),
              const SizedBox(width: AffluenaSpacing.space4),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(displayName, style: textTheme.titleMedium),
                    const SizedBox(height: AffluenaSpacing.space1),
                    Text(email, style: textTheme.bodySmall),
                  ],
                ),
              ),
            ],
          ),
          if (isLoading) ...[
            const SizedBox(height: AffluenaSpacing.space4),
            const LinearProgressIndicator(minHeight: 2),
          ],
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

    return Material(
      type: MaterialType.transparency,
      child: ListTile(
        contentPadding: EdgeInsets.zero,
        enabled: onTap != null,
        onTap: onTap,
        leading: Icon(icon, color: colors.forest),
        title: Text(title, style: textTheme.bodyLarge),
        subtitle: Text(value, style: textTheme.bodySmall),
        trailing: const Icon(Icons.chevron_right),
      ),
    );
  }
}

class NotificationRule extends StatelessWidget {
  const NotificationRule({
    required this.title,
    required this.channel,
    super.key,
  });

  final String title;
  final String channel;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Material(
      type: MaterialType.transparency,
      child: SwitchListTile(
        contentPadding: EdgeInsets.zero,
        value: true,
        onChanged: (_) {},
        title: Text(title, style: textTheme.bodyLarge),
        subtitle: Text(channel, style: textTheme.bodySmall),
      ),
    );
  }
}

class SettingsMessage extends StatelessWidget {
  const SettingsMessage({
    required this.message,
    required this.isError,
    super.key,
  });

  final String message;
  final bool isError;

  @override
  Widget build(BuildContext context) {
    final colors = context.affluenaColors;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: isError ? colors.coral.withAlpha(32) : colors.forestSoft,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isError ? colors.coral : colors.borderSubtle),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AffluenaSpacing.space3),
        child: Text(message),
      ),
    );
  }
}
