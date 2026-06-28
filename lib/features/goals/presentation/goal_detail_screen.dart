import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/affluena_theme.dart';
import '../../../app/theme/sky_palette.dart';
import '../../../core/formatters/money_formatter.dart';
import '../../shared/presentation/widgets/drill_in_scaffold.dart';
import '../../shared/presentation/widgets/sky_detail.dart';
import '../../shared/presentation/widgets/sky_progress_bar.dart';
import '../application/goal_controller.dart';
import '../data/goal_models.dart';
import 'goal_contribute_sheet.dart';

/// Per-goal detail (Tabungan) in the Sky & Denim language — opened from a
/// Beranda dashboard card. Reads the goal from the already-loaded
/// [goalControllerProvider]; "Setor" reuses the existing contribute sheet.
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

    final achieved = goal.progressPercent >= 100;
    final current = goal;

    return DrillInScaffold(
      title: goal.name,
      body: ListView(
        padding: AffluenaInsets.screen,
        children: [
          SkyDetailHero(
            label: 'Terkumpul',
            amount: MoneyFormatter.idr(goal.collectedAmountMinor),
            sub: 'dari ${MoneyFormatter.idr(goal.targetAmountMinor)}',
          ),
          const SizedBox(height: AffluenaSpacing.space5),
          SkyProgressBar(value: goal.progressPercent / 100, height: 8),
          const SizedBox(height: AffluenaSpacing.space3),
          Row(
            children: [
              Text(
                'Tercapai ${goal.progressPercent}%',
                style: TextStyle(fontSize: 13, color: context.sky.muted),
              ),
              const Spacer(),
              SkyStatusPill(
                label: achieved
                    ? 'Tercapai'
                    : (goal.isActive ? 'Aktif' : 'Selesai'),
                color: achieved
                    ? context.sky.income
                    : (goal.isActive ? context.sky.accent : context.sky.faint),
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
        ],
      ),
    );
  }
}
