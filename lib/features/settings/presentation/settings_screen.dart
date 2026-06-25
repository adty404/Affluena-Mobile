import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/affluena_theme.dart';
import '../../../app/theme/theme_mode_controller.dart';
import '../../auth/application/auth_controller.dart';
import '../../auth/data/auth_models.dart';
import '../../budgets/presentation/budget_screen.dart';
import '../../categories/presentation/category_tag_management_screen.dart';
import '../../debts/presentation/debt_screen.dart';
import '../../goals/presentation/goal_screen.dart';
import '../../insights/presentation/audit_log_screen.dart';
import '../../insights/application/insights_controller.dart';
import '../../insights/presentation/insights_screen.dart';
import '../../onboarding/presentation/onboarding_screen.dart';
import '../../quick_entry/presentation/quick_entry_templates_screen.dart';
import '../../recurring/presentation/recurring_screen.dart';
import '../../shared/presentation/widgets/affluena_banner.dart';
import '../../shared/presentation/widgets/affluena_card.dart';
import '../../shared/presentation/widgets/section_header.dart';
import '../../transactions/presentation/split_bill_list_screen.dart';
import '../../trackers/presentation/tracker_screen.dart';
import '../application/settings_controller.dart';
import 'settings_screen_widgets.dart';
import 'settings_sheets.dart';
import 'theme_settings_sheet.dart';

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
    final securityPreferences = ref.watch(securityPreferencesProvider);
    final themeMode = ref.watch(appThemeModeProvider);
    final user = profile.asData?.value ?? authState.user;
    final securityState = securityPreferences.asData?.value;

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
            AffluenaBanner.error(
              settingsErrorMessage(profile.error!),
              onRetry: () => ref.invalidate(settingsProfileProvider),
            ),
          ],
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
                SettingsDeviceLockRow(
                  key: const Key('settings-device-lock-row'),
                  securityPreferences: securityPreferences,
                  onChanged: (enabled) => ref
                      .read(securityPreferencesProvider.notifier)
                      .setDeviceLockEnabled(enabled),
                ),
              ],
            ),
          ),
          const SizedBox(height: AffluenaSpacing.space6),
          const SectionHeader(title: 'Appearance'),
          const SizedBox(height: AffluenaSpacing.space3),
          AffluenaCard(
            child: Column(
              children: [
                SettingsRow(
                  key: const Key('settings-theme-row'),
                  icon: themeMode.icon,
                  title: 'Theme',
                  value: themeMode.label,
                  onTap: () => showThemeSettingsSheet(context),
                ),
                const Divider(height: 1),
                SettingsRow(
                  icon: Icons.slideshow_outlined,
                  title: 'App tour',
                  value: 'Replay the welcome guide',
                  onTap: () => context.push(OnboardingScreen.replayLocation()),
                ),
              ],
            ),
          ),
          const SizedBox(height: AffluenaSpacing.space6),
          const SectionHeader(title: 'Daily tools'),
          const SizedBox(height: AffluenaSpacing.space3),
          AffluenaCard(
            child: Column(
              children: [
                SettingsRow(
                  icon: Icons.bolt_outlined,
                  title: 'Quick-entry templates',
                  value: 'Saved transaction shortcuts',
                  onTap: () => context.push(QuickEntryTemplatesScreen.path),
                ),
                const Divider(height: 1),
                SettingsRow(
                  icon: Icons.call_split_outlined,
                  title: 'Split bill',
                  value: 'Ongoing splits and who owes you',
                  onTap: () => context.push(SplitBillListScreen.path),
                ),
                const Divider(height: 1),
                SettingsRow(
                  icon: Icons.category_outlined,
                  title: 'Categories & Tags',
                  value: 'Hierarchy and labels',
                  onTap: () => context.push(CategoryTagManagementScreen.path),
                ),
              ],
            ),
          ),
          const SizedBox(height: AffluenaSpacing.space6),
          const SectionHeader(title: 'Planning'),
          const SizedBox(height: AffluenaSpacing.space3),
          AffluenaCard(
            child: Column(
              children: [
                SettingsRow(
                  icon: Icons.pie_chart_outline,
                  title: 'Budgets',
                  value: 'Monthly category limits and alerts',
                  onTap: () => context.push(BudgetScreen.path),
                ),
                const Divider(height: 1),
                SettingsRow(
                  icon: Icons.handshake_outlined,
                  title: 'Debt & Tracker',
                  value: 'Payable, receivable, and payments',
                  onTap: () => context.push(DebtScreen.path),
                ),
                const Divider(height: 1),
                SettingsRow(
                  icon: Icons.receipt_long_outlined,
                  title: 'Installments & Subscriptions',
                  value: 'Tenor plans and recurring bills',
                  onTap: () => context.push(TrackerScreen.path),
                ),
                const Divider(height: 1),
                SettingsRow(
                  icon: Icons.autorenew,
                  title: 'Recurring',
                  value: 'Scheduled income, expenses, and transfers',
                  onTap: () => context.push(RecurringScreen.path),
                ),
                const Divider(height: 1),
                SettingsRow(
                  icon: Icons.flag_outlined,
                  title: 'Goals',
                  value: 'Saving targets and shared invites',
                  onTap: () => context.push(GoalScreen.path),
                ),
              ],
            ),
          ),
          const SizedBox(height: AffluenaSpacing.space6),
          const SectionHeader(title: 'Insights'),
          const SizedBox(height: AffluenaSpacing.space3),
          AffluenaCard(
            child: Column(
              children: [
                SettingsRow(
                  icon: Icons.analytics_outlined,
                  title: 'Reports & Exports',
                  value: 'Monthly reports and transaction CSV',
                  onTap: () =>
                      context.push(InsightsScreen.location(InsightTab.exports)),
                ),
                const Divider(height: 1),
                SettingsRow(
                  icon: Icons.manage_search_outlined,
                  title: 'Audit logs',
                  value: 'Activity and system requests',
                  onTap: () => context.push(AuditLogScreen.path),
                ),
                const Divider(height: 1),
                SettingsRow(
                  icon: Icons.notifications_active_outlined,
                  title: 'Alerts & Activity',
                  value: 'Budget alerts and account audit trail',
                  onTap: () =>
                      context.push(InsightsScreen.location(InsightTab.alerts)),
                ),
                const Divider(height: 1),
                SettingsRow(
                  icon: Icons.tune_outlined,
                  title: 'Notification rules',
                  value: 'Budget, due, recurring, security, summary',
                  onTap: () =>
                      context.push(InsightsScreen.location(InsightTab.rules)),
                ),
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
