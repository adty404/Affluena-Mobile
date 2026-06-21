import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

import '../features/dashboard/presentation/dashboard_screen.dart';
import '../features/quick_entry/presentation/quick_entry_screen.dart';
import '../features/settings/presentation/settings_screen.dart';
import '../features/shared/presentation/app_shell.dart';
import '../features/transactions/presentation/transactions_screen.dart';
import '../features/wallets/presentation/wallets_screen.dart';

final appRouter = GoRouter(
  initialLocation: DashboardScreen.path,
  routes: [
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
          ],
        ),
      ],
    ),
  ],
);

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
