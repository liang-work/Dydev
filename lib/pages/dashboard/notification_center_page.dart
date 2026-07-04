import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/notification.dart';
import '../../providers/auth_provider.dart';

class NotificationCenterPage extends StatefulWidget {
  const NotificationCenterPage({super.key});

  @override
  State<NotificationCenterPage> createState() => _NotificationCenterPageState();
}

class _NotificationCenterPageState extends State<NotificationCenterPage> {
  List<NotificationModel> _notifications = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  Future<void> _fetch() async {
    setState(() => _loading = true);
    try {
      final api = context.read<AuthProvider>().apiService;
      _notifications = await api.getNotifications();
    } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  bool get _hasUnread => _notifications.any((n) => !n.isRead);

  Future<void> _markAllRead() async {
    final api = context.read<AuthProvider>().apiService;
    for (final n in _notifications.where((n) => !n.isRead)) {
      try {
        await api.markNotificationRead(n.id);
      } catch (_) {}
    }
    _fetch();
  }

  Future<void> _handleAction(int id, String action) async {
    final api = context.read<AuthProvider>().apiService;
    try {
      if (action == 'accept') {
        await api.acceptInvitation(id);
      } else if (action == 'reject') {
        await api.rejectInvitation(id);
      } else {
        await api.markNotificationRead(id);
      }
      _fetch();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('操作失败: $e')));
      }
    }
  }

  String _typeName(String type) => type == 'invitation' ? '团队邀请' : '系统通知';

  Color _typeColor(String type) => type == 'invitation' ? Colors.blue : Colors.grey;

  String _formatDate(String date) {
    try {
      final dt = DateTime.parse(date);
      return '${dt.month}/${dt.day} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return date;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('通知中心'),
        actions: [
          if (_hasUnread)
            TextButton(
              onPressed: _markAllRead,
              child: const Text('全部标记已读'),
            ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetch,
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _notifications.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.notifications_off, size: 48, color: Colors.grey.shade300),
                      const SizedBox(height: 12),
                      Text('暂无任何通知', style: TextStyle(color: Colors.grey.shade500)),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _notifications.length,
                  itemBuilder: (_, i) {
                    final n = _notifications[i];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      color: !n.isRead ? theme.colorScheme.primaryContainer.withValues(alpha: 0.3) : null,
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: _typeColor(n.type).withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(_typeName(n.type), style: TextStyle(fontSize: 12, color: _typeColor(n.type))),
                                ),
                                const Spacer(),
                                Text(_formatDate(n.createdAt), style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(n.title, style: theme.textTheme.titleMedium),
                            const SizedBox(height: 4),
                            Text(n.content, style: TextStyle(color: Colors.grey.shade600)),
                            const SizedBox(height: 12),
                            if (n.type == 'invitation' && n.status == 'pending')
                              Row(
                                children: [
                                  FilledButton.icon(
                                    onPressed: () => _handleAction(n.id, 'accept'),
                                    icon: const Icon(Icons.check, size: 16),
                                    label: const Text('接受邀请'),
                                  ),
                                  const SizedBox(width: 8),
                                  OutlinedButton.icon(
                                    onPressed: () => _handleAction(n.id, 'reject'),
                                    icon: const Icon(Icons.close, size: 16),
                                    label: const Text('拒绝'),
                                  ),
                                ],
                              )
                            else if (n.status == 'accepted')
                              Row(
                                children: [
                                  Icon(Icons.check_circle, size: 16, color: Colors.green.shade600),
                                  const SizedBox(width: 4),
                                  Text('已接受', style: TextStyle(color: Colors.green.shade600)),
                                ],
                              )
                            else if (n.status == 'rejected')
                              Row(
                                children: [
                                  Icon(Icons.cancel, size: 16, color: Colors.grey.shade500),
                                  const SizedBox(width: 4),
                                  Text('已拒绝', style: TextStyle(color: Colors.grey.shade500)),
                                ],
                              )
                            else if (!n.isRead)
                              TextButton(
                                onPressed: () => _handleAction(n.id, 'mark_read'),
                                child: const Text('标记已读'),
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
