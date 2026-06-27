import 'package:clock/clock.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/affluena_theme.dart';
import '../../../core/api/api_error.dart';
import '../../../core/formatters/date_formatter.dart';
import '../../../core/formatters/money_formatter.dart';
import '../../auth/application/auth_controller.dart';
import '../../budgets/presentation/budget_screen.dart';
import '../../quick_entry/presentation/quick_entry_screen.dart';
import '../../shared/presentation/widgets/affluena_card.dart';
import '../../shared/presentation/widgets/affluena_skeleton.dart';
import '../../shared/presentation/widgets/metric_tile.dart';
import '../../shared/presentation/widgets/section_header.dart';
import '../../shared/presentation/widgets/transaction_tile.dart';
import '../../trackers/presentation/tracker_screen.dart';
import '../../transactions/application/transactions_controller.dart';
import '../../transactions/data/transaction_models.dart';
import '../../transactions/presentation/transaction_detail_sheet.dart';
import '../../transactions/presentation/transactions_screen.dart';
import '../../wallets/presentation/wallets_screen.dart';
import '../application/dashboard_home_controller.dart';
import '../data/dashboard_models.dart';
part 'dashboard_sections.dart';
part 'dashboard_support.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  static const path = '/';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final home = ref.watch(dashboardHomeProvider);

    return home.when(
      skipLoadingOnReload: true,
      loading: () => const _DashboardLoading(),
      error: (error, stackTrace) => _DashboardError(
        message: _dashboardErrorMessage(error),
        onRetry: () => ref.invalidate(dashboardHomeProvider),
      ),
      data: (home) => _DashboardContent(home: home),
    );
  }
}

class _DashboardContent extends ConsumerWidget {
  const _DashboardContent({required this.home});

  final DashboardHome home;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summary = home.summary;
    final user = ref.watch(authControllerProvider).user;

    return SafeArea(
      child: ListView(
        padding: AffluenaInsets.screen,
        children: [
          _DashboardHeader(
            // clock.now() (not DateTime.now()) so golden tests can freeze the
            // time-of-day greeting via withClock; identical to now() in prod.
            greeting: _greetingForNow(clock.now()),
            initial: _avatarInitial(user?.name, user?.email),
          ),
          const SizedBox(height: AffluenaSpacing.space6),
          _BalanceCard(summary: summary),
          const SizedBox(height: AffluenaSpacing.space5),
          const _QuickActions(),
          const SizedBox(height: AffluenaSpacing.space6),
          home.isEmpty
              ? const _EmptyDashboardState()
              : _BudgetCard(summary: summary),
          if (summary.hasUpcoming) ...[
            const SizedBox(height: AffluenaSpacing.space6),
            _UpcomingSection(summary: summary),
          ],
          const SizedBox(height: AffluenaSpacing.space6),
          SectionHeader(
            title: 'Recent transactions',
            actionLabel: 'See all',
            onAction: () => context.go(TransactionsScreen.path),
          ),
          const SizedBox(height: AffluenaSpacing.space2),
          _RecentTransactions(home: home),
        ],
      ),
    );
  }
}
