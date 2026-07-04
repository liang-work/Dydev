import 'package:flutter/foundation.dart';
import '../models/dashboard_stats.dart';
import '../models/store_app.dart';
import '../services/api_service.dart';
import '../services/database_service.dart';

/// Fetches and caches dashboard data (stats, my apps, featured apps).
///
/// On load, it first returns cached data from SQLite for instant display,
/// then refreshes from the API in the background.
class DashboardProvider extends ChangeNotifier {
  final ApiService _apiService;

  DashboardStats _stats = DashboardStats();
  List<StoreApp> _myApps = [];
  List<StoreApp> _featuredApps = [];
  bool _isLoading = false;
  String? _error;

  DashboardProvider({required ApiService apiService})
      : _apiService = apiService;

  // ---- Getters ----

  DashboardStats get stats => _stats;
  List<StoreApp> get myApps => _myApps;
  List<StoreApp> get featuredApps => _featuredApps;
  bool get isLoading => _isLoading;
  String? get error => _error;

  /// Total download count across all of the developer's apps.
  int get totalDownloads =>
      _myApps.fold(0, (sum, app) => sum + app.downloadCount);

  // ---- Data loading ----

  /// Load dashboard data: stats + my apps + featured apps.
  ///
  /// 1. Returns cached data from SQLite immediately.
  /// 2. Fetches fresh data from the API in the background.
  /// 3. Updates the cache and notifies listeners.
  Future<void> load() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    // Step 1: serve cached data immediately.
    _stats = await DatabaseService.getStats();
    _myApps = await DatabaseService.getStoreApps();
    notifyListeners();

    // Step 2: fetch from API.
    try {
      final results = await Future.wait([
        _apiService.getStoreStats(),
        _apiService.getMyApps(),
        _apiService.getFeaturedApps(),
      ]);

      _stats = results[0] as DashboardStats;
      _myApps = results[1] as List<StoreApp>;
      _featuredApps = results[2] as List<StoreApp>;

      // Update the local cache.
      await Future.wait([
        DatabaseService.saveStats(_stats),
        DatabaseService.saveStoreApps(_myApps),
      ]);
    } catch (e) {
      _error = e.toString();
    }

    _isLoading = false;
    notifyListeners();
  }

  /// Force-refresh from the API, ignoring cached data.
  Future<void> refresh() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final results = await Future.wait([
        _apiService.getStoreStats(),
        _apiService.getMyApps(),
        _apiService.getFeaturedApps(),
      ]);

      _stats = results[0] as DashboardStats;
      _myApps = results[1] as List<StoreApp>;
      _featuredApps = results[2] as List<StoreApp>;

      await Future.wait([
        DatabaseService.saveStats(_stats),
        DatabaseService.saveStoreApps(_myApps),
      ]);
    } catch (e) {
      _error = e.toString();
    }

    _isLoading = false;
    notifyListeners();
  }
}
