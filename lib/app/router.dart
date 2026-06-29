import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/auth/application/auth_controller.dart';
import '../features/auth/presentation/auth_screens.dart';
import '../features/budgets/presentation/budget_detail_screen.dart';
import '../features/budgets/presentation/budget_screen.dart';
import '../features/categories/presentation/category_tag_management_screen.dart';
import '../features/debts/presentation/debt_detail_screen.dart';
import '../features/debts/presentation/debt_screen.dart';
import '../features/goals/presentation/goal_detail_screen.dart';
import '../features/goals/presentation/goal_screen.dart';
import '../features/insights/presentation/audit_log_screen.dart';
import '../features/insights/presentation/insights_screen.dart';
import '../features/onboarding/application/onboarding_controller.dart';
import '../features/onboarding/presentation/onboarding_screen.dart';
import '../features/partner/presentation/partner_screen.dart';
import '../features/quick_entry/presentation/quick_entry_screen.dart';
import '../features/quick_entry/presentation/quick_entry_templates_screen.dart';
import '../features/recurring/presentation/recurring_detail_screen.dart';
import '../features/recurring/presentation/recurring_screen.dart';
import '../features/redesign/presentation/activity_feed_screen.dart';
import '../features/redesign/presentation/redesign_shell.dart';
import '../features/redesign/presentation/room_detail_screen.dart';
import '../features/redesign/presentation/rooms_home_screen.dart';
import '../features/redesign/presentation/sky_insights_screen.dart';
import '../features/settings/presentation/settings_screen.dart';
import '../features/trackers/presentation/installment_detail_screen.dart';
import '../features/trackers/presentation/subscription_detail_screen.dart';
import '../features/trackers/presentation/tracker_screen.dart';
import '../features/transactions/presentation/split_bill_list_screen.dart';
import '../features/transactions/presentation/split_bill_screen.dart';
import '../features/transactions/presentation/transaction_create_screen.dart';
import '../features/transactions/presentation/transactions_screen.dart';
import '../features/wallets/presentation/wallet_detail_screen.dart';
import '../features/wallets/presentation/wallet_sharing_screen.dart';
import '../features/wallets/presentation/wallets_screen.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  final refreshNotifier = _RouterRefreshNotifier(ref);
  ref.onDispose(refreshNotifier.dispose);

  return GoRouter(
    initialLocation: AuthBootstrapScreen.path,
    refreshListenable: refreshNotifier,
    redirect: (context, state) {
      final authState = ref.read(authControllerProvider);
      final onboardingDone = ref.read(onboardingControllerProvider);
      final location = state.matchedLocation;
      final isBootstrap = location == AuthBootstrapScreen.path;
      final isAuthRoute = _publicAuthRoutes.contains(location);
      final atOnboarding = location == OnboardingScreen.path;

      // First-run onboarding gate (evaluated before auth).
      if (onboardingDone == null) {
        return isBootstrap ? null : AuthBootstrapScreen.path;
      }
      if (!onboardingDone) {
        return atOnboarding ? null : OnboardingScreen.path;
      }
      if (atOnboarding) {
        // Onboarding is complete here. Allow it to stay open only when it is
        // being reviewed from settings (?replay=true); otherwise the first-run
        // flow just finished, so move on to the normal auth destination.
        if (state.uri.queryParameters['replay'] == 'true') return null;
        return authState.isAuthenticated
            ? RedesignShell.path
            : LoginScreen.path;
      }

      if (authState.isChecking) {
        return isBootstrap ? null : AuthBootstrapScreen.path;
      }

      if (authState.isAuthenticated) {
        if (isBootstrap || isAuthRoute) return RedesignShell.path;
        return null;
      }

      if (isBootstrap) return LoginScreen.path;
      if (!isAuthRoute) return LoginScreen.path;
      return null;
    },
    routes: [
      GoRoute(
        path: AuthBootstrapScreen.path,
        pageBuilder: _fadePage((_) => const AuthBootstrapScreen()),
      ),
      GoRoute(
        path: LoginScreen.path,
        pageBuilder: _fadePage((_) => const LoginScreen()),
      ),
      GoRoute(
        path: RegisterScreen.path,
        pageBuilder: _fadePage((_) => const RegisterScreen()),
      ),
      GoRoute(
        path: ForgotPasswordScreen.path,
        pageBuilder: _fadePage((_) => const ForgotPasswordScreen()),
      ),
      GoRoute(
        path: OnboardingScreen.path,
        pageBuilder: _fadePage(
          (state) => OnboardingScreen(
            replay: state.uri.queryParameters['replay'] == 'true',
          ),
        ),
      ),
      GoRoute(
        path: ResetPasswordScreen.path,
        pageBuilder: _fadePage(
          (state) => ResetPasswordScreen(
            token: state.uri.queryParameters['token'],
            email: state.extra is String ? state.extra as String : null,
          ),
        ),
      ),
      // Feature surfaces. The old dashboard + 5-tab AppShell were retired in the
      // redesign final flip; these are now plain top-level routes reached from
      // the new shell (Home rooms → wallet detail, "Lainnya" → Settings → the
      // planning/insight modules) or via deep link.
      // The ex-tab screens (wallets/quick-entry/transactions/settings) each own
      // a DrillInScaffold (AppBar + back button) so they work as pushed routes
      // reached from the new shell.
      GoRoute(
        path: WalletsScreen.path,
        pageBuilder: _fadePage((_) => const WalletsScreen()),
      ),
      GoRoute(
        path: WalletDetailScreen.path,
        pageBuilder: _slidePage(
          (state) =>
              WalletDetailScreen(walletId: state.pathParameters['walletId']!),
        ),
      ),
      GoRoute(
        path: WalletSharingScreen.path,
        pageBuilder: _slidePage(
          (state) =>
              WalletSharingScreen(walletId: state.pathParameters['walletId']!),
        ),
      ),
      GoRoute(
        path: QuickEntryScreen.path,
        pageBuilder: _fadePage((_) => const QuickEntryScreen()),
      ),
      GoRoute(
        path: QuickEntryTemplatesScreen.path,
        pageBuilder: _slidePage((_) => const QuickEntryTemplatesScreen()),
      ),
      GoRoute(
        path: TransactionsScreen.path,
        pageBuilder: _fadePage((_) => const TransactionsScreen()),
      ),
      GoRoute(
        path: SplitBillListScreen.path,
        pageBuilder: _slidePage((_) => const SplitBillListScreen()),
      ),
      GoRoute(
        path: SplitBillScreen.path,
        pageBuilder: _slidePage((_) => const SplitBillScreen()),
      ),
      GoRoute(
        path: TransactionCreateScreen.path,
        pageBuilder: _slidePage((_) => const TransactionCreateScreen()),
      ),
      GoRoute(
        path: SettingsScreen.path,
        pageBuilder: _fadePage((_) => const SettingsScreen()),
      ),
      GoRoute(
        path: PartnerScreen.path,
        pageBuilder: _slidePage((_) => const PartnerScreen()),
      ),
      GoRoute(
        path: BudgetScreen.path,
        pageBuilder: _slidePage((_) => const BudgetScreen()),
      ),
      GoRoute(
        path: CategoryTagManagementScreen.path,
        pageBuilder: _slidePage((_) => const CategoryTagManagementScreen()),
      ),
      GoRoute(
        path: DebtScreen.path,
        pageBuilder: _slidePage((_) => const DebtScreen()),
      ),
      GoRoute(
        path: DebtDetailScreen.path,
        pageBuilder: _slidePage(
          (state) => DebtDetailScreen(debtId: state.pathParameters['debtId']!),
        ),
      ),
      GoRoute(
        path: TrackerScreen.path,
        pageBuilder: _slidePage((_) => const TrackerScreen()),
      ),
      GoRoute(
        path: RecurringScreen.path,
        pageBuilder: _slidePage((_) => const RecurringScreen()),
      ),
      GoRoute(
        path: GoalScreen.path,
        pageBuilder: _slidePage((_) => const GoalScreen()),
      ),
      GoRoute(
        path: InsightsScreen.path,
        pageBuilder: _slidePage(
          (state) => InsightsScreen(
            initialTab: InsightsScreen.tabFromQuery(
              state.uri.queryParameters['tab'],
            ),
          ),
        ),
      ),
      GoRoute(
        path: AuditLogScreen.path,
        pageBuilder: _slidePage((_) => const AuditLogScreen()),
      ),
      // Redesign surfaces. [RedesignShell] (/beranda) is the authenticated home;
      // the rooms/activity/insights standalone routes remain as deep-link
      // targets, and /rooms/:walletId is the room detail pushed from Home.
      GoRoute(
        path: RoomsHomeScreen.path,
        pageBuilder: _fadePage((_) => const RoomsHomeScreen()),
      ),
      GoRoute(
        path: RoomDetailScreen.path,
        pageBuilder: _slidePage(
          (state) =>
              RoomDetailScreen(walletId: state.pathParameters['walletId']!),
        ),
      ),
      // Per-item detail screens opened from the Beranda dashboard cards.
      GoRoute(
        path: BudgetDetailScreen.path,
        pageBuilder: _slidePage(
          (state) => BudgetDetailScreen(id: state.pathParameters['id']!),
        ),
      ),
      GoRoute(
        path: GoalDetailScreen.path,
        pageBuilder: _slidePage(
          (state) => GoalDetailScreen(id: state.pathParameters['id']!),
        ),
      ),
      GoRoute(
        path: InstallmentDetailScreen.path,
        pageBuilder: _slidePage(
          (state) => InstallmentDetailScreen(id: state.pathParameters['id']!),
        ),
      ),
      GoRoute(
        path: SubscriptionDetailScreen.path,
        pageBuilder: _slidePage(
          (state) => SubscriptionDetailScreen(id: state.pathParameters['id']!),
        ),
      ),
      GoRoute(
        path: RecurringDetailScreen.path,
        pageBuilder: _slidePage(
          (state) => RecurringDetailScreen(id: state.pathParameters['id']!),
        ),
      ),
      GoRoute(
        path: ActivityFeedScreen.path,
        pageBuilder: _slidePage((_) => const ActivityFeedScreen()),
      ),
      GoRoute(
        path: SkyInsightsScreen.path,
        pageBuilder: _slidePage((_) => const SkyInsightsScreen()),
      ),
      GoRoute(
        path: RedesignShell.path,
        pageBuilder: _fadePage((_) => const RedesignShell()),
      ),
    ],
  );
});

const _publicAuthRoutes = {
  LoginScreen.path,
  RegisterScreen.path,
  ForgotPasswordScreen.path,
  ResetPasswordScreen.path,
};

class _RouterRefreshNotifier extends ChangeNotifier {
  _RouterRefreshNotifier(Ref ref) {
    ref.listen<AuthState>(authControllerProvider, (_, next) {
      notifyListeners();
    });
    ref.listen(onboardingControllerProvider, (_, _) {
      notifyListeners();
    });
  }
}

Page<dynamic> Function(BuildContext, GoRouterState) _fadePage(
  Widget Function(GoRouterState state) builder,
) {
  return (context, state) {
    return CustomTransitionPage<void>(
      key: state.pageKey,
      child: builder(state),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(opacity: animation, child: child);
      },
    );
  };
}

/// Forward/back slide for drill-in screens, giving a clear spatial sense of
/// moving deeper and returning. Falls back to no animation under reduce-motion.
Page<dynamic> Function(BuildContext, GoRouterState) _slidePage(
  Widget Function(GoRouterState state) builder,
) {
  return (context, state) {
    return CustomTransitionPage<void>(
      key: state.pageKey,
      child: builder(state),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        if (MediaQuery.maybeDisableAnimationsOf(context) ?? false) {
          return child;
        }
        final position = animation.drive(
          Tween(
            begin: const Offset(1, 0),
            end: Offset.zero,
          ).chain(CurveTween(curve: Curves.easeOutCubic)),
        );
        final outgoing = secondaryAnimation.drive(
          Tween(
            begin: Offset.zero,
            end: const Offset(-0.2, 0),
          ).chain(CurveTween(curve: Curves.easeOutCubic)),
        );
        return SlideTransition(
          position: outgoing,
          child: SlideTransition(position: position, child: child),
        );
      },
    );
  };
}
