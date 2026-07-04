/// API endpoint constants for the Developer Platform.
class ApiConfig {
  /// Base URL for all API requests.
  static const String baseUrl = 'https://dev-api.dy.ci/';

  // ---- Accounts ----
  static const String health = '/api/accounts/health/';
  static const String oidcConfig = '/api/accounts/oidc/config/';
  static const String oidcLogin = '/api/accounts/oidc/login/';
  static const String oidcCallback = '/api/accounts/oidc/callback/';
  static const String tokenRefresh = '/api/accounts/token/refresh/';
  static const String userMe = '/api/accounts/user/me/';

  // ---- Store ----
  static const String storeApps = '/api/store/apps/';
  static const String storeMyApps = '/api/store/apps/my_apps/';
  static const String storeStats = '/api/store/stats/';
  static const String storeFeatured = '/api/store/featured/';
  static const String storeRecent = '/api/store/recent/';
  static const String storeTop = '/api/store/top/';
}
