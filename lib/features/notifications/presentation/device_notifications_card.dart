import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/affluena_theme.dart';
import '../../shared/presentation/widgets/affluena_card.dart';
import '../../shared/presentation/widgets/status_badge.dart';
import '../application/notification_scheduler.dart';

/// The "Aktifkan notifikasi perangkat" row on Pengaturan → Aturan notifikasi.
///
/// Shows whether the app may post device notifications (the Android 13+
/// POST_NOTIFICATIONS permission) and offers a single explicit button to
/// request it — the only place the user is ever re-prompted (the scheduler
/// auto-asks at most once, on first start with an enabled rule). Renders
/// nothing on platforms without device-notification support (e.g. tests on
/// the macOS host), so the rules list is unchanged there.
class DeviceNotificationsCard extends ConsumerStatefulWidget {
  const DeviceNotificationsCard({super.key});

  @override
  ConsumerState<DeviceNotificationsCard> createState() =>
      _DeviceNotificationsCardState();
}

class _DeviceNotificationsCardState
    extends ConsumerState<DeviceNotificationsCard> {
  bool? _enabled;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    Future.microtask(_load);
  }

  Future<void> _load() async {
    final device = ref.read(deviceNotificationsProvider);
    if (!device.isSupported) return;
    final enabled = await device.areEnabled();
    if (!mounted) return;
    setState(() => _enabled = enabled);
  }

  Future<void> _request() async {
    setState(() => _busy = true);
    final device = ref.read(deviceNotificationsProvider);
    final granted = await device.requestPermission();
    if (!mounted) return;
    setState(() {
      _busy = false;
      _enabled = granted;
    });
    if (!granted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Izin notifikasi belum diberikan. Kamu bisa mengaktifkannya '
            'lewat pengaturan sistem Android.',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final device = ref.watch(deviceNotificationsProvider);
    if (!device.isSupported) return const SizedBox.shrink();

    final colors = context.affluenaColors;
    final enabled = _enabled ?? false;

    return AffluenaCard(
      child: Row(
        children: [
          Icon(Icons.notifications_active_outlined, color: colors.forest),
          const SizedBox(width: AffluenaSpacing.space3),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Aktifkan notifikasi perangkat',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const SizedBox(height: AffluenaSpacing.space1),
                Text(
                  enabled
                      ? 'Pengingat jatuh tempo (H-3 dan H-1) muncul di '
                            'perangkatmu.'
                      : 'Izinkan notifikasi supaya pengingat jatuh tempo '
                            'muncul di perangkatmu.',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
          const SizedBox(width: AffluenaSpacing.space3),
          if (enabled)
            const StatusBadge(label: 'Aktif', tone: StatusTone.success)
          else
            FilledButton.tonal(
              key: const Key('device-notifications-enable'),
              onPressed: _busy ? null : _request,
              child: Text(_busy ? 'Meminta...' : 'Aktifkan'),
            ),
        ],
      ),
    );
  }
}
