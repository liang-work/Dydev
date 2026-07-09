import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/auth_provider.dart';

/// Group header label in the navigation drawer.
class _GroupHeader extends StatelessWidget {
  final String label;
  const _GroupHeader({required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(28, 16, 16, 4),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
      ),
    );
  }
}

/// User info section at the bottom of the drawer.
class _UserSection extends StatelessWidget {
  final String? username;
  final String? nickname;
  final String? email;
  final VoidCallback onLogout;

  const _UserSection({
    required this.username,
    required this.nickname,
    required this.email,
    required this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final displayName = nickname?.isNotEmpty == true ? nickname! : username ?? '?';

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
      child: Row(
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: cs.primaryContainer,
            child: Text(
              displayName.substring(0, 1).toUpperCase(),
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: cs.onPrimaryContainer,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  displayName,
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(fontWeight: FontWeight.w500),
                  overflow: TextOverflow.ellipsis,
                ),
                if (email?.isNotEmpty == true)
                  Text(
                    email!,
                    style: Theme.of(context)
                        .textTheme
                        .labelSmall
                        ?.copyWith(color: cs.onSurfaceVariant),
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
          IconButton(
            icon: Icon(Icons.logout, size: 18, color: cs.onSurfaceVariant),
            onPressed: onLogout,
            tooltip: 'sidebar.logout.tooltip'.tr(),
            visualDensity: VisualDensity.compact,
          ),
        ],
      ),
    );
  }
}

/// The left navigation sidebar using M3 NavigationDrawer.
class Sidebar extends StatelessWidget {
  final String currentRoute;
  final void Function(String route) onNavigate;
  final VoidCallback onLogout;

  const Sidebar({
    super.key,
    required this.currentRoute,
    required this.onNavigate,
    required this.onLogout,
  });

  static const _routes = [
    '/dashboard',
    '/dashboard/notifications',
    '/dashboard/apps',
    '/dashboard/osgames',
    '/dashboard/osgames/manage',
    '/dashboard/osgames/categories',
    '/dashboard/storages',
    '/dashboard/softwares',
    '/dashboard/announcements',
    '/dashboard/telemetry',
    '/dashboard/config',
  ];

  static int _routeToIndex(String route) {
    if (route == '/dashboard') return 0;
    if (route == '/dashboard/notifications') return 1;
    if (route.startsWith('/dashboard/apps')) return 2;
    if (route == '/dashboard/osgames') return 3;
    if (route.startsWith('/dashboard/osgames/manage')) return 4;
    if (route.startsWith('/dashboard/osgames/categories')) return 5;
    if (route.startsWith('/dashboard/storages')) return 6;
    if (route.startsWith('/dashboard/softwares')) return 7;
    if (route.startsWith('/dashboard/announcements')) return 8;
    if (route.startsWith('/dashboard/telemetry')) return 9;
    if (route.startsWith('/dashboard/config')) return 10;
    return -1;
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final cs = Theme.of(context).colorScheme;
    final idx = _routeToIndex(currentRoute);

    return NavigationDrawer(
      selectedIndex: idx >= 0 ? idx : null,
      onDestinationSelected: (i) => onNavigate(_routes[i]),
      children: [
        // Logo
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
          child: Row(
            children: [
              Icon(Icons.code, size: 20, color: cs.primary),
              const SizedBox(width: 8),
              Text(
                'app.title'.tr(),
                style: Theme.of(context)
                    .textTheme
                    .titleSmall
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),

        // === 概览 ===
        _GroupHeader(label: 'nav.overview'.tr()),
        NavigationDrawerDestination(
          icon: const Icon(Icons.dashboard_outlined),
          selectedIcon: const Icon(Icons.dashboard),
          label: Text('nav.dashboard'.tr()),
        ),
        NavigationDrawerDestination(
          icon: const Icon(Icons.notifications_outlined),
          selectedIcon: const Icon(Icons.notifications),
          label: Text('nav.notifications'.tr()),
        ),
        NavigationDrawerDestination(
          icon: const Icon(Icons.store_outlined),
          selectedIcon: const Icon(Icons.store),
          label: Text('nav.apps'.tr()),
        ),

        // === 开源游戏 ===
        _GroupHeader(label: 'nav.osgames'.tr()),
        NavigationDrawerDestination(
          icon: const Icon(Icons.gamepad_outlined),
          selectedIcon: const Icon(Icons.gamepad),
          label: Text('nav.osgames.games'.tr()),
        ),
        NavigationDrawerDestination(
          icon: const Icon(Icons.admin_panel_settings_outlined),
          selectedIcon: const Icon(Icons.admin_panel_settings),
          label: Text('nav.osgames.manage'.tr()),
        ),
        NavigationDrawerDestination(
          icon: const Icon(Icons.category_outlined),
          selectedIcon: const Icon(Icons.category),
          label: Text('nav.osgames.categories'.tr()),
        ),

        // === 分发管理 ===
        _GroupHeader(label: 'nav.distribution'.tr()),
        NavigationDrawerDestination(
          icon: const Icon(Icons.storage_outlined),
          selectedIcon: const Icon(Icons.storage),
          label: Text('nav.storages'.tr()),
        ),
        NavigationDrawerDestination(
          icon: const Icon(Icons.inventory_2_outlined),
          selectedIcon: const Icon(Icons.inventory_2),
          label: Text('nav.softwares'.tr()),
        ),
        NavigationDrawerDestination(
          icon: const Icon(Icons.campaign_outlined),
          selectedIcon: const Icon(Icons.campaign),
          label: Text('nav.announcements'.tr()),
        ),

        // === 数据与配置 ===
        _GroupHeader(label: 'nav.data_config'.tr()),
        NavigationDrawerDestination(
          icon: const Icon(Icons.analytics_outlined),
          selectedIcon: const Icon(Icons.analytics),
          label: Text('nav.telemetry'.tr()),
        ),
        NavigationDrawerDestination(
          icon: const Icon(Icons.tune_outlined),
          selectedIcon: const Icon(Icons.tune),
          label: Text('nav.config'.tr()),
        ),

        const SizedBox(height: 8),
        const Divider(),
        _UserSection(
          username: auth.user?.username,
          nickname: auth.user?.nickname,
          email: auth.user?.email,
          onLogout: onLogout,
        ),
      ],
    );
  }
}
