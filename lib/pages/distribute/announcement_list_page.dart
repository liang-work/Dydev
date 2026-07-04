import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/software.dart';
import '../../models/announcement.dart';
import '../../providers/auth_provider.dart';

class AnnouncementListPage extends StatefulWidget {
  const AnnouncementListPage({super.key});

  @override
  State<AnnouncementListPage> createState() => _AnnouncementListPageState();
}

class _AnnouncementListPageState extends State<AnnouncementListPage> {
  List<Software> _softwares = [];
  String? _selectedId;
  Software? _selected;
  List<Announcement> _announcements = [];
  bool _loadingSoftwares = true;
  bool _loadingAnnouncements = false;

  // Form
  bool _showFormDialog = false;
  Announcement? _editing;
  String _formType = 'update';
  final _formTitleCtrl = TextEditingController();
  final _formContentCtrl = TextEditingController();
  String _formFilterType = 'all';
  List<String> _formFilterVersions = [];
  List<String> _formFilterChannels = [];
  String _formExpiresAt = '';
  final _versionInputCtrl = TextEditingController();
  List<String> _channels = [];
  bool _loadingChannels = false;

  @override
  void initState() {
    super.initState();
    _loadSoftwares();
  }

  @override
  void dispose() {
    _formTitleCtrl.dispose();
    _formContentCtrl.dispose();
    _versionInputCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadSoftwares() async {
    setState(() => _loadingSoftwares = true);
    try {
      final api = context.read<AuthProvider>().apiService;
      _softwares = await api.getSoftwares();
    } catch (_) {}
    if (mounted) setState(() => _loadingSoftwares = false);
  }

  void _selectSoftware(String id) {
    setState(() {
      _selectedId = id;
      _selected = _softwares.firstWhere((s) => s.id == id);
    });
    _loadAnnouncements();
    _loadChannels();
  }

  Future<void> _loadAnnouncements() async {
    if (_selectedId == null) return;
    setState(() => _loadingAnnouncements = true);
    try {
      final api = context.read<AuthProvider>().apiService;
      _announcements = await api.getAnnouncements(_selectedId!);
    } catch (_) {}
    if (mounted) setState(() => _loadingAnnouncements = false);
  }

  Future<void> _loadChannels() async {
    if (_selectedId == null) return;
    setState(() => _loadingChannels = true);
    try {
      final api = context.read<AuthProvider>().apiService;
      final chs = await api.getChannels(_selectedId);
      _channels = chs.map((c) => c.channelType).toList();
    } catch (_) {}
    if (mounted) setState(() => _loadingChannels = false);
  }

  void _openCreate() {
    _editing = null;
    _formType = 'update';
    _formTitleCtrl.clear();
    _formContentCtrl.clear();
    _formFilterType = 'all';
    _formFilterVersions = [];
    _formFilterChannels = [];
    _formExpiresAt = '';
    setState(() => _showFormDialog = true);
  }

  void _openEdit(Announcement a) {
    _editing = a;
    _formType = a.announcementType;
    _formTitleCtrl.text = a.title;
    _formContentCtrl.text = a.content;
    _formFilterType = a.filterType;
    _formFilterVersions = [...a.filterVersions];
    _formFilterChannels = [...a.filterChannels];
    _formExpiresAt = a.expiresAt?.substring(0, 16) ?? '';
    setState(() => _showFormDialog = true);
  }

  Future<void> _save() async {
    if (_selectedId == null) return;
    final data = {
      'software': _selectedId,
      'announcement_type': _formType,
      'title': _formTitleCtrl.text,
      'content': _formContentCtrl.text,
      'filter_type': _formFilterType,
      'filter_versions': _formFilterVersions,
      'filter_channels': _formFilterChannels,
      'expires_at': _formExpiresAt.isNotEmpty ? _formExpiresAt : null,
    };
    try {
      final api = context.read<AuthProvider>().apiService;
      if (_editing != null) {
        await api.updateAnnouncement(_editing!.id, data);
      } else {
        await api.createAnnouncement(data);
      }
      setState(() => _showFormDialog = false);
      _loadAnnouncements();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('保存失败: $e')));
      }
    }
  }

  Future<void> _publish(String id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('确认发布'),
        content: const Text('确定要发布此公告吗？发布后将立即推送给目标用户。'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('取消')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('发布')),
        ],
      ),
    );
    if (confirm != true) return;
    try {
      final api = context.read<AuthProvider>().apiService;
      await api.publishAnnouncement(id);
      _loadAnnouncements();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('发布失败: $e')));
      }
    }
  }

  Future<void> _delete(String id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('确认删除'),
        content: const Text('确定要删除此公告吗？'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('取消')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('删除')),
        ],
      ),
    );
    if (confirm != true) return;
    try {
      final api = context.read<AuthProvider>().apiService;
      await api.deleteAnnouncement(id);
      _loadAnnouncements();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('删除失败: $e')));
      }
    }
  }

  String _typeLabel(String t) {
    const labels = {'urgent': '紧急', 'update': '更新', 'operation': '运营', 'custom': '自定义'};
    return labels[t] ?? t;
  }

  Color _typeColor(String t) {
    switch (t) {
      case 'urgent':
        return Colors.red;
      case 'update':
        return Colors.blue;
      case 'operation':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  String _statusLabel(String s) {
    const labels = {'draft': '草稿', 'published': '已发布', 'expired': '已过期'};
    return labels[s] ?? s;
  }

  Color _statusColor(String s) {
    switch (s) {
      case 'published':
        return Colors.green;
      case 'draft':
        return Colors.orange;
      case 'expired':
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }

  String _formatDate(String d) {
    try {
      return DateTime.parse(d).toLocal().toString().substring(0, 16);
    } catch (_) {
      return d;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Stack(
      children: [
        Scaffold(
      appBar: AppBar(title: const Text('公告管理')),
      body: Row(
        children: [
          SizedBox(
            width: 240,
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  alignment: Alignment.centerLeft,
                  child: Text('选择软件', style: theme.textTheme.titleSmall),
                ),
                const Divider(height: 1),
                Expanded(
                  child: _loadingSoftwares
                      ? const Center(child: CircularProgressIndicator())
                      : _softwares.isEmpty
                          ? const Center(child: Text('暂无软件'))
                          : ListView.builder(
                              itemCount: _softwares.length,
                              itemBuilder: (_, i) {
                                final sw = _softwares[i];
                                final selected = sw.id == _selectedId;
                                return ListTile(
                                  dense: true,
                                  selected: selected,
                                  selectedTileColor: theme.colorScheme.primaryContainer,
                                  leading: Container(
                                    width: 32, height: 32,
                                    decoration: BoxDecoration(
                                      color: theme.colorScheme.primary.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Icon(Icons.inventory_2, size: 16, color: theme.colorScheme.primary),
                                  ),
                                  title: Text(sw.name, style: const TextStyle(fontSize: 14)),
                                  subtitle: Text(sw.slug, style: const TextStyle(fontSize: 11)),
                                  onTap: () => _selectSoftware(sw.id),
                                );
                              },
                            ),
                ),
              ],
            ),
          ),
          VerticalDivider(width: 1),
          Expanded(
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(_selected?.name ?? '公告管理', style: theme.textTheme.titleMedium),
                            Text(_selected != null ? '管理该软件的公告推送' : '请从左侧选择一个软件', style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
                          ],
                        ),
                      ),
                      if (_selectedId != null)
                        FilledButton.tonalIcon(
                          onPressed: _openCreate,
                          icon: const Icon(Icons.add, size: 18),
                          label: const Text('创建公告'),
                        ),
                    ],
                  ),
                ),
                Expanded(
                  child: _loadingAnnouncements
                      ? const Center(child: CircularProgressIndicator())
                      : _selectedId == null
                          ? Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.campaign, size: 48, color: Colors.grey.shade300),
                                  const SizedBox(height: 12),
                                  Text('请从左侧选择一个软件来管理公告', style: TextStyle(color: Colors.grey.shade500)),
                                ],
                              ),
                            )
                          : _announcements.isEmpty
                              ? Center(
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.campaign, size: 48, color: Colors.grey.shade300),
                                      const SizedBox(height: 12),
                                      Text('暂无公告', style: TextStyle(color: Colors.grey.shade500)),
                                      const SizedBox(height: 4),
                                      Text('点击"创建公告"按钮添加第一条公告', style: TextStyle(color: Colors.grey.shade400, fontSize: 13)),
                                    ],
                                  ),
                                )
                              : ListView.builder(
                                  padding: const EdgeInsets.all(16),
                                  itemCount: _announcements.length,
                                  itemBuilder: (_, i) {
                                    final a = _announcements[i];
                                    return Card(
                                      margin: const EdgeInsets.only(bottom: 8),
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
                                                    color: _typeColor(a.announcementType).withValues(alpha: 0.1),
                                                    borderRadius: BorderRadius.circular(4),
                                                  ),
                                                  child: Text(_typeLabel(a.announcementType), style: TextStyle(fontSize: 12, color: _typeColor(a.announcementType))),
                                                ),
                                                const SizedBox(width: 8),
                                                Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                                  decoration: BoxDecoration(
                                                    color: _statusColor(a.status).withValues(alpha: 0.1),
                                                    borderRadius: BorderRadius.circular(4),
                                                  ),
                                                  child: Text(_statusLabel(a.status), style: TextStyle(fontSize: 12, color: _statusColor(a.status))),
                                                ),
                                                const Spacer(),
                                                PopupMenuButton<String>(
                                                  onSelected: (v) {
                                                    if (v == 'edit') _openEdit(a);
                                                    if (v == 'publish') _publish(a.id);
                                                    if (v == 'delete') _delete(a.id);
                                                  },
                                                  itemBuilder: (_) => [
                                                    const PopupMenuItem(value: 'edit', child: Text('编辑')),
                                                    if (a.status == 'draft')
                                                      const PopupMenuItem(value: 'publish', child: Text('发布')),
                                                    const PopupMenuItem(value: 'delete', child: Text('删除', style: TextStyle(color: Colors.red))),
                                                  ],
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 8),
                                            Text(a.title, style: theme.textTheme.titleMedium),
                                            const SizedBox(height: 4),
                                            Text(a.content, style: TextStyle(color: Colors.grey.shade600), maxLines: 2, overflow: TextOverflow.ellipsis),
                                            const SizedBox(height: 8),
                                            Row(
                                              children: [
                                                if (a.filterType != 'all')
                                                  Text('筛选: ${a.filterType == 'version' ? '版本: ${a.filterVersions.join(', ')}' : '渠道: ${a.filterChannels.join(', ')}'}', style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
                                                const SizedBox(width: 16),
                                                if (a.publishedAt != null)
                                                  Text('发布于: ${_formatDate(a.publishedAt!)}', style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
                                                if (a.expiresAt != null)
                                                  Text('过期于: ${_formatDate(a.expiresAt!)}', style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                  },
                                ),
                ),
              ],
            ),
          ),
        ],
      ),
      ),
      _buildDialogOverlay(),
    ]);
  }

  Widget _buildDialogOverlay() {
    if (!_showFormDialog) return const SizedBox.shrink();
    final theme = Theme.of(context);
    return Material(
      color: Colors.black26,
      child: Center(
        child: Dialog(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(_editing != null ? '编辑公告' : '创建公告', style: theme.textTheme.titleLarge),
                  const SizedBox(height: 20),
                  DropdownButtonFormField<String>(
                    value: _formType,
                    decoration: const InputDecoration(labelText: '公告类型', border: OutlineInputBorder()),
                    items: const [
                      DropdownMenuItem(value: 'urgent', child: Text('紧急公告')),
                      DropdownMenuItem(value: 'update', child: Text('更新公告')),
                      DropdownMenuItem(value: 'operation', child: Text('运营公告')),
                      DropdownMenuItem(value: 'custom', child: Text('自定义公告')),
                    ],
                    onChanged: (v) => setState(() => _formType = v ?? 'update'),
                  ),
                  const SizedBox(height: 16),
                  TextField(controller: _formTitleCtrl, decoration: const InputDecoration(labelText: '标题', border: OutlineInputBorder())),
                  const SizedBox(height: 16),
                  TextField(controller: _formContentCtrl, maxLines: 5, decoration: const InputDecoration(labelText: '内容', border: OutlineInputBorder())),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: _formFilterType,
                    decoration: const InputDecoration(labelText: '目标用户筛选', border: OutlineInputBorder()),
                    items: const [
                      DropdownMenuItem(value: 'all', child: Text('所有用户')),
                      DropdownMenuItem(value: 'version', child: Text('按版本筛选')),
                      DropdownMenuItem(value: 'channel', child: Text('按渠道筛选')),
                    ],
                    onChanged: (v) => setState(() => _formFilterType = v ?? 'all'),
                  ),
                  if (_formFilterType == 'version') ...[
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(child: TextField(controller: _versionInputCtrl, decoration: const InputDecoration(labelText: '目标版本', hintText: '输入版本号后点击添加', border: OutlineInputBorder()))),
                        const SizedBox(width: 8),
                        IconButton(onPressed: () {
                          final v = _versionInputCtrl.text.trim();
                          if (v.isNotEmpty && !_formFilterVersions.contains(v)) { setState(() => _formFilterVersions.add(v)); _versionInputCtrl.clear(); }
                        }, icon: const Icon(Icons.add)),
                      ],
                    ),
                    Wrap(spacing: 6, runSpacing: 4, children: _formFilterVersions.map((v) => Chip(
                      label: Text(v, style: const TextStyle(fontSize: 12)),
                      deleteIcon: const Icon(Icons.close, size: 16),
                      onDeleted: () => setState(() => _formFilterVersions.remove(v)),
                    )).toList()),
                  ],
                  if (_formFilterType == 'channel') ...[
                    const SizedBox(height: 12),
                    const Text('目标渠道', style: TextStyle(fontWeight: FontWeight.w500)),
                    const SizedBox(height: 8),
                    if (_loadingChannels)
                      const Text('加载渠道中...')
                    else if (_channels.isEmpty)
                      Text('该软件暂无渠道', style: TextStyle(color: Colors.grey.shade500))
                    else
                      Wrap(spacing: 6, children: _channels.map((c) => FilterChip(
                        label: Text(c),
                        selected: _formFilterChannels.contains(c),
                        onSelected: (v) { setState(() { if (v) { _formFilterChannels.add(c); } else { _formFilterChannels.remove(c); } }); },
                      )).toList()),
                  ],
                  const SizedBox(height: 16),
                  TextField(
                    decoration: const InputDecoration(labelText: '过期时间（可选）', border: OutlineInputBorder(), hintText: 'yyyy-MM-dd HH:mm'),
                    controller: TextEditingController(text: _formExpiresAt),
                    onChanged: (v) => _formExpiresAt = v,
                  ),
                  const SizedBox(height: 20),
                  Row(mainAxisAlignment: MainAxisAlignment.end, children: [
                    OutlinedButton(onPressed: () => setState(() => _showFormDialog = false), child: const Text('取消')),
                    const SizedBox(width: 12),
                    FilledButton(onPressed: _save, child: Text(_editing != null ? '保存' : '创建')),
                  ]),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
