import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import 'widgets/sidebar.dart';

/// The main authenticated layout with a left sidebar and content area.
///
/// This widget wraps all dashboard sub-pages via GoRouter ShellRoute.
class DashboardLayout extends StatelessWidget {
  final Widget child;

  const DashboardLayout({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final routePath = GoRouterState.of(context).matchedLocation;

    return Scaffold(
      body: SafeArea(
        child: Row(
          children: [
            Sidebar(
              currentRoute: routePath,
              onNavigate: (route) => context.go(route),
              onLogout: () async {
                await context.read<AuthProvider>().logout();
                if (context.mounted) context.go('/login');
              },
            ),

            // Main content area.
            Expanded(
              child: Container(
                color: Colors.grey.shade50,
                child: Column(
                  children: [
                    _buildTopBar(context, routePath),
                    Expanded(child: child),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar(BuildContext context, String routePath) {
    final auth = context.watch<AuthProvider>();

    // Determine page title from the current route.
    final pageTitle = _pageTitleFor(routePath);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Row(
        children: [
          Text(
            pageTitle,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          const Spacer(),
          IconButton(
            icon: Icon(Icons.settings_outlined, color: Colors.grey.shade500, size: 20),
            tooltip: 'nav.settings'.tr(),
            onPressed: () => context.go('/dashboard/settings'),
          ),
          if (auth.user != null)
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.person_outline, color: Colors.grey.shade500, size: 18),
                const SizedBox(width: 6),
                Text(
                  auth.user!.nickname.isNotEmpty ? auth.user!.nickname : auth.user!.username,
                  style: TextStyle(color: Colors.grey.shade700, fontSize: 14),
                ),
              ],
            ),
        ],
      ),
    );
  }

  static String _pageTitleFor(String path) {
    if (path == '/dashboard') return 'app_bar.dashboard'.tr();
    if (path.startsWith('/dashboard/notifications')) return 'app_bar.notifications'.tr();
    if (path.startsWith('/dashboard/storages')) return 'app_bar.storages'.tr();
    if (path.startsWith('/dashboard/softwares')) return 'app_bar.softwares'.tr();
    if (path.startsWith('/dashboard/announcements')) return 'app_bar.announcements'.tr();
    if (path.startsWith('/dashboard/telemetry')) return 'app_bar.telemetry'.tr();
    if (path.startsWith('/dashboard/config')) return 'app_bar.config'.tr();
    if (path.startsWith('/dashboard/apps')) return 'app_bar.apps'.tr();
    if (path.startsWith('/dashboard/settings')) return 'app_bar.settings'.tr();
    return 'app_bar.dashboard'.tr();
  }
}
