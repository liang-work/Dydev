import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ApiConfig {
  static const String _bootstrapBaseUrl = 'https://dev-api.dy.ci/';
  static const String _clientConfigPath = '/api/config/client/pull/';
  static const String _clientConfigToken = '4bcc1ebf038741a9faed516567211c0f';
  static const String _serverUrlCacheKey = 'server_url';

  static String baseUrl = _bootstrapBaseUrl;
  static String get backendApiBase => '${baseUrl}api';

  static Future<void> initialize() async {
    final preferences = await SharedPreferences.getInstance();
    final cachedUrl = preferences.getString(_serverUrlCacheKey);
    final normalizedCachedUrl = _normalizeServerUrl(cachedUrl);
    if (normalizedCachedUrl != null) {
      baseUrl = normalizedCachedUrl;
    }

    if (_clientConfigToken.isEmpty) return;

    try {
      final response = await Dio(
        BaseOptions(
          baseUrl: _bootstrapBaseUrl,
          connectTimeout: const Duration(seconds: 10),
          receiveTimeout: const Duration(seconds: 10),
        ),
      ).get(_clientConfigPath, queryParameters: {'token': _clientConfigToken});
      final data = response.data;
      final serverUrl = data is Map ? data['server_url'] as String? : null;
      final normalizedServerUrl = _normalizeServerUrl(serverUrl);
      if (normalizedServerUrl == null) return;

      baseUrl = normalizedServerUrl;
      await preferences.setString(_serverUrlCacheKey, normalizedServerUrl);
    } catch (_) {}
  }

  static String? _normalizeServerUrl(String? value) {
    final trimmedValue = value?.trim();
    if (trimmedValue == null || trimmedValue.isEmpty) return null;

    final candidate = trimmedValue.contains('://')
        ? trimmedValue
        : 'https://$trimmedValue';
    final uri = Uri.tryParse(candidate);
    if (uri == null ||
        !uri.hasAuthority ||
        (uri.scheme != 'http' && uri.scheme != 'https') ||
        uri.userInfo.isNotEmpty ||
        uri.hasQuery ||
        uri.hasFragment) {
      return null;
    }

    final isLocalhost =
        uri.host == 'localhost' || uri.host == '127.0.0.1' || uri.host == '::1';
    if (uri.scheme != 'https' && !isLocalhost) return null;

    final normalizedPath = uri.path.replaceAll(RegExp(r'/+$'), '');
    return uri.replace(path: '$normalizedPath/').toString();
  }

  // Must match server's OIDC_REDIRECT_AFTER_AUTH.
  static const String callbackUrl = 'https://developer.dy.ci/callback';

  // ---- Accounts ----
  static const String health = '/api/accounts/health/';
  static const String oidcConfig = '/api/accounts/oidc/config/';
  static const String oidcLogin = '/api/accounts/oidc/login/';
  static const String oidcCallback = '/api/accounts/oidc/callback/';
  static const String oidcLogout = '/api/accounts/oidc/logout/';
  static const String tokenRefresh = '/api/accounts/token/refresh/';
  static const String oauthDeviceLogin = '/api/accounts/oauth/device-login/';
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

  // ---- OSGames ----
  static const String osgamesGames = '/api/osgames/games/';
  static const String osgamesCategories = '/api/osgames/categories/';
  static const String osgamesIssues = '/api/osgames/issues/';
  static const String osgamesStats = '/api/osgames/stats/';
  static const String osgamesAdminPending = '/api/osgames/admin/pending/';
  static const String osgamesAdminApprove = '/api/osgames/admin/approve/';
  static const String osgamesAdminReject = '/api/osgames/admin/reject/';
  static const String osgamesAdminTakedown = '/api/osgames/admin/takedown/';
  static const String osgamesAdminBadges = '/api/osgames/admin/badges/';

  // ---- Store ----
  static const String storeApps = '/api/store/apps/';
  static const String storeMyApps = '/api/store/apps/my_apps/';

  // Helper: build a sub-resource URL
  static String resourceUrl(String base, Object id) => '$base$id/';
  static String actionUrl(String base, Object id, String action) =>
      '$base$id/$action/';
}
