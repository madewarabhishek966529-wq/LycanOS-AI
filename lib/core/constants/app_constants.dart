/// Global, environment-independent constants for LycanOS AI.
///
/// Anything that changes between environments (dev/staging/prod) belongs in
/// [EnvConfig], not here.
class AppConstants {
  AppConstants._();

  // App metadata
  static const String appName = 'LycanOS AI';
  static const String appTagline = 'AI-Powered Business OS';
  static const String appVersion = '0.1.0';

  // Local storage box / table names
  static const String hiveAuthBox = 'lycanos_auth_box';
  static const String hiveSettingsBox = 'lycanos_settings_box';
  static const String hiveCacheBox = 'lycanos_cache_box';

  // Secure storage keys
  static const String keyAccessToken = 'access_token';
  static const String keyRefreshToken = 'refresh_token';
  static const String keyUserRole = 'user_role';

  // Pagination
  static const int defaultPageSize = 20;

  // Timeouts
  static const Duration connectTimeout = Duration(seconds: 15);
  static const Duration receiveTimeout = Duration(seconds: 20);

  // Sync
  static const Duration syncRetryInterval = Duration(seconds: 30);

  // Roles (mirrors backend RBAC roles — see backend/app/core/security.py)
  static const String roleOwner = 'owner';
  static const String roleManager = 'manager';
  static const String roleCashier = 'cashier';
  static const String roleEmployee = 'employee';
}
