/// Route path + name constants for GoRouter.
///
/// Feature screens are added to [AppRouter] as their phases land; this file
/// is the stable contract other features/tests reference by name so route
/// strings never get hand-typed and mistyped elsewhere.
class RouteNames {
  RouteNames._();

  static const String splash = '/splash';
  static const String login = '/login';
  static const String register = '/register';
  static const String forgotPassword = '/forgot-password';

  static const String dashboard = '/dashboard';
  static const String pos = '/pos';
  static const String inventory = '/inventory';
  static const String customers = '/customers';
  static const String employees = '/employees';
  static const String reports = '/reports';
  static const String aiAssistant = '/ai-assistant';
  static const String settings = '/settings';
}
