import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'providers/auth_provider.dart';
import 'pages/login_page.dart';
import 'pages/dashboard/dashboard_layout.dart';
import 'pages/dashboard/dashboard_page.dart';
import 'pages/dashboard/notification_center_page.dart';
import 'pages/distribute/storage_list_page.dart';
import 'pages/distribute/storage_detail_page.dart';
import 'pages/distribute/software_list_page.dart';
import 'pages/distribute/software_detail_page.dart';
import 'pages/distribute/version_list_page.dart';
import 'pages/distribute/announcement_list_page.dart';
import 'pages/telemetry/telemetry_list_page.dart';
import 'pages/config/config_list_page.dart';
import 'pages/settings/profile_page.dart';

/// Shell route: wraps all authenticated pages inside the sidebar layout.
class _DashboardShell extends StatelessWidget {
  final Widget child;
  const _DashboardShell({required this.child});

  @override
  Widget build(BuildContext context) => DashboardLayout(child: child);
}

/// The root application widget.
///
/// Sets up go_router with an auth redirect guard and a Material Design 3
/// theme that mirrors the reference frontend's shadcn/ui colour palette.
///
/// The router is rebuilt when [AuthProvider] notifies listeners, which
/// ensures the redirect guard re-evaluates after login / logout.
class DevPlatformApp extends StatelessWidget {
  const DevPlatformApp({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    final router = GoRouter(
      refreshListenable: auth,
      initialLocation: '/login',
      redirect: (ctx, state) {
        final a = ctx.read<AuthProvider>();
        final isLoggedIn = a.isAuthenticated;
        final isLoginRoute = state.matchedLocation == '/login';
        if (!isLoggedIn && !isLoginRoute) return '/login';
        if (isLoggedIn && isLoginRoute) return '/dashboard';
        return null;
      },
      routes: [
        GoRoute(path: '/login', name: 'login', builder: (_, _) => const LoginPage()),
        ShellRoute(
          builder: (_, _, child) => _DashboardShell(child: child),
          routes: [
            GoRoute(path: '/dashboard', name: 'dashboard', builder: (_, _) => const DashboardPage()),
            GoRoute(path: '/dashboard/notifications', name: 'notifications', builder: (_, _) => const NotificationCenterPage()),
            GoRoute(path: '/dashboard/storages', name: 'storages', builder: (_, _) => const StorageListPage()),
            GoRoute(path: '/dashboard/storages/:id', name: 'storage_detail', builder: (_, state) => StorageDetailPage(storageId: state.pathParameters['id']!)),
            GoRoute(path: '/dashboard/softwares', name: 'softwares', builder: (_, _) => const SoftwareListPage()),
            GoRoute(path: '/dashboard/softwares/:id', name: 'software_detail', builder: (_, state) => SoftwareDetailPage(softwareId: state.pathParameters['id']!)),
            GoRoute(path: '/dashboard/softwares/:id/versions', name: 'version_list', builder: (_, state) => VersionListPage(softwareId: state.pathParameters['id']!)),
            GoRoute(path: '/dashboard/versions', name: 'versions_redirect', redirect: (_, _) => '/dashboard/softwares'),
            GoRoute(path: '/dashboard/announcements', name: 'announcements', builder: (_, _) => const AnnouncementListPage()),
            GoRoute(path: '/dashboard/telemetry', name: 'telemetry', builder: (_, _) => const TelemetryListPage()),
            GoRoute(path: '/dashboard/config', name: 'config', builder: (_, _) => const ConfigListPage()),
            GoRoute(path: '/dashboard/settings', name: 'settings', builder: (_, _) => const ProfilePage()),
          ],
        ),
      ],
    );

    return MaterialApp.router(
      title: '开发者平台',
      debugShowCheckedModeBanner: false,
      routerConfig: router,
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: const Color(0xFF6366F1),
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


