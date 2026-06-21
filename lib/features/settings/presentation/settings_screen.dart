import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/affluena_theme.dart';
import '../../auth/application/auth_controller.dart';
import '../../auth/data/auth_models.dart';
import '../../shared/presentation/widgets/affluena_card.dart';
import '../../shared/presentation/widgets/section_header.dart';
import '../application/settings_controller.dart';
import 'settings_screen_widgets.dart';
import 'settings_sheets.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  static const path = '/settings';

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  String? _feedback;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final authState = ref.watch(authControllerProvider);
    final profile = ref.watch(settingsProfileProvider);
    final user = profile.asData?.value ?? authState.user;

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
          SettingsProfileCard(user: user, isLoading: profile.isLoading),
          if (profile.hasError) ...[
            const SizedBox(height: AffluenaSpacing.space3),
            SettingsMessage(
              message: settingsErrorMessage(profile.error!),
              isError: true,
            ),
          ],
          if (_feedback != null) ...[
            const SizedBox(height: AffluenaSpacing.space3),
            SettingsMessage(message: _feedback!, isError: false),
          ],
          const SizedBox(height: AffluenaSpacing.space6),
          const SectionHeader(title: 'Security'),
          const SizedBox(height: AffluenaSpacing.space3),
          AffluenaCard(
            child: Column(
              children: [
                SettingsRow(
                  key: const Key('settings-account-row'),
                  icon: Icons.person_outline,
                  title: 'Account',
                  value: 'Name and avatar',
                  onTap: user == null ? null : () => _openAccount(user),
                ),
                const Divider(height: 1),
                SettingsRow(
                  key: const Key('settings-password-row'),
                  icon: Icons.lock_outline,
                  title: 'Password',
                  value: 'Change your password',
                  onTap: _openPassword,
                ),
                const Divider(height: 1),
                SettingsRow(
                  key: const Key('settings-sessions-row'),
                  icon: Icons.devices_outlined,
                  title: 'Sessions',
                  value: 'Manage signed-in devices',
                  onTap: _openSessions,
                ),
                const Divider(height: 1),
                Material(
                  type: MaterialType.transparency,
                  child: SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    value: true,
                    onChanged: (_) {},
                    title: Text('Biometric lock', style: textTheme.bodyLarge),
                    subtitle: Text(
                      'Face ID or fingerprint',
                      style: textTheme.bodySmall,
                    ),
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
                NotificationRule(title: 'Budget alerts', channel: 'Both'),
                Divider(height: 1),
                NotificationRule(title: 'Due reminders', channel: 'In-app'),
                Divider(height: 1),
                NotificationRule(title: 'Recurring runs', channel: 'Email'),
                Divider(height: 1),
                NotificationRule(title: 'Security alerts', channel: 'Both'),
                Divider(height: 1),
                NotificationRule(title: 'Weekly summary', channel: 'Email'),
              ],
            ),
          ),
          const SizedBox(height: AffluenaSpacing.space6),
          OutlinedButton.icon(
            key: const Key('settings-logout-button'),
            onPressed: authState.isSubmitting
                ? null
                : () => ref.read(authControllerProvider.notifier).logout(),
            icon: const Icon(Icons.logout),
            label: Text(authState.isSubmitting ? 'Logging out' : 'Log out'),
          ),
        ],
      ),
    );
  }

  Future<void> _openAccount(AuthUser user) async {
    final message = await showAccountSettingsSheet(context, user);
    if (!mounted || message == null) return;
    setState(() => _feedback = message);
  }

  Future<void> _openPassword() async {
    final message = await showPasswordSettingsSheet(context);
    if (!mounted || message == null) return;
    setState(() => _feedback = message);
  }

  Future<void> _openSessions() async {
    await showSessionSettingsSheet(context);
  }
}
