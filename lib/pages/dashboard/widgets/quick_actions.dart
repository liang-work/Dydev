import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// A shortcut action card displayed in the dashboard.
class _QuickActionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String description;
  final VoidCallback onTap;

  const _QuickActionCard({
    required this.icon,
    required this.label,
    required this.description,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Card(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: cs.outlineVariant),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: cs.primary.withAlpha(26),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: cs.primary, size: 28),
                ),
                const SizedBox(height: 12),
                Text(
                  label,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
    );
  }
}

/// Quick action shortcuts: Publish App, Create Software, View Notifications.
class QuickActions extends StatelessWidget {
  const QuickActions({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'dashboard.quick_actions'.tr(),
          style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        LayoutBuilder(
          builder: (context, constraints) {
            if (constraints.maxWidth < 400) {
              return Column(
                children: [
                  _QuickActionCard(
                    icon: Icons.publish,
                    label: 'dashboard.quick_actions.publish'.tr(),
                    description: '提交新的应用到商店',
                    onTap: () => context.go('/dashboard/apps?action=create'),
                  ),
                  const SizedBox(height: 12),
                  _QuickActionCard(
                    icon: Icons.add_circle_outline,
                    label: 'dashboard.quick_actions.create_software'.tr(),
                    description: '创建新的软件分发项目',
                    onTap: () => context.go('/dashboard/softwares?action=create'),
                  ),
                  const SizedBox(height: 12),
                  _QuickActionCard(
                    icon: Icons.notifications_outlined,
                    label: 'dashboard.quick_actions.view_notifications'.tr(),
                    description: '查看系统通知和邀请',
                    onTap: () => context.go('/dashboard/notifications'),
                  ),
                ],
              );
            }
            return Row(
              children: [
                Expanded(child: _QuickActionCard(
                  icon: Icons.publish,
                  label: 'dashboard.quick_actions.publish'.tr(),
                  description: '提交新的应用到商店',
                  onTap: () => context.go('/dashboard/apps?action=create'),
                )),
                const SizedBox(width: 12),
                Expanded(child: _QuickActionCard(
                  icon: Icons.add_circle_outline,
                  label: 'dashboard.quick_actions.create_software'.tr(),
                  description: '创建新的软件分发项目',
                  onTap: () => context.go('/dashboard/softwares?action=create'),
                )),
                const SizedBox(width: 12),
                Expanded(child: _QuickActionCard(
                  icon: Icons.notifications_outlined,
                  label: 'dashboard.quick_actions.view_notifications'.tr(),
                  description: '查看系统通知和邀请',
                  onTap: () => context.go('/dashboard/notifications'),
                )),
              ],
            );
          },
        ),
      ],
    );
  }
}
