import 'package:flutter/foundation.dart';
import '../models/dashboard_stats.dart';
import '../models/store_app.dart';
import '../services/api_service.dart';
import '../services/database_service.dart';

/// Fetches and caches dashboard data (my apps and computed stats).
///
/// On load, it first returns cached data from SQLite for instant display,
/// then refreshes from the API in the background. Stats are computed
/// locally from the my_apps list rather than a server endpoint.
class DashboardProvider extends ChangeNotifier {
  final ApiService _apiService;

  List<StoreApp> _myApps = [];
  bool _isLoading = false;
  String? _error;

  DashboardProvider({required ApiService apiService})
      : _apiService = apiService;

  // ---- Getters ----

  List<StoreApp> get myApps => _myApps;
  bool get isLoading => _isLoading;
  String? get error => _error;

  /// Stats computed from the current [myApps] list.
  DashboardStats get stats => DashboardStats.fromApps(_myApps);

  // ---- Data loading ----

  /// Load dashboard data.
  ///
  /// 1. Serves cached apps from SQLite immediately.
  /// 2. Fetches fresh data from the API in the background.
  /// 3. Updates the cache when the API response arrives.
  Future<void> load() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    // Step 1: serve cached data immediately.
    _myApps = await DatabaseService.getStoreApps();
    notifyListeners();

    // Step 2: fetch from API.
    try {
      _myApps = await _apiService.getMyApps();
      await DatabaseService.saveStoreApps(_myApps);
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
      _myApps = await _apiService.getMyApps();
      await DatabaseService.saveStoreApps(_myApps);
    } catch (e) {
      _error = e.toString();
    }

    _isLoading = false;
    notifyListeners();
  }
}
