import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/budgets/presentation/budget_screen.dart';
import '../features/dashboard/presentation/dashboard_screen.dart';
import '../features/auth/application/auth_controller.dart';
import '../features/auth/presentation/auth_screens.dart';
import '../features/debts/presentation/debt_screen.dart';
import '../features/quick_entry/presentation/quick_entry_screen.dart';
import '../features/settings/presentation/settings_screen.dart';
import '../features/shared/presentation/app_shell.dart';
import '../features/transactions/presentation/transactions_screen.dart';
import '../features/wallets/presentation/wallets_screen.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  final refreshNotifier = _RouterRefreshNotifier(ref);
  ref.onDispose(refreshNotifier.dispose);

  return GoRouter(
    initialLocation: AuthBootstrapScreen.path,
    refreshListenable: refreshNotifier,
    redirect: (context, state) {
      final authState = ref.read(authControllerProvider);
      final location = state.matchedLocation;
      final isBootstrap = location == AuthBootstrapScreen.path;
      final isAuthRoute = _publicAuthRoutes.contains(location);

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
        path: ResetPasswordScreen.path,
        pageBuilder: _fadePage((_) => const ResetPasswordScreen()),
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
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: QuickEntryScreen.path,
                pageBuilder: _fadePage((_) => const QuickEntryScreen()),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: TransactionsScreen.path,
                pageBuilder: _fadePage((_) => const TransactionsScreen()),
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
                path: DebtScreen.path,
                pageBuilder: _fadePage((_) => const DebtScreen()),
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
