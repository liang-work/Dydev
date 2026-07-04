import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/auth_provider.dart';

/// A single navigation item in the sidebar.
class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final Color bgColor;
    final Color fgColor;
    if (isSelected) {
      bgColor = theme.colorScheme.primary.withAlpha(20);
      fgColor = theme.colorScheme.primary;
    } else {
      bgColor = Colors.transparent;
      fgColor = Colors.grey.shade600;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 1),
      child: Material(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                Icon(icon, size: 18, color: fgColor),
                const SizedBox(width: 12),
                Text(label, style: TextStyle(color: fgColor, fontSize: 14, fontWeight: FontWeight.w500)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Group header label in the sidebar.
class _GroupHeader extends StatelessWidget {
  final String label;
  const _GroupHeader({required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 20, top: 20, bottom: 6),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: Colors.grey.shade500,
          letterSpacing: 0.8,
        ),
      ),
    );
  }
}

/// The left navigation sidebar matching the reference frontend design.
///
/// Sections:
///   概览  – 仪表板, 通知中心
///   分发管理 – 存储管理, 软件分发, 版本管理, 公告管理
///   数据与配置 – 软件遥测, 云端配置
///   底部 – 用户信息 + 退出
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

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    return Container(
      width: 240,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(right: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Column(
        children: [
          // ---- Logo ----
          Container(
            height: 56,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
            ),
            child: Row(
              children: [
                Icon(Icons.code, size: 20, color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  '开发者平台',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),

          // ---- Navigation ----
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 8),
              children: [
                // === 概览 ===
                const _GroupHeader(label: '概览'),
                _NavItem(
                  icon: Icons.dashboard_outlined,
                  label: '仪表板',
                  isSelected: currentRoute == '/dashboard',
                  onTap: () => onNavigate('/dashboard'),
                ),
                _NavItem(
                  icon: Icons.notifications_outlined,
                  label: '通知中心',
                  isSelected: currentRoute == '/dashboard/notifications',
                  onTap: () => onNavigate('/dashboard/notifications'),
                ),

                // === 分发管理 ===
                const _GroupHeader(label: '分发管理'),
                _NavItem(
                  icon: Icons.storage_outlined,
                  label: '存储管理',
                  isSelected: currentRoute.startsWith('/dashboard/storages'),
                  onTap: () => onNavigate('/dashboard/storages'),
                ),
                _NavItem(
                  icon: Icons.inventory_2_outlined,
                  label: '软件分发',
                  isSelected: currentRoute.startsWith('/dashboard/softwares'),
                  onTap: () => onNavigate('/dashboard/softwares'),
                ),
                _NavItem(
                  icon: Icons.layers_outlined,
                  label: '版本管理',
                  isSelected: currentRoute.contains('/versions'),
                  onTap: () => onNavigate('/dashboard/softwares'),
                ),
                _NavItem(
                  icon: Icons.campaign_outlined,
                  label: '公告管理',
                  isSelected: currentRoute.startsWith('/dashboard/announcements'),
                  onTap: () => onNavigate('/dashboard/announcements'),
                ),

                // === 数据与配置 ===
                const _GroupHeader(label: '数据与配置'),
                _NavItem(
                  icon: Icons.analytics_outlined,
                  label: '软件遥测',
                  isSelected: currentRoute.startsWith('/dashboard/telemetry'),
                  onTap: () => onNavigate('/dashboard/telemetry'),
                ),
                _NavItem(
                  icon: Icons.tune_outlined,
                  label: '云端配置',
                  isSelected: currentRoute.startsWith('/dashboard/config'),
                  onTap: () => onNavigate('/dashboard/config'),
                ),
              ],
            ),
          ),

          // ---- User info + Logout ----
          Container(
            decoration: BoxDecoration(
              border: Border(top: BorderSide(color: Colors.grey.shade200)),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                // Avatar
                CircleAvatar(
                  radius: 16,
                  backgroundColor: Theme.of(context).colorScheme.primary.withAlpha(26),
                  child: Text(
                    (auth.user?.nickname.isNotEmpty == true
                            ? auth.user!.nickname
                            : auth.user?.username ?? '?')
                        .substring(0, 1)
                        .toUpperCase(),
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                // Name + email
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        auth.user?.nickname.isNotEmpty == true
                            ? auth.user!.nickname
                            : auth.user?.username ?? '',
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (auth.user?.email.isNotEmpty == true)
                        Text(
                          auth.user!.email,
                          style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                          overflow: TextOverflow.ellipsis,
                        ),
                    ],
                  ),
                ),
                // Logout button
                IconButton(
                  icon: Icon(Icons.logout, size: 18, color: Colors.grey.shade500),
                  onPressed: onLogout,
                  tooltip: '退出登录',
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
