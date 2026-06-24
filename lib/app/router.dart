import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/budgets/presentation/budget_screen.dart';
import '../features/categories/presentation/category_tag_management_screen.dart';
import '../features/dashboard/presentation/dashboard_screen.dart';
import '../features/auth/application/auth_controller.dart';
import '../features/auth/presentation/auth_screens.dart';
import '../features/debts/presentation/debt_detail_screen.dart';
import '../features/debts/presentation/debt_screen.dart';
import '../features/goals/presentation/goal_screen.dart';
import '../features/insights/presentation/audit_log_screen.dart';
import '../features/insights/presentation/insights_screen.dart';
import '../features/onboarding/application/onboarding_controller.dart';
import '../features/onboarding/presentation/onboarding_screen.dart';
import '../features/quick_entry/presentation/quick_entry_templates_screen.dart';
import '../features/quick_entry/presentation/quick_entry_screen.dart';
import '../features/recurring/presentation/recurring_screen.dart';
import '../features/settings/presentation/security_screen.dart';
import '../features/settings/presentation/settings_screen.dart';
import '../features/shared/presentation/app_shell.dart';
import '../features/trackers/presentation/tracker_screen.dart';
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
            ? DashboardScreen.path
            : LoginScreen.path;
      }

      if (authState.isChecking) {
        return isBootstrap ? null : AuthBootstrapScreen.path;
      }

      if (authState.isAuthenticated) {
        if (isBootstrap || isAuthRoute) return DashboardScreen.path;
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
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return AppShell(navigationShell: navigationShell);
        },
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: DashboardScreen.path,
                pageBuilder: _fadePage((_) => const DashboardScreen()),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: WalletsScreen.path,
                pageBuilder: _fadePage((_) => const WalletsScreen()),
              ),
              GoRoute(
                path: WalletDetailScreen.path,
                pageBuilder: _fadePage(
                  (state) => WalletDetailScreen(
                    walletId: state.pathParameters['walletId']!,
                  ),
                ),
              ),
              GoRoute(
                path: WalletSharingScreen.path,
                pageBuilder: _fadePage(
                  (state) => WalletSharingScreen(
                    walletId: state.pathParameters['walletId']!,
                  ),
                ),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: QuickEntryScreen.path,
                pageBuilder: _fadePage((_) => const QuickEntryScreen()),
              ),
              GoRoute(
                path: QuickEntryTemplatesScreen.path,
                pageBuilder: _fadePage(
                  (_) => const QuickEntryTemplatesScreen(),
                ),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: TransactionsScreen.path,
                pageBuilder: _fadePage((_) => const TransactionsScreen()),
              ),
              GoRoute(
                path: SplitBillScreen.path,
                pageBuilder: _fadePage((_) => const SplitBillScreen()),
              ),
              GoRoute(
                path: TransactionCreateScreen.path,
                pageBuilder: _fadePage((_) => const TransactionCreateScreen()),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: SettingsScreen.path,
                pageBuilder: _fadePage((_) => const SettingsScreen()),
              ),
              GoRoute(
                path: BudgetScreen.path,
                pageBuilder: _fadePage((_) => const BudgetScreen()),
              ),
              GoRoute(
                path: CategoryTagManagementScreen.path,
                pageBuilder: _fadePage(
                  (_) => const CategoryTagManagementScreen(),
                ),
              ),
              GoRoute(
                path: DebtScreen.path,
                pageBuilder: _fadePage((_) => const DebtScreen()),
              ),
              GoRoute(
                path: DebtDetailScreen.path,
                pageBuilder: _fadePage(
                  (state) =>
                      DebtDetailScreen(debtId: state.pathParameters['debtId']!),
                ),
              ),
              GoRoute(
                path: TrackerScreen.path,
                pageBuilder: _fadePage((_) => const TrackerScreen()),
              ),
              GoRoute(
                path: RecurringScreen.path,
                pageBuilder: _fadePage((_) => const RecurringScreen()),
              ),
              GoRoute(
                path: GoalScreen.path,
                pageBuilder: _fadePage((_) => const GoalScreen()),
              ),
              GoRoute(
                path: InsightsScreen.path,
                pageBuilder: _fadePage(
                  (state) => InsightsScreen(
                    initialTab: InsightsScreen.tabFromQuery(
                      state.uri.queryParameters['tab'],
                    ),
                  ),
                ),
              ),
              GoRoute(
                path: AuditLogScreen.path,
                pageBuilder: _fadePage((_) => const AuditLogScreen()),
              ),
              GoRoute(
                path: SecurityScreen.path,
                pageBuilder: _fadePage((_) => const SecurityScreen()),
              ),
            ],
          ),
        ],
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
