/// Single source of truth for backend route paths (relative to
/// [EnvConfig.apiBaseUrl]). Keeping these in one place means a backend
/// route rename is a one-line fix instead of a repo-wide search.
class ApiEndpoints {
  ApiEndpoints._();

  // Auth
  static const String login = '/auth/login';
  static const String register = '/auth/register';
  static const String refreshToken = '/auth/refresh';
  static const String forgotPassword = '/auth/forgot-password';
  static const String me = '/auth/me';

  // Dashboard
  static const String dashboardSummary = '/dashboard/summary';

  // Inventory
  static const String products = '/inventory/products';
  static const String categories = '/inventory/categories';
  static const String suppliers = '/inventory/suppliers';

  // POS
  static const String invoices = '/pos/invoices';
  static const String posVoiceBilling = '/pos/voice-billing';

  // Customers
  static const String customers = '/customers';

  // Employees
  static const String employees = '/employees';

  // Reports
  static const String reports = '/reports';

  // AI Assistant
  static const String aiChat = '/ai/chat';
  static const String aiInsights = '/ai/insights';

  static String withId(String base, String id) => '$base/$id';
}
