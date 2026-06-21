import 'package:flutter/material.dart';

import '../../../app/theme/affluena_theme.dart';
import '../../shared/presentation/widgets/affluena_card.dart';
import '../../shared/presentation/widgets/section_header.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  static const path = '/settings';

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(
          AffluenaSpacing.space5,
          AffluenaSpacing.space4,
          AffluenaSpacing.space5,
          AffluenaSpacing.space8,
        ),
        children: [
          Text('Profile', style: textTheme.headlineMedium),
          const SizedBox(height: AffluenaSpacing.space5),
          AffluenaCard(
            child: Row(
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundColor: AffluenaColors.forest,
                  child: Text(
                    'A',
                    style: textTheme.titleLarge?.copyWith(
                      color: AffluenaColors.surfaceElevated,
                    ),
                  ),
                ),
                const SizedBox(width: AffluenaSpacing.space4),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Affluena Demo', style: textTheme.titleMedium),
                      const SizedBox(height: AffluenaSpacing.space1),
                      Text('demo@affluena.com', style: textTheme.bodySmall),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AffluenaSpacing.space6),
          const SectionHeader(title: 'Security'),
          const SizedBox(height: AffluenaSpacing.space3),
          AffluenaCard(
            child: Column(
              children: [
                const _SettingsRow(
                  icon: Icons.person_outline,
                  title: 'Account',
                  value: 'Name and email',
                ),
                const Divider(height: 1),
                const _SettingsRow(
                  icon: Icons.lock_outline,
                  title: 'Password',
                  value: 'Last updated recently',
                ),
                const Divider(height: 1),
                const _SettingsRow(
                  icon: Icons.devices_outlined,
                  title: 'Sessions',
                  value: 'Manage signed-in devices',
                ),
                const Divider(height: 1),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  value: true,
                  onChanged: (_) {},
                  title: Text('Biometric lock', style: textTheme.bodyLarge),
                  subtitle: Text(
                    'Face ID or fingerprint',
                    style: textTheme.bodySmall,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AffluenaSpacing.space6),
          const SectionHeader(title: 'Notifications'),
          const SizedBox(height: AffluenaSpacing.space3),
          const AffluenaCard(
            child: Column(
              children: [
                _NotificationRule(title: 'Budget alerts', channel: 'Both'),
                Divider(height: 1),
                _NotificationRule(title: 'Due reminders', channel: 'In-app'),
                Divider(height: 1),
                _NotificationRule(title: 'Recurring runs', channel: 'Email'),
                Divider(height: 1),
                _NotificationRule(title: 'Security alerts', channel: 'Both'),
                Divider(height: 1),
                _NotificationRule(title: 'Weekly summary', channel: 'Email'),
              ],
            ),
          ),
          const SizedBox(height: AffluenaSpacing.space6),
          OutlinedButton(onPressed: () {}, child: const Text('Log out')),
        ],
      ),
    );
  }
}

class _SettingsRow extends StatelessWidget {
  const _SettingsRow({
    required this.icon,
    required this.title,
    required this.value,
  });

  final IconData icon;
  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon, color: AffluenaColors.forest),
      title: Text(title, style: textTheme.bodyLarge),
      subtitle: Text(value, style: textTheme.bodySmall),
      trailing: const Icon(Icons.chevron_right),
    );
  }
}

class _NotificationRule extends StatelessWidget {
  const _NotificationRule({required this.title, required this.channel});

  final String title;
  final String channel;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return SwitchListTile(
      contentPadding: EdgeInsets.zero,
      value: true,
      onChanged: (_) {},
      title: Text(title, style: textTheme.bodyLarge),
      subtitle: Text(channel, style: textTheme.bodySmall),
    );
  }
}
