import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'providers/auth_provider.dart';
import 'utils/global_keys.dart';
import 'theme/app_theme.dart';
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
import 'pages/store/app_list_page.dart';
import 'pages/telemetry/telemetry_list_page.dart';
import 'pages/config/config_list_page.dart';
import 'pages/settings/profile_page.dart';
import 'pages/settings/app_settings_page.dart';
import 'pages/osgames/game_list_page.dart';
import 'pages/osgames/game_manage_page.dart';
import 'pages/osgames/category_list_page.dart';
import 'providers/theme_provider.dart';

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
/// theme generated from the indigo seed colour.
class DevPlatformApp extends StatelessWidget {
  const DevPlatformApp({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final themeProv = context.watch<ThemeProvider>();

    final router = GoRouter(
      navigatorKey: navigatorKey,
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
            GoRoute(path: '/dashboard/announcements', name: 'announcements', builder: (_, _) => const AnnouncementListPage()),
            GoRoute(path: '/dashboard/telemetry', name: 'telemetry', builder: (_, _) => const TelemetryListPage()),
            GoRoute(path: '/dashboard/apps', name: 'apps', builder: (_, _) => const AppListPage()),
            GoRoute(path: '/dashboard/osgames', name: 'osgames', builder: (_, _) => const GameListPage()),
            GoRoute(path: '/dashboard/osgames/manage', name: 'osgames_manage', builder: (_, _) => const GameManagePage()),
            GoRoute(path: '/dashboard/osgames/categories', name: 'osgames_categories', builder: (_, _) => const CategoryListPage()),
            GoRoute(path: '/dashboard/config', name: 'config', builder: (_, _) => const ConfigListPage()),
            GoRoute(path: '/dashboard/settings', name: 'settings', builder: (_, _) => const ProfilePage()),
            GoRoute(path: '/dashboard/app-settings', name: 'app_settings', builder: (_, _) => const AppSettingsPage()),
          ],
        ),
      ],
    );

    return MaterialApp.router(
      title: 'app.title'.tr(),
      debugShowCheckedModeBanner: false,
      routerConfig: router,
      localizationsDelegates: context.localizationDelegates,
      supportedLocales: context.supportedLocales,
      locale: context.locale,
      themeMode: themeProv.mode,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
    );
  }
}


