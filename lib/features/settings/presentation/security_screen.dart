import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/affluena_theme.dart';
import '../../auth/application/auth_controller.dart';
import '../../auth/data/auth_models.dart';
import '../../insights/application/insights_controller.dart';
import '../../insights/presentation/insights_screen.dart';
import '../../shared/presentation/widgets/affluena_banner.dart';
import '../../shared/presentation/widgets/affluena_card.dart';
import '../../shared/presentation/widgets/drill_in_scaffold.dart';
import '../../shared/presentation/widgets/section_header.dart';
import '../application/settings_controller.dart';
import 'settings_screen_widgets.dart';
import 'settings_sheets.dart';

class SecurityScreen extends ConsumerStatefulWidget {
  const SecurityScreen({super.key});

  static const path = '/security';

  @override
  ConsumerState<SecurityScreen> createState() => _SecurityScreenState();
}

class _SecurityScreenState extends ConsumerState<SecurityScreen> {
  String? _feedback;

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);
    final profile = ref.watch(settingsProfileProvider);
    final securityPreferences = ref.watch(securityPreferencesProvider);
    final user = profile.asData?.value ?? authState.user;
    final securityState = securityPreferences.asData?.value;

    return DrillInScaffold(
      title: 'Security center',
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          AffluenaSpacing.space5,
          AffluenaSpacing.space4,
          AffluenaSpacing.space5,
          AffluenaSpacing.space8,
        ),
        children: [
          SettingsProfileCard(user: user, isLoading: profile.isLoading),
          if (_feedback != null) ...[
            const SizedBox(height: AffluenaSpacing.space3),
            AffluenaBanner.success(
              _feedback!,
              onDismiss: () => setState(() => _feedback = null),
            ),
          ],
          if (securityState?.actionError != null) ...[
            const SizedBox(height: AffluenaSpacing.space3),
            AffluenaBanner.error(securityState!.actionError!),
          ],
          if (securityState?.actionMessage != null) ...[
            const SizedBox(height: AffluenaSpacing.space3),
            AffluenaBanner.success(securityState!.actionMessage!),
          ],
          const SizedBox(height: AffluenaSpacing.space6),
          const SectionHeader(title: 'Security'),
          const SizedBox(height: AffluenaSpacing.space3),
          AffluenaCard(
            child: Column(
              children: [
                SettingsRow(
                  key: const Key('security-account-row'),
                  icon: Icons.person_outline,
                  title: 'Account',
                  value: 'Name and avatar',
                  onTap: user == null ? null : () => _openAccount(user),
                ),
                const Divider(height: 1),
                SettingsRow(
                  key: const Key('security-password-row'),
                  icon: Icons.lock_outline,
                  title: 'Password',
                  value: 'Change your password',
                  onTap: _openPassword,
                ),
                const Divider(height: 1),
                SettingsRow(
                  key: const Key('security-sessions-row'),
                  icon: Icons.devices_outlined,
                  title: 'Sessions',
                  value: 'Manage signed-in devices',
                  onTap: _openSessions,
                ),
                const Divider(height: 1),
                SettingsDeviceLockRow(
                  key: const Key('security-device-lock-row'),
                  securityPreferences: securityPreferences,
                  onChanged: (enabled) => ref
                      .read(securityPreferencesProvider.notifier)
                      .setDeviceLockEnabled(enabled),
                ),
              ],
            ),
          ),
          const SizedBox(height: AffluenaSpacing.space6),
          const SectionHeader(title: 'Advanced protection'),
          const SizedBox(height: AffluenaSpacing.space3),
          AffluenaCard(
            child: Column(
              children: [
                SettingsRow(
                  key: const Key('security-notification-rules-row'),
                  icon: Icons.notification_important_outlined,
                  title: 'Security alerts',
                  value: 'Managed in notification rules',
                  onTap: () =>
                      context.push(InsightsScreen.location(InsightTab.rules)),
                ),
                const Divider(height: 1),
                const SettingsRow(
                  key: Key('security-two-factor-row'),
                  icon: Icons.verified_user_outlined,
                  title: 'Two-factor authentication',
                  value: 'Not available in this API build',
                  onTap: null,
                ),
                const Divider(height: 1),
                const SettingsRow(
                  key: Key('security-push-row'),
                  icon: Icons.notifications_outlined,
                  title: 'Push notifications',
                  value: 'Waiting for push provider support',
                  onTap: null,
                ),
                const Divider(height: 1),
                const SettingsRow(
                  key: Key('security-login-alerts-row'),
                  icon: Icons.mark_email_unread_outlined,
                  title: 'Login email alerts',
                  value: 'No dedicated login-alert endpoint yet',
                  onTap: null,
                ),
              ],
            ),
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
