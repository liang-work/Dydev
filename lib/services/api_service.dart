import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../config/api_config.dart';
import '../models/user.dart';
import '../models/store_app.dart';
import '../models/notification.dart';
import '../models/software.dart';
import '../models/version.dart';
import '../models/channel.dart';
import '../models/software_member.dart';
import '../models/storage_backend.dart';
import '../models/storage_file.dart';
import '../models/announcement.dart';
import '../models/telemetry_data.dart';
import '../models/config_item.dart';
import '../models/github_account.dart';
import '../models/gitea_account.dart';
import '../models/game.dart';
import '../models/game_category.dart';
import '../models/game_issue.dart';
import '../utils/http_status.dart';
import 'auth_service.dart';
import 'logger_service.dart';

class ApiService {
  static const _tag = 'ApiService';

  late final Dio _dio;
  final AuthService _authService;
  final VoidCallback? _onForceLogout;

  ApiService({required this._authService, this._onForceLogout}) {
    LoggerService.d(_tag, 'Initialising API service (baseUrl: ${ApiConfig.baseUrl})');

    _dio = Dio(BaseOptions(
      baseUrl: ApiConfig.baseUrl,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 15),
      headers: {'Content-Type': 'application/json'},
    ));

    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) {
        LoggerService.d(_tag, '--> ${options.method} ${options.path}');
        handler.next(options);
      },
      onResponse: (response, handler) {
        LoggerService.d(_tag, '<-- ${response.statusCode} ${response.requestOptions.path}');
        handler.next(response);
      },
      onError: (error, handler) {
        LoggerService.e(_tag, '<-- ERROR ${error.response?.statusCode} ${error.requestOptions.path}: ${error.message}', error.error, error.stackTrace);
        handler.next(error);
      },
    ));

    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await _authService.getAccessToken();
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        handler.next(options);
      },
      onError: (error, handler) async {
        final statusCode = error.response?.statusCode ?? 0;
        if (statusCode == 401) {
          LoggerService.w(_tag, 'Got 401, attempting token refresh ...');
          final refreshToken = await _authService.getRefreshToken();
          if (refreshToken != null) {
            try {
              final refreshResponse = await Dio(BaseOptions(baseUrl: ApiConfig.baseUrl)).post(
                ApiConfig.tokenRefresh,
                data: {'refresh': refreshToken},
              );
              final newAccess = refreshResponse.data['access'] as String;
              LoggerService.i(_tag, 'Token refreshed successfully');
              await _authService.saveTokens(accessToken: newAccess);
              final retryOptions = error.requestOptions;
              retryOptions.headers['Authorization'] = 'Bearer $newAccess';
              final retryResponse = await _dio.fetch(retryOptions);
              return handler.resolve(retryResponse);
            } catch (e) {
              LoggerService.e(_tag, 'Token refresh failed', e);
            }
          }
          LoggerService.w(_tag, 'Token refresh failed or no refresh token, forcing logout');
          _onForceLogout?.call();
          return handler.resolve(Response(requestOptions: error.requestOptions));
        }
        showHttpErrorDialog(statusCode);
        handler.next(error);
      },
    ));
  }

  /// Unwrap a DRF paginated or non-paginated list response.
  List _unwrapList(dynamic data) {
    if (data is List) {
      LoggerService.d(_tag, '_unwrapList: raw list count=${data.length}');
      return data;
    }
    if (data is Map && data['results'] is List) {
      final list = data['results'] as List;
      LoggerService.d(_tag, '_unwrapList: results count=${list.length}');
      return list;
    }
    if (data is Map && data['data'] is List) return data['data'] as List;
    LoggerService.w(_tag, 'Unexpected API response format: ${data.runtimeType}');
    if (data is Map) {
      final keys = data.keys.join(', ');
      LoggerService.w(_tag, '  Map keys: $keys');
    }
    return [];
  }

  // ---- Auth ----
  Future<User> validateToken(String token) async {
    final response = await Dio(BaseOptions(baseUrl: ApiConfig.baseUrl)).get(
      ApiConfig.userMe,
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );
    return User.fromJson(response.data);
  }

  Future<User> getUserProfile() async {
    final response = await _dio.get(ApiConfig.userMe);
    return User.fromJson(response.data);
  }

  Future<User> updateProfile(Map<String, dynamic> data) async {
    final response = await _dio.patch(ApiConfig.userProfile, data: data);
    return User.fromJson(response.data);
  }

  // ---- Store ----
  Future<List<StoreApp>> getMyApps() async {
    final response = await _dio.get(ApiConfig.storeMyApps);
    return _unwrapList(response.data).map((j) => StoreApp.fromJson(j)).toList();
  }

  Future<List<StoreApp>> getStoreApps() async {
    final response = await _dio.get(ApiConfig.storeApps);
    return _unwrapList(response.data).map((j) => StoreApp.fromJson(j)).toList();
  }

  Future<StoreApp> createStoreApp(Map<String, dynamic> data) async {
    final response = await _dio.post(ApiConfig.storeApps, data: data);
    return StoreApp.fromJson(response.data);
  }

  Future<StoreApp> updateStoreApp(Object id, Map<String, dynamic> data) async {
    final response = await _dio.put(ApiConfig.resourceUrl(ApiConfig.storeApps, id), data: data);
    return StoreApp.fromJson(response.data);
  }

  Future<void> deleteStoreApp(Object id) async {
    await _dio.delete(ApiConfig.resourceUrl(ApiConfig.storeApps, id));
  }

  Future<void> publishStoreApp(Object id) async {
    await _dio.post(ApiConfig.actionUrl(ApiConfig.storeApps, id, 'publish'));
  }

  Future<void> unpublishStoreApp(Object id) async {
    await _dio.post(ApiConfig.actionUrl(ApiConfig.storeApps, id, 'unpublish'));
  }

  Future<List<Map<String, dynamic>>> getStoreCategories() async {
    final response = await _dio.get('/api/store/categories/');
    return _unwrapList(response.data).cast<Map<String, dynamic>>();
  }

  Future<void> syncStoreAppVersion(Object id) async {
    await _dio.post(ApiConfig.actionUrl(ApiConfig.storeApps, id, 'sync_version'));
  }

  // ---- Notifications ----
  Future<List<NotificationModel>> getNotifications() async {
    final response = await _dio.get(ApiConfig.notifications);
    return _unwrapList(response.data).map((j) => NotificationModel.fromJson(j)).toList();
  }

  Future<void> markNotificationRead(int id) async {
    await _dio.post(ApiConfig.actionUrl(ApiConfig.notifications, id, 'mark_read'));
  }

  Future<void> acceptInvitation(int id) async {
    await _dio.post(ApiConfig.actionUrl(ApiConfig.notifications, id, 'accept'));
  }

  Future<void> rejectInvitation(int id) async {
    await _dio.post(ApiConfig.actionUrl(ApiConfig.notifications, id, 'reject'));
  }

  // ---- Softwares ----
  Future<List<Software>> getSoftwares() async {
    final response = await _dio.get(ApiConfig.softwares);
    return _unwrapList(response.data).map((j) => Software.fromJson(j)).toList();
  }

  Future<Software> getSoftware(String id) async {
    final response = await _dio.get(ApiConfig.resourceUrl(ApiConfig.softwares, id));
    return Software.fromJson(response.data);
  }

  Future<Software> createSoftware(Map<String, dynamic> data) async {
    final response = await _dio.post(ApiConfig.softwares, data: data);
    return Software.fromJson(response.data);
  }

  Future<Software> updateSoftware(String id, Map<String, dynamic> data) async {
    final response = await _dio.put(ApiConfig.resourceUrl(ApiConfig.softwares, id), data: data);
    return Software.fromJson(response.data);
  }

  Future<void> deleteSoftware(String id) async {
    await _dio.delete(ApiConfig.resourceUrl(ApiConfig.softwares, id));
  }

  Future<Map<String, dynamic>> resetSoftwareToken(String id) async {
    final response = await _dio.post(ApiConfig.actionUrl(ApiConfig.softwares, id, 'reset_token'));
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> resetTelemetryToken(String id) async {
    final response = await _dio.post(ApiConfig.actionUrl(ApiConfig.softwares, id, 'reset_telemetry_token'));
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> resetAnnouncementToken(String id) async {
    final response = await _dio.post(ApiConfig.actionUrl(ApiConfig.softwares, id, 'reset_announcement_token'));
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> resetUpdateToken(String id) async {
    final response = await _dio.post(ApiConfig.actionUrl(ApiConfig.softwares, id, 'reset_update_token'));
    return response.data as Map<String, dynamic>;
  }

  // ---- Members ----
  Future<List<SoftwareMember>> getMembers(String softwareId) async {
    final response = await _dio.get(ApiConfig.actionUrl(ApiConfig.softwares, softwareId, 'members'));
    return _unwrapList(response.data).map((j) => SoftwareMember.fromJson(j)).toList();
  }

  Future<void> addMember(String softwareId, Map<String, dynamic> data) async {
    await _dio.post(ApiConfig.actionUrl(ApiConfig.softwares, softwareId, 'members'), data: data);
  }

  Future<void> removeMember(String softwareId, String memberId) async {
    await _dio.delete('${ApiConfig.actionUrl(ApiConfig.softwares, softwareId, 'members')}$memberId/');
  }

  // ---- Channels ----
  Future<List<Channel>> getChannels([String? softwareId]) async {
    if (softwareId != null) {
      final response = await _dio.get(ApiConfig.actionUrl(ApiConfig.softwares, softwareId, 'channels'));
      return _unwrapList(response.data).map((j) => Channel.fromJson(j)).toList();
    }
    final response = await _dio.get(ApiConfig.channels);
    return _unwrapList(response.data).map((j) => Channel.fromJson(j)).toList();
  }

  Future<Channel> createChannel(Map<String, dynamic> data) async {
    final response = await _dio.post(ApiConfig.channels, data: data);
    return Channel.fromJson(response.data);
  }

  Future<Channel> updateChannel(String id, Map<String, dynamic> data) async {
    final response = await _dio.put(ApiConfig.resourceUrl(ApiConfig.channels, id), data: data);
    return Channel.fromJson(response.data);
  }

  Future<void> deleteChannel(String id) async {
    await _dio.delete(ApiConfig.resourceUrl(ApiConfig.channels, id));
  }

  // ---- Versions ----
  Future<List<Version>> getVersions(String softwareId) async {
    final response = await _dio.get(ApiConfig.actionUrl(ApiConfig.softwares, softwareId, 'versions'));
    return _unwrapList(response.data).map((j) => Version.fromJson(j)).toList();
  }

  Future<Version> createVersion(Map<String, dynamic> data) async {
    final response = await _dio.post(ApiConfig.versions, data: data);
    return Version.fromJson(response.data);
  }

  Future<Version> updateVersion(String id, Map<String, dynamic> data) async {
    final response = await _dio.put(ApiConfig.resourceUrl(ApiConfig.versions, id), data: data);
    return Version.fromJson(response.data);
  }

  Future<void> deleteVersion(String id) async {
    await _dio.delete(ApiConfig.resourceUrl(ApiConfig.versions, id));
  }

  Future<void> publishVersion(String id) async {
    await _dio.post(ApiConfig.actionUrl(ApiConfig.versions, id, 'publish'));
  }

  Future<void> deprecateVersion(String id) async {
    await _dio.post(ApiConfig.actionUrl(ApiConfig.versions, id, 'deprecate'));
  }

  Future<void> setGrayVersion(String id, int percentage) async {
    await _dio.post(ApiConfig.actionUrl(ApiConfig.versions, id, 'set_gray'), data: {'percentage': percentage});
  }

  // ---- Storages ----
  Future<List<StorageBackend>> getStorages() async {
    final response = await _dio.get(ApiConfig.storages);
    return _unwrapList(response.data).map((j) => StorageBackend.fromJson(j)).toList();
  }

  Future<StorageBackend> getStorage(String id) async {
    final response = await _dio.get(ApiConfig.resourceUrl(ApiConfig.storages, id));
    return StorageBackend.fromJson(response.data);
  }

  Future<StorageBackend> createStorage(Map<String, dynamic> data) async {
    final response = await _dio.post(ApiConfig.storages, data: data);
    return StorageBackend.fromJson(response.data);
  }

  Future<StorageBackend> updateStorage(String id, Map<String, dynamic> data) async {
    final response = await _dio.put(ApiConfig.resourceUrl(ApiConfig.storages, id), data: data);
    return StorageBackend.fromJson(response.data);
  }

  Future<void> deleteStorage(String id) async {
    await _dio.delete(ApiConfig.resourceUrl(ApiConfig.storages, id));
  }

  Future<Map<String, dynamic>> testStorageConnection(String id) async {
    final response = await _dio.post(ApiConfig.actionUrl(ApiConfig.storages, id, 'test_connection'));
    return response.data as Map<String, dynamic>;
  }

  Future<List<StorageFile>> getStorageFiles(String storageId, {String prefix = ''}) async {
    final params = prefix.isNotEmpty ? {'prefix': prefix} : null;
    final response = await _dio.get(
      ApiConfig.actionUrl(ApiConfig.storages, storageId, 'files'),
      queryParameters: params,
    );
    final data = response.data;
    final files = (data is Map ? data['files'] : data) as List;
    return files.map((j) => StorageFile.fromJson(j)).toList();
  }

  Future<void> uploadFile(String storageId, String filePath, String fileName,
      {String pathPrefix = '', void Function(int, int)? onProgress}) async {
    final formData = FormData.fromMap({
      'file': await MultipartFile.fromFile(filePath, filename: fileName),
      if (pathPrefix.isNotEmpty) 'path': pathPrefix,
    });
    await _dio.post(
      ApiConfig.actionUrl(ApiConfig.storages, storageId, 'upload'),
      data: formData,
      options: Options(contentType: 'multipart/form-data'),
      onSendProgress: onProgress != null
          ? (sent, total) => onProgress(sent, total)
          : null,
    );
  }

  Future<void> createFolder(String storageId, String path, String name) async {
    await _dio.post(
      ApiConfig.actionUrl(ApiConfig.storages, storageId, 'create_folder'),
      data: {'path': path, 'name': name},
    );
  }

  Future<void> renameFile(String storageId, String key, String newName) async {
    await _dio.post(
      ApiConfig.actionUrl(ApiConfig.storages, storageId, 'rename'),
      data: {'key': key, 'new_name': newName},
    );
  }

  Future<void> deleteStorageFile(String storageId, String key) async {
    await _dio.post(
      ApiConfig.actionUrl(ApiConfig.storages, storageId, 'delete_file'),
      data: {'key': key},
    );
  }

  Future<String> generateStorageUrl(String storageId, String key, String linkType, {int expires = 86400}) async {
    final response = await _dio.get(
      ApiConfig.actionUrl(ApiConfig.storages, storageId, 'generate_url'),
      queryParameters: {'key': key, 'link_type': linkType, 'expires': expires},
    );
    return response.data['url'] as String;
  }

  // ---- Announcements ----
  Future<List<Announcement>> getAnnouncements(String softwareId) async {
    final response = await _dio.get(
      ApiConfig.announcements,
      queryParameters: {'software': softwareId},
    );
    return _unwrapList(response.data).map((j) => Announcement.fromJson(j)).toList();
  }

  Future<Announcement> createAnnouncement(Map<String, dynamic> data) async {
    final response = await _dio.post(ApiConfig.announcements, data: data);
    return Announcement.fromJson(response.data);
  }

  Future<Announcement> updateAnnouncement(String id, Map<String, dynamic> data) async {
    final response = await _dio.put(ApiConfig.resourceUrl(ApiConfig.announcements, id), data: data);
    return Announcement.fromJson(response.data);
  }

  Future<void> deleteAnnouncement(String id) async {
    await _dio.delete(ApiConfig.resourceUrl(ApiConfig.announcements, id));
  }

  Future<Announcement> publishAnnouncement(String id) async {
    final response = await _dio.post(ApiConfig.actionUrl(ApiConfig.announcements, id, 'publish'));
    return Announcement.fromJson(response.data);
  }

  // ---- Telemetry ----
  Future<List<TelemetryData>> getTelemetryData({Map<String, dynamic>? params}) async {
    final response = await _dio.get(ApiConfig.telemetryData, queryParameters: params);
    return _unwrapList(response.data).map((j) => TelemetryData.fromJson(j)).toList();
  }

  Future<void> deleteTelemetryData(int id) async {
    await _dio.delete(ApiConfig.resourceUrl(ApiConfig.telemetryData, id));
  }

  Future<void> batchDeleteTelemetry(List<int> ids) async {
    await _dio.post('${ApiConfig.telemetryData}batch-delete/', data: {'ids': ids});
  }

  Future<Map<String, dynamic>> getTelemetryStats(String softwareId, {Map<String, dynamic>? params}) async {
    final queryParams = params ?? {};
    queryParams['software'] = softwareId;
    final response = await _dio.get(ApiConfig.telemetryStats, queryParameters: queryParams);
    return response.data as Map<String, dynamic>;
  }

  Future<List<Map<String, dynamic>>> getMetricDefinitions({Map<String, dynamic>? params}) async {
    final response = await _dio.get(ApiConfig.telemetryDefinitions, queryParameters: params);
    return _unwrapList(response.data).cast<Map<String, dynamic>>();
  }

  Future<void> createMetricDefinition(Map<String, dynamic> data) async {
    await _dio.post(ApiConfig.telemetryDefinitions, data: data);
  }

  Future<void> updateMetricDefinition(int id, Map<String, dynamic> data) async {
    await _dio.put(ApiConfig.resourceUrl(ApiConfig.telemetryDefinitions, id), data: data);
  }

  Future<void> deleteMetricDefinition(int id) async {
    await _dio.delete(ApiConfig.resourceUrl(ApiConfig.telemetryDefinitions, id));
  }

  Future<List<Map<String, dynamic>>> getIssues({Map<String, dynamic>? params}) async {
    final response = await _dio.get(ApiConfig.telemetryIssues, queryParameters: params);
    return _unwrapList(response.data).cast<Map<String, dynamic>>();
  }

  Future<void> updateIssue(int id, Map<String, dynamic> data) async {
    await _dio.put(ApiConfig.resourceUrl(ApiConfig.telemetryIssues, id), data: data);
  }

  Future<List<TelemetryData>> getIssueLogs(int issueId) async {
    final response = await _dio.get(ApiConfig.actionUrl(ApiConfig.telemetryIssues, issueId, 'logs'));
    return _unwrapList(response.data).map((j) => TelemetryData.fromJson(j)).toList();
  }

  // ---- Config Items ----
  Future<List<ConfigItem>> getConfigItems({required String softwareId}) async {
    final response = await _dio.get(
      ApiConfig.configItems,
      queryParameters: {'software': softwareId},
    );
    return _unwrapList(response.data).map((j) => ConfigItem.fromJson(j)).toList();
  }

  Future<ConfigItem> createConfigItem(Map<String, dynamic> data) async {
    final response = await _dio.post(ApiConfig.configItems, data: data);
    return ConfigItem.fromJson(response.data);
  }

  Future<ConfigItem> updateConfigItem(String id, Map<String, dynamic> data) async {
    final response = await _dio.put(ApiConfig.resourceUrl(ApiConfig.configItems, id), data: data);
    return ConfigItem.fromJson(response.data);
  }

  Future<void> deleteConfigItem(String id) async {
    await _dio.delete(ApiConfig.resourceUrl(ApiConfig.configItems, id));
  }

  // ---- GitHub ----
  Future<Map<String, dynamic>> getGithubOAuthUrl() async {
    final response = await _dio.get(ApiConfig.githubOauth);
    return response.data as Map<String, dynamic>;
  }

  Future<GitHubAccount?> getGithubAccount() async {
    try {
      final response = await _dio.get(ApiConfig.githubAccount);
      return GitHubAccount.fromJson(response.data);
    } catch (_) {
      return null;
    }
  }

  Future<void> unbindGithub() async {
    await _dio.delete('${ApiConfig.githubAccount}unbind/');
  }

  Future<List<Map<String, dynamic>>> getGithubRepos() async {
    final response = await _dio.get(ApiConfig.githubRepos);
    return _unwrapList(response.data).cast<Map<String, dynamic>>();
  }

  Future<List<Map<String, dynamic>>> getGithubReleases(String repo) async {
    final response = await _dio.get(
      ApiConfig.githubReleases,
      queryParameters: {'repo': repo},
    );
    return _unwrapList(response.data).cast<Map<String, dynamic>>();
  }

  Future<List<GitHubMirror>> getGithubMirrors() async {
    final response = await _dio.get(ApiConfig.githubMirrors);
    return _unwrapList(response.data).map((j) => GitHubMirror.fromJson(j)).toList();
  }

  Future<void> createGithubMirror(Map<String, dynamic> data) async {
    await _dio.post(ApiConfig.githubMirrors, data: data);
  }

  Future<void> updateGithubMirror(String id, Map<String, dynamic> data) async {
    await _dio.put(ApiConfig.resourceUrl(ApiConfig.githubMirrors, id), data: data);
  }

  Future<void> deleteGithubMirror(String id) async {
    await _dio.delete(ApiConfig.resourceUrl(ApiConfig.githubMirrors, id));
  }

  // ---- OSGames ----
  Future<List<Game>> getOsgamesGames() async {
    final response = await _dio.get(ApiConfig.osgamesGames);
    return _unwrapList(response.data).map((j) => Game.fromJson(j)).toList();
  }

  Future<Game> getOsgamesGame(Object id) async {
    final response = await _dio.get(ApiConfig.resourceUrl(ApiConfig.osgamesGames, id));
    return Game.fromJson(response.data);
  }

  Future<Game> createOsgamesGame(Map<String, dynamic> data) async {
    final response = await _dio.post(ApiConfig.osgamesGames, data: data);
    return Game.fromJson(response.data);
  }

  Future<Game> updateOsgamesGame(Object id, Map<String, dynamic> data) async {
    final response = await _dio.put(ApiConfig.resourceUrl(ApiConfig.osgamesGames, id), data: data);
    return Game.fromJson(response.data);
  }

  Future<void> deleteOsgamesGame(Object id) async {
    await _dio.delete(ApiConfig.resourceUrl(ApiConfig.osgamesGames, id));
  }

  Future<void> submitOsgamesGame(Object id) async {
    await _dio.post(ApiConfig.actionUrl(ApiConfig.osgamesGames, id, 'submit'));
  }

  Future<Map<String, dynamic>> getOsgamesGameGiteaInfo(Object id) async {
    final response = await _dio.get(ApiConfig.actionUrl(ApiConfig.osgamesGames, id, 'gitea-info'));
    return response.data as Map<String, dynamic>;
  }

  Future<List<GameCategory>> getOsgamesCategories() async {
    final response = await _dio.get(ApiConfig.osgamesCategories);
    return _unwrapList(response.data).map((j) => GameCategory.fromJson(j)).toList();
  }

  Future<GameCategory> createOsgamesCategory(Map<String, dynamic> data) async {
    final response = await _dio.post(ApiConfig.osgamesCategories, data: data);
    return GameCategory.fromJson(response.data);
  }

  Future<GameCategory> updateOsgamesCategory(Object id, Map<String, dynamic> data) async {
    final response = await _dio.put(ApiConfig.resourceUrl(ApiConfig.osgamesCategories, id), data: data);
    return GameCategory.fromJson(response.data);
  }

  Future<void> deleteOsgamesCategory(Object id) async {
    await _dio.delete(ApiConfig.resourceUrl(ApiConfig.osgamesCategories, id));
  }

  Future<Map<String, dynamic>> getOsgamesStats() async {
    final response = await _dio.get(ApiConfig.osgamesStats);
    return response.data as Map<String, dynamic>;
  }

  // Admin
  Future<List<Game>> getOsgamesAdminPending({String? status}) async {
    final params = status != null && status != 'all' ? {'status': status} : null;
    final response = await _dio.get(ApiConfig.osgamesAdminPending, queryParameters: params);
    return _unwrapList(response.data).map((j) => Game.fromJson(j)).toList();
  }

  Future<void> approveOsgamesGame(Object id, {String? note}) async {
    await _dio.post(ApiConfig.resourceUrl(ApiConfig.osgamesAdminApprove, id), data: {'note': note});
  }

  Future<void> rejectOsgamesGame(Object id, {String? reason}) async {
    await _dio.post(ApiConfig.resourceUrl(ApiConfig.osgamesAdminReject, id), data: {'reason': reason});
  }

  Future<void> takedownOsgamesGame(Object id, {String? reason}) async {
    await _dio.post(ApiConfig.resourceUrl(ApiConfig.osgamesAdminTakedown, id), data: {'reason': reason});
  }

  Future<void> updateOsgamesGameBadges(Object id, List<String> badges) async {
    await _dio.post(ApiConfig.resourceUrl(ApiConfig.osgamesAdminBadges, id), data: {'badges': badges});
  }

  // Game Issues
  Future<List<GameIssue>> getOsgamesGameIssues(Object gameId) async {
    final response = await _dio.get('${ApiConfig.osgamesIssues}?game=$gameId');
    return _unwrapList(response.data).map((j) => GameIssue.fromJson(j)).toList();
  }

  Future<void> updateOsgamesIssueStatus(Object issueId, String status) async {
    await _dio.patch(ApiConfig.resourceUrl(ApiConfig.osgamesIssues, issueId), data: {'status': status});
  }

  Future<void> deleteOsgamesIssue(Object issueId) async {
    await _dio.delete(ApiConfig.resourceUrl(ApiConfig.osgamesIssues, issueId));
  }

  // ---- Gitea ----
  Future<GiteaAccount> getGiteaAccount() async {
    try {
      final response = await _dio.get(ApiConfig.giteaAccount);
      return GiteaAccount.fromJson(response.data);
    } catch (_) {
      return GiteaAccount(connected: false);
    }
  }

  Future<Map<String, dynamic>> getGiteaAuthUrl() async {
    final response = await _dio.get(ApiConfig.giteaAuthUrl);
    return response.data as Map<String, dynamic>;
  }

  Future<void> unbindGitea() async {
    await _dio.post(ApiConfig.giteaDisconnect);
  }
}
