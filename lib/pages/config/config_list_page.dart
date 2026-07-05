import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../models/config_item.dart';
import '../../models/software.dart';
import '../../providers/auth_provider.dart';
import '../../services/logger_service.dart';

class ConfigListPage extends StatefulWidget {
  const ConfigListPage({super.key});

  @override
  State<ConfigListPage> createState() => _ConfigListPageState();
}

class _ConfigListPageState extends State<ConfigListPage> {
  List<Software> _softwares = [];
  List<ConfigItem> _items = [];
  String? _selectedSoftwareId;
  bool _loadingItems = false;

  // Form
  bool _showDialog = false;
  ConfigItem? _editingItem;
  final _formKeyCtrl = TextEditingController();
  final _formValueCtrl = TextEditingController();
  final _formDescCtrl = TextEditingController();
  bool _formIsActive = true;
  String? _jsonError;

  @override
  void initState() {
    super.initState();
    _loadSoftwares();
  }

  @override
  void dispose() {
    _formKeyCtrl.dispose();
    _formValueCtrl.dispose();
    _formDescCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadSoftwares() async {
    try {
      final api = context.read<AuthProvider>().apiService;
      _softwares = await api.getSoftwares();
      if (_softwares.isNotEmpty && _selectedSoftwareId == null) {
        _selectedSoftwareId = _softwares.first.id;
        _loadItems();
      }
    } catch (e, s) {
      LoggerService.e('_ConfigListPageState', 'load softwares', e, s);
    }
  }

  Future<void> _loadItems() async {
    if (_selectedSoftwareId == null) return;
    setState(() => _loadingItems = true);
    try {
      final api = context.read<AuthProvider>().apiService;
      _items = await api.getConfigItems(softwareId: _selectedSoftwareId!);
    } catch (e, s) {
      LoggerService.e('_ConfigListPageState', 'load config items', e, s);
    }
    if (mounted) setState(() => _loadingItems = false);
  }

  bool get _canEdit {
    final sw = _softwares.cast<Software?>().firstWhere(
      (s) => s!.id == _selectedSoftwareId,
      orElse: () => null,
    );
    return sw != null && ['owner', 'admin', 'developer'].contains(sw.role);
  }

  void _openCreate() {
    _editingItem = null;
    _formKeyCtrl.clear();
    _formValueCtrl.clear();
    _formDescCtrl.clear();
    _formIsActive = true;
    _jsonError = null;
    setState(() => _showDialog = true);
  }

  void _openEdit(ConfigItem item) {
    _editingItem = item;
    _formKeyCtrl.text = item.key;
    _formValueCtrl.text = const JsonEncoder.withIndent('  ').convert(item.value);
    _formDescCtrl.text = item.description;
    _formIsActive = item.isActive;
    _jsonError = null;
    setState(() => _showDialog = true);
  }

  Future<void> _save() async {
    if (_selectedSoftwareId == null) return;
    try {
      final value = jsonDecode(_formValueCtrl.text);
      final data = {
        'software': _selectedSoftwareId,
        'key': _formKeyCtrl.text,
        'value': value,
        'description': _formDescCtrl.text,
        'is_active': _formIsActive,
      };
      final api = context.read<AuthProvider>().apiService;
      if (_editingItem != null) {
        await api.updateConfigItem(_editingItem!.id, data);
      } else {
        await api.createConfigItem(data);
      }
      setState(() => _showDialog = false);
      _loadItems();
    } on FormatException {
      setState(() => _jsonError = '无效的 JSON 格式');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('保存失败: $e')));
      }
    }
  }

  Future<void> _delete(String id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('确认删除'),
        content: const Text('确定删除此配置项吗？'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('取消')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('删除')),
        ],
      ),
    );
    if (confirm != true) return;
    try {
      final api = context.read<AuthProvider>().apiService;
      await api.deleteConfigItem(id);
      _loadItems();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('删除失败: $e')));
      }
    }
  }

  String _formatDate(String d) {
    try {
      return DateTime.parse(d).toLocal().toString().substring(0, 19);
    } catch (_) {
      return d;
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Stack(
      children: [
        Scaffold(
          appBar: AppBar(
            leading: Navigator.of(context).canPop()
                ? IconButton(icon: Icon(Icons.arrow_back), onPressed: () => context.pop())
                : null,
            title: const Text('云端配置'),
            actions: [
              if (_canEdit)
                IconButton(
                  icon: const Icon(Icons.add),
                  onPressed: _openCreate,
                  tooltip: '新增配置项',
                ),
            ],
          ),
          body: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                color: cs.surfaceContainerLow,
                child: Row(
                  children: [
                    const Text('所属软件: ', style: TextStyle(fontWeight: FontWeight.w600)),
                    const SizedBox(width: 8),
                    DropdownButton<String>(
                      value: _selectedSoftwareId,
                      items: _softwares.map((sw) => DropdownMenuItem(value: sw.id, child: Text(sw.name))).toList(),
                      onChanged: (v) {
                        setState(() => _selectedSoftwareId = v);
                        _loadItems();
                      },
                    ),
                    const Spacer(),
                    IconButton(icon: const Icon(Icons.refresh), onPressed: _loadItems),
                  ],
                ),
              ),
              Expanded(
                child: _loadingItems
                    ? const Center(child: CircularProgressIndicator())
                    : _items.isEmpty
                        ? Center(child: Text('暂无配置项', style: TextStyle(color: cs.onSurfaceVariant)))
                        : SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: DataTable(
                              columns: const [
                                DataColumn(label: Text('Key')),
                                DataColumn(label: Text('Value')),
                                DataColumn(label: Text('描述')),
                                DataColumn(label: Text('状态')),
                                DataColumn(label: Text('更新')),
                                DataColumn(label: Text('操作')),
                              ],
                              rows: _items.map((item) {
                                final isActive = item.isActive;
                                return DataRow(cells: [
                                  DataCell(Text(item.key, style: const TextStyle(fontWeight: FontWeight.bold, fontFamily: 'monospace'))),
                                  DataCell(Container(
                                    constraints: const BoxConstraints(maxWidth: 200),
                                    child: Text(
                                      const JsonEncoder.withIndent('  ').convert(item.value),
                                      style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
                                      overflow: TextOverflow.ellipsis, maxLines: 2,
                                    ),
                                  )),
                                  DataCell(Text(item.description.isEmpty ? '-' : item.description)),
                                  DataCell(Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: isActive ? cs.tertiaryContainer : cs.surfaceContainerHighest,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(isActive ? '已启用' : '已禁用', style: TextStyle(color: isActive ? cs.tertiary : cs.onSurfaceVariant, fontSize: 12)),
                                  )),
                                  DataCell(Text(_formatDate(item.updatedAt), style: const TextStyle(fontSize: 12))),
                                  DataCell(_canEdit
                                      ? Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            IconButton(icon: const Icon(Icons.edit, size: 18), onPressed: () => _openEdit(item)),
                                            IconButton(icon: Icon(Icons.delete, size: 18, color: cs.error), onPressed: () => _delete(item.id)),
                                          ],
                                        )
                                      : Text('无权限', style: TextStyle(color: cs.onSurfaceVariant, fontStyle: FontStyle.italic))),
                                ]);
                              }).toList(),
                            ),
                          ),
              ),
            ],
          ),
          floatingActionButton: _canEdit
              ? FloatingActionButton.small(onPressed: _openCreate, child: const Icon(Icons.add))
              : null,
        ),
        _buildDialogOverlay(),
      ],
    );
  }

  Widget _buildDialogOverlay() {
    if (!_showDialog) return const SizedBox.shrink();
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    return Material(
      color: cs.scrim.withValues(alpha: 0.26),
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
                  Text(_editingItem != null ? '编辑配置' : '新增配置', style: theme.textTheme.titleLarge),
                  const SizedBox(height: 4),
                  Text('配置变更将通过 WebSocket 实时推送至在线客户端。', style: TextStyle(color: cs.onSurfaceVariant, fontSize: 13)),
                  const SizedBox(height: 20),
                  TextField(controller: _formKeyCtrl, decoration: const InputDecoration(labelText: '配置键 (Key)', border: OutlineInputBorder(), helperText: '例如: server_url, enable_feature_x'), enabled: _editingItem == null),
                  const SizedBox(height: 16),
                  TextField(controller: _formValueCtrl, maxLines: 5, decoration: InputDecoration(labelText: '配置值 (Value - JSON格式)', border: const OutlineInputBorder(), errorText: _jsonError, helperText: '例如: "https://api.com" 或 {"enabled": true}'), onChanged: (v) {
                    try { jsonDecode(v); setState(() => _jsonError = null); }
                    on FormatException { setState(() => _jsonError = '无效的 JSON 格式'); }
                  }),
                  const SizedBox(height: 16),
                  TextField(controller: _formDescCtrl, decoration: const InputDecoration(labelText: '描述', border: OutlineInputBorder())),
                  const SizedBox(height: 12),
                  Row(children: [
                    Checkbox(value: _formIsActive, onChanged: (v) => setState(() => _formIsActive = v ?? true)),
                    const Text('立即启用'),
                  ]),
                  const SizedBox(height: 20),
                  Row(mainAxisAlignment: MainAxisAlignment.end, children: [
                    OutlinedButton(onPressed: () => setState(() => _showDialog = false), child: const Text('取消')),
                    const SizedBox(width: 12),
                    FilledButton(onPressed: _jsonError != null ? null : _save, child: const Text('保存并推送')),
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
