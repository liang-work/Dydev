import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import 'widgets/sidebar.dart';

/// The main authenticated layout with a left sidebar and content area.
///
/// On desktop (width >= 768) the sidebar is fixed to the left.
/// On mobile (width < 768) the sidebar is hidden behind a hamburger drawer.
class DashboardLayout extends StatelessWidget {
  final Widget child;

  const DashboardLayout({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final routePath = GoRouterState.of(context).matchedLocation;

    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 768;
        return _DashboardContent(
          isMobile: isMobile,
          routePath: routePath,
          child: child,
        );
      },
    );
  }
}

class _DashboardContent extends StatefulWidget {
  final bool isMobile;
  final String routePath;
  final Widget child;

  const _DashboardContent({
    required this.isMobile,
    required this.routePath,
    required this.child,
  });

  @override
  State<_DashboardContent> createState() => _DashboardContentState();
}

class _DashboardContentState extends State<_DashboardContent> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  Widget _buildSidebar(BuildContext context) {
    return Sidebar(
      currentRoute: widget.routePath,
      onNavigate: (route) {
        if (widget.isMobile) _scaffoldKey.currentState?.closeDrawer();
        context.go(route);
      },
      onLogout: () async {
        await context.read<AuthProvider>().logout();
        if (context.mounted) context.go('/login');
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    if (widget.isMobile) {
      return Scaffold(
        key: _scaffoldKey,
        drawer: Drawer(child: _buildSidebar(context)),
        body: SafeArea(
          child: Container(
            color: cs.surfaceContainerLow,
            child: Column(
              children: [
                _buildTopBar(context, widget.routePath, widget.isMobile),
                Expanded(child: widget.child),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      body: Row(
        children: [
          _buildSidebar(context),
          Expanded(
            child: SafeArea(
              left: false, right: false,
              child: Container(
                color: cs.surfaceContainerLow,
                child: Column(
                  children: [
                    _buildTopBar(context, widget.routePath, widget.isMobile),
                    Expanded(child: widget.child),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopBar(BuildContext context, String routePath, bool isMobile) {
    final auth = context.watch<AuthProvider>();
    final cs = Theme.of(context).colorScheme;
    final pageTitle = _pageTitleFor(routePath);

    return Container(
      padding: EdgeInsets.symmetric(horizontal: isMobile ? 12 : 24, vertical: 12),
      decoration: BoxDecoration(
        color: cs.surface,
        border: Border(bottom: BorderSide(color: cs.outlineVariant)),
      ),
      child: Row(
        children: [
          if (isMobile)
            IconButton(
              icon: const Icon(Icons.menu),
              onPressed: () => _scaffoldKey.currentState?.openDrawer(),
            ),
          if (isMobile) const SizedBox(width: 4),
          Expanded(
            child: Text(
              pageTitle,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
          ),
          const Spacer(),
          IconButton(
            icon: Icon(Icons.settings_outlined, color: cs.onSurfaceVariant, size: 20),
            tooltip: 'nav.settings'.tr(),
            onPressed: () => context.go('/dashboard/app-settings'),
          ),
          if (auth.user != null)
            isMobile
                ? CircleAvatar(
                    radius: 12,
                    backgroundImage: auth.user!.avatar.isNotEmpty
                        ? NetworkImage(auth.user!.avatar) as ImageProvider
                        : null,
                    child: auth.user!.avatar.isEmpty
                        ? Icon(Icons.person_outline, size: 14, color: cs.onSurfaceVariant)
                        : null,
                  )
                : Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircleAvatar(
                        radius: 12,
                        backgroundImage: auth.user!.avatar.isNotEmpty
                            ? NetworkImage(auth.user!.avatar) as ImageProvider
                            : null,
                        child: auth.user!.avatar.isEmpty
                            ? Icon(Icons.person_outline, size: 14, color: cs.onSurfaceVariant)
                            : null,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        auth.user!.nickname.isNotEmpty ? auth.user!.nickname : auth.user!.username,
                        style: TextStyle(color: cs.onSurface, fontSize: 14),
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
    if (path.startsWith('/dashboard/osgames')) return 'app_bar.osgames'.tr();
    if (path.startsWith('/dashboard/settings')) return 'app_bar.settings'.tr();
    if (path.startsWith('/dashboard/app-settings')) return 'app_bar.settings'.tr();
    return 'app_bar.dashboard'.tr();
  }
}
