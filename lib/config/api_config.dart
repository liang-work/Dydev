class ApiConfig {
  static const String baseUrl = 'https://dev-api.dy.ci/';
  static const String backendApiBase = '$baseUrl/api';

  // Must match server's OIDC_REDIRECT_AFTER_AUTH.
  static const String callbackUrl = 'https://developer.dy.ci/callback';

  // ---- Accounts ----
  static const String health = '/api/accounts/health/';
  static const String oidcConfig = '/api/accounts/oidc/config/';
  static const String oidcLogin = '/api/accounts/oidc/login/';
  static const String oidcCallback = '/api/accounts/oidc/callback/';
  static const String oidcLogout = '/api/accounts/oidc/logout/';
  static const String tokenRefresh = '/api/accounts/token/refresh/';
  static const String userMe = '/api/accounts/user/me/';
  static const String userProfile = '/api/accounts/user/profile/';
  static const String notifications = '/api/accounts/notifications/';

  // ---- Gitea ----
  static const String giteaAuthUrl = '/api/accounts/gitea/auth-url/';
  static const String giteaCallback = '/api/accounts/gitea/callback/';
  static const String giteaDisconnect = '/api/accounts/gitea/disconnect/';
  static const String giteaAccount = '/api/accounts/gitea/account/';

  // ---- Distribute: Softwares ----
  static const String softwares = '/api/distribute/softwares/';

  // ---- Distribute: Versions ----
  static const String versions = '/api/distribute/versions/';
  static const String channels = '/api/distribute/channels/';

  // ---- Distribute: Storages ----
  static const String storages = '/api/distribute/storages/';

  // ---- Announcement ----
  static const String announcements = '/api/announcement/announcements/';

  // ---- Telemetry ----
  static const String telemetryData = '/api/telemetry/data/';
  static const String telemetryStats = '/api/telemetry/data/stats/';
  static const String telemetryDefinitions = '/api/telemetry/definitions/';
  static const String telemetryIssues = '/api/telemetry/issues/';

  // ---- Config ----
  static const String configItems = '/api/config/items/';

  // ---- GitHub ----
  static const String githubOauth = '/api/github/oauth/';
  static const String githubAccount = '/api/github/account/';
  static const String githubRepos = '/api/github/account/repos/';
  static const String githubReleases = '/api/github/account/releases/';
  static const String githubMirrors = '/api/github/mirrors/';

  // ---- Store ----
  static const String storeApps = '/api/store/apps/';
  static const String storeMyApps = '/api/store/apps/my_apps/';

  // Helper: build a sub-resource URL
  static String resourceUrl(String base, Object id) => '$base$id/';
  static String actionUrl(String base, Object id, String action) =>
      '$base$id/$action/';
}
