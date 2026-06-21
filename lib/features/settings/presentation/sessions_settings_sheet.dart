import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/affluena_theme.dart';
import '../../auth/data/auth_models.dart';
import '../application/settings_controller.dart';
import 'settings_sheet_widgets.dart';

Future<void> showSessionSettingsSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (_) => const _SessionsSheet(),
  );
}

class _SessionsSheet extends ConsumerStatefulWidget {
  const _SessionsSheet();

  @override
  ConsumerState<_SessionsSheet> createState() => _SessionsSheetState();
}

class _SessionsSheetState extends ConsumerState<_SessionsSheet> {
  String? _message;
  String? _revokingSessionId;

  @override
  Widget build(BuildContext context) {
    final sessions = ref.watch(settingsSessionsProvider);
    return SettingsSheetFrame(
      title: 'Signed-in sessions',
      child: sessions.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => _sessionError(error),
        data: _sessionList,
      ),
    );
  }

  Widget _sessionError(Object error) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SettingsInlineMessage(
          message: settingsErrorMessage(error),
          isError: true,
        ),
        const SizedBox(height: AffluenaSpacing.space3),
        OutlinedButton.icon(
          key: const Key('settings-sessions-retry-button'),
          onPressed: () => ref.invalidate(settingsSessionsProvider),
          icon: const Icon(Icons.refresh),
          label: const Text('Retry'),
        ),
      ],
    );
  }

  Widget _sessionList(List<AuthSessionRecord> records) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (_message != null) ...[
          SettingsInlineMessage(message: _message!, isError: false),
          const SizedBox(height: AffluenaSpacing.space3),
        ],
        if (records.isEmpty)
          const _EmptySessions()
        else
          for (final session in records) _sessionRow(session: session),
      ],
    );
  }

  Widget _sessionRow({required AuthSessionRecord session}) {
    final textTheme = Theme.of(context).textTheme;
    final userAgent = session.userAgent?.trim().isNotEmpty == true
        ? session.userAgent!
        : 'Unknown device';
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AffluenaSpacing.space2),
      child: Row(
        children: [
          const Icon(Icons.devices_outlined, color: AffluenaColors.forest),
          const SizedBox(width: AffluenaSpacing.space3),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(userAgent, style: textTheme.bodyLarge),
                const SizedBox(height: AffluenaSpacing.space1),
                Text(
                  'Token ending ${session.tokenSuffix}',
                  style: textTheme.bodySmall,
                ),
              ],
            ),
          ),
          TextButton(
            key: Key('settings-revoke-session-${session.id.substring(0, 8)}'),
            onPressed: _revokingSessionId == null
                ? () => _confirmRevoke(session)
                : null,
            child: Text(
              _revokingSessionId == session.id ? 'Revoking' : 'Revoke',
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmRevoke(AuthSessionRecord session) async {
    final shouldRevoke = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Revoke this session?'),
        content: const Text(
          'If this is your current session, you may need to log in again.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            key: const Key('settings-confirm-revoke-button'),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Revoke session'),
          ),
        ],
      ),
    );
    if (shouldRevoke != true) return;
    setState(() {
      _message = null;
      _revokingSessionId = session.id;
    });
    final result = await ref
        .read(settingsSessionsProvider.notifier)
        .revokeSession(session.id);
    if (!mounted) return;
    setState(() {
      _revokingSessionId = null;
      _message = result.message;
    });
  }
}

class _EmptySessions extends StatelessWidget {
  const _EmptySessions();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: AffluenaSpacing.space4),
      child: Text('No active sessions found.'),
    );
  }
}
