import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../models/software.dart';
import '../../providers/auth_provider.dart';
import '../../services/logger_service.dart';

class SoftwareListPage extends StatefulWidget {
  const SoftwareListPage({super.key});

  @override
  State<SoftwareListPage> createState() => _SoftwareListPageState();
}

class _SoftwareListPageState extends State<SoftwareListPage> {
  List<Software> _softwares = [];
  bool _loading = true;

  // Form
  bool _showDialog = false;
  Software? _editing;
  bool _submitting = false;
  final _formNameCtrl = TextEditingController();
  final _formSlugCtrl = TextEditingController();
  final _formDescCtrl = TextEditingController();
  final _formIconCtrl = TextEditingController();
  final _formWebsiteCtrl = TextEditingController();
  List<String> _formPlatforms = [];
  String? _copiedTokenId;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _formNameCtrl.dispose();
    _formSlugCtrl.dispose();
    _formDescCtrl.dispose();
    _formIconCtrl.dispose();
    _formWebsiteCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final api = context.read<AuthProvider>().apiService;
      _softwares = await api.getSoftwares();
      LoggerService.d('SoftwareList', 'loaded ${_softwares.length} softwares');
    } catch (e, s) {
      LoggerService.e('_SoftwareListPageState', 'load softwares', e, s);
    }
    if (mounted) setState(() => _loading = false);
  }

  void _openCreate() {
    _editing = null;
    _formNameCtrl.clear();
    _formSlugCtrl.clear();
    _formDescCtrl.clear();
    _formIconCtrl.clear();
    _formWebsiteCtrl.clear();
    _formPlatforms = [];
    setState(() => _showDialog = true);
  }

  void _openEdit(Software sw) {
    _editing = sw;
    _formNameCtrl.text = sw.name;
    _formSlugCtrl.text = sw.slug;
    _formDescCtrl.text = sw.description;
    _formIconCtrl.text = sw.iconUrl;
    _formWebsiteCtrl.text = sw.websiteUrl;
    _formPlatforms = [...sw.platforms];
    setState(() => _showDialog = true);
  }

  Future<void> _submit() async {
    setState(() => _submitting = true);
    try {
      final data = {
        'name': _formNameCtrl.text,
        'slug': _formSlugCtrl.text,
        'description': _formDescCtrl.text,
        'platforms': _formPlatforms,
        'icon_url': _formIconCtrl.text,
        'website_url': _formWebsiteCtrl.text,
      };
      final api = context.read<AuthProvider>().apiService;
      if (_editing != null) {
        await api.updateSoftware(_editing!.id, data);
      } else {
        await api.createSoftware(data);
      }
      setState(() => _showDialog = false);
      _load();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('保存失败: $e')));
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Future<void> _delete(String id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('确认删除'),
        content: const Text('确定要删除这个软件吗？所有版本数据也会被删除。'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('取消')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('删除', style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (confirm != true) return;
    try {
      final api = context.read<AuthProvider>().apiService;
      await api.deleteSoftware(id);
      _load();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('删除失败: $e')));
      }
    }
  }

  Future<void> _resetToken(String id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('确认重置'),
        content: const Text('确定要重置该软件的访问令牌吗？重置后，旧的令牌将立即失效。'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('取消')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('重置', style: TextStyle(color: Colors.orange))),
        ],
      ),
    );
    if (confirm != true) return;
    try {
      final api = context.read<AuthProvider>().apiService;
      final result = await api.resetSoftwareToken(id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('新令牌: ${result['token']}')));
      }
      _load();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('重置失败: $e')));
      }
    }
  }

  void _togglePlatform(String p) {
    setState(() {
      if (_formPlatforms.contains(p)) {
        _formPlatforms.remove(p);
      } else {
        _formPlatforms.add(p);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Stack(
      children: [
        Scaffold(
          appBar: AppBar(
            title: const Text('软件分发'),
            actions: [
              FilledButton.tonalIcon(
                onPressed: _openCreate,
                icon: const Icon(Icons.add, size: 18),
                label: const Text('添加软件'),
              ),
              const SizedBox(width: 8),
            ],
          ),
          body: _loading
              ? const Center(child: CircularProgressIndicator())
              : _softwares.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.inventory_2, size: 48, color: Colors.grey.shade300),
                          const SizedBox(height: 12),
                          Text('还没有软件，点击上方按钮添加', style: TextStyle(color: Colors.grey.shade500)),
                        ],
                      ),
                    )
                  : GridView.builder(
                      padding: const EdgeInsets.all(16),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3, crossAxisSpacing: 16, mainAxisSpacing: 16, childAspectRatio: 1.2,
                      ),
                      itemCount: _softwares.length,
                      itemBuilder: (_, i) {
                        final sw = _softwares[i];
                        return Card(
                          clipBehavior: Clip.antiAlias,
                          child: InkWell(
                            onTap: () => context.push('/dashboard/softwares/${sw.id}'),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Container(
                                        width: 40, height: 40,
                                        decoration: BoxDecoration(
                                          color: theme.colorScheme.primary.withValues(alpha: 0.1),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Icon(Icons.inventory_2, color: theme.colorScheme.primary),
                                      ),
                                      const Spacer(),
                                      PopupMenuButton<String>(
                                        onSelected: (v) {
                                          if (v == 'edit') _openEdit(sw);
                                          if (v == 'versions') context.push('/dashboard/softwares/${sw.id}/versions');
                                          if (v == 'token') _resetToken(sw.id);
                                          if (v == 'delete') _delete(sw.id);
                                        },
                                        itemBuilder: (_) => [
                                          const PopupMenuItem(value: 'edit', child: _MenuItemRow(Icons.edit_outlined, '编辑')),
                                          const PopupMenuItem(value: 'versions', child: _MenuItemRow(Icons.call_split, '版本管理')),
                                          const PopupMenuItem(value: 'token', child: _MenuItemRow(Icons.refresh_outlined, '重置 Token')),
                                          const PopupMenuItem(value: 'delete', child: _MenuItemRow(Icons.delete_outline, '删除', isDestructive: true)),
                                        ],
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  Text(sw.name, style: theme.textTheme.titleSmall),
                                  Text(sw.slug, style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
                                  const Spacer(),
                                  Text(sw.description.isEmpty ? '暂无描述' : sw.description,
                                      style: TextStyle(color: Colors.grey.shade600, fontSize: 13), maxLines: 2, overflow: TextOverflow.ellipsis),
                                  const SizedBox(height: 8),
                                  Wrap(
                                    spacing: 4, runSpacing: 4,
                                    children: [
                                      ...sw.platforms.map((p) => Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(4)),
                                        child: Text(p, style: const TextStyle(fontSize: 11)),
                                      )),
                                      if (sw.versionCount > 0)
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(color: theme.colorScheme.primaryContainer, borderRadius: BorderRadius.circular(4)),
                                          child: Text('${sw.versionCount} 个版本', style: TextStyle(fontSize: 11, color: theme.colorScheme.primary)),
                                        ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                                          decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: BorderRadius.circular(4)),
                                          child: Text(sw.token, style: const TextStyle(fontFamily: 'monospace', fontSize: 10), maxLines: 1, overflow: TextOverflow.ellipsis),
                                        ),
                                      ),
                                      const SizedBox(width: 4),
                                      GestureDetector(
                                        onTap: () {
                                          Clipboard.setData(ClipboardData(text: sw.token));
                                          setState(() => _copiedTokenId = sw.id);
                                          Future.delayed(const Duration(seconds: 2), () {
                                            if (mounted) setState(() => _copiedTokenId = null);
                                          });
                                        },
                                        child: Icon(_copiedTokenId == sw.id ? Icons.check : Icons.copy, size: 16, color: _copiedTokenId == sw.id ? Colors.green : Colors.grey),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
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
            constraints: const BoxConstraints(maxWidth: 500),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(_editing != null ? '编辑软件' : '添加软件', style: theme.textTheme.titleLarge),
                  const SizedBox(height: 4),
                  const Text('填写软件基本信息'),
                  const SizedBox(height: 20),
                  TextField(controller: _formNameCtrl, decoration: const InputDecoration(labelText: '软件名称 *', border: OutlineInputBorder())),
                  const SizedBox(height: 16),
                  TextField(controller: _formSlugCtrl, decoration: const InputDecoration(labelText: 'URL标识 (slug) *', border: OutlineInputBorder(), helperText: '用于客户端检查更新时的标识')),
                  const SizedBox(height: 16),
                  TextField(controller: _formDescCtrl, maxLines: 3, decoration: const InputDecoration(labelText: '描述', border: OutlineInputBorder())),
                  const SizedBox(height: 16),
                  Text('支持平台', style: const TextStyle(fontWeight: FontWeight.w500)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    children: ['Windows', 'macOS', 'Linux', 'Android', 'iOS', 'Web'].map((p) => FilterChip(
                      label: Text(p, style: const TextStyle(fontSize: 13)),
                      selected: _formPlatforms.contains(p),
                      onSelected: (_) => _togglePlatform(p),
                    )).toList(),
                  ),
                  const SizedBox(height: 16),
                  TextField(controller: _formIconCtrl, decoration: const InputDecoration(labelText: '图标 URL (可选)', border: OutlineInputBorder())),
                  const SizedBox(height: 16),
                  TextField(controller: _formWebsiteCtrl, decoration: const InputDecoration(labelText: '官网 URL (可选)', border: OutlineInputBorder())),
                  const SizedBox(height: 20),
                  Row(mainAxisAlignment: MainAxisAlignment.end, children: [
                    OutlinedButton(onPressed: () => setState(() => _showDialog = false), child: const Text('取消')),
                    const SizedBox(width: 12),
                    FilledButton(
                      onPressed: _submitting ? null : _submit,
                      child: _submitting
                          ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                          : Text(_editing != null ? '保存' : '创建'),
                    ),
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

class _MenuItemRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isDestructive;
  const _MenuItemRow(this.icon, this.label, {this.isDestructive = false});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: isDestructive ? Colors.red : null),
        const SizedBox(width: 8),
        Text(label, style: isDestructive ? const TextStyle(color: Colors.red) : null),
      ],
    );
  }
}
