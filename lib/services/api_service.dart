import 'package:dio/dio.dart';
import '../config/api_config.dart';
import '../models/user.dart';
import '../models/store_app.dart';
import '../models/dashboard_stats.dart';
import 'auth_service.dart';
import 'logger_service.dart';

/// Dio-based HTTP client for the Developer Platform API.
///
/// Automatically attaches the Bearer token on every request
/// and attempts token refresh on 401 responses.
class ApiService {
  static const _tag = 'ApiService';

  late final Dio _dio;
  final AuthService _authService;

  ApiService({required AuthService authService}) : _authService = authService {
    LoggerService.d(_tag, 'Initialising API service (baseUrl: ${ApiConfig.baseUrl})');

    _dio = Dio(BaseOptions(
      baseUrl: ApiConfig.baseUrl,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 15),
      headers: {'Content-Type': 'application/json'},
    ));

    // Logging interceptor: trace every request / response.
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) {
        LoggerService.d(_tag, '--> ${options.method} ${options.path}');
        handler.next(options);
      },
      onResponse: (response, handler) {
        LoggerService.d(_tag,
            '<-- ${response.statusCode} ${response.requestOptions.path}');
        handler.next(response);
      },
      onError: (error, handler) {
        LoggerService.e(_tag,
            '<-- ERROR ${error.response?.statusCode} ${error.requestOptions.path}: ${error.message}',
            error.error, error.stackTrace);
        handler.next(error);
      },
    ));

    // Auth interceptor: attach Bearer token + auto-refresh on 401.
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await _authService.getAccessToken();
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        handler.next(options);
      },
      onError: (error, handler) async {
        if (error.response?.statusCode == 401) {
          LoggerService.w(_tag, 'Got 401, attempting token refresh ...');
          final refreshToken = await _authService.getRefreshToken();
          if (refreshToken != null) {
            try {
              final refreshResponse = await Dio(
                BaseOptions(baseUrl: ApiConfig.baseUrl),
              ).post(
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
        }
        handler.next(error);
      },
    ));
  }

  // ---- Auth ----

  /// Validate an access token by fetching the user profile.
  /// Returns the [User] on success, throws on failure.
  Future<User> validateToken(String token) async {
    LoggerService.i(_tag, 'Validating token ...');
    final response = await Dio(BaseOptions(baseUrl: ApiConfig.baseUrl)).get(
      ApiConfig.userMe,
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );
    final user = User.fromJson(response.data);
    LoggerService.i(_tag, 'Token valid, user: ${user.username}');
    return user;
  }

  // ---- User ----

  /// Fetch the current user profile.
  Future<User> getUserProfile() async {
    final response = await _dio.get(ApiConfig.userMe);
    return User.fromJson(response.data);
  }

  // ---- Store ----

  /// Fetch the developer's own apps.
  Future<List<StoreApp>> getMyApps() async {
    LoggerService.d(_tag, 'getMyApps');
    final response = await _dio.get(ApiConfig.storeMyApps);
    final List<dynamic> data = response.data;
    LoggerService.d(_tag, 'Fetched ${data.length} apps');
    return data.map((j) => StoreApp.fromJson(j)).toList();
  }

  /// Fetch store-wide statistics.
  Future<DashboardStats> getStoreStats() async {
    LoggerService.d(_tag, 'getStoreStats');
    final response = await _dio.get(ApiConfig.storeStats);
    return DashboardStats.fromJson(response.data);
  }

  /// Fetch featured / popular apps.
  Future<List<StoreApp>> getFeaturedApps() async {
    LoggerService.d(_tag, 'getFeaturedApps');
    final response = await _dio.get(ApiConfig.storeFeatured);
    final List<dynamic> data = response.data;
    return data.map((j) => StoreApp.fromJson(j)).toList();
  }

  /// Fetch the most recent apps.
  Future<List<StoreApp>> getRecentApps() async {
    final response = await _dio.get(ApiConfig.storeRecent);
    final List<dynamic> data = response.data;
    return data.map((j) => StoreApp.fromJson(j)).toList();
  }

  /// Fetch the top / most-downloaded apps.
  Future<List<StoreApp>> getTopApps() async {
    final response = await _dio.get(ApiConfig.storeTop);
    final List<dynamic> data = response.data;
    return data.map((j) => StoreApp.fromJson(j)).toList();
  }
}
