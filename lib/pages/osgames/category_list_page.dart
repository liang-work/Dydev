import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../models/game_category.dart';
import '../../providers/auth_provider.dart';
import '../../services/logger_service.dart';

class CategoryListPage extends StatefulWidget {
  const CategoryListPage({super.key});

  @override
  State<CategoryListPage> createState() => _CategoryListPageState();
}

class _CategoryListPageState extends State<CategoryListPage> {
  List<GameCategory> _categories = [];
  bool _loading = true;

  bool _showDialog = false;
  GameCategory? _editing;
  bool _saving = false;

  final _formNameCtrl = TextEditingController();
  final _formSlugCtrl = TextEditingController();
  final _formIconCtrl = TextEditingController(text: '🎮');
  final _formDescCtrl = TextEditingController();
  final _formSortCtrl = TextEditingController(text: '0');
  bool _formActive = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _formNameCtrl.dispose();
    _formSlugCtrl.dispose();
    _formIconCtrl.dispose();
    _formDescCtrl.dispose();
    _formSortCtrl.dispose();
    super.dispose();
  }

  List<GameCategory> get _sortedCategories => [..._categories]..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final api = context.read<AuthProvider>().apiService;
      _categories = await api.getOsgamesCategories();
    } catch (e, s) {
      LoggerService.e('CategoryListPage', 'load failed', e, s);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('加载失败')));
      }
    }
    if (mounted) setState(() => _loading = false);
  }

  void _openCreate() {
    _editing = null;
    _formNameCtrl.clear();
    _formSlugCtrl.clear();
    _formIconCtrl.text = '🎮';
    _formDescCtrl.clear();
    _formSortCtrl.text = '${_categories.length}';
    _formActive = true;
    setState(() => _showDialog = true);
  }

  void _openEdit(GameCategory cat) {
    _editing = cat;
    _formNameCtrl.text = cat.name;
    _formSlugCtrl.text = cat.slug;
    _formIconCtrl.text = cat.icon.isNotEmpty ? cat.icon : '🎮';
    _formDescCtrl.text = cat.description;
    _formSortCtrl.text = '${cat.sortOrder}';
    _formActive = cat.isActive;
    setState(() => _showDialog = true);
  }

  Future<void> _save() async {
    if (_formNameCtrl.text.trim().isEmpty || _formSlugCtrl.text.trim().isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('请填写分类名称和 Slug')));
      }
      return;
    }
    setState(() => _saving = true);
    try {
      final data = {
        'name': _formNameCtrl.text.trim(),
        'slug': _formSlugCtrl.text.trim(),
        'icon': _formIconCtrl.text.trim(),
        'description': _formDescCtrl.text.trim(),
        'sort_order': int.tryParse(_formSortCtrl.text) ?? 0,
        'is_active': _formActive,
      };
      final api = context.read<AuthProvider>().apiService;
      if (_editing != null) {
        await api.updateOsgamesCategory(_editing!.id, data);
      } else {
        await api.createOsgamesCategory(data);
      }
      setState(() => _showDialog = false);
      _load();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('保存成功')));
      }
    } catch (e, s) {
      LoggerService.e('CategoryListPage', 'save failed', e, s);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('保存失败')));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _delete(GameCategory cat) async {
    final confirm = await showDialog<bool>(context: context, builder: (ctx) => AlertDialog(
      title: const Text('确认删除'),
      content: Text('确定要删除分类 "${cat.name}" 吗？'),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('取消')),
        TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('删除')),
      ],
    ));
    if (confirm != true) return;
    if (!mounted) return;
    try {
      await context.read<AuthProvider>().apiService.deleteOsgamesCategory(cat.id);
      _load();
    } catch (e, s) {
      LoggerService.e('CategoryListPage', 'delete failed', e, s);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('删除失败')));
      }
    }
  }

  Future<void> _moveUp(GameCategory cat) async {
    final sorted = _sortedCategories;
    final idx = sorted.indexWhere((c) => c.id == cat.id);
    if (idx <= 0) return;
    final prev = sorted[idx - 1];
    try {
      final api = context.read<AuthProvider>().apiService;
      await Future.wait([
        api.updateOsgamesCategory(cat.id, {'sort_order': prev.sortOrder}),
        api.updateOsgamesCategory(prev.id, {'sort_order': cat.sortOrder}),
      ]);
      _load();
    } catch (_) {}
  }

  Future<void> _moveDown(GameCategory cat) async {
    final sorted = _sortedCategories;
    final idx = sorted.indexWhere((c) => c.id == cat.id);
    if (idx >= sorted.length - 1) return;
    final next = sorted[idx + 1];
    try {
      final api = context.read<AuthProvider>().apiService;
      await Future.wait([
        api.updateOsgamesCategory(cat.id, {'sort_order': next.sortOrder}),
        api.updateOsgamesCategory(next.id, {'sort_order': cat.sortOrder}),
      ]);
      _load();
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = Theme.of(context).colorScheme;
    return Stack(
      children: [
        Scaffold(
          appBar: AppBar(
            leading: Navigator.of(context).canPop()
                ? IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => context.pop())
                : null,
            title: const Text('分类管理'),
            actions: [
              FilledButton.tonalIcon(
                onPressed: _openCreate,
                icon: const Icon(Icons.add, size: 18),
                label: const Text('添加分类'),
              ),
              const SizedBox(width: 8),
            ],
          ),
          body: _loading
              ? const Center(child: CircularProgressIndicator())
              : _categories.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.category, size: 48, color: cs.surfaceContainerHigh),
                          const SizedBox(height: 12),
                          Text('暂无分类', style: TextStyle(color: cs.onSurfaceVariant)),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _sortedCategories.length,
                      itemBuilder: (_, i) {
                        final cat = _sortedCategories[i];
                        final isFirst = i == 0;
                        final isLast = i == _sortedCategories.length - 1;
                        return Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Row(
                              children: [
                                Text(cat.icon.isNotEmpty ? cat.icon : '🎮', style: const TextStyle(fontSize: 28)),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(children: [
                                        Text(cat.name, style: theme.textTheme.titleSmall),
                                        const SizedBox(width: 8),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(
                                            border: Border.all(color: cs.outlineVariant),
                                            borderRadius: BorderRadius.circular(4),
                                          ),
                                          child: Text(cat.slug, style: TextStyle(fontSize: 10, color: cs.onSurfaceVariant)),
                                        ),
                                        if (!cat.isActive) ...[
                                          const SizedBox(width: 8),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                                            decoration: BoxDecoration(
                                              color: cs.error.withValues(alpha: 0.1),
                                              borderRadius: BorderRadius.circular(4),
                                            ),
                                            child: Text('已禁用', style: TextStyle(fontSize: 10, color: cs.error)),
                                          ),
                                        ],
                                      ]),
                                      const SizedBox(height: 4),
                                      Text(cat.description.isNotEmpty ? cat.description : '暂无描述',
                                          style: TextStyle(fontSize: 13, color: cs.onSurfaceVariant),
                                          maxLines: 1, overflow: TextOverflow.ellipsis),
                                      const SizedBox(height: 2),
                                      Text('排序: ${cat.sortOrder} | 游戏数: ${cat.gameCount}',
                                          style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant)),
                                    ],
                                  ),
                                ),
                                Column(
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.arrow_upward, size: 16),
                                      onPressed: isFirst ? null : () => _moveUp(cat),
                                      visualDensity: VisualDensity.compact,
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.arrow_downward, size: 16),
                                      onPressed: isLast ? null : () => _moveDown(cat),
                                      visualDensity: VisualDensity.compact,
                                    ),
                                  ],
                                ),
                                OutlinedButton(
                                  onPressed: () => _openEdit(cat),
                                  child: const Text('编辑', style: TextStyle(fontSize: 12)),
                                ),
                                const SizedBox(width: 8),
                                OutlinedButton(
                                  onPressed: () => _delete(cat),
                                  style: OutlinedButton.styleFrom(foregroundColor: cs.error),
                                  child: const Text('删除', style: TextStyle(fontSize: 12)),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
        ),
        if (_showDialog) _buildDialog(theme, cs),
      ],
    );
  }

  Widget _buildDialog(ThemeData theme, ColorScheme cs) {
    return Material(
      color: cs.scrim.withValues(alpha: 0.26),
      child: Center(
        child: Dialog(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 500),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(_editing != null ? '编辑分类' : '添加分类', style: theme.textTheme.titleLarge),
                    const SizedBox(height: 4),
                    Text('配置分类信息', style: TextStyle(color: cs.onSurfaceVariant, fontSize: 13)),
                    const SizedBox(height: 20),
                    Row(children: [
                      SizedBox(
                        width: 80,
                        child: TextField(controller: _formIconCtrl, decoration: const InputDecoration(labelText: '图标', border: OutlineInputBorder())),
                      ),
                      const SizedBox(width: 12),
                      Expanded(child: TextField(controller: _formNameCtrl, decoration: const InputDecoration(labelText: '分类名称 *', border: OutlineInputBorder()))),
                    ]),
                    const SizedBox(height: 12),
                    TextField(controller: _formSlugCtrl, decoration: const InputDecoration(labelText: 'Slug *（用于 URL）', border: OutlineInputBorder(), helperText: '只能包含字母、数字、连字符')),
                    const SizedBox(height: 12),
                    TextField(controller: _formDescCtrl, maxLines: 2, decoration: const InputDecoration(labelText: '描述', border: OutlineInputBorder())),
                    const SizedBox(height: 12),
                    Row(children: [
                      SizedBox(
                        width: 120,
                        child: TextField(controller: _formSortCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: '排序', border: OutlineInputBorder())),
                      ),
                      const SizedBox(width: 16),
                      Checkbox(value: _formActive, onChanged: (v) => setState(() => _formActive = v ?? true)),
                      const Text('启用'),
                    ]),
                    const SizedBox(height: 20),
                    Row(mainAxisAlignment: MainAxisAlignment.end, children: [
                      OutlinedButton(onPressed: () => setState(() => _showDialog = false), child: const Text('取消')),
                      const SizedBox(width: 12),
                      FilledButton(
                        onPressed: _saving ? null : _save,
                        child: _saving
                            ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                            : const Text('保存'),
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
