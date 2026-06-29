import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/affluena_theme.dart';
import '../../../core/formatters/money_formatter.dart';
import '../../redesign/presentation/room_detail_screen.dart';
import '../../shared/presentation/widgets/affluena_card.dart';
import '../../shared/presentation/widgets/affluena_skeleton.dart';
import '../../shared/presentation/widgets/drill_in_scaffold.dart';
import '../../shared/presentation/widgets/section_header.dart';
import '../../wallets/application/wallets_controller.dart';
import '../../wallets/data/wallet_models.dart';
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
                  AffluenaCard(
                    child: Column(
                      children: [
                        for (var i = 0; i < byOwner[ownerId]!.length; i++) ...[
                          if (i > 0) const Divider(height: 1),
                          _SharedWalletRow(wallet: byOwner[ownerId]![i]),
                        ],
                      ],
                    ),
                  ),
                ],
              ],
            );
          },
        ),
      ),
    );
  }
}

class _SharedWalletRow extends StatelessWidget {
  const _SharedWalletRow({required this.wallet});

  final Wallet wallet;

  @override
  Widget build(BuildContext context) {
    final colors = context.affluenaColors;
    final textTheme = Theme.of(context).textTheme;
    return Material(
      type: MaterialType.transparency,
      child: InkWell(
        onTap: () => context.push(RoomDetailScreen.location(wallet.id)),
        borderRadius: BorderRadius.circular(AffluenaRadii.md),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: AffluenaSpacing.space2),
          child: Row(
            children: [
              DecoratedBox(
                decoration: BoxDecoration(
                  color: colors.forestSoft,
                  borderRadius: BorderRadius.circular(AffluenaRadii.md),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(AffluenaSpacing.space3),
                  child: Icon(
                    walletIcon(wallet.type),
                    color: colors.forest,
                    size: 18,
                  ),
                ),
              ),
              const SizedBox(width: AffluenaSpacing.space3),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      wallet.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: textTheme.bodyLarge?.copyWith(color: colors.ink),
                    ),
                    Text(
                      walletTypeLabel(wallet.type),
                      style: textTheme.bodySmall?.copyWith(
                        color: colors.inkMuted,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AffluenaSpacing.space2),
              Text(
                MoneyFormatter.idr(wallet.balanceMinor),
                style: textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: colors.ink,
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
