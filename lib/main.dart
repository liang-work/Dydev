import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'app.dart';
import 'providers/auth_provider.dart';
import 'providers/dashboard_provider.dart';
import 'services/auth_service.dart';
import 'services/logger_service.dart';

/// Base URL for the Developer Platform API.
/// Defined here so all other modules reference [ApiConfig.baseUrl].
const String kApiBaseUrl = 'https://dev-api.dy.ci/';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // ---- Initialise database backend ----
  // Mobile (Android / iOS) uses the platform plugin automatically.
  // Desktop (Windows / Linux / macOS) requires the FFI bridge.
  if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
    LoggerService.i('main', 'Desktop platform detected, initialising sqflite FFI ...');
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }

  // ---- Initialise global log level ----
  // Set to LogLevel.warning for release builds.
  LoggerService.level = LogLevel.debug;

  final authService = AuthService();

  // Compose the provider tree with both auth and dashboard providers.
  // DashboardProvider depends on ApiService which comes from AuthProvider.
  runApp(
    ChangeNotifierProvider<AuthProvider>(
      create: (_) => AuthProvider(authService: authService)..init(),
      child: ChangeNotifierProvider<DashboardProvider>(
        create: (context) => DashboardProvider(
          apiService: context.read<AuthProvider>().apiService,
        ),
        child: const DevPlatformApp(),
      ),
    ),
  );
}
