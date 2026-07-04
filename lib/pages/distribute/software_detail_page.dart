import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../models/software.dart';
import '../../models/channel.dart';
import '../../models/software_member.dart';
import '../../providers/auth_provider.dart';
import '../../services/logger_service.dart';

class SoftwareDetailPage extends StatefulWidget {
  final String softwareId;
  const SoftwareDetailPage({super.key, required this.softwareId});

  @override
  State<SoftwareDetailPage> createState() => _SoftwareDetailPageState();
}

class _SoftwareDetailPageState extends State<SoftwareDetailPage> {
  Software? _software;
  List<Channel> _channels = [];
  List<SoftwareMember> _members = [];
  bool _loading = true;

  // Edit dialog
  bool _showEditDialog = false;
  bool _submitting = false;
  final _editNameCtrl = TextEditingController();
  final _editSlugCtrl = TextEditingController();
  final _editDescCtrl = TextEditingController();
  List<String> _editPlatforms = [];

  // Channel dialog
  bool _showChannelDialog = false;
  Channel? _editingChannel;
  bool _channelSubmitting = false;
  final _channelNameCtrl = TextEditingController();
  final _channelTypeCtrl = TextEditingController();
  bool _channelActive = true;

  // Member dialog
  bool _showMemberDialog = false;
  bool _memberSubmitting = false;
  final _memberUsernameCtrl = TextEditingController();
  String _memberRole = 'viewer';
  final _memberPermissions = <String, bool>{'distribute': false, 'telemetry': false, 'dyconfig': false};

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _editNameCtrl.dispose();
    _editSlugCtrl.dispose();
    _editDescCtrl.dispose();
    _channelNameCtrl.dispose();
    _channelTypeCtrl.dispose();
    _memberUsernameCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    try {
      final api = context.read<AuthProvider>().apiService;
      final results = await Future.wait([
        api.getSoftware(widget.softwareId),
        api.getChannels(widget.softwareId),
        api.getMembers(widget.softwareId),
      ]);
      _software = results[0] as Software;
      _channels = results[1] as List<Channel>;
      _members = results[2] as List<SoftwareMember>;
      _editNameCtrl.text = _software!.name;
      _editSlugCtrl.text = _software!.slug;
      _editDescCtrl.text = _software!.description;
      _editPlatforms = [..._software!.platforms];
    } catch (e, s) {
      LoggerService.e('_SoftwareDetailPageState', 'load software detail', e, s);
    }
    if (mounted) setState(() => _loading = false);
  }

  void _togglePlatform(String p) {
    setState(() {
      if (_editPlatforms.contains(p)) { _editPlatforms.remove(p); } else { _editPlatforms.add(p); }
    });
  }

  Future<void> _saveSoftware() async {
    setState(() => _submitting = true);
    try {
      final api = context.read<AuthProvider>().apiService;
      await api.updateSoftware(widget.softwareId, {
        'name': _editNameCtrl.text,
        'slug': _editSlugCtrl.text,
        'description': _editDescCtrl.text,
        'platforms': _editPlatforms,
      });
      setState(() => _showEditDialog = false);
      _loadData();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('保存失败: $e')));
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Future<void> _deleteSoftware() async {
    final code = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('危险操作'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('请输入软件 Slug 以确认删除：'),
            const SizedBox(height: 12),
            TextField(
              decoration: const InputDecoration(border: OutlineInputBorder(), hintText: '输入 slug'),
              onChanged: (v) => Navigator.pop(ctx, v),
            ),
          ],
        ),
      ),
    );
    if (code != _software?.slug) return;
    try {
      final api = context.read<AuthProvider>().apiService;
      await api.deleteSoftware(widget.softwareId);
      if (mounted) context.go('/dashboard/softwares');
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('删除失败: $e')));
    }
  }

  Future<void> _resetTokenType(String type) async {
    final names = {'main': '主访问令牌', 'telemetry': '遥测数据令牌', 'announcement': '公告令牌', 'update': '更新检查令牌'};
    final name = names[type] ?? '令牌';
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('确认重置'),
        content: Text('确定要重置$name吗？重置后旧的$name将立即失效！'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('取消')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('重置', style: TextStyle(color: Colors.orange))),
        ],
      ),
    );
    if (confirm != true) return;
    try {
      final api = context.read<AuthProvider>().apiService;
      switch (type) {
        case 'main': await api.resetSoftwareToken(widget.softwareId); break;
        case 'telemetry': await api.resetTelemetryToken(widget.softwareId); break;
        case 'announcement': await api.resetAnnouncementToken(widget.softwareId); break;
        case 'update': await api.resetUpdateToken(widget.softwareId); break;
      }
      _loadData();
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$name已成功重置')));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('重置失败: $e')));
    }
  }

  // Channel methods
  void _openChannelDialog([Channel? c]) {
    _editingChannel = c;
    _channelNameCtrl.text = c?.name ?? '';
    _channelTypeCtrl.text = c?.channelType ?? '';
    _channelActive = c?.isActive ?? true;
    setState(() => _showChannelDialog = true);
  }

  Future<void> _saveChannel() async {
    setState(() => _channelSubmitting = true);
    try {
      final data = {'name': _channelNameCtrl.text, 'channel_type': _channelTypeCtrl.text, 'is_active': _channelActive, 'software': widget.softwareId};
      final api = context.read<AuthProvider>().apiService;
      if (_editingChannel != null) {
        await api.updateChannel(_editingChannel!.id, data);
      } else {
        await api.createChannel(data);
      }
      setState(() { _showChannelDialog = false; _editingChannel = null; });
      _loadData();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('保存失败: $e')));
    } finally {
      if (mounted) setState(() => _channelSubmitting = false);
    }
  }

  Future<void> _deleteChannel(String id) async {
    final confirm = await showDialog<bool>(context: context, builder: (ctx) => AlertDialog(
      title: const Text('确认删除'), content: const Text('确定要删除这个渠道吗？'),
      actions: [TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('取消')),
        TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('删除', style: TextStyle(color: Colors.red)))],
    ));
    if (confirm != true) return;
    try {
      await context.read<AuthProvider>().apiService.deleteChannel(id);
      _loadData();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('删除失败: $e')));
    }
  }

  Future<void> _removeMember(SoftwareMember m) async {
    final isSelf = false; // simplified
    final confirmMsg = isSelf ? '确定要离开该团队吗？' : '确定要将成员 ${m.username} 从团队中移除吗？';
    final confirm = await showDialog<bool>(context: context, builder: (ctx) => AlertDialog(
      title: const Text('确认'), content: Text(confirmMsg),
      actions: [TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('取消')),
        TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('确认'))],
    ));
    if (confirm != true) return;
    try {
      await context.read<AuthProvider>().apiService.removeMember(widget.softwareId, m.id);
      if (isSelf) { if (mounted) context.go('/dashboard/softwares'); } else { _loadData(); }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('操作失败: $e')));
    }
  }

  Future<void> _addMember() async {
    setState(() => _memberSubmitting = true);
    try {
      final data = {
        'username': _memberUsernameCtrl.text,
        'role': _memberRole,
        if (_memberRole == 'custom') 'permissions': _memberPermissions,
      };
      await context.read<AuthProvider>().apiService.addMember(widget.softwareId, data);
      setState(() { _showMemberDialog = false; _memberUsernameCtrl.clear(); });
      _loadData();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('添加失败: $e')));
    } finally {
      if (mounted) setState(() => _memberSubmitting = false);
    }
  }

  String _formatDate(String d) {
    try { return DateTime.parse(d).toLocal().toString().substring(0, 10); } catch (_) { return d; }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (_loading) return Scaffold(appBar: AppBar(title: const Text('软件详情')), body: const Center(child: CircularProgressIndicator()));

    return Stack(children: [Scaffold(
      appBar: AppBar(
        title: Text(_software?.name ?? '软件详情'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () => setState(() => _showEditDialog = true),
          ),
          IconButton(
            icon: Icon(Icons.delete, color: Colors.red.shade400),
            onPressed: _deleteSoftware,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Basic info card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 48, height: 48,
                          decoration: BoxDecoration(color: theme.colorScheme.primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
                          child: Icon(Icons.inventory_2, color: theme.colorScheme.primary),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(_software!.name, style: theme.textTheme.titleLarge),
                              Text(_software!.slug, style: TextStyle(color: Colors.grey.shade600)),
                            ],
                          ),
                        ),
                        FilledButton.tonalIcon(
                          onPressed: () => context.push('/dashboard/softwares/${widget.softwareId}/versions'),
                          icon: const Icon(Icons.tag, size: 18),
                          label: const Text('版本管理'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const Divider(),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        _infoCol('描述', _software!.description.isEmpty ? '暂无描述' : _software!.description),
                        _infoCol('版本数', '${_software!.versionCount}'),
                        _infoCol('创建时间', _formatDate(_software!.createdAt)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      children: _software!.platforms.map((p) => Chip(label: Text(p, style: const TextStyle(fontSize: 12)))).toList(),
                    ),
                    // Token section
                    if (_software!.token.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      const Divider(),
                      const SizedBox(height: 8),
                      _tokenSection('主访问令牌', _software!.token, 'main', Icons.vpn_key, theme.colorScheme.primary),
                      if (_software!.telemetryToken != null)
                        _tokenSection('遥测数据令牌', _software!.telemetryToken!, 'telemetry', Icons.analytics, Colors.blue),
                      if (_software!.announcementToken != null)
                        _tokenSection('公告令牌', _software!.announcementToken!, 'announcement', Icons.campaign, Colors.green),
                      if (_software!.updateToken != null)
                        _tokenSection('更新检查令牌', _software!.updateToken!, 'update', Icons.download, Colors.purple),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Channels + Members grid
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('发布渠道', style: theme.textTheme.titleMedium),
                              FilledButton.tonalIcon(
                                onPressed: () => _openChannelDialog(),
                                icon: const Icon(Icons.add, size: 16),
                                label: const Text('添加渠道'),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          if (_channels.isEmpty)
                            const Center(child: Padding(padding: EdgeInsets.all(24), child: Text('暂无渠道')))
                          else
                            ..._channels.map((c) => ListTile(
                              dense: true,
                              leading: Container(
                                width: 32, height: 32,
                                decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(6)),
                                child: const Icon(Icons.layers, size: 16),
                              ),
                              title: Text(c.name, style: const TextStyle(fontSize: 14)),
                              subtitle: Text(c.channelType, style: const TextStyle(fontSize: 12)),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: c.isActive ? Colors.green.withValues(alpha: 0.1) : Colors.grey.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(c.isActive ? '启用' : '禁用', style: TextStyle(fontSize: 11, color: c.isActive ? Colors.green : Colors.grey)),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.edit, size: 16),
                                    onPressed: () => _openChannelDialog(c),
                                  ),
                                  IconButton(
                                    icon: Icon(Icons.delete, size: 16, color: Colors.red.shade400),
                                    onPressed: () => _deleteChannel(c.id),
                                  ),
                                ],
                              ),
                            )),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('团队协作', style: theme.textTheme.titleMedium),
                              FilledButton.tonalIcon(
                                onPressed: () {
                                  _memberUsernameCtrl.clear();
                                  _memberRole = 'viewer';
                                  _memberPermissions.updateAll((_, _) => false);
                                  setState(() => _showMemberDialog = true);
                                },
                                icon: const Icon(Icons.person_add, size: 16),
                                label: const Text('添加成员'),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          if (_members.isEmpty)
                            const Center(child: Padding(padding: EdgeInsets.all(24), child: Text('暂无其他成员')))
                          else
                            ..._members.map((m) => ListTile(
                              dense: true,
                              leading: CircleAvatar(
                                radius: 16,
                                child: Text(m.username.isNotEmpty ? m.username[0].toUpperCase() : '?'),
                              ),
                              title: Row(
                                children: [
                                  Text(m.username, style: const TextStyle(fontSize: 14)),
                                  const SizedBox(width: 6),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                                    decoration: BoxDecoration(
                                      color: Colors.grey.shade100,
                                      borderRadius: BorderRadius.circular(3),
                                    ),
                                    child: Text(m.role, style: const TextStyle(fontSize: 10)),
                                  ),
                                ],
                              ),
                              subtitle: Text(m.email, style: const TextStyle(fontSize: 12)),
                              trailing: IconButton(
                                icon: Icon(Icons.exit_to_app, size: 16, color: Colors.red.shade400),
                                tooltip: '移除',
                                onPressed: () => _removeMember(m),
                              ),
                            )),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Client API card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('客户端 API', style: theme.textTheme.titleMedium),
                    const SizedBox(height: 4),
                    Text('在客户端使用以下接口检查更新', style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
                    const SizedBox(height: 12),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(8)),
                      child: SelectableText(
                        'GET https://dev-api.dy.ci/api/distribute/check/${_software!.slug}/?version=1.0.0&os=win10&arch=x64&channel=stable',
                        style: const TextStyle(fontFamily: 'monospace', fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      ),
      _buildEditDialog(),
      _buildChannelDialog(),
      _buildMemberDialog(),
    ]);
  }

  Widget _buildEditDialog() {
    if (!_showEditDialog) return const SizedBox.shrink();
    final theme = Theme.of(context);
    return Material(
      color: Colors.black26,
      child: Center(
        child: Dialog(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('编辑软件', style: theme.textTheme.titleLarge),
                const SizedBox(height: 20),
                TextField(controller: _editNameCtrl, decoration: const InputDecoration(labelText: '软件名称', border: OutlineInputBorder())),
                const SizedBox(height: 12),
                TextField(controller: _editSlugCtrl, decoration: const InputDecoration(labelText: 'URL标识', border: OutlineInputBorder())),
                const SizedBox(height: 12),
                TextField(controller: _editDescCtrl, maxLines: 3, decoration: const InputDecoration(labelText: '描述', border: OutlineInputBorder())),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 6,
                  children: ['Windows', 'macOS', 'Linux', 'Android', 'iOS', 'Web'].map((p) => FilterChip(
                    label: Text(p, style: const TextStyle(fontSize: 13)),
                    selected: _editPlatforms.contains(p),
                    onSelected: (_) => _togglePlatform(p),
                  )).toList(),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    OutlinedButton(onPressed: () => setState(() => _showEditDialog = false), child: const Text('取消')),
                    const SizedBox(width: 12),
                    FilledButton(onPressed: _submitting ? null : _saveSoftware, child: _submitting
                        ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                        : const Text('保存')),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildChannelDialog() {
    if (!_showChannelDialog) return const SizedBox.shrink();
    final theme = Theme.of(context);
    return Material(
      color: Colors.black26,
      child: Center(
        child: Dialog(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(_editingChannel != null ? '编辑渠道' : '添加渠道', style: theme.textTheme.titleLarge),
                const SizedBox(height: 20),
                TextField(controller: _channelNameCtrl, decoration: const InputDecoration(labelText: '渠道名称', border: OutlineInputBorder(), hintText: '例如：稳定版')),
                const SizedBox(height: 12),
                TextField(controller: _channelTypeCtrl, decoration: const InputDecoration(labelText: '渠道类型', border: OutlineInputBorder(), hintText: '如 stable, beta')),
                const SizedBox(height: 12),
                CheckboxListTile(
                  value: _channelActive,
                  onChanged: (v) => setState(() => _channelActive = v ?? true),
                  title: const Text('启用此渠道'),
                  controlAffinity: ListTileControlAffinity.leading,
                  contentPadding: EdgeInsets.zero,
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    OutlinedButton(onPressed: () => setState(() { _showChannelDialog = false; _editingChannel = null; }), child: const Text('取消')),
                    const SizedBox(width: 12),
                    FilledButton(onPressed: _channelSubmitting ? null : _saveChannel, child: _channelSubmitting
                        ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                        : const Text('保存')),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMemberDialog() {
    if (!_showMemberDialog) return const SizedBox.shrink();
    final theme = Theme.of(context);
    return Material(
      color: Colors.black26,
      child: Center(
        child: Dialog(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('添加团队成员', style: theme.textTheme.titleLarge),
            const SizedBox(height: 4),
            const Text('输入用户名并分配权限角色。'),
            const SizedBox(height: 16),
            TextField(controller: _memberUsernameCtrl, decoration: const InputDecoration(labelText: '用户名', border: OutlineInputBorder())),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _memberRole,
              decoration: const InputDecoration(labelText: '角色权限', border: OutlineInputBorder()),
              items: const [
                DropdownMenuItem(value: 'admin', child: Text('管理员 (Admin)')),
                DropdownMenuItem(value: 'developer', child: Text('开发者 (Developer)')),
                DropdownMenuItem(value: 'viewer', child: Text('观察者 (Viewer)')),
                DropdownMenuItem(value: 'custom', child: Text('自定义 (Custom)')),
              ],
              onChanged: (v) => setState(() => _memberRole = v ?? 'viewer'),
            ),
            if (_memberRole == 'custom') ...[
              const SizedBox(height: 12),
              ...['distribute', 'telemetry', 'dyconfig'].map((perm) => CheckboxListTile(
                value: _memberPermissions[perm] ?? false,
                onChanged: (v) => setState(() => _memberPermissions[perm] = v ?? false),
                title: Text(perm == 'distribute' ? '分发管理' : perm == 'telemetry' ? '遥测监控' : '云端配置', style: const TextStyle(fontSize: 13)),
                controlAffinity: ListTileControlAffinity.leading,
                contentPadding: EdgeInsets.zero,
                dense: true,
              )),
            ],
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                OutlinedButton(onPressed: () => setState(() => _showMemberDialog = false), child: const Text('取消')),
                const SizedBox(width: 12),
                FilledButton(onPressed: _memberSubmitting ? null : _addMember, child: _memberSubmitting
                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Text('确认添加')),
              ],
            ),
          ],
        ),
      ),
      ),
      ),
    );
  }

  Widget _infoCol(String label, String value) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
          const SizedBox(height: 2),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _tokenSection(String label, String token, String type, IconData icon, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: BorderRadius.circular(8)),
        child: Row(
          children: [
            Icon(icon, size: 20, color: color),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(label, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                        decoration: BoxDecoration(color: Colors.grey.shade200, borderRadius: BorderRadius.circular(3)),
                        child: Text(type, style: const TextStyle(fontSize: 9)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(token, style: const TextStyle(fontFamily: 'monospace', fontSize: 11)),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.copy, size: 16),
              onPressed: () {
                Clipboard.setData(ClipboardData(text: token));
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('已复制')));
              },
            ),
            IconButton(
              icon: const Icon(Icons.refresh, size: 16),
              onPressed: () => _resetTokenType(type),
            ),
          ],
        ),
      ),
    );
  }
}
