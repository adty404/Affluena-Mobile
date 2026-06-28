import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/affluena_theme.dart';
import '../../../app/theme/sky_palette.dart';
import '../../../core/formatters/money_formatter.dart';
import '../../shared/presentation/widgets/drill_in_scaffold.dart';
import '../../shared/presentation/widgets/sky_detail.dart';
import '../../shared/presentation/widgets/sky_progress_bar.dart';
import '../application/budget_controller.dart';
import '../data/budget_models.dart';

/// Per-budget detail (Anggaran) in the Sky & Denim language — opened from a
/// Beranda dashboard card. Reads the budget from the already-loaded
/// [budgetControllerProvider]; editing stays in the budget list screen.
class BudgetDetailScreen extends ConsumerWidget {
  const BudgetDetailScreen({required this.id, super.key});

  final String id;

  static const path = '/budgets/:id';
  static String location(String id) => '/budgets/$id';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(budgetControllerProvider);
    BudgetSummary? budget;
    for (final b in state.budgets) {
      if (b.id == id) {
        budget = b;
        break;
      }
    }

    if (budget == null) {
      return DrillInScaffold(
        title: 'Anggaran',
        body: SkyDetailPlaceholder(
          loading: state.isLoading,
          message: 'Anggaran tidak ditemukan.',
        ),
      );
    }

    final over = budget.usagePercent >= 100;
    final accent = over ? context.sky.danger : context.sky.accent;

    return DrillInScaffold(
      title: state.categoryName(budget.categoryId),
      body: ListView(
        padding: AffluenaInsets.screen,
        children: [
          SkyDetailHero(
            label: 'Terpakai bulan ini',
            amount: MoneyFormatter.idr(budget.spentMinor),
            sub:
                'dari ${MoneyFormatter.idr(budget.limitMinor)} · sisa ${MoneyFormatter.idr(budget.remainingMinor)}',
            amountColor: over ? context.sky.danger : null,
          ),
          const SizedBox(height: AffluenaSpacing.space5),
          SkyProgressBar(
            value: budget.usagePercent / 100,
            height: 8,
            fillColor: accent,
          ),
          const SizedBox(height: AffluenaSpacing.space3),
          Row(
            children: [
              Text(
                'Terpakai ${budget.usagePercent.round()}%',
                style: TextStyle(fontSize: 13, color: context.sky.muted),
              ),
              const Spacer(),
              SkyStatusPill(
                label: over ? 'Lewat batas' : 'Aman',
                color: over ? context.sky.danger : context.sky.income,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
