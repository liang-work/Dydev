import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'logger_service.dart';

/// Manages authentication tokens using secure device storage.
///
/// Tokens are stored in the platform keychain / encrypted storage
/// and never written to plain-text SharedPreferences.
class AuthService {
  static const _tag = 'AuthService';
  static const _accessTokenKey = 'access_token';
  static const _refreshTokenKey = 'refresh_token';

  final FlutterSecureStorage _storage;

  AuthService({FlutterSecureStorage? storage})
      : _storage = storage ?? const FlutterSecureStorage();

  /// Persist both access and refresh tokens.
  Future<void> saveTokens(
      {required String accessToken, String? refreshToken}) async {
    LoggerService.d(_tag,
        'saveTokens(accessToken=[${accessToken.length} chars], refreshToken=${refreshToken != null ? '[${refreshToken.length} chars]' : 'null'})');
    await _storage.write(key: _accessTokenKey, value: accessToken);
    if (refreshToken != null) {
      await _storage.write(key: _refreshTokenKey, value: refreshToken);
    }
  }

  /// Retrieve the stored access token, or null.
  Future<String?> getAccessToken() async {
    final token = await _storage.read(key: _accessTokenKey);
    LoggerService.d(_tag,
        'getAccessToken() -> ${token != null ? '[${token.length} chars]' : 'null'}');
    return token;
  }

  /// Retrieve the stored refresh token, or null.
  Future<String?> getRefreshToken() async {
    return _storage.read(key: _refreshTokenKey);
  }

  /// Check whether a stored access token exists (does NOT validate expiry).
  Future<bool> hasToken() async {
    final token = await _storage.read(key: _accessTokenKey);
    final exists = token != null && token.isNotEmpty;
    LoggerService.d(_tag, 'hasToken() -> $exists');
    return exists;
  }

  /// Remove all stored tokens (used on logout).
  Future<void> clearTokens() async {
    LoggerService.i(_tag, 'Clearing all tokens');
    await _storage.delete(key: _accessTokenKey);
    await _storage.delete(key: _refreshTokenKey);
  }
}
