import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/affluena_theme.dart';
import '../../../app/theme/section_palette.dart';
import '../../../core/formatters/money_formatter.dart';
import '../../redesign/presentation/room_detail_screen.dart';
import '../../shared/presentation/widgets/affluena_skeleton.dart';
import '../../shared/presentation/widgets/drill_in_scaffold.dart';
import '../../shared/presentation/widgets/section_header.dart';
import '../../wallets/application/wallets_controller.dart';
import '../../wallets/data/wallet_models.dart';
import '../../wallets/presentation/wallet_appearance.dart';
import '../../wallets/presentation/wallet_format.dart';
import '../application/partner_controller.dart';

/// "Dibagikan untukku" — every wallet other people have shared with me
/// (read-only), grouped by the person who shared it. Opened from the Beranda
/// "Dibagikan untukku" section's "Lihat semua".
class SharedWithMeScreen extends ConsumerWidget {
  const SharedWithMeScreen({super.key});

  static const path = '/shared-with-me';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final walletsAsync = ref.watch(walletListProvider);
    final partnerState = ref.watch(partnerControllerProvider);

    return DrillInScaffold(
      title: 'Dibagikan untukku',
      body: SafeArea(
        child: walletsAsync.when(
          loading: () => const _LoadingBody(),
          error: (_, _) =>
              const _MessageBody('Dompet yang dibagikan gagal dimuat.'),
          data: (wallets) {
            final viewableOwnerIds = partnerState.viewableOwnerIds;
            final shared = wallets
                .where((w) => w.isViewer && viewableOwnerIds.contains(w.userId))
                .toList(growable: false);

            if (shared.isEmpty) {
              return const _MessageBody(
                'Belum ada yang membagikan dompetnya ke kamu.',
              );
            }

            final nameByOwner = <String, String>{
              for (final link in partnerState.links)
                if (link.isIncoming && link.isJoined)
                  link.userId: link.displayName,
            };

            // Group by owner, preserving first-seen order.
            final byOwner = <String, List<Wallet>>{};
            for (final wallet in shared) {
              byOwner.putIfAbsent(wallet.userId, () => <Wallet>[]).add(wallet);
            }

            return ListView(
              padding: AffluenaInsets.screen,
              children: [
                Text(
                  'Dompet yang orang lain bagikan ke kamu. Hanya bisa dilihat — '
                  'kamu tidak bisa mengubah transaksinya.',
                  style: TextStyle(
                    fontSize: 13,
                    height: 1.5,
                    color: context.affluenaColors.inkMuted,
                  ),
                ),
                for (final ownerId in byOwner.keys) ...[
                  const SizedBox(height: AffluenaSpacing.space5),
                  SectionHeader(
                    title: 'Dari ${nameByOwner[ownerId] ?? 'Seseorang'}',
                  ),
                  const SizedBox(height: AffluenaSpacing.space3),
                  for (var i = 0; i < byOwner[ownerId]!.length; i++) ...[
                    if (i > 0) const SizedBox(height: AffluenaSpacing.space3),
                    _SharedWalletCard(wallet: byOwner[ownerId]![i]),
                  ],
                ],
              ],
            );
          },
        ),
      ),
    );
  }
}

/// A wallet shared TO me, rendered as a full card matching Beranda's
/// "Dibagikan untukku" cards: the relational magenta section hue (or the
/// wallet's own colour, solid, when set), its icon, name, type, and balance.
/// Tapping opens the read-only room detail.
class _SharedWalletCard extends StatelessWidget {
  const _SharedWalletCard({required this.wallet});

  final Wallet wallet;

  @override
  Widget build(BuildContext context) {
    final colors = context.affluenaColors;
    final hue = SectionPalette.dibagikan.of(context);
    final color = parseWalletColor(wallet.color);
    final hasColor = color != null;
    final titleColor = hasColor ? Colors.white : colors.ink;
    final subtitleColor = hasColor ? Colors.white70 : colors.inkMuted;
    final iconColor = hasColor ? Colors.white : hue.strong;
    final iconBg = hasColor ? Colors.white.withValues(alpha: 0.2) : hue.iconBg;
    final radius = BorderRadius.circular(AffluenaRadii.card);

    return Material(
      color: hasColor ? color : hue.tint,
      borderRadius: radius,
      child: InkWell(
        onTap: () => context.push(RoomDetailScreen.location(wallet.id)),
        borderRadius: radius,
        child: Ink(
          decoration: BoxDecoration(
            border: Border.all(color: hasColor ? color : hue.border),
            borderRadius: radius,
          ),
          padding: const EdgeInsets.all(AffluenaSpacing.space4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              DecoratedBox(
                decoration: BoxDecoration(
                  color: iconBg,
                  borderRadius: BorderRadius.circular(AffluenaRadii.lg),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(AffluenaSpacing.space3),
                  child: Icon(
                    resolveWalletIcon(wallet),
                    color: iconColor,
                    size: 20,
                  ),
                ),
              ),
              const SizedBox(height: AffluenaSpacing.space3),
              Text(
                wallet.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: titleColor,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                walletTypeLabel(wallet.type),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 12, color: subtitleColor),
              ),
              const SizedBox(height: AffluenaSpacing.space3),
              Text(
                MoneyFormatter.idr(wallet.balanceMinor),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.2,
                  color: titleColor,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MessageBody extends StatelessWidget {
  const _MessageBody(this.message);

  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: AffluenaInsets.screen,
        child: Text(
          message,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 14,
            color: context.affluenaColors.inkMuted,
          ),
        ),
      ),
    );
  }
}

class _LoadingBody extends StatelessWidget {
  const _LoadingBody();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: AffluenaInsets.screen,
      children: const [
        AffluenaSkeleton(height: 18, width: 140),
        SizedBox(height: AffluenaSpacing.space4),
        AffluenaSkeleton(height: 72),
        SizedBox(height: AffluenaSpacing.space3),
        AffluenaSkeleton(height: 72),
      ],
    );
  }
}
