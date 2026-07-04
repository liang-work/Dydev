import 'package:dio/dio.dart';
import '../config/api_config.dart';
import '../models/user.dart';
import '../models/store_app.dart';
import '../models/dashboard_stats.dart';
import 'auth_service.dart';

/// Dio-based HTTP client for the Developer Platform API.
///
/// Automatically attaches the Bearer token on every request
/// and attempts token refresh on 401 responses.
class ApiService {
  late final Dio _dio;
  final AuthService _authService;

  ApiService({required AuthService authService}) : _authService = authService {
    _dio = Dio(BaseOptions(
      baseUrl: ApiConfig.baseUrl,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 15),
      headers: {'Content-Type': 'application/json'},
    ));

    // Request interceptor: attach Bearer token.
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await _authService.getAccessToken();
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        handler.next(options);
      },
      onError: (error, handler) async {
        // If we get a 401, attempt a token refresh once.
        if (error.response?.statusCode == 401) {
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
              await _authService.saveTokens(accessToken: newAccess);

              // Retry the original request with the new token.
              final retryOptions = error.requestOptions;
              retryOptions.headers['Authorization'] = 'Bearer $newAccess';
              final retryResponse = await _dio.fetch(retryOptions);
              return handler.resolve(retryResponse);
            } catch (_) {
              // Refresh failed — let the caller handle the 401.
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
    final response = await Dio(BaseOptions(baseUrl: ApiConfig.baseUrl)).get(
      ApiConfig.userMe,
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );
    return User.fromJson(response.data);
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
    final response = await _dio.get(ApiConfig.storeMyApps);
    final List<dynamic> data = response.data;
    return data.map((j) => StoreApp.fromJson(j)).toList();
  }

  /// Fetch store-wide statistics.
  Future<DashboardStats> getStoreStats() async {
    final response = await _dio.get(ApiConfig.storeStats);
    return DashboardStats.fromJson(response.data);
  }

  /// Fetch featured / popular apps.
  Future<List<StoreApp>> getFeaturedApps() async {
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
