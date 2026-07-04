import 'package:flutter/foundation.dart';
import '../models/user.dart';
import '../services/auth_service.dart';
import '../services/api_service.dart';
import '../services/database_service.dart';
import '../services/logger_service.dart';

/// Authentication state.
enum AuthStatus { uninitialized, authenticated, unauthenticated }

/// Manages authentication state and exposes login / logout actions.
///
/// On app start, [init] checks for a stored token. If a valid token
/// exists the user is marked authenticated; otherwise they are sent
/// to the login screen.
class AuthProvider extends ChangeNotifier {
  final AuthService _authService;
  late final ApiService _apiService;

  AuthStatus _status = AuthStatus.uninitialized;
  User? _user;
  String? _error;

  AuthProvider({required AuthService authService})
      : _authService = authService {
    _apiService = ApiService(authService: authService);
  }

  // ---- Getters ----

  AuthStatus get status => _status;
  User? get user => _user;
  String? get error => _error;
  ApiService get apiService => _apiService;
  bool get isAuthenticated => _status == AuthStatus.authenticated;

  // ---- Initialization ----

  /// Called once on app startup. Reads the stored token and
  /// attempts to validate it against the server.
  Future<void> init() async {
    final hasToken = await _authService.hasToken();
    if (!hasToken) {
      _status = AuthStatus.unauthenticated;
      notifyListeners();
      return;
    }

    try {
      _user = await DatabaseService.getUser();
      _status = AuthStatus.authenticated;
    } catch (e, s) {
      LoggerService.e('AuthProvider', 'init failed to load cached user', e, s);
      _status = AuthStatus.unauthenticated;
    }
    notifyListeners();
  }

  // ---- Login via access token ----

  /// Login by directly providing an access token.
  /// Validates the token against the server and persists it on success.
  Future<bool> loginWithToken(String token) async {
    _error = null;
    try {
      final user = await _apiService.validateToken(token);
      await _authService.saveTokens(accessToken: token);
      await DatabaseService.saveUser(user);
      _user = user;
      _status = AuthStatus.authenticated;
      notifyListeners();
      return true;
    } catch (e, s) {
      LoggerService.e('AuthProvider', 'Token validation failed', e, s);
      _error = 'Token validation failed: ${e.toString()}';
      notifyListeners();
      return false;
    }
  }

  // ---- Logout ----

  /// Clear tokens, cached data and set state to unauthenticated.
  Future<void> logout() async {
    await _authService.clearTokens();
    await DatabaseService.clearAll();
    _user = null;
    _status = AuthStatus.unauthenticated;
    notifyListeners();
  }
}
