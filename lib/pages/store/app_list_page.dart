import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/store_app.dart';
import '../../models/software.dart';
import '../../models/version.dart';
import '../../providers/auth_provider.dart';
import '../../services/logger_service.dart';

class AppListPage extends StatefulWidget {
  const AppListPage({super.key});

  @override
  State<AppListPage> createState() => _AppListPageState();
}

class _AppListPageState extends State<AppListPage> {
  List<StoreApp> _apps = [];
  bool _loading = true;

  bool _showDialog = false;
  StoreApp? _editing;
  bool _submitting = false;

  // Form controllers
  final _formNameCtrl = TextEditingController();
  final _formSlugCtrl = TextEditingController();
  final _formDescCtrl = TextEditingController();
  final _formDetailCtrl = TextEditingController();
  final _formSubtitleCtrl = TextEditingController();
  final _formVersionCtrl = TextEditingController();
  final _formIconCtrl = TextEditingController();
  final _formCoverCtrl = TextEditingController();
  final _formScreenshotsCtrl = TextEditingController();
  final _formWebsiteCtrl = TextEditingController();
  final _formSourceCtrl = TextEditingController();
  final _formDeveloperCtrl = TextEditingController();
  final _formEmailCtrl = TextEditingController();
  final _formQqCtrl = TextEditingController();
  final _formWechatCtrl = TextEditingController();
  final _formContactCtrl = TextEditingController();
  final _formSupportCtrl = TextEditingController();
  final _formPriceCtrl = TextEditingController(text: '0');
  final _formTagsCtrl = TextEditingController();
  List<String> _formPlatforms = [];
  bool _formUseDistribute = false;

  // Distribute linking
  List<Software> _softwares = [];
  String? _formSoftware;
  String? _formChannel;
  Version? _selectedChannelVersion;

  @override
  void initState() {
    super.initState();
    _load();
    _loadSoftwares();
  }

  @override
  void dispose() {
    _formNameCtrl.dispose();
    _formSlugCtrl.dispose();
    _formDescCtrl.dispose();
    _formDetailCtrl.dispose();
    _formSubtitleCtrl.dispose();
    _formVersionCtrl.dispose();
    _formIconCtrl.dispose();
    _formCoverCtrl.dispose();
    _formScreenshotsCtrl.dispose();
    _formWebsiteCtrl.dispose();
    _formSourceCtrl.dispose();
    _formDeveloperCtrl.dispose();
    _formEmailCtrl.dispose();
    _formQqCtrl.dispose();
    _formWechatCtrl.dispose();
    _formContactCtrl.dispose();
    _formSupportCtrl.dispose();
    _formPriceCtrl.dispose();
    _formTagsCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final api = context.read<AuthProvider>().apiService;
      _apps = await api.getMyApps();
    } catch (e, s) {
      LoggerService.e('AppListPage', 'load failed', e, s);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('common.operation.failed'.tr())));
      }
    }
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _loadSoftwares() async {
    try {
      final api = context.read<AuthProvider>().apiService;
      _softwares = await api.getSoftwares();
    } catch (_) {}
  }

  Future<void> _onSoftwareChanged() async {
    _formChannel = null;
    _selectedChannelVersion = null;
    if (_formSoftware == null) return;
    try {
      final api = context.read<AuthProvider>().apiService;
      final channels = await api.getChannels(_formSoftware!);
      if (channels.isNotEmpty) _formChannel = channels.first.id;
    } catch (_) {}
  }

  Future<void> _onChannelChanged() async {
    _selectedChannelVersion = null;
    if (_formSoftware == null || _formChannel == null) return;
    try {
      final api = context.read<AuthProvider>().apiService;
      final versions = await api.getVersions(_formSoftware!);
      final filtered = versions.where((v) => v.channel == _formChannel && v.status == 'released').toList();
      filtered.sort((a, b) => b.versionCode.compareTo(a.versionCode));
      if (filtered.isNotEmpty) {
        final latest = filtered.first;
        _selectedChannelVersion = latest;
        _formVersionCtrl.text = latest.version;
        setState(() {});
      }
    } catch (_) {}
  }

  void _openCreate() {
    _editing = null;
    _formNameCtrl.clear();
    _formSlugCtrl.clear();
    _formDescCtrl.clear();
    _formDetailCtrl.clear();
    _formSubtitleCtrl.clear();
    _formVersionCtrl.clear();
    _formIconCtrl.clear();
    _formCoverCtrl.clear();
    _formScreenshotsCtrl.clear();
    _formWebsiteCtrl.clear();
    _formSourceCtrl.clear();
    _formDeveloperCtrl.clear();
    _formEmailCtrl.clear();
    _formQqCtrl.clear();
    _formWechatCtrl.clear();
    _formContactCtrl.clear();
    _formSupportCtrl.clear();
    _formPriceCtrl.text = '0';
    _formTagsCtrl.clear();
    _formPlatforms = [];
    _formUseDistribute = false;
    _formSoftware = null;
    _formChannel = null;
    _selectedChannelVersion = null;
    setState(() => _showDialog = true);
  }

  void _openEdit(StoreApp app) {
    _editing = app;
    _formNameCtrl.text = app.name;
    _formSlugCtrl.text = app.slug;
    _formDescCtrl.text = app.shortDescription;
    _formDetailCtrl.text = app.description;
    _formSubtitleCtrl.text = app.subtitle;
    _formVersionCtrl.text = app.currentVersion;
    _formIconCtrl.text = app.iconUrl;
    _formCoverCtrl.text = app.coverUrl;
    _formScreenshotsCtrl.text = app.screenshots.join('\n');
    _formWebsiteCtrl.text = app.websiteUrl;
    _formSourceCtrl.text = app.sourceUrl;
    _formDeveloperCtrl.text = app.developerName;
    _formEmailCtrl.text = app.developerEmail;
    _formQqCtrl.text = app.developerQq;
    _formWechatCtrl.text = app.developerWechat;
    _formContactCtrl.text = app.developerContactCustom;
    _formSupportCtrl.text = app.supportUrl;
    _formPriceCtrl.text = app.price.toStringAsFixed(2);
    _formTagsCtrl.text = app.tags.join(', ');
    _formPlatforms = [...app.platforms];
    _formUseDistribute = app.useDistribute;
    _formSoftware = app.software;
    _formChannel = app.channel;
    _selectedChannelVersion = null;
    if (_formUseDistribute && _formSoftware != null) {
      _onSoftwareChanged();
      _onChannelChanged();
    }
    setState(() => _showDialog = true);
  }

  Future<void> _submit() async {
    setState(() => _submitting = true);
    try {
      final data = {
        'name': _formNameCtrl.text,
        'slug': _formSlugCtrl.text,
        'short_description': _formDescCtrl.text,
        'description': _formDetailCtrl.text,
        'subtitle': _formSubtitleCtrl.text,
        'current_version': _formVersionCtrl.text,
        'icon_url': _formIconCtrl.text,
        'cover_url': _formCoverCtrl.text,
        'screenshots': _formScreenshotsCtrl.text
            .split('\n')
            .map((s) => s.trim())
            .where((s) => s.isNotEmpty)
            .toList(),
        'website_url': _formWebsiteCtrl.text,
        'source_url': _formSourceCtrl.text,
        'developer_name': _formDeveloperCtrl.text,
        'developer_email': _formEmailCtrl.text,
        'developer_qq': _formQqCtrl.text,
        'developer_wechat': _formWechatCtrl.text,
        'developer_contact_custom': _formContactCtrl.text,
        'support_url': _formSupportCtrl.text,
        'price': double.tryParse(_formPriceCtrl.text) ?? 0,
        'is_free': (double.tryParse(_formPriceCtrl.text) ?? 0) == 0,
        'tags': _formTagsCtrl.text
            .split(',')
            .map((t) => t.trim())
            .where((t) => t.isNotEmpty)
            .toList(),
        'platforms': _formPlatforms,
        'use_distribute': _formUseDistribute,
        'software': _formSoftware,
        'channel': _formChannel,
      };
      final api = context.read<AuthProvider>().apiService;
      if (_editing != null) {
        await api.updateStoreApp(_editing!.id, data);
      } else {
        await api.createStoreApp(data);
      }
      setState(() => _showDialog = false);
      _load();
    } catch (e, s) {
      LoggerService.e('AppListPage', 'save failed', e, s);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('common.operation.failed'.tr())));
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Future<void> _publish(String id) async {
    final confirm = await showDialog<bool>(context: context, builder: (ctx) => AlertDialog(
      title: Text('common.confirm'.tr()),
      content: Text('store.publish.confirm'.tr()),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text('common.cancel'.tr())),
        TextButton(onPressed: () => Navigator.pop(ctx, true), child: Text('common.publish'.tr())),
      ],
    ));
    if (confirm != true) return;
    try {
      await context.read<AuthProvider>().apiService.publishStoreApp(id);
      _load();
    } catch (e, s) {
      LoggerService.e('AppListPage', 'publish failed', e, s);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('common.operation.failed'.tr())));
      }
    }
  }

  Future<void> _unpublish(String id) async {
    final confirm = await showDialog<bool>(context: context, builder: (ctx) => AlertDialog(
      title: Text('common.confirm'.tr()),
      content: Text('store.unpublish.confirm'.tr()),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text('common.cancel'.tr())),
        TextButton(onPressed: () => Navigator.pop(ctx, true), child: Text('common.unpublish'.tr())),
      ],
    ));
    if (confirm != true) return;
    try {
      await context.read<AuthProvider>().apiService.unpublishStoreApp(id);
      _load();
    } catch (e, s) {
      LoggerService.e('AppListPage', 'unpublish failed', e, s);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('common.operation.failed'.tr())));
      }
    }
  }

  Future<void> _delete(String id) async {
    final confirm = await showDialog<bool>(context: context, builder: (ctx) => AlertDialog(
      title: Text('common.confirm'.tr()),
      content: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('common.delete.confirm'.tr()),
        const SizedBox(height: 8),
        Text('store.delete.hint'.tr(), style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
      ]),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text('common.cancel'.tr())),
        TextButton(onPressed: () => Navigator.pop(ctx, true), child: Text('common.delete'.tr(), style: const TextStyle(color: Colors.red))),
      ],
    ));
    if (confirm != true) return;
    try {
      await context.read<AuthProvider>().apiService.deleteStoreApp(id);
      _load();
    } catch (e, s) {
      LoggerService.e('AppListPage', 'delete failed', e, s);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('common.operation.failed'.tr())));
      }
    }
  }

  String _statusLabel(String s) {
    switch (s) {
      case 'draft': return 'store.status.draft'.tr();
      case 'pending': return 'store.status.pending'.tr();
      case 'published': return 'store.status.published'.tr();
      case 'rejected': return 'store.status.rejected'.tr();
      case 'removed': return 'store.status.removed'.tr();
      default: return s;
    }
  }

  Color _statusColor(String s) {
    switch (s) {
      case 'published': return Colors.green;
      case 'pending': return Colors.orange;
      case 'rejected': return Colors.red;
      case 'removed': return Colors.grey;
      default: return Colors.blueGrey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Stack(
      children: [
        Scaffold(
          appBar: AppBar(
            title: Text('store.title'.tr()),
            actions: [
              FilledButton.tonalIcon(
                onPressed: _openCreate,
                icon: const Icon(Icons.add, size: 18),
                label: Text('store.create'.tr()),
              ),
              const SizedBox(width: 8),
            ],
          ),
          body: _loading
              ? const Center(child: CircularProgressIndicator())
              : _apps.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.store, size: 48, color: Colors.grey.shade300),
                          const SizedBox(height: 12),
                          Text('store.empty'.tr(), style: TextStyle(color: Colors.grey.shade500)),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _apps.length,
                      itemBuilder: (_, i) {
                        final app = _apps[i];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Row(
                              children: [
                                Container(
                                  width: 48, height: 48,
                                  decoration: BoxDecoration(
                                    color: app.iconUrl.isNotEmpty ? null : theme.colorScheme.primaryContainer,
                                    borderRadius: BorderRadius.circular(8),
                                    image: app.iconUrl.isNotEmpty
                                        ? DecorationImage(image: NetworkImage(app.iconUrl), fit: BoxFit.cover) : null,
                                  ),
                                  child: app.iconUrl.isEmpty ? Icon(Icons.store, color: theme.colorScheme.primary) : null,
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(children: [
                                        Text(app.name, style: theme.textTheme.titleSmall),
                                        const SizedBox(width: 8),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: _statusColor(app.status.name).withValues(alpha: 0.1),
                                            borderRadius: BorderRadius.circular(4),
                                          ),
                                          child: Text(_statusLabel(app.status.name),
                                              style: TextStyle(fontSize: 11, color: _statusColor(app.status.name))),
                                        ),
                                      ]),
                                      const SizedBox(height: 4),
                                      Text(app.shortDescription.isEmpty ? 'store.no_description'.tr() : app.shortDescription,
                                          style: TextStyle(color: Colors.grey.shade600, fontSize: 13), maxLines: 1, overflow: TextOverflow.ellipsis),
                                    ],
                                  ),
                                ),
                                PopupMenuButton<String>(
                                  onSelected: (v) {
                                    if (v == 'edit') _openEdit(app);
                                    if (v == 'publish') _publish('${app.id}');
                                    if (v == 'unpublish') _unpublish('${app.id}');
                                    if (v == 'delete') _delete('${app.id}');
                                  },
                                  itemBuilder: (_) => [
                                    PopupMenuItem(value: 'edit', child: Text('common.edit'.tr())),
                                    if (app.status.name == 'draft' || app.status.name == 'removed')
                                      PopupMenuItem(value: 'publish', child: Text('common.publish'.tr())),
                                    if (app.status.name == 'published')
                                      PopupMenuItem(value: 'unpublish', child: Text('common.unpublish'.tr())),
                                    PopupMenuItem(value: 'delete', child: Text('common.delete'.tr(), style: const TextStyle(color: Colors.red))),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
        ),
        _buildDialogOverlay(),
      ],
    );
  }

  Widget _buildDialogOverlay() {
    if (!_showDialog) return const SizedBox.shrink();
    final theme = Theme.of(context);
    return Material(
      color: Colors.black26,
      child: Center(
        child: Dialog(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600, maxHeight: 650),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(_editing != null ? 'store.edit'.tr() : 'store.create'.tr(), style: theme.textTheme.titleLarge),
                    const SizedBox(height: 20),
                    // Basic info
                    TextField(controller: _formNameCtrl, decoration: const InputDecoration(labelText: '应用名称 *', border: OutlineInputBorder())),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _formSlugCtrl,
                      enabled: _editing == null,
                      decoration: const InputDecoration(labelText: '标识 (slug) *', border: OutlineInputBorder(), helperText: '创建后不可修改'),
                    ),
                    const SizedBox(height: 12),
                    TextField(controller: _formSubtitleCtrl, decoration: const InputDecoration(labelText: '副标题', border: OutlineInputBorder())),
                    const SizedBox(height: 12),
                    TextField(controller: _formDescCtrl, maxLines: 2, decoration: const InputDecoration(labelText: '简短描述 *', border: OutlineInputBorder())),
                    const SizedBox(height: 12),
                    TextField(controller: _formDetailCtrl, maxLines: 4, decoration: const InputDecoration(labelText: '详细描述', border: OutlineInputBorder())),
                    const SizedBox(height: 12),
                    Text('支持平台', style: const TextStyle(fontWeight: FontWeight.w500)),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 6,
                      children: ['Windows', 'macOS', 'Linux', 'Android', 'iOS'].map((p) => FilterChip(
                        label: Text(p, style: const TextStyle(fontSize: 13)),
                        selected: _formPlatforms.contains(p),
                        onSelected: (_) {
                          setState(() {
                            if (_formPlatforms.contains(p)) { _formPlatforms.remove(p); } else { _formPlatforms.add(p); }
                          });
                        },
                      )).toList(),
                    ),
                    const SizedBox(height: 12),
                    Row(children: [
                      Expanded(child: TextField(controller: _formIconCtrl, decoration: const InputDecoration(labelText: '图标 URL', border: OutlineInputBorder()))),
                      const SizedBox(width: 12),
                      Expanded(child: TextField(controller: _formCoverCtrl, decoration: const InputDecoration(labelText: '封面图 URL', border: OutlineInputBorder()))),
                    ]),
                    const SizedBox(height: 12),
                    TextField(controller: _formScreenshotsCtrl, maxLines: 3, decoration: const InputDecoration(labelText: '截图 URL（每行一个）', border: OutlineInputBorder())),
                    const SizedBox(height: 16),
                    const Divider(),
                    const SizedBox(height: 8),
                    Text('下载和链接', style: const TextStyle(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 8),
                    // Use distribute checkbox
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade300), borderRadius: BorderRadius.circular(8), color: Colors.grey.shade50),
                      child: Row(children: [
                        Checkbox(value: _formUseDistribute, onChanged: (v) => setState(() => _formUseDistribute = v ?? false)),
                        const SizedBox(width: 8),
                        const Text('关联分发系统（下载链接自动从分发版本获取）'),
                      ]),
                    ),
                    if (_formUseDistribute) ...[
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        value: _formSoftware,
                        decoration: const InputDecoration(labelText: '选择软件', border: OutlineInputBorder()),
                        items: _softwares.map((s) => DropdownMenuItem(value: s.id, child: Text(s.name))).toList(),
                        onChanged: (v) { setState(() => _formSoftware = v); _onSoftwareChanged(); },
                      ),
                    ],
                    const SizedBox(height: 12),
                    TextField(
                      controller: _formVersionCtrl,
                      enabled: !_formUseDistribute,
                      decoration: InputDecoration(
                        labelText: _formUseDistribute ? '当前版本（自动填充）' : '当前版本',
                        border: const OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(children: [
                      Expanded(child: TextField(controller: _formWebsiteCtrl, decoration: const InputDecoration(labelText: '官网链接', border: OutlineInputBorder()))),
                      const SizedBox(width: 12),
                      Expanded(child: TextField(controller: _formSourceCtrl, decoration: const InputDecoration(labelText: '源码链接', border: OutlineInputBorder()))),
                    ]),
                    const SizedBox(height: 16),
                    const Divider(),
                    const SizedBox(height: 8),
                    Text('定价与标签', style: const TextStyle(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 8),
                    Row(children: [
                      Expanded(child: TextField(controller: _formPriceCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: '价格（0 为免费）', border: OutlineInputBorder()))),
                      const SizedBox(width: 12),
                      Expanded(child: TextField(controller: _formTagsCtrl, decoration: const InputDecoration(labelText: '标签（逗号分隔）', border: OutlineInputBorder()))),
                    ]),
                    const SizedBox(height: 16),
                    const Divider(),
                    const SizedBox(height: 8),
                    Text('开发者信息', style: const TextStyle(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 8),
                    Row(children: [
                      Expanded(child: TextField(controller: _formDeveloperCtrl, decoration: const InputDecoration(labelText: '开发者名称', border: OutlineInputBorder()))),
                      const SizedBox(width: 12),
                      Expanded(child: TextField(controller: _formEmailCtrl, decoration: const InputDecoration(labelText: '开发者邮箱', border: OutlineInputBorder()))),
                    ]),
                    const SizedBox(height: 16),
                    const Divider(),
                    const SizedBox(height: 8),
                    Text('联系方式', style: const TextStyle(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 8),
                    Row(children: [
                      Expanded(child: TextField(controller: _formQqCtrl, decoration: const InputDecoration(labelText: 'QQ', border: OutlineInputBorder()))),
                      const SizedBox(width: 12),
                      Expanded(child: TextField(controller: _formWechatCtrl, decoration: const InputDecoration(labelText: '微信', border: OutlineInputBorder()))),
                    ]),
                    const SizedBox(height: 12),
                    Row(children: [
                      Expanded(child: TextField(controller: _formContactCtrl, decoration: const InputDecoration(labelText: '自定义联系方式', border: OutlineInputBorder()))),
                      const SizedBox(width: 12),
                      Expanded(child: TextField(controller: _formSupportCtrl, decoration: const InputDecoration(labelText: '支持/反馈页面', border: OutlineInputBorder()))),
                    ]),
                    const SizedBox(height: 20),
                    Row(mainAxisAlignment: MainAxisAlignment.end, children: [
                      OutlinedButton(onPressed: () => setState(() => _showDialog = false), child: Text('common.cancel'.tr())),
                      const SizedBox(width: 12),
                      FilledButton(
                        onPressed: _submitting ? null : _submit,
                        child: _submitting
                            ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                            : Text(_editing != null ? 'common.save'.tr() : 'common.create'.tr()),
                      ),
                    ]),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}