import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/affluena_theme.dart';
import '../../../app/theme/sky_palette.dart';
import '../../../core/formatters/money_formatter.dart';
import '../../goals/application/goal_controller.dart';
import '../../goals/data/goal_models.dart';
import '../../goals/presentation/goal_screen.dart';
import '../../shared/presentation/widgets/sky_avatar.dart';
import '../../shared/presentation/widgets/sky_progress_bar.dart';
import '../../shared/presentation/widgets/sky_room_card.dart';
import '../../wallets/application/wallets_controller.dart';
import '../../wallets/data/wallet_models.dart';
import '../../wallets/presentation/wallet_format.dart';
import 'room_detail_screen.dart';
import 'sky_quick_add_sheet.dart';

/// Redesign Tahap 2 — the "Spaces" home: wallets rendered as rooms, savings
/// goals as progress rooms, in the Sky & Denim language.
///
/// Mounted on its own additive route so the existing app/shell is untouched; a
/// later integration stage promotes it to the default home with a new nav
/// shell.
class RoomsHomeScreen extends StatelessWidget {
  const RoomsHomeScreen({super.key});

  static const path = '/rooms';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SkyPalette.ground,
      floatingActionButton: FloatingActionButton(
        backgroundColor: SkyPalette.accent,
        foregroundColor: Colors.white,
        onPressed: () => showSkyQuickAddSheet(context),
        child: const Icon(Icons.add),
      ),
      body: const SafeArea(child: RoomsHomeView()),
    );
  }
}

/// The Spaces home body (no Scaffold/FAB) so it can be hosted standalone
/// ([RoomsHomeScreen]) or inside the redesign nav shell.
class RoomsHomeView extends ConsumerWidget {
  const RoomsHomeView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final walletsAsync = ref.watch(walletListProvider);
    final goals = ref.watch(goalControllerProvider).goals;

    return walletsAsync.when(
      loading: () => const Center(
        child: CircularProgressIndicator(color: SkyPalette.accent),
      ),
      error: (error, _) =>
          _RoomsError(onRetry: () => ref.invalidate(walletListProvider)),
      data: (wallets) => _RoomsContent(wallets: wallets, goals: goals),
    );
  }
}

class _RoomsContent extends StatelessWidget {
  const _RoomsContent({required this.wallets, required this.goals});

  final List<Wallet> wallets;
  final List<Goal> goals;

  @override
  Widget build(BuildContext context) {
    final spending = wallets.where((w) => !w.isGoal).toList(growable: false);
    final savings = goals.where((g) => g.isActive).toList(growable: false);
    final total = spending.fold<int>(0, (sum, w) => sum + w.balanceMinor);

    return ListView(
      padding: AffluenaInsets.screen,
      children: [
        const Text(
          'TOTAL',
          style: TextStyle(
            fontSize: 11,
            letterSpacing: 1.4,
            fontWeight: FontWeight.w600,
            color: SkyPalette.faint,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          MoneyFormatter.idr(total),
          style: const TextStyle(
            fontSize: 27,
            fontWeight: FontWeight.w700,
            color: SkyPalette.ink,
            fontFeatures: [FontFeature.tabularFigures()],
          ),
        ),
        const SizedBox(height: 6),
        const Text(
          'Ketuk dompet untuk buka detailnya',
          style: TextStyle(fontSize: 11.5, color: SkyPalette.faint),
        ),
        const SizedBox(height: AffluenaSpacing.space5),
        for (final wallet in spending) ...[
          _WalletRoom(wallet: wallet),
          const SizedBox(height: AffluenaSpacing.space2),
        ],
        if (savings.isNotEmpty) ...[
          const SizedBox(height: AffluenaSpacing.space3),
          const Text(
            'Tabungan',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: SkyPalette.muted,
            ),
          ),
          const SizedBox(height: AffluenaSpacing.space2),
          for (final goal in savings) ...[
            _GoalRoom(goal: goal),
            const SizedBox(height: AffluenaSpacing.space2),
          ],
        ],
      ],
    );
  }
}

bool _isShared(Wallet wallet) {
  return wallet.members.isNotEmpty ||
      (wallet.role != null && wallet.role != 'owner');
}

class _WalletRoom extends StatelessWidget {
  const _WalletRoom({required this.wallet});

  final Wallet wallet;

  @override
  Widget build(BuildContext context) {
    final shared = _isShared(wallet);
    final useAvatars = shared && wallet.members.length >= 2;

    return SkyRoomCard(
      shared: shared,
      leading: useAvatars
          ? _AvatarStack(members: wallet.members)
          : _IconTile(icon: walletIcon(wallet.type)),
      title: wallet.name,
      subtitle: walletTypeLabel(wallet.type),
      badge: wallet.isViewer
          ? const _RoomPill(label: 'LIHAT')
          : (shared ? const _RoomPill(label: 'BERSAMA') : null),
      trailing: _AmountTrailing(
        amount: MoneyFormatter.idr(wallet.balanceMinor),
      ),
      onTap: () => context.push(RoomDetailScreen.location(wallet.id)),
      onLongPress: () => showSkyQuickAddSheet(context, wallet: wallet),
    );
  }
}

class _GoalRoom extends StatelessWidget {
  const _GoalRoom({required this.goal});

  final Goal goal;

  @override
  Widget build(BuildContext context) {
    return SkyRoomCard(
      leading: const _IconTile(icon: Icons.flag_outlined, accent: true),
      title: goal.name,
      subtitle:
          '${MoneyFormatter.idr(goal.collectedAmountMinor)} / ${MoneyFormatter.idr(goal.targetAmountMinor)}',
      trailing: Text(
        '${goal.progressPercent}%',
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w700,
          color: SkyPalette.accent,
          fontFeatures: [FontFeature.tabularFigures()],
        ),
      ),
      footer: SkyProgressBar(value: goal.progressPercent / 100),
      onTap: () => context.push(GoalScreen.path),
    );
  }
}

class _IconTile extends StatelessWidget {
  const _IconTile({required this.icon, this.accent = false});

  final IconData icon;
  final bool accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 38,
      height: 38,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: accent ? SkyPalette.accentSoft : SkyPalette.sheet,
        borderRadius: BorderRadius.circular(AffluenaRadii.md),
        border: Border.all(
          color: accent ? SkyPalette.accentSoftBorder : SkyPalette.line,
        ),
      ),
      child: Icon(
        icon,
        size: 19,
        color: accent ? SkyPalette.accent : SkyPalette.muted,
      ),
    );
  }
}

class _AvatarStack extends StatelessWidget {
  const _AvatarStack({required this.members});

  final List<WalletMember> members;

  @override
  Widget build(BuildContext context) {
    String initial(WalletMember m) =>
        m.email.isEmpty ? '?' : m.email[0].toUpperCase();

    return SizedBox(
      width: 44,
      height: 38,
      child: Stack(
        children: [
          Positioned(
            left: 0,
            top: 5,
            child: SkyAvatar(
              initial: initial(members[0]),
              borderColor: SkyPalette.accentSoft,
            ),
          ),
          Positioned(
            left: 15,
            top: 5,
            child: SkyAvatar(
              initial: initial(members[1]),
              color: SkyPalette.avatarSecondary,
              borderColor: SkyPalette.accentSoft,
            ),
          ),
        ],
      ),
    );
  }
}

class _RoomPill extends StatelessWidget {
  const _RoomPill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: SkyPalette.surface,
        borderRadius: BorderRadius.circular(AffluenaRadii.pill),
        border: Border.all(color: SkyPalette.accentSoftBorder),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 8.5,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.4,
          color: SkyPalette.accentInk,
        ),
      ),
    );
  }
}

class _AmountTrailing extends StatelessWidget {
  const _AmountTrailing({required this.amount});

  final String amount;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          amount,
          style: const TextStyle(
            fontSize: 13.5,
            fontWeight: FontWeight.w600,
            color: SkyPalette.ink,
            fontFeatures: [FontFeature.tabularFigures()],
          ),
        ),
        const SizedBox(width: 2),
        const Icon(Icons.chevron_right, size: 16, color: SkyPalette.faint),
      ],
    );
  }
}

class _RoomsError extends StatelessWidget {
  const _RoomsError({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: AffluenaInsets.screen,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Tidak bisa memuat dompet.',
              style: TextStyle(fontSize: 14, color: SkyPalette.muted),
            ),
            const SizedBox(height: AffluenaSpacing.space3),
            TextButton(
              onPressed: onRetry,
              style: TextButton.styleFrom(foregroundColor: SkyPalette.accent),
              child: const Text('Coba lagi'),
            ),
          ],
        ),
      ),
    );
  }
}
