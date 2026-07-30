import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/auth/presentation/providers/auth_state_provider.dart';
import '../../features/auth/presentation/screens/forgot_password_screen.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/register_screen.dart';
import '../../features/auth/presentation/screens/splash_screen.dart';
import '../../features/ai_assistant/presentation/screens/ai_assistant_screen.dart';
import '../../features/customers/presentation/screens/customers_screen.dart';
import '../../features/dashboard/presentation/screens/dashboard_screen.dart';
import '../../features/employees/presentation/screens/employees_screen.dart';
import '../../features/inventory/presentation/screens/inventory_screen.dart';
import '../../features/pos/presentation/screens/pos_screen.dart';
import '../../features/reports/presentation/screens/reports_screen.dart';
import '../../features/settings/presentation/screens/settings_screen.dart';
import '../../shared/widgets/app_shell.dart';
import 'route_names.dart';

/// Provider so the router can be rebuilt when [authStateProvider] changes
/// (login/logout should immediately redirect) — this is the standard
/// go_router + Riverpod refresh pattern.
final appRouterProvider = Provider<GoRouter>((ref) {
  // Watched (not just read) so this provider — and therefore the GoRouter
  // instance — rebuilds if the notifier itself is ever recreated (e.g. in
  // tests that override authRepositoryProvider mid-session).
  ref.watch(authStateProvider.notifier);
  return GoRouter(
    initialLocation: RouteNames.splash,
    refreshListenable: _AuthRefreshListenable(ref),
    redirect: (context, state) {
      final authState = ref.read(authStateProvider);
      final isSplash = state.matchedLocation == RouteNames.splash;
      final isAuthRoute = [
        RouteNames.login,
        RouteNames.register,
        RouteNames.forgotPassword,
      ].contains(state.matchedLocation);

      // Still restoring the session from secure storage — stay on splash.
      if (authState.status == AuthStatus.unknown) {
        return isSplash ? null : RouteNames.splash;
      }

      final isAuthenticated = authState.status == AuthStatus.authenticated;

      if (!isAuthenticated && !isAuthRoute) return RouteNames.login;
      if (isAuthenticated && (isAuthRoute || isSplash)) return RouteNames.dashboard;
      if (!isAuthenticated && isSplash) return RouteNames.login;

      return null;
    },
    routes: [
      GoRoute(path: RouteNames.splash, builder: (context, state) => const SplashScreen()),
      GoRoute(path: RouteNames.login, builder: (context, state) => const LoginScreen()),
      GoRoute(path: RouteNames.register, builder: (context, state) => const RegisterScreen()),
      GoRoute(path: RouteNames.forgotPassword, builder: (context, state) => const ForgotPasswordScreen()),
      ShellRoute(
        builder: (context, state, child) {
          return AppShell(currentPath: state.matchedLocation, child: child);
        },
        routes: [
          GoRoute(path: RouteNames.dashboard, builder: (context, state) => const DashboardScreen()),
          GoRoute(path: RouteNames.pos, builder: (context, state) => const PosScreen()),
          GoRoute(path: RouteNames.inventory, builder: (context, state) => const InventoryScreen()),
          GoRoute(path: RouteNames.customers, builder: (context, state) => const CustomersScreen()),
          GoRoute(path: RouteNames.employees, builder: (context, state) => const EmployeesScreen()),
          GoRoute(path: RouteNames.reports, builder: (context, state) => const ReportsScreen()),
          GoRoute(path: RouteNames.aiAssistant, builder: (context, state) => const AiAssistantScreen()),
          GoRoute(path: RouteNames.settings, builder: (context, state) => const SettingsScreen()),
        ],
      ),
    ],
  );
});

/// Bridges Riverpod's [authStateProvider] to a [Listenable] so GoRouter's
/// `refreshListenable` can trigger re-evaluation of `redirect` whenever the
/// session state changes.
class _AuthRefreshListenable extends ChangeNotifier {
  _AuthRefreshListenable(Ref ref) {
    ref.listen(authStateProvider, (previous, next) {
      if (previous?.status != next.status) notifyListeners();
    });
  }
}
