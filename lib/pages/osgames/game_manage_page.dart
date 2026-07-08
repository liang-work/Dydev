import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../models/game.dart';
import '../../providers/auth_provider.dart';
import '../../services/logger_service.dart';

class GameManagePage extends StatefulWidget {
  const GameManagePage({super.key});

  @override
  State<GameManagePage> createState() => _GameManagePageState();
}

class _GameManagePageState extends State<GameManagePage> {
  List<Game> _games = [];
  bool _loading = true;
  String _currentTab = 'pending';



  static const _tabs = ['pending', 'published', 'rejected', 'all'];
  static const _tabLabels = {'pending': '待审核', 'published': '已上架', 'rejected': '已拒绝', 'all': '全部'};

  @override
  void initState() {
    super.initState();
    _load();
  }

  int get _pendingCount => _games.where((g) => g.status == 'pending').length;

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final api = context.read<AuthProvider>().apiService;
      _games = await api.getOsgamesAdminPending(status: _currentTab);
    } catch (e, s) {
      LoggerService.e('GameManagePage', 'load failed', e, s);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('加载失败')));
      }
    }
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _approve(Game game) async {
    final confirm = await showDialog<bool>(context: context, builder: (ctx) => AlertDialog(
      title: const Text('确认'),
      content: Text('确定要通过 "${game.name}" 的上架申请吗？'),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('取消')),
        TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('通过')),
      ],
    ));
    if (confirm != true) return;
    if (!mounted) return;
    try {
      await context.read<AuthProvider>().apiService.approveOsgamesGame(game.id);
      _load();
    } catch (e, s) {
      LoggerService.e('GameManagePage', 'approve failed', e, s);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('操作失败')));
      }
    }
  }

  Future<void> _reject(Game game) async {
    final confirm = await showDialog<bool>(context: context, builder: (ctx) => AlertDialog(
      title: const Text('确认'),
      content: Text('确定要拒绝 "${game.name}" 的上架申请吗？'),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('取消')),
        TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('拒绝')),
      ],
    ));
    if (confirm != true) return;
    if (!mounted) return;
    try {
      await context.read<AuthProvider>().apiService.rejectOsgamesGame(game.id);
      _load();
    } catch (e, s) {
      LoggerService.e('GameManagePage', 'reject failed', e, s);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('操作失败')));
      }
    }
  }

  Future<void> _takedown(Game game) async {
    final confirm = await showDialog<bool>(context: context, builder: (ctx) => AlertDialog(
      title: const Text('确认'),
      content: Text('确定要下架 "${game.name}" 吗？'),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('取消')),
        TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('下架')),
      ],
    ));
    if (confirm != true) return;
    if (!mounted) return;
    try {
      await context.read<AuthProvider>().apiService.takedownOsgamesGame(game.id, reason: '管理员下架');
      _load();
    } catch (e, s) {
      LoggerService.e('GameManagePage', 'takedown failed', e, s);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('操作失败')));
      }
    }
  }

  String _priceTypeLabel(String t) {
    switch (t) {
      case 'free': return '免费';
      case 'paid': return '付费';
      case 'donation': return '捐赠支持';
      default: return t;
    }
  }

  Color _statusColor(ColorScheme cs, String s) {
    switch (s) {
      case 'published': return cs.tertiary;
      case 'pending': return cs.secondary;
      case 'rejected': return cs.error;
      default: return cs.onSurfaceVariant;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        leading: Navigator.of(context).canPop()
            ? IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => context.pop())
            : null,
        title: const Text('游戏管理'),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 12),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              border: Border.all(color: cs.outlineVariant),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text('待审核: $_pendingCount', style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant)),
          ),
        ],
      ),
      body: Column(
        children: [
          // Tab filters
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: _tabs.map((t) {
                final isSelected = _currentTab == t;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(_tabLabels[t] ?? t),
                    selected: isSelected,
                    onSelected: (_) {
                      setState(() => _currentTab = t);
                      _load();
                    },
                  ),
                );
              }).toList(),
            ),
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _games.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.inventory_2, size: 48, color: cs.surfaceContainerHigh),
                            const SizedBox(height: 12),
                            Text('暂无${_tabLabels[_currentTab]}的游戏', style: TextStyle(color: cs.onSurfaceVariant)),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: _games.length,
                        itemBuilder: (_, i) {
                          final game = _games[i];
                          return Card(
                            margin: const EdgeInsets.only(bottom: 8),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    width: 56, height: 56,
                                    decoration: BoxDecoration(
                                      color: game.iconUrl.isNotEmpty ? null : theme.colorScheme.primaryContainer,
                                      borderRadius: BorderRadius.circular(12),
                                      image: game.iconUrl.isNotEmpty
                                          ? DecorationImage(image: NetworkImage(game.iconUrl), fit: BoxFit.contain) : null,
                                    ),
                                    child: game.iconUrl.isEmpty ? Icon(Icons.inventory_2, color: theme.colorScheme.primary) : null,
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(children: [
                                          Text(game.name, style: theme.textTheme.titleSmall),
                                          const SizedBox(width: 8),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: _statusColor(cs, game.status).withValues(alpha: 0.1),
                                              borderRadius: BorderRadius.circular(4),
                                            ),
                                            child: Text(game.statusLabel, style: TextStyle(fontSize: 10, color: _statusColor(cs, game.status))),
                                          ),
                                        ]),
                                        const SizedBox(height: 4),
                                        Text(game.shortDescription, style: TextStyle(color: cs.onSurfaceVariant, fontSize: 13), maxLines: 1, overflow: TextOverflow.ellipsis),
                                        const SizedBox(height: 4),
                                        Row(children: [
                                          Text('开发者: ${game.developerName}', style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant)),
                                          if (game.categoryName.isNotEmpty) ...[
                                            const SizedBox(width: 12),
                                            Text('分类: ${game.categoryName}', style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant)),
                                          ],
                                        ]),
                                        if (game.badges.isNotEmpty) ...[
                                          const SizedBox(height: 4),
                                          Wrap(
                                            spacing: 4,
                                            children: game.badges.map((b) => _BadgeChip(badge: b)).toList(),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                  Column(
                                    children: [
                                      FilledButton.tonal(
                                        onPressed: () {
                                          showDialog(context: context, builder: (ctx) => AlertDialog(
                                            title: Text(game.name),
                                            content: SingleChildScrollView(
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  if (game.iconUrl.isNotEmpty)
                                                    ClipRRect(
                                                      borderRadius: BorderRadius.circular(8),
                                                      child: Image.network(game.iconUrl, height: 80, width: 80, fit: BoxFit.contain),
                                                    ),
                                                  const SizedBox(height: 8),
                                                  Text(game.shortDescription),
                                                  const SizedBox(height: 8),
                                                  if (game.description.isNotEmpty) Text(game.description),
                                                  const SizedBox(height: 8),
                                                  Text('开发者: ${game.developerName}', style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant)),
                                                  if (game.categoryName.isNotEmpty)
                                                    Text('分类: ${game.categoryName}', style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant)),
                                                  Text('平台: ${game.platforms.join(", ")}', style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant)),
                                                  Text('价格类型: ${_priceTypeLabel(game.priceType)}', style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant)),
                                                  if (game.badges.isNotEmpty) ...[
                                                    const SizedBox(height: 4),
                                                    Wrap(spacing: 4, children: game.badges.map((b) => _BadgeChip(badge: b)).toList()),
                                                  ],
                                                ],
                                              ),
                                            ),
                                            actions: [
                                              if (game.status == 'pending') ...[
                                                FilledButton(onPressed: () { Navigator.pop(ctx); _approve(game); }, child: const Text('通过')),
                                                const SizedBox(width: 8),
                                                FilledButton(onPressed: () { Navigator.pop(ctx); _reject(game); }, style: FilledButton.styleFrom(backgroundColor: cs.error), child: const Text('拒绝')),
                                              ],
                                              if (game.status == 'published')
                                                FilledButton(onPressed: () { Navigator.pop(ctx); _takedown(game); }, style: FilledButton.styleFrom(backgroundColor: cs.error), child: const Text('下架')),
                                              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('关闭')),
                                            ],
                                          ));
                                        },
                                        style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6)),
                                        child: const Text('查看详情', style: TextStyle(fontSize: 12)),
                                      ),
                                      if (game.status == 'pending') ...[
                                        const SizedBox(height: 6),
                                        FilledButton(
                                          onPressed: () => _approve(game),
                                          style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6)),
                                          child: const Text('通过', style: TextStyle(fontSize: 12)),
                                        ),
                                        const SizedBox(height: 4),
                                        FilledButton(
                                          onPressed: () => _reject(game),
                                          style: FilledButton.styleFrom(backgroundColor: cs.error, padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6)),
                                          child: const Text('拒绝', style: TextStyle(fontSize: 12)),
                                        ),
                                      ],
                                      if (game.status == 'published') ...[
                                        const SizedBox(height: 6),
                                        FilledButton(
                                          onPressed: () => _takedown(game),
                                          style: FilledButton.styleFrom(backgroundColor: cs.error, padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6)),
                                          child: const Text('下架', style: TextStyle(fontSize: 12)),
                                        ),
                                      ],
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
    );
  }
}

class _BadgeChip extends StatelessWidget {
  final String badge;
  const _BadgeChip({required this.badge});

  @override
  Widget build(BuildContext context) {
    final config = _badgeConfig[badge];
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
      decoration: BoxDecoration(
        color: (config?.color ?? Colors.grey).withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(config?.label ?? badge, style: TextStyle(fontSize: 10, color: config?.color ?? Colors.grey, fontWeight: FontWeight.w500)),
    );
  }
}

const _badgeConfig = {
  'official': _BadgeConfig(label: '官方', color: Color(0xFF3B82F6)),
  'verified': _BadgeConfig(label: '认证', color: Color(0xFF22C55E)),
  'featured': _BadgeConfig(label: '精选', color: Color(0xFFA855F7)),
  'trending': _BadgeConfig(label: '热门', color: Color(0xFFF97316)),
  'new': _BadgeConfig(label: '新品', color: Color(0xFF06B6D4)),
};

class _BadgeConfig {
  final String label;
  final Color color;
  const _BadgeConfig({required this.label, required this.color});
}
