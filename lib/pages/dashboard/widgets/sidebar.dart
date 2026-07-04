import 'package:flutter/material.dart';

/// A navigation item in the sidebar.
class _SidebarItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _SidebarItem({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = isSelected ? Theme.of(context).colorScheme.primary : Colors.grey.shade600;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      child: Material(
        color: isSelected ? Theme.of(context).colorScheme.primary.withAlpha(20) : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            child: Row(
              children: [
                Icon(icon, size: 20, color: color),
                const SizedBox(width: 12),
                Text(label, style: TextStyle(color: color, fontWeight: FontWeight.w500)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// The left navigation sidebar for the dashboard layout.
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
    return Container(
      width: 240,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(right: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Column(
        children: [
          // --- Logo area ---
          Container(
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
            child: Row(
              children: [
                Icon(Icons.code, color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  '开发者平台',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          // --- Navigation items ---
          Expanded(
            child: ListView(
              padding: const EdgeInsets.only(top: 8),
              children: [
                const Padding(
                  padding: EdgeInsets.only(left: 16, top: 12, bottom: 4),
                  child: Text('概览', style: TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.w600)),
                ),
                _SidebarItem(
                  icon: Icons.dashboard,
                  label: '仪表板',
                  isSelected: currentRoute == '/dashboard',
                  onTap: () => onNavigate('/dashboard'),
                ),
                _SidebarItem(
                  icon: Icons.notifications_outlined,
                  label: '通知中心',
                  isSelected: currentRoute == '/dashboard/notifications',
                  onTap: () {},
                ),

                const Padding(
                  padding: EdgeInsets.only(left: 16, top: 16, bottom: 4),
                  child: Text('应用', style: TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.w600)),
                ),
                _SidebarItem(
                  icon: Icons.store,
                  label: '应用商店',
                  isSelected: false,
                  onTap: () {},
                ),
                _SidebarItem(
                  icon: Icons.my_library_books,
                  label: '我的应用',
                  isSelected: currentRoute.startsWith('/dashboard/my-apps'),
                  onTap: () => onNavigate('/dashboard/my-apps'),
                ),
                _SidebarItem(
                  icon: Icons.publish,
                  label: '发布应用',
                  isSelected: currentRoute.startsWith('/dashboard/publish'),
                  onTap: () {},
                ),

                const Padding(
                  padding: EdgeInsets.only(left: 16, top: 16, bottom: 4),
                  child: Text('管理', style: TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.w600)),
                ),
                _SidebarItem(
                  icon: Icons.cloud_upload_outlined,
                  label: '软件分发',
                  isSelected: false,
                  onTap: () {},
                ),
                _SidebarItem(
                  icon: Icons.bar_chart_outlined,
                  label: '遥测数据',
                  isSelected: false,
                  onTap: () {},
                ),
                _SidebarItem(
                  icon: Icons.settings_outlined,
                  label: '个人设置',
                  isSelected: currentRoute.startsWith('/dashboard/settings'),
                  onTap: () => onNavigate('/dashboard/settings'),
                ),
              ],
            ),
          ),

          // --- User area ---
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.all(12),
            child: SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: onLogout,
                icon: const Icon(Icons.logout, size: 16),
                label: const Text('退出登录'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.grey.shade600,
                  side: BorderSide(color: Colors.grey.shade300),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
