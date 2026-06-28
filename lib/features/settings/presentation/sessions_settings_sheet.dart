import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/affluena_theme.dart';
import '../../auth/data/auth_models.dart';
import '../../shared/presentation/widgets/affluena_banner.dart';
import '../../shared/presentation/widgets/affluena_skeleton.dart';
import '../../shared/presentation/widgets/status_badge.dart';
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
    final currentToken = ref
        .watch(currentSessionTokenSuffixProvider)
        .asData
        ?.value;
    return SettingsSheetFrame(
      title: 'Sesi yang masuk',
      child: sessions.when(
        loading: () => const _SessionsSkeleton(),
        error: (error, _) => _sessionError(error),
        data: (records) => _sessionList(records, currentToken),
      ),
    );
  }

  Widget _sessionError(Object error) {
    return AffluenaBanner.error(
      settingsErrorMessage(error),
      onRetry: () => ref.invalidate(settingsSessionsProvider),
      key: const Key('settings-sessions-error-banner'),
    );
  }

  Widget _sessionList(List<AuthSessionRecord> records, String? currentToken) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (_message != null) ...[
          AffluenaBanner.success(
            _message!,
            onDismiss: () => setState(() => _message = null),
          ),
          const SizedBox(height: AffluenaSpacing.space3),
        ],
        if (records.isEmpty)
          const _EmptySessions()
        else
          for (final session in records)
            _SessionRow(
              session: session,
              isCurrent: isCurrentSession(session, currentToken),
              isRevoking: _revokingSessionId == session.id,
              onRevoke: _revokingSessionId == null
                  ? () => _confirmRevoke(session)
                  : null,
            ),
      ],
    );
  }

  Future<void> _confirmRevoke(AuthSessionRecord session) async {
    final colors = context.affluenaColors;
    final isCurrent = isCurrentSession(
      session,
      ref.read(currentSessionTokenSuffixProvider).asData?.value,
    );
    final shouldRevoke = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cabut sesi ini?'),
        content: Text(
          isCurrent
              ? 'Ini adalah sesi di perangkat ini. Mencabutnya akan '
                    'mengeluarkanmu dari sini.'
              : 'Perangkat itu akan dikeluarkan dan perlu masuk lagi.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Batal'),
          ),
          FilledButton(
            key: const Key('settings-confirm-revoke-button'),
            style: FilledButton.styleFrom(backgroundColor: colors.coral),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Cabut sesi'),
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
      _message = result.success ? result.message : null;
    });
    if (!result.success) {
      _showRevokeError(result.message);
    }
  }

  void _showRevokeError(String message) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Tidak dapat mencabut'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}

class _SessionRow extends StatelessWidget {
  const _SessionRow({
    required this.session,
    required this.isCurrent,
    required this.isRevoking,
    required this.onRevoke,
  });

  final AuthSessionRecord session;
  final bool isCurrent;
  final bool isRevoking;
  final VoidCallback? onRevoke;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colors = context.affluenaColors;
    final lastUsed = session.lastUsedLabel;
    final location = session.locationLabel;

    final detailParts = <String>[
      'Masuk ${session.createdLabel}',
      if (lastUsed != null) 'Terakhir dipakai $lastUsed',
      ?location,
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AffluenaSpacing.space2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: AffluenaSpacing.space1),
            child: Icon(Icons.devices_outlined, color: colors.forest),
          ),
          const SizedBox(width: AffluenaSpacing.space3),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        session.deviceLabel,
                        style: textTheme.bodyLarge,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (isCurrent) ...[
                      const SizedBox(width: AffluenaSpacing.space2),
                      const StatusBadge(
                        label: 'Perangkat ini',
                        tone: StatusTone.success,
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: AffluenaSpacing.space1),
                Text(
                  detailParts.join(' · '),
                  style: textTheme.bodySmall?.copyWith(color: colors.inkMuted),
                ),
              ],
            ),
          ),
          TextButton(
            key: Key('settings-revoke-session-${session.id.substring(0, 8)}'),
            onPressed: onRevoke,
            child: Text(isRevoking ? 'Mencabut...' : 'Cabut'),
          ),
        ],
      ),
    );
  }
}

class _SessionsSkeleton extends StatelessWidget {
  const _SessionsSkeleton();

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < 3; i++)
          Padding(
            padding: const EdgeInsets.symmetric(
              vertical: AffluenaSpacing.space2,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const AffluenaSkeleton.circle(size: 24),
                const SizedBox(width: AffluenaSpacing.space3),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      AffluenaSkeleton.line(width: 160, height: 14),
                      SizedBox(height: AffluenaSpacing.space2),
                      AffluenaSkeleton.line(width: 220),
                    ],
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _EmptySessions extends StatelessWidget {
  const _EmptySessions();

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colors = context.affluenaColors;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AffluenaSpacing.space5),
      child: Column(
        children: [
          Icon(Icons.devices_outlined, size: 40, color: colors.inkMuted),
          const SizedBox(height: AffluenaSpacing.space3),
          Text(
            'Tidak ada sesi lain',
            style: textTheme.titleMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AffluenaSpacing.space1),
          Text(
            'Hanya perangkat ini yang masuk ke akunmu.',
            style: textTheme.bodySmall?.copyWith(color: colors.inkMuted),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
