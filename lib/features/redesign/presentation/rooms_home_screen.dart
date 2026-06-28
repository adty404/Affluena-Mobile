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
      backgroundColor: context.sky.ground,
      floatingActionButton: FloatingActionButton(
        backgroundColor: context.sky.accent,
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
      loading: () =>
          Center(child: CircularProgressIndicator(color: context.sky.accent)),
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
      // Extra bottom padding so the last row clears the floating nav pill.
      padding: AffluenaInsets.screen.copyWith(bottom: 120),
      children: [
        Text(
          'Total',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: context.sky.muted,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          MoneyFormatter.idr(total),
          style: TextStyle(
            fontSize: 25,
            fontWeight: FontWeight.w700,
            color: context.sky.ink,
            fontFeatures: [FontFeature.tabularFigures()],
          ),
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            Icon(Icons.info_outline, size: 13, color: context.sky.faint),
            const SizedBox(width: 5),
            Text(
              'Tahan kamar untuk catat cepat',
              style: TextStyle(fontSize: 11, color: context.sky.faint),
            ),
          ],
        ),
        const SizedBox(height: AffluenaSpacing.space5),
        for (final wallet in spending) ...[
          _WalletRoom(wallet: wallet),
          const SizedBox(height: AffluenaSpacing.space2),
        ],
        if (savings.isNotEmpty) ...[
          const SizedBox(height: AffluenaSpacing.space3),
          Text(
            'Tabungan',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: context.sky.muted,
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
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: context.sky.accent,
          fontFeatures: [FontFeature.tabularFigures()],
        ),
      ),
      footer: SkyProgressBar(value: goal.progressPercent / 100, height: 7),
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
      width: 34,
      height: 34,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: accent ? context.sky.accentSoft : context.sky.sheet,
        borderRadius: BorderRadius.circular(11),
        border: Border.all(
          color: accent ? context.sky.accentSoftBorder : context.sky.line,
        ),
      ),
      child: Icon(
        icon,
        size: 18,
        color: accent ? context.sky.accent : context.sky.muted,
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
      height: 34,
      child: Stack(
        children: [
          Positioned(
            left: 0,
            top: 3,
            child: SkyAvatar(
              initial: initial(members[0]),
              borderColor: context.sky.accentSoft,
            ),
          ),
          Positioned(
            left: 15,
            top: 3,
            child: SkyAvatar(
              initial: initial(members[1]),
              color: context.sky.avatarSecondary,
              borderColor: context.sky.accentSoft,
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
        color: context.sky.surface,
        borderRadius: BorderRadius.circular(AffluenaRadii.pill),
        border: Border.all(color: context.sky.accentSoftBorder),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 8.5,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.4,
          color: context.sky.accentInk,
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
          style: TextStyle(
            fontSize: 13.5,
            fontWeight: FontWeight.w600,
            color: context.sky.ink,
            fontFeatures: [FontFeature.tabularFigures()],
          ),
        ),
        const SizedBox(width: 2),
        Icon(Icons.chevron_right, size: 16, color: context.sky.faint),
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
            Text(
              'Tidak bisa memuat dompet.',
              style: TextStyle(fontSize: 14, color: context.sky.muted),
            ),
            const SizedBox(height: AffluenaSpacing.space3),
            TextButton(
              onPressed: onRetry,
              style: TextButton.styleFrom(foregroundColor: context.sky.accent),
              child: const Text('Coba lagi'),
            ),
          ],
        ),
      ),
    );
  }
}
