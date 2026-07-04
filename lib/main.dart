import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'app.dart';
import 'providers/auth_provider.dart';
import 'services/auth_service.dart';

/// Base URL for the Developer Platform API.
/// Defined here so all other modules reference [ApiConfig.baseUrl].
const String kApiBaseUrl = 'https://dev-api.dy.ci/';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  final authService = AuthService();

  runApp(
    ChangeNotifierProvider(
      create: (_) => AuthProvider(authService: authService)..init(),
      child: DevPlatformApp(),
    ),
  );
}
