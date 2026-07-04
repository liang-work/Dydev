import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'providers/auth_provider.dart';
import 'pages/login_page.dart';
import 'pages/dashboard/dashboard_layout.dart';
import 'pages/dashboard/dashboard_page.dart';
import 'pages/settings/profile_page.dart';

/// The root application widget.
///
/// Sets up go_router with an auth redirect guard and a Material Design 3
/// theme that mirrors the reference frontend's shadcn/ui colour palette.
class DevPlatformApp extends StatelessWidget {
  DevPlatformApp({super.key});

  final _router = GoRouter(
    initialLocation: '/login',
    redirect: (context, state) {
      final auth = context.read<AuthProvider>();
      final isLoggedIn = auth.isAuthenticated;
      final isLoginRoute = state.matchedLocation == '/login';

      // Unauthenticated users are sent to /login.
      if (!isLoggedIn && !isLoginRoute) return '/login';
      // Authenticated users on /login are sent to /dashboard.
      if (isLoggedIn && isLoginRoute) return '/dashboard';
      return null;
    },
    routes: [
      GoRoute(
        path: '/login',
        name: 'login',
          builder: (_, _) => const LoginPage(),
        ),
        ShellRoute(
          builder: (_, _, child) => DashboardLayout(child: child),
        routes: [
          GoRoute(
            path: '/dashboard',
            name: 'dashboard',
            builder: (_, _) => const DashboardPage(),
          ),
          GoRoute(
            path: '/dashboard/settings',
            name: 'settings',
            builder: (_, _) => const ProfilePage(),
          ),
        ],
      ),
    ],
  );

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: '开发者平台',
      debugShowCheckedModeBanner: false,
      routerConfig: _router,
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: const Color(0xFF6366F1), // Indigo – matches the reference.
        scaffoldBackgroundColor: Colors.grey.shade50,
        appBarTheme: AppBarTheme(
          elevation: 0,
          scrolledUnderElevation: 1,
          backgroundColor: Colors.white,
          foregroundColor: Colors.grey.shade800,
        ),
        cardTheme: CardThemeData(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: Colors.grey.shade200),
          ),
        ),
      ),
    );
  }
}
