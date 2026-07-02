import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/affluena_theme.dart';
import '../../../app/theme/sky_palette.dart';
import '../../../core/formatters/money_formatter.dart';
import '../../auth/application/auth_controller.dart';
import '../../shared/presentation/appearance/item_appearance.dart';
import '../../shared/presentation/widgets/drill_in_scaffold.dart';
import '../../shared/presentation/widgets/sky_detail.dart';
import '../../shared/presentation/widgets/sky_progress_bar.dart';
import '../application/goal_controller.dart';
import '../data/goal_models.dart';
import 'goal_contribute_sheet.dart';
import 'goal_members_section.dart';

/// Per-goal detail (Tabungan) in the Sky & Denim language — opened from a
/// Beranda dashboard card. Reads the goal from the already-loaded
/// [goalControllerProvider]; "Setor" reuses the existing contribute sheet, and
/// shared goals list their members.
class GoalDetailScreen extends ConsumerWidget {
  const GoalDetailScreen({required this.id, super.key});

  final String id;

  static const path = '/goals/:id';
  static String location(String id) => '/goals/$id';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(goalControllerProvider);
    Goal? goal;
    for (final g in state.goals) {
      if (g.id == id) {
        goal = g;
        break;
      }
    }

    if (goal == null) {
      return DrillInScaffold(
        title: 'Tabungan',
        body: SkyDetailPlaceholder(
          loading: state.isLoading,
          message: 'Tabungan tidak ditemukan.',
        ),
      );
    }

    final current = goal;
    final achieved = current.progressPercent >= 100;
    // The item's chosen colour accents the hero + progress; achieved keeps
    // its income-green semantics.
    final itemColor = parseItemColor(current.color);
    final accent = itemColor ?? context.sky.accent;
    final currentUserId = ref.watch(
      authControllerProvider.select((auth) => auth.user?.id),
    );

    return DrillInScaffold(
      title: current.name,
      body: ListView(
        padding: AffluenaInsets.screen,
        children: [
          SkyDetailHero(
            label: 'Terkumpul',
            amount: MoneyFormatter.idr(current.collectedAmountMinor),
            sub: 'dari ${MoneyFormatter.idr(current.targetAmountMinor)}',
            accent: itemColor,
          ),
          const SizedBox(height: AffluenaSpacing.space5),
          SkyProgressBar(
            value: current.progressPercent / 100,
            height: 8,
            fillColor: accent,
          ),
          const SizedBox(height: AffluenaSpacing.space3),
          Row(
            children: [
              Text(
                'Tercapai ${current.progressPercent}%',
                style: TextStyle(fontSize: 13, color: context.sky.muted),
              ),
              const Spacer(),
              SkyStatusPill(
                label: achieved
                    ? 'Tercapai'
                    : (current.isActive ? 'Aktif' : 'Selesai'),
                color: achieved
                    ? context.sky.income
                    : (current.isActive ? accent : context.sky.faint),
              ),
            ],
          ),
          if (current.isActive) ...[
            const SizedBox(height: AffluenaSpacing.space6),
            FilledButton.icon(
              onPressed: () => showGoalContributeSheet(context, current),
              icon: const Icon(Icons.add_card_outlined),
              label: const Text('Setor'),
            ),
          ],
          if (current.members.isNotEmpty) ...[
            const SizedBox(height: AffluenaSpacing.space6),
            Text(
              'Anggota',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: context.sky.ink,
              ),
            ),
            const SizedBox(height: AffluenaSpacing.space3),
            GoalMembersSection(
              members: current.members,
              currentUserId: currentUserId,
              busy: state.isSaving,
              onRespond: (member, status) => ref
                  .read(goalControllerProvider.notifier)
                  .respondInvite(current, member, status),
            ),
          ],
        ],
      ),
    );
  }
}
