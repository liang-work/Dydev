import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../models/game.dart';
import '../../models/game_category.dart';
import '../../models/game_issue.dart';
import '../../providers/auth_provider.dart';
import '../../services/logger_service.dart';

class GameListPage extends StatefulWidget {
  const GameListPage({super.key});

  @override
  State<GameListPage> createState() => _GameListPageState();
}

class _GameListPageState extends State<GameListPage> {
  List<Game> _games = [];
  bool _loading = true;

  // Create / Edit dialog
  bool _showDialog = false;
  Game? _editing;
  bool _submitting = false;

  // Form controllers
  final _formNameCtrl = TextEditingController();
  final _formSubtitleCtrl = TextEditingController();
  final _formShortDescCtrl = TextEditingController();
  final _formDescCtrl = TextEditingController();
  final _formIconCtrl = TextEditingController();
  final _formCoverCtrl = TextEditingController();
  final _formWebsiteCtrl = TextEditingController();
  final _formSourceCtrl = TextEditingController();
  final _formDonationCtrl = TextEditingController();
  final _formPriceCtrl = TextEditingController(text: '0');
  final _formTagsCtrl = TextEditingController();
  String _formPriceType = 'free';
  List<String> _formPlatforms = [];
  int? _formCategory;
  List<GameCategory> _categories = [];

  // Screenshots
  final List<TextEditingController> _screenshotCtrls = [];

  // Custom links
  final List<_CustomLinkForm> _customLinkForms = [];

  // Issues dialog
  bool _showIssuesDialog = false;
  Game? _issuesGame;
  List<GameIssue> _issues = [];
  bool _issuesLoading = false;

  // Delete
  Game? _deletingGame;
  bool _showDeleteDialog = false;
  bool _deleting = false;

  // Submit
  String? _submittingId;

  String _currentFilter = 'all';

  static const _statusOptions = ['all', 'draft', 'pending', 'published', 'rejected'];

  @override
  void initState() {
    super.initState();
    _load();
    _loadCategories();
  }

  @override
  void dispose() {
    _formNameCtrl.dispose();
    _formSubtitleCtrl.dispose();
    _formShortDescCtrl.dispose();
    _formDescCtrl.dispose();
    _formIconCtrl.dispose();
    _formCoverCtrl.dispose();
    _formWebsiteCtrl.dispose();
    _formSourceCtrl.dispose();
    _formDonationCtrl.dispose();
    _formPriceCtrl.dispose();
    _formTagsCtrl.dispose();
    for (final c in _screenshotCtrls) { c.dispose(); }
    super.dispose();
  }

  List<Game> get _filteredGames {
    if (_currentFilter == 'all') return _games;
    return _games.where((g) => g.status == _currentFilter).toList();
  }

  int get _totalCount => _games.length;
  int get _publishedCount => _games.where((g) => g.status == 'published').length;
  int get _pendingCount => _games.where((g) => g.status == 'pending').length;

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final api = context.read<AuthProvider>().apiService;
      _games = await api.getOsgamesGames();
    } catch (e, s) {
      LoggerService.e('GameListPage', 'load failed', e, s);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('common.operation.failed'.tr())));
      }
    }
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _loadCategories() async {
    try {
      final api = context.read<AuthProvider>().apiService;
      _categories = await api.getOsgamesCategories();
    } catch (_) {}
  }

  void _openCreate() {
    _editing = null;
    _resetForm();
    setState(() => _showDialog = true);
  }

  void _openEdit(Game game) {
    _editing = game;
    _formNameCtrl.text = game.name;
    _formSubtitleCtrl.text = game.subtitle;
    _formShortDescCtrl.text = game.shortDescription;
    _formDescCtrl.text = game.description;
    _formIconCtrl.text = game.iconUrl;
    _formCoverCtrl.text = game.coverUrl;
    _formWebsiteCtrl.text = game.websiteUrl;
    _formSourceCtrl.text = game.sourceUrl;
    _formDonationCtrl.text = game.donationUrl;
    _formPriceCtrl.text = game.price.toStringAsFixed(2);
    _formTagsCtrl.text = game.tags.join(', ');
    _formPriceType = game.priceType;
    _formPlatforms = [...game.platforms];
    _formCategory = game.category;
    _screenshotCtrls.clear();
    for (final s in game.screenshots) {
      _screenshotCtrls.add(TextEditingController(text: s.imageUrl));
    }
    _customLinkForms.clear();
    for (final l in game.customLinks) {
      _customLinkForms.add(_CustomLinkForm(label: l.label, url: l.url, action: l.action));
    }
    setState(() => _showDialog = true);
  }

  void _resetForm() {
    _formNameCtrl.clear();
    _formSubtitleCtrl.clear();
    _formShortDescCtrl.clear();
    _formDescCtrl.clear();
    _formIconCtrl.clear();
    _formCoverCtrl.clear();
    _formWebsiteCtrl.clear();
    _formSourceCtrl.clear();
    _formDonationCtrl.clear();
    _formPriceCtrl.text = '0';
    _formTagsCtrl.clear();
    _formPriceType = 'free';
    _formPlatforms = [];
    _formCategory = null;
    _screenshotCtrls.clear();
    _customLinkForms.clear();
  }

  void _addScreenshot() {
    setState(() => _screenshotCtrls.add(TextEditingController()));
  }

  void _removeScreenshot(int index) {
    _screenshotCtrls[index].dispose();
    setState(() => _screenshotCtrls.removeAt(index));
  }

  void _addCustomLink() {
    setState(() => _customLinkForms.add(_CustomLinkForm()));
  }

  void _removeCustomLink(int index) {
    setState(() => _customLinkForms.removeAt(index));
  }

  Future<void> _submitForm() async {
    if (_formNameCtrl.text.trim().isEmpty || _formShortDescCtrl.text.trim().isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('请填写游戏名称和简短描述')));
      }
      return;
    }
    setState(() => _submitting = true);
    try {
      final tags = _formTagsCtrl.text
          .split(',')
          .map((t) => t.trim())
          .where((t) => t.isNotEmpty)
          .toList();
      final screenshots = _screenshotCtrls
          .map((c) => c.text.trim())
          .where((s) => s.isNotEmpty)
          .map((url) => {'image_url': url})
          .toList();
      final data = gameToCreateJson(
        name: _formNameCtrl.text.trim(),
        subtitle: _formSubtitleCtrl.text.trim(),
        shortDescription: _formShortDescCtrl.text.trim(),
        description: _formDescCtrl.text.trim(),
        category: _formCategory,
        tags: tags,
        platforms: _formPlatforms,
        priceType: _formPriceType,
        price: double.tryParse(_formPriceCtrl.text) ?? 0,
        donationUrl: _formDonationCtrl.text.trim(),
        iconUrl: _formIconCtrl.text.trim(),
        coverUrl: _formCoverCtrl.text.trim(),
        websiteUrl: _formWebsiteCtrl.text.trim(),
        sourceUrl: _formSourceCtrl.text.trim(),
        customLinks: _customLinkForms
            .map((f) => CustomLink(label: f.label, url: f.url, action: f.action))
            .toList(),
        screenshots: screenshots,
      );
      final api = context.read<AuthProvider>().apiService;
      if (_editing != null) {
        await api.updateOsgamesGame(_editing!.id, data);
      } else {
        await api.createOsgamesGame(data);
      }
      setState(() => _showDialog = false);
      _load();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('common.save.success'.tr())));
      }
    } catch (e, s) {
      LoggerService.e('GameListPage', 'save failed', e, s);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('common.operation.failed'.tr())));
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Future<void> _submitForReview(Game game) async {
    setState(() => _submittingId = '${game.id}');
    try {
      await context.read<AuthProvider>().apiService.submitOsgamesGame(game.id);
      _load();
    } catch (e, s) {
      LoggerService.e('GameListPage', 'submit failed', e, s);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('common.operation.failed'.tr())));
      }
    } finally {
      if (mounted) setState(() => _submittingId = null);
    }
  }

  Future<void> _delete(Game game) async {
    _deletingGame = game;
    setState(() => _showDeleteDialog = true);
  }

  Future<void> _confirmDelete() async {
    if (_deletingGame == null) return;
    setState(() => _deleting = true);
    try {
      await context.read<AuthProvider>().apiService.deleteOsgamesGame(_deletingGame!.id);
      _deletingGame = null;
      _showDeleteDialog = false;
      _load();
    } catch (e, s) {
      LoggerService.e('GameListPage', 'delete failed', e, s);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('common.operation.failed'.tr())));
      }
    } finally {
      if (mounted) setState(() => _deleting = false);
    }
  }

  Future<void> _viewIssues(Game game) async {
    _issuesGame = game;
    _issuesLoading = true;
    setState(() => _showIssuesDialog = true);
    try {
      final api = context.read<AuthProvider>().apiService;
      _issues = await api.getOsgamesGameIssues(game.id);
    } catch (_) {
      _issues = [];
    } finally {
      if (mounted) setState(() => _issuesLoading = false);
    }
  }

  Future<void> _updateIssueStatus(int issueId, String status) async {
    try {
      final api = context.read<AuthProvider>().apiService;
      await api.updateOsgamesIssueStatus(issueId, status);
      if (_issuesGame != null) {
        _issues = await api.getOsgamesGameIssues(_issuesGame!.id);
      }
      if (mounted) setState(() {});
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('common.operation.failed'.tr())));
      }
    }
  }

  Future<void> _deleteIssue(int issueId) async {
    try {
      final api = context.read<AuthProvider>().apiService;
      await api.deleteOsgamesIssue(issueId);
      if (_issuesGame != null) {
        _issues = await api.getOsgamesGameIssues(_issuesGame!.id);
      }
      if (mounted) setState(() {});
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('common.operation.failed'.tr())));
      }
    }
  }

  Color _statusColor(ColorScheme cs, String s) {
    switch (s) {
      case 'published': return cs.tertiary;
      case 'pending': return cs.secondary;
      case 'rejected': return cs.error;
      case 'removed':
      case 'takedown': return cs.onSurfaceVariant;
      default: return cs.onSurfaceVariant;
    }
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
            title: const Text('OSGames'),
            actions: [
              FilledButton.tonalIcon(
                onPressed: _openCreate,
                icon: const Icon(Icons.add, size: 18),
                label: const Text('创建游戏'),
              ),
              const SizedBox(width: 8),
            ],
          ),
          body: _loading
              ? const Center(child: CircularProgressIndicator())
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Stats
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                      child: LayoutBuilder(
                        builder: (_, constraints) {
                          final w = constraints.maxWidth;
                          final isWide = w >= 600;
                          return Row(
                            children: [
                              _StatCard(
                                icon: Icons.gamepad,
                                label: '游戏总数',
                                value: '$_totalCount',
                                color: cs.primary,
                                flex: isWide ? null : 1,
                              ),
                              if (isWide) const SizedBox(width: 12),
                              if (!isWide) const Spacer(),
                              _StatCard(
                                icon: Icons.check_circle,
                                label: '已上架',
                                value: '$_publishedCount',
                                color: cs.tertiary,
                                flex: isWide ? null : 1,
                              ),
                              if (isWide) const SizedBox(width: 12) else const Spacer(),
                              _StatCard(
                                icon: Icons.pending,
                                label: '待审核',
                                value: '$_pendingCount',
                                color: cs.secondary,
                                flex: isWide ? null : 1,
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                    // Status filters
                    const SizedBox(height: 12),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: _statusOptions.map((s) {
                            final labels = {
                              'all': '全部',
                              'draft': '草稿',
                              'pending': '待审核',
                              'published': '已上架',
                              'rejected': '已拒绝',
                            };
                            final isSelected = _currentFilter == s;
                            return Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: ChoiceChip(
                                label: Text(labels[s] ?? s),
                                selected: isSelected,
                                onSelected: (_) {
                                  setState(() => _currentFilter = s);
                                },
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Game list
                    Expanded(
                      child: _filteredGames.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.gamepad, size: 48, color: cs.surfaceContainerHigh),
                                  const SizedBox(height: 12),
                                  Text('暂无游戏', style: TextStyle(color: cs.onSurfaceVariant)),
                                  const SizedBox(height: 12),
                                  OutlinedButton.icon(
                                    onPressed: _openCreate,
                                    icon: const Icon(Icons.add, size: 16),
                                    label: const Text('创建第一个游戏'),
                                  ),
                                ],
                              ),
                            )
                          : LayoutBuilder(
                              builder: (_, constraints) {
                                final crossAxisCount = constraints.maxWidth < 600 ? 1
                                    : constraints.maxWidth < 900 ? 2 : 3;
                                return GridView.builder(
                                  padding: const EdgeInsets.all(16),
                                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: crossAxisCount,
                                    mainAxisSpacing: 12,
                                    crossAxisSpacing: 12,
                                    childAspectRatio: 1.1,
                                  ),
                                  itemCount: _filteredGames.length,
                                  itemBuilder: (_, i) => _buildGameCard(_filteredGames[i], theme, cs),
                                );
                              },
                            ),
                    ),
                  ],
                ),
        ),
        // Create/Edit dialog overlay
        if (_showDialog) _buildDialogOverlay(theme, cs),
        // Delete confirmation
        if (_showDeleteDialog) _buildDeleteDialog(theme, cs),
        // Issues dialog
        if (_showIssuesDialog) _buildIssuesDialog(theme, cs),
      ],
    );
  }

  Widget _buildGameCard(Game game, ThemeData theme, ColorScheme cs) {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 48, height: 48,
                  decoration: BoxDecoration(
                    color: game.iconUrl.isNotEmpty ? null : theme.colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(8),
                    image: game.iconUrl.isNotEmpty
                        ? DecorationImage(image: NetworkImage(game.iconUrl), fit: BoxFit.cover) : null,
                  ),
                  child: game.iconUrl.isEmpty ? Icon(Icons.gamepad, color: theme.colorScheme.primary, size: 24) : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [
                        Expanded(
                          child: Text(game.name, style: theme.textTheme.titleSmall, overflow: TextOverflow.ellipsis),
                        ),
                        const SizedBox(width: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: _statusColor(cs, game.status).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(game.statusLabel,
                              style: TextStyle(fontSize: 10, color: _statusColor(cs, game.status))),
                        ),
                      ]),
                      if (game.shortDescription.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(game.shortDescription,
                            style: TextStyle(color: cs.onSurfaceVariant, fontSize: 12),
                            maxLines: 1, overflow: TextOverflow.ellipsis),
                      ],
                      if (game.platforms.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Wrap(
                          spacing: 4,
                          runSpacing: 2,
                          children: game.platforms.map((p) => Container(
                            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                            decoration: BoxDecoration(
                              border: Border.all(color: cs.outlineVariant),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(p, style: TextStyle(fontSize: 9, color: cs.onSurfaceVariant)),
                          )).toList(),
                        ),
                      ],
                      Text(game.priceTypeLabel,
                          style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant)),
                      if (game.rejectionReason.isNotEmpty)
                        Container(
                          margin: const EdgeInsets.only(top: 2),
                          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                          decoration: BoxDecoration(
                            color: cs.error.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text('拒绝理由: ${game.rejectionReason}',
                              style: TextStyle(fontSize: 10, color: cs.error)),
                        ),
                    ],
                  ),
                ),
              ],
            ),
            const Spacer(),
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Row(
                children: [
                  // Edit
                  IconButton(
                    icon: const Icon(Icons.edit, size: 16),
                    onPressed: () => _openEdit(game),
                    tooltip: '编辑',
                    visualDensity: VisualDensity.compact,
                    constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                  ),
                  // Submit for review (draft/rejected only)
                  if (game.status == 'draft' || game.status == 'rejected')
                    IconButton(
                      icon: _submittingId == '${game.id}'
                          ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                          : const Icon(Icons.send, size: 16),
                      onPressed: _submittingId == null ? () => _submitForReview(game) : null,
                      tooltip: '提交审核',
                      visualDensity: VisualDensity.compact,
                      constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                    ),
                  // Issues (published only)
                  if (game.status == 'published')
                    IconButton(
                      icon: const Icon(Icons.feedback, size: 16),
                      onPressed: () => _viewIssues(game),
                      tooltip: '反馈',
                      visualDensity: VisualDensity.compact,
                      constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                    ),
                  const Spacer(),
                  // Delete
                  IconButton(
                    icon: Icon(Icons.delete, size: 16, color: cs.error),
                    onPressed: () => _delete(game),
                    tooltip: '删除',
                    visualDensity: VisualDensity.compact,
                    constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDialogOverlay(ThemeData theme, ColorScheme cs) {
    return Material(
      color: cs.scrim.withValues(alpha: 0.26),
      child: Center(
        child: Dialog(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: 600, maxHeight: MediaQuery.of(context).size.height * 0.85),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(_editing != null ? '编辑游戏' : '创建游戏', style: theme.textTheme.titleLarge),
                    const SizedBox(height: 4),
                    Text('填写游戏信息以发布到 OS Games', style: TextStyle(color: cs.onSurfaceVariant, fontSize: 13)),
                    const SizedBox(height: 20),

                    // Basic info
                    Text('基本信息', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                    const SizedBox(height: 12),
                    Row(children: [
                      Expanded(child: TextField(controller: _formNameCtrl, decoration: const InputDecoration(labelText: '游戏名称 *', border: OutlineInputBorder()))),
                      const SizedBox(width: 12),
                      Expanded(child: TextField(controller: _formSubtitleCtrl, decoration: const InputDecoration(labelText: '副标题', border: OutlineInputBorder()))),
                    ]),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: TextField(controller: _formShortDescCtrl, maxLines: 2, decoration: const InputDecoration(labelText: '简短描述 *', border: OutlineInputBorder())),
                    ),
                    TextField(controller: _formDescCtrl, maxLines: 4, decoration: const InputDecoration(labelText: '详细描述', border: OutlineInputBorder())),
                    const SizedBox(height: 12),
                    Row(children: [
                      Expanded(
                        child: DropdownButtonFormField<int>(
                          initialValue: _formCategory,
                          decoration: const InputDecoration(labelText: '分类', border: OutlineInputBorder()),
                          items: _categories.map((c) => DropdownMenuItem(value: c.id, child: Text(c.name))).toList(),
                          onChanged: (v) => setState(() => _formCategory = v),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(child: TextField(controller: _formTagsCtrl, decoration: const InputDecoration(labelText: '标签（逗号分隔）', border: OutlineInputBorder()))),
                    ]),
                    const SizedBox(height: 16),

                    // Platform & Price
                    const Divider(),
                    const SizedBox(height: 8),
                    Text('平台与价格', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                    const SizedBox(height: 12),
                    Text('支持平台', style: const TextStyle(fontSize: 13)),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 6,
                      children: ['Windows', 'macOS', 'Linux', 'Web', 'Android', 'iOS'].map((p) => FilterChip(
                        label: Text(p, style: const TextStyle(fontSize: 12)),
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
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          initialValue: _formPriceType,
                          decoration: const InputDecoration(labelText: '价格类型', border: OutlineInputBorder()),
                          items: const [
                            DropdownMenuItem(value: 'free', child: Text('免费')),
                            DropdownMenuItem(value: 'paid', child: Text('付费')),
                            DropdownMenuItem(value: 'donation', child: Text('捐赠支持')),
                          ],
                          onChanged: (v) => setState(() => _formPriceType = v ?? 'free'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      if (_formPriceType == 'paid')
                        Expanded(child: TextField(controller: _formPriceCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: '价格', border: OutlineInputBorder())))
                      else if (_formPriceType == 'donation')
                        Expanded(child: TextField(controller: _formDonationCtrl, decoration: const InputDecoration(labelText: '捐赠链接', border: OutlineInputBorder()))),
                    ]),
                    const SizedBox(height: 16),

                    // Media
                    const Divider(),
                    const SizedBox(height: 8),
                    Text('媒体资源', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                    const SizedBox(height: 12),
                    Row(children: [
                      Expanded(child: TextField(controller: _formIconCtrl, decoration: const InputDecoration(labelText: '图标 URL', border: OutlineInputBorder()))),
                      const SizedBox(width: 12),
                      Expanded(child: TextField(controller: _formCoverCtrl, decoration: const InputDecoration(labelText: '封面 URL', border: OutlineInputBorder()))),
                    ]),
                    const SizedBox(height: 12),
                    Text('截图', style: const TextStyle(fontSize: 13)),
                    const SizedBox(height: 6),
                    ..._screenshotCtrls.asMap().entries.map((e) => Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Row(
                        children: [
                          Expanded(child: TextField(
                            controller: e.value,
                            decoration: InputDecoration(
                              labelText: '截图 ${e.key + 1} URL',
                              border: const OutlineInputBorder(),
                              isDense: true,
                            ),
                          )),
                          const SizedBox(width: 6),
                          IconButton(
                            icon: Icon(Icons.close, size: 18, color: cs.error),
                            onPressed: () => _removeScreenshot(e.key),
                            visualDensity: VisualDensity.compact,
                          ),
                        ],
                      ),
                    )),
                    OutlinedButton.icon(
                      onPressed: _addScreenshot,
                      icon: const Icon(Icons.add, size: 16),
                      label: const Text('添加截图', style: TextStyle(fontSize: 13)),
                    ),
                    const SizedBox(height: 12),

                    // Custom links
                    Text('自定义链接', style: const TextStyle(fontSize: 13)),
                    const SizedBox(height: 6),
                    ..._customLinkForms.asMap().entries.map((e) => Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Row(
                        children: [
                          SizedBox(
                            width: 100,
                            child: TextField(
                              controller: TextEditingController(text: e.value.label),
                              onChanged: (v) => _customLinkForms[e.key].label = v,
                              decoration: const InputDecoration(labelText: '名称', border: OutlineInputBorder(), isDense: true),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: TextField(
                              controller: TextEditingController(text: e.value.url),
                              onChanged: (v) => _customLinkForms[e.key].url = v,
                              decoration: const InputDecoration(labelText: 'URL', border: OutlineInputBorder(), isDense: true),
                            ),
                          ),
                          const SizedBox(width: 6),
                          SizedBox(
                            width: 100,
                            child: DropdownButtonFormField<String>(
                              initialValue: e.value.action,
                              decoration: const InputDecoration(border: OutlineInputBorder(), isDense: true),
                              items: const [
                                DropdownMenuItem(value: 'open', child: Text('打开')),
                                DropdownMenuItem(value: 'copy', child: Text('复制')),
                              ],
                              onChanged: (v) => setState(() => _customLinkForms[e.key].action = v ?? 'open'),
                            ),
                          ),
                          const SizedBox(width: 6),
                          IconButton(
                            icon: Icon(Icons.close, size: 18, color: cs.error),
                            onPressed: () => _removeCustomLink(e.key),
                            visualDensity: VisualDensity.compact,
                          ),
                        ],
                      ),
                    )),
                    OutlinedButton.icon(
                      onPressed: _addCustomLink,
                      icon: const Icon(Icons.add, size: 16),
                      label: const Text('添加链接', style: TextStyle(fontSize: 13)),
                    ),
                    const SizedBox(height: 16),

                    // Links
                    const Divider(),
                    const SizedBox(height: 8),
                    Text('链接', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                    const SizedBox(height: 12),
                    Row(children: [
                      Expanded(child: TextField(controller: _formWebsiteCtrl, decoration: const InputDecoration(labelText: '官网 URL', border: OutlineInputBorder()))),
                      const SizedBox(width: 12),
                      Expanded(child: TextField(controller: _formSourceCtrl, decoration: const InputDecoration(labelText: '源码 URL', border: OutlineInputBorder()))),
                    ]),
                    const SizedBox(height: 20),

                    // Actions
                    Row(mainAxisAlignment: MainAxisAlignment.end, children: [
                      OutlinedButton(onPressed: () => setState(() => _showDialog = false), child: Text('common.cancel'.tr())),
                      const SizedBox(width: 12),
                      FilledButton(
                        onPressed: _submitting ? null : _submitForm,
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

  Widget _buildDeleteDialog(ThemeData theme, ColorScheme cs) {
    return Material(
      color: cs.scrim.withValues(alpha: 0.26),
      child: Center(
        child: Dialog(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('确认删除', style: theme.textTheme.titleMedium),
              const SizedBox(height: 12),
              Text('确定要删除游戏 "${_deletingGame?.name ?? ''}" 吗？此操作不可恢复。'),
              const SizedBox(height: 20),
              Row(mainAxisAlignment: MainAxisAlignment.end, children: [
                OutlinedButton(onPressed: () => setState(() => _showDeleteDialog = false), child: Text('common.cancel'.tr())),
                const SizedBox(width: 12),
                FilledButton(
                  onPressed: _deleting ? null : _confirmDelete,
                  style: FilledButton.styleFrom(backgroundColor: cs.error),
                  child: _deleting
                      ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                      : Text('common.delete'.tr()),
                ),
              ]),
            ]),
          ),
        ),
      ),
    );
  }

  Widget _buildIssuesDialog(ThemeData theme, ColorScheme cs) {
    return Material(
      color: cs.scrim.withValues(alpha: 0.26),
      child: Center(
        child: Dialog(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: 600, maxHeight: MediaQuery.of(context).size.height * 0.8),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    Expanded(child: Text('${_issuesGame?.name ?? ''} - 问题反馈', style: theme.textTheme.titleMedium)),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => setState(() => _showIssuesDialog = false),
                    ),
                  ]),
                  const Divider(),
                  Expanded(
                    child: _issuesLoading
                        ? const Center(child: CircularProgressIndicator())
                        : _issues.isEmpty
                            ? Center(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.feedback_outlined, size: 40, color: cs.onSurfaceVariant.withValues(alpha: 0.5)),
                                    const SizedBox(height: 8),
                                    Text('暂无反馈', style: TextStyle(color: cs.onSurfaceVariant)),
                                  ],
                                ),
                              )
                            : ListView.builder(
                                itemCount: _issues.length,
                                itemBuilder: (_, i) {
                                  final issue = _issues[i];
                                  return Card(
                                    margin: const EdgeInsets.only(bottom: 8),
                                    child: Padding(
                                      padding: const EdgeInsets.all(12),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(children: [
                                            Expanded(
                                              child: Row(children: [
                                                Text(issue.title, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14)),
                                                const SizedBox(width: 6),
                                                Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                                                  decoration: BoxDecoration(
                                                    border: Border.all(color: cs.outlineVariant),
                                                    borderRadius: BorderRadius.circular(4),
                                                  ),
                                                  child: Text(issue.issueTypeLabel, style: TextStyle(fontSize: 10, color: cs.onSurfaceVariant)),
                                                ),
                                              ]),
                                            ),
                                            Row(children: [
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                                                decoration: BoxDecoration(
                                                  borderRadius: BorderRadius.circular(4),
                                                  color: _issueStatusColor(cs, issue.status).withValues(alpha: 0.1),
                                                ),
                                                child: Text(issue.statusLabel, style: TextStyle(fontSize: 10, color: _issueStatusColor(cs, issue.status))),
                                              ),
                                              IconButton(
                                                icon: Icon(Icons.delete, size: 16, color: cs.error),
                                                onPressed: () => _deleteIssue(issue.id),
                                                visualDensity: VisualDensity.compact,
                                              ),
                                            ]),
                                          ]),
                                          const SizedBox(height: 4),
                                          Text(issue.content, style: TextStyle(fontSize: 13, color: cs.onSurfaceVariant)),
                                          const SizedBox(height: 8),
                                          Row(children: [
                                            Text('${issue.username} · ${issue.createdAt.length >= 10 ? issue.createdAt.substring(0, 10) : issue.createdAt}',
                                                style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant)),
                                            const Spacer(),
                                            SizedBox(
                                              width: 120,
                                              child: DropdownButtonFormField<String>(
                                                initialValue: issue.status,
                                                isDense: true,
                                                decoration: const InputDecoration(
                                                  border: OutlineInputBorder(),
                                                  contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                                  isDense: true,
                                                ),
                                                items: const [
                                                  DropdownMenuItem(value: 'open', child: Text('待处理', style: TextStyle(fontSize: 12))),
                                                  DropdownMenuItem(value: 'confirmed', child: Text('已确认', style: TextStyle(fontSize: 12))),
                                                  DropdownMenuItem(value: 'in_progress', child: Text('处理中', style: TextStyle(fontSize: 12))),
                                                  DropdownMenuItem(value: 'resolved', child: Text('已解决', style: TextStyle(fontSize: 12))),
                                                  DropdownMenuItem(value: 'closed', child: Text('已关闭', style: TextStyle(fontSize: 12))),
                                                ],
                                                onChanged: (v) {
                                                  if (v != null) _updateIssueStatus(issue.id, v);
                                                },
                                              ),
                                            ),
                                          ]),
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
          ),
        ),
      ),
    );
  }

  Color _issueStatusColor(ColorScheme cs, String status) {
    switch (status) {
      case 'open': return cs.error;
      case 'confirmed': return cs.secondary;
      case 'in_progress': return cs.tertiary;
      case 'resolved': return cs.primary;
      case 'closed': return cs.onSurfaceVariant;
      default: return cs.onSurfaceVariant;
    }
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  final int? flex;

  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
    this.flex,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cs.outlineVariant),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 18, color: color),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(value, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: cs.onSurface)),
              Text(label, style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant)),
            ],
          ),
        ],
      ),
    );
  }
}

class _CustomLinkForm {
  String label;
  String url;
  String action;

  _CustomLinkForm({this.label = '', this.url = '', this.action = 'open'});
}
