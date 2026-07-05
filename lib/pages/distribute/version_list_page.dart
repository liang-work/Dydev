import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../models/software.dart';
import '../../models/version.dart';
import '../../models/channel.dart';
import '../../models/storage_backend.dart';
import '../../models/storage_file.dart';
import '../../models/github_account.dart';
import '../../providers/auth_provider.dart';
import '../../services/logger_service.dart';

class VersionListPage extends StatefulWidget {
  final String softwareId;
  const VersionListPage({super.key, required this.softwareId});

  @override
  State<VersionListPage> createState() => _VersionListPageState();
}

class _VersionListPageState extends State<VersionListPage> {
  Software? _software;
  List<Version> _versions = [];
  List<Channel> _channels = [];
  bool _loading = true;

  // Form
  bool _showDialog = false;
  Version? _editingVersion;
  bool _submitting = false;
  final _formVersionCtrl = TextEditingController();
  final _formVersionCodeCtrl = TextEditingController();
  String _formVersionType = 'patch';
  List<String> _formChannels = [];
  final _formTitleCtrl = TextEditingController();
  final _formNotesCtrl = TextEditingController();
  final _formUrlCtrl = TextEditingController();
  final _formFileSizeCtrl = TextEditingController();
  final _formFileHashCtrl = TextEditingController();
  final _formOsCtrl = TextEditingController();
  final _formArchCtrl = TextEditingController();
  // Asset fields
  List<Map<String, String>> _formAssets = [];

  // Gray dialog
  bool _showGrayDialog = false;
  Version? _grayVersion;
  double _grayPercentage = 100;

  // Storage selector
  bool _showStorageSelector = false;
  List<StorageBackend> _storages = [];
  String? _selectedStorageId;
  List<StorageFile> _storageFiles = [];
  String _storagePath = '';
  bool _loadingStorageFiles = false;
  StorageFile? _selectedStorageFile;

  // GitHub Release selector
  bool _showGithubSelector = false;
  GitHubAccount? _githubAccount;
  List<Map<String, dynamic>> _githubRepos = [];
  String? _selectedGithubRepo;
  List<Map<String, dynamic>> _githubReleases = [];
  Map<String, dynamic>? _selectedGithubRelease;
  Map<String, dynamic>? _selectedGithubAsset;

  // Active asset index (-1 = main URL, >=0 = asset at index)
  int _activeAssetIndex = -1;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _formVersionCtrl.dispose();
    _formVersionCodeCtrl.dispose();
    _formTitleCtrl.dispose();
    _formNotesCtrl.dispose();
    _formUrlCtrl.dispose();
    _formFileSizeCtrl.dispose();
    _formFileHashCtrl.dispose();
    _formOsCtrl.dispose();
    _formArchCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    try {
      final api = context.read<AuthProvider>().apiService;
      final results = await Future.wait([
        api.getSoftware(widget.softwareId),
        api.getVersions(widget.softwareId),
        api.getChannels(widget.softwareId),
        api.getStorages(),
        api.getGithubAccount().catchError((_) => null),
      ]);
      _software = results[0] as Software;
      _versions = results[1] as List<Version>;
      _channels = results[2] as List<Channel>;
      _storages = results[3] as List<StorageBackend>;
      _githubAccount = results[4] as GitHubAccount?;
      if (_githubAccount != null) {
        try {
          _githubRepos = await api.getGithubRepos();
        } catch (_) {}
      }
      LoggerService.d('VersionList', 'loaded software=${_software?.name}, versions=${_versions.length}, channels=${_channels.length}');
    } catch (e, s) {
      LoggerService.e('_VersionListPageState', 'load versions', e, s);
    }
    if (mounted) setState(() => _loading = false);
  }

  void _resetForm() {
    _formVersionCtrl.clear();
    _formVersionCodeCtrl.clear();
    _formVersionType = 'patch';
    _formChannels = _channels.isNotEmpty ? [_channels.first.id] : [];
    _formTitleCtrl.clear();
    _formNotesCtrl.clear();
    _formUrlCtrl.clear();
    _formFileSizeCtrl.clear();
    _formFileHashCtrl.clear();
    _formOsCtrl.clear();
    _formArchCtrl.clear();
    _formAssets = [];
  }

  void _openCreate() {
    _editingVersion = null;
    _resetForm();
    setState(() => _showDialog = true);
  }

  void _openEdit(Version v) {
    _editingVersion = v;
    _formVersionCtrl.text = v.version;
    _formVersionCodeCtrl.text = v.versionCode.toString();
    _formVersionType = v.versionType;
    _formChannels = v.channel != null ? [v.channel!] : [];
    _formTitleCtrl.text = v.title;
    _formNotesCtrl.text = v.releaseNotes;
    _formUrlCtrl.text = v.directDownloadUrl;
    _formFileSizeCtrl.text = v.fileSize.toString();
    _formFileHashCtrl.text = v.fileHash;
    _formOsCtrl.text = v.targetOs;
    _formArchCtrl.text = v.targetArch;
    _formAssets = v.assets.map((a) => {
      'os': a.os, 'arch': a.arch, 'download_url': a.downloadUrl, 'file_size': a.fileSize.toString(),
    }).toList();
    setState(() => _showDialog = true);
  }

  Future<void> _submit() async {
    setState(() => _submitting = true);
    try {
      final data = {
        'software': widget.softwareId,
        'version': _formVersionCtrl.text,
        'version_code': int.tryParse(_formVersionCodeCtrl.text) ?? 0,
        'version_type': _formVersionType,
        'channels': _formChannels,
        'title': _formTitleCtrl.text,
        'release_notes': _formNotesCtrl.text,
        'direct_download_url': _formUrlCtrl.text,
        'file_size': int.tryParse(_formFileSizeCtrl.text) ?? 0,
        'file_hash': _formFileHashCtrl.text,
        'target_os': _formOsCtrl.text,
        'target_arch': _formArchCtrl.text,
        'assets': _formAssets,
      };
      final api = context.read<AuthProvider>().apiService;
      if (_editingVersion != null) {
        await api.updateVersion(_editingVersion!.id, data);
      } else {
        await api.createVersion(data);
      }
      setState(() => _showDialog = false);
      _loadData();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('保存失败: $e')));
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Future<void> _publish(String id) async {
    try {
      await context.read<AuthProvider>().apiService.publishVersion(id);
      _loadData();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('发布失败: $e')));
    }
  }

  Future<void> _deprecate(String id) async {
    final confirm = await showDialog<bool>(context: context, builder: (ctx) => AlertDialog(
      title: const Text('确认'), content: const Text('确定要废弃这个版本吗？'),
      actions: [TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('取消')),
        TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('确认'))],
    ));
    if (confirm != true) return;
    try {
      await context.read<AuthProvider>().apiService.deprecateVersion(id);
      _loadData();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('废弃失败: $e')));
    }
  }

  Future<void> _delete(String id) async {
    final confirm = await showDialog<bool>(context: context, builder: (ctx) => AlertDialog(
      title: const Text('确认'), content: const Text('确定要删除这个版本吗？'),
      actions: [TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('取消')),
        TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('删除', style: TextStyle(color: Colors.red)))],
    ));
    if (confirm != true) return;
    try {
      await context.read<AuthProvider>().apiService.deleteVersion(id);
      _loadData();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('删除失败: $e')));
    }
  }

  Future<void> _setGray() async {
    if (_grayVersion == null) return;
    try {
      await context.read<AuthProvider>().apiService.setGrayVersion(_grayVersion!.id, _grayPercentage.round());
      setState(() => _showGrayDialog = false);
      _loadData();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('设置灰度失败: $e')));
    }
  }

  void _addAsset() {
    setState(() => _formAssets.add({'os': '', 'arch': '', 'download_url': '', 'file_size': '0'}));
  }

  void _removeAsset(int i) {
    setState(() => _formAssets.removeAt(i));
  }

  // ---- Storage selector ----
  void _openStorageSelector([int assetIndex = -1]) {
    _activeAssetIndex = assetIndex;
    setState(() {
      _showStorageSelector = true;
      _selectedStorageId = null;
      _storageFiles = [];
      _storagePath = '';
      _selectedStorageFile = null;
    });
  }

  Future<void> _loadStorageFiles() async {
    if (_selectedStorageId == null) return;
    setState(() => _loadingStorageFiles = true);
    try {
      final api = context.read<AuthProvider>().apiService;
      _storageFiles = await api.getStorageFiles(_selectedStorageId!, prefix: _storagePath);
    } catch (_) {}
    if (mounted) setState(() => _loadingStorageFiles = false);
  }

  void _closeStorageSelector() {
    setState(() {
      _showStorageSelector = false;
      _selectedStorageId = null;
      _storageFiles = [];
      _storagePath = '';
      _selectedStorageFile = null;
    });
  }

  Future<void> _confirmStorageFile() async {
    if (_selectedStorageFile == null || _selectedStorageId == null) return;
    try {
      final api = context.read<AuthProvider>().apiService;
      final url = await api.generateStorageUrl(_selectedStorageId!, _selectedStorageFile!.key, 'direct');
      if (_activeAssetIndex >= 0) {
        setState(() {
          _formAssets[_activeAssetIndex]['download_url'] = url;
          _formAssets[_activeAssetIndex]['file_size'] = _selectedStorageFile!.size.toString();
        });
      } else {
        _formUrlCtrl.text = url;
        _formFileSizeCtrl.text = _selectedStorageFile!.size.toString();
      }
      _closeStorageSelector();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('生成链接失败: $e')));
    }
  }

  // ---- GitHub Release selector ----
  void _openGithubSelector([int assetIndex = -1]) {
    _activeAssetIndex = assetIndex;
    setState(() {
      _showGithubSelector = true;
      _selectedGithubRepo = null;
      _githubReleases = [];
      _selectedGithubRelease = null;
      _selectedGithubAsset = null;
    });
  }

  Future<void> _onGithubRepoChanged() async {
    setState(() {
      _githubReleases = [];
      _selectedGithubRelease = null;
      _selectedGithubAsset = null;
    });
    if (_selectedGithubRepo == null || _selectedGithubRepo!.isEmpty) return;
    try {
      final api = context.read<AuthProvider>().apiService;
      _githubReleases = await api.getGithubReleases(_selectedGithubRepo!);
      if (mounted) setState(() {});
    } catch (_) {}
  }

  void _closeGithubSelector() {
    setState(() {
      _showGithubSelector = false;
      _selectedGithubRepo = null;
      _githubReleases = [];
      _selectedGithubRelease = null;
      _selectedGithubAsset = null;
    });
  }

  void _confirmGithubAsset() {
    if (_selectedGithubAsset == null) return;
    final url = _selectedGithubAsset!['browser_download_url'] as String? ?? '';
    final size = _selectedGithubAsset!['size'] as int? ?? 0;
    if (_activeAssetIndex >= 0) {
      setState(() {
        _formAssets[_activeAssetIndex]['download_url'] = url;
        if (size > 0) _formAssets[_activeAssetIndex]['file_size'] = size.toString();
      });
    } else {
      _formUrlCtrl.text = url;
      if (size > 0) _formFileSizeCtrl.text = size.toString();
      if (_selectedGithubRelease != null) {
      final tag = _selectedGithubRelease!['tag_name'] as String? ?? '';
      final title = _selectedGithubRelease!['name'] as String? ?? '';
      final body = _selectedGithubRelease!['body'] as String? ?? '';
      if (_formVersionCtrl.text.isEmpty) {
        _formVersionCtrl.text = tag.startsWith('v') ? tag.substring(1) : tag;
      }
      if (_formTitleCtrl.text.isEmpty && title.isNotEmpty) {
        _formTitleCtrl.text = title;
      }
      if (_formNotesCtrl.text.isEmpty && body.isNotEmpty) {
        _formNotesCtrl.text = body;
      }
    }
    _closeGithubSelector();
  }
  }

  String _statusLabel(String s) {
    const map = {'draft': '草稿', 'testing': '测试中', 'released': '已发布', 'deprecated': '已废弃'};
    return map[s] ?? s;
  }

  Color _statusColor(String s) {
    switch (s) {
      case 'released': return Colors.green;
      case 'draft': return Colors.orange;
      case 'testing': return Colors.blue;
      case 'deprecated': return Colors.red;
      default: return Colors.grey;
    }
  }

  String _versionTypeLabel(String t) {
    const map = {'major': '主版本', 'minor': '次版本', 'patch': '补丁'};
    return map[t] ?? t;
  }

  String _formatFileSize(int bytes) {
    if (bytes == 0) return '0 B';
    const units = ['B', 'KB', 'MB', 'GB'];
    final i = (bytes.bitLength / 10).floor();
    return '${(bytes / (1 << (i * 10))).toStringAsFixed(1)} ${units[i]}';
  }

  String _formatDate(String d) {
    try { return DateTime.parse(d).toLocal().toString().substring(0, 16); } catch (_) { return d; }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Stack(children: [Scaffold(
      appBar: AppBar(
        title: Text('${_software?.name ?? ''} - 版本管理'),
        actions: [
          FilledButton.tonalIcon(
            onPressed: _openCreate,
            icon: const Icon(Icons.add, size: 18),
            label: const Text('发布新版本'),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _versions.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.tag, size: 48, color: Colors.grey.shade300),
                      const SizedBox(height: 12),
                      Text('还没有版本，点击上方按钮发布', style: TextStyle(color: Colors.grey.shade500)),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _versions.length,
                  itemBuilder: (_, i) {
                    final v = _versions[i];
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
                                  width: 36, height: 36,
                                  decoration: BoxDecoration(
                                    color: v.versionType == 'major' ? Colors.red.shade50 : v.versionType == 'minor' ? Colors.blue.shade50 : Colors.green.shade50,
                                    borderRadius: BorderRadius.circular(18),
                                  ),
                                  child: Icon(Icons.tag, size: 18,
                                      color: v.versionType == 'major' ? Colors.red : v.versionType == 'minor' ? Colors.blue : Colors.green),
                                ),
                                const SizedBox(width: 12),
                                Text('v${v.version}', style: theme.textTheme.titleMedium),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: _statusColor(v.status).withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(_statusLabel(v.status), style: TextStyle(fontSize: 11, color: _statusColor(v.status))),
                                ),
                                if (v.channelName != null) ...[
                                  const SizedBox(width: 6),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(4)),
                                    child: Text(v.channelName!, style: const TextStyle(fontSize: 11)),
                                  ),
                                ],
                                if (v.isAbTest)
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(color: Colors.purple.shade50, borderRadius: BorderRadius.circular(4)),
                                    child: const Text('AB测试', style: TextStyle(fontSize: 11, color: Colors.purple)),
                                  ),
                                const Spacer(),
                                if (v.status == 'draft')
                                  FilledButton.icon(
                                    onPressed: () => _publish(v.id),
                                    icon: const Icon(Icons.rocket_launch, size: 16),
                                    label: const Text('发布'),
                                    style: FilledButton.styleFrom(visualDensity: VisualDensity.compact),
                                  ),
                                if (v.status == 'released')
                                  OutlinedButton.icon(
                                    onPressed: () {
                                      _grayVersion = v;
                                      _grayPercentage = v.grayPercentage.toDouble();
                                      setState(() => _showGrayDialog = true);
                                    },
                                    icon: const Icon(Icons.percent, size: 16),
                                    label: const Text('灰度'),
                                    style: OutlinedButton.styleFrom(visualDensity: VisualDensity.compact),
                                  ),
                                const SizedBox(width: 8),
                                PopupMenuButton<String>(
                                  onSelected: (action) {
                                    if (action == 'edit') _openEdit(v);
                                    if (action == 'deprecate' && v.status == 'released') _deprecate(v.id);
                                    if (action == 'delete') _delete(v.id);
                                  },
                                  itemBuilder: (_) => [
                                    const PopupMenuItem(value: 'edit', child: Text('编辑')),
                                    if (v.status == 'released')
                                      const PopupMenuItem(value: 'deprecate', child: Text('废弃')),
                                    const PopupMenuItem(value: 'delete', child: Text('删除', style: TextStyle(color: Colors.red))),
                                  ],
                                ),
                              ],
                            ),
                            if (v.title.isNotEmpty) ...[
                              const SizedBox(height: 8),
                              Text(v.title, style: TextStyle(color: Colors.grey.shade600)),
                            ],
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                const Icon(Icons.download, size: 14),
                                const SizedBox(width: 4),
                                Text('${v.downloadCount} 次下载', style: const TextStyle(fontSize: 12)),
                                if (v.fileSize > 0) ...[
                                  const SizedBox(width: 16),
                                  Text(_formatFileSize(v.fileSize), style: const TextStyle(fontSize: 12)),
                                ],
                                const SizedBox(width: 16),
                                Text(_formatDate(v.createdAt), style: const TextStyle(fontSize: 12)),
                              ],
                            ),
                            if (v.directDownloadUrl.isNotEmpty) ...[
                              const SizedBox(height: 8),
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(4)),
                                child: Text(v.directDownloadUrl, style: const TextStyle(fontFamily: 'monospace', fontSize: 11), maxLines: 1, overflow: TextOverflow.ellipsis),
                              ),
                            ],
                            if (v.assets.isNotEmpty) ...[
                              const SizedBox(height: 8),
                              ...v.assets.map((a) => Padding(
                                padding: const EdgeInsets.only(bottom: 4),
                                child: Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                                      decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(3)),
                                      child: Text('${a.os}/${a.arch}', style: const TextStyle(fontSize: 10)),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(a.downloadUrl, style: const TextStyle(fontFamily: 'monospace', fontSize: 10), maxLines: 1, overflow: TextOverflow.ellipsis),
                                    ),
                                  ],
                                ),
                              )),
                            ],
                          ],
                        ),
                      ),
                    );
                  },
                ),
      ),
      _buildDialogOverlay(),
      _buildGrayDialog(),
      _buildStorageSelector(),
      _buildGithubSelector(),
    ]);
  }

  Widget _buildDialogOverlay() {
    if (!_showDialog) return const SizedBox.shrink();
    final theme = Theme.of(context);
    return Material(
      color: Colors.black26,
      child: Center(
        child: Dialog(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560, maxHeight: 600),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(_editingVersion != null ? '编辑版本' : '发布新版本', style: theme.textTheme.titleLarge),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _formVersionCtrl,
                        decoration: const InputDecoration(labelText: '版本号 *', border: OutlineInputBorder(), hintText: '1.0.0'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: _formVersionCodeCtrl,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: '版本代码 *', border: OutlineInputBorder(), hintText: '100'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: ['major', 'minor', 'patch'].map((t) {
                    final selected = _formVersionType == t;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: Text(_versionTypeLabel(t)),
                        selected: selected,
                        onSelected: (_) => setState(() => _formVersionType = t),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 12),
                Text('发布渠道 *', style: const TextStyle(fontWeight: FontWeight.w500)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: _channels.map((c) => FilterChip(
                    label: Text('${c.name} (${c.channelType})'),
                    selected: _formChannels.contains(c.id),
                    onSelected: (v) {
                      setState(() {
                        if (v) { _formChannels.add(c.id); } else { _formChannels.remove(c.id); }
                      });
                    },
                  )).toList(),
                ),
                if (_channels.isEmpty)
                  Text('请先创建渠道', style: TextStyle(color: Colors.red.shade400, fontSize: 12)),
                const SizedBox(height: 12),
                TextField(
                  controller: _formTitleCtrl,
                  decoration: const InputDecoration(labelText: '发布标题 *', border: OutlineInputBorder(), hintText: 'v1.0.0 正式发布'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _formNotesCtrl,
                  maxLines: 4,
                  decoration: const InputDecoration(labelText: '更新日志', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _formOsCtrl,
                        decoration: const InputDecoration(labelText: '目标操作系统', border: OutlineInputBorder(), hintText: 'win10, linux'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: _formArchCtrl,
                        decoration: const InputDecoration(labelText: '目标架构', border: OutlineInputBorder(), hintText: 'x64, arm64'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Divider(),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _formUrlCtrl,
                        decoration: const InputDecoration(labelText: '下载链接 *', border: OutlineInputBorder()),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    OutlinedButton.icon(
                      onPressed: () => _openStorageSelector(),
                      icon: const Icon(Icons.storage, size: 16),
                      label: const Text('从存储选择'),
                    ),
                    const SizedBox(width: 8),
                    OutlinedButton.icon(
                      onPressed: () => _openGithubSelector(),
                      icon: const Icon(Icons.code, size: 16),
                      label: const Text('GitHub Release'),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _formFileSizeCtrl,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: '文件大小 (字节)', border: OutlineInputBorder()),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: _formFileHashCtrl,
                        decoration: const InputDecoration(labelText: 'SHA256（可选）', border: OutlineInputBorder()),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Divider(),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('平台资源', style: TextStyle(fontWeight: FontWeight.w600)),
                    TextButton.icon(
                      onPressed: _addAsset,
                      icon: const Icon(Icons.add, size: 16),
                      label: const Text('添加资源'),
                    ),
                  ],
                ),
                ..._formAssets.asMap().entries.map((entry) {
                  final i = entry.key;
                  final asset = entry.value;
                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade200), borderRadius: BorderRadius.circular(8)),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Text('资源 #${i + 1}', style: const TextStyle(fontWeight: FontWeight.w500)),
                            const Spacer(),
                            IconButton(
                              icon: Icon(Icons.delete, size: 16, color: Colors.red.shade400),
                              onPressed: () => _removeAsset(i),
                            ),
                          ],
                        ),
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                decoration: const InputDecoration(labelText: 'OS', border: OutlineInputBorder(), isDense: true),
                                controller: TextEditingController(text: asset['os']),
                                onChanged: (v) => setState(() => _formAssets[i]['os'] = v),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: TextField(
                                decoration: const InputDecoration(labelText: 'Arch', border: OutlineInputBorder(), isDense: true),
                                controller: TextEditingController(text: asset['arch']),
                                onChanged: (v) => setState(() => _formAssets[i]['arch'] = v),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                decoration: const InputDecoration(labelText: '下载链接', border: OutlineInputBorder(), isDense: true),
                                controller: TextEditingController(text: asset['download_url']),
                                onChanged: (v) => setState(() => _formAssets[i]['download_url'] = v),
                              ),
                            ),
                            const SizedBox(width: 4),
                            IconButton(
                              icon: Icon(Icons.storage, size: 16, color: Colors.grey.shade600),
                              onPressed: () => _openStorageSelector(i),
                              tooltip: '从存储选择',
                              visualDensity: VisualDensity.compact,
                            ),
                            IconButton(
                              icon: Icon(Icons.code, size: 16, color: Colors.grey.shade600),
                              onPressed: () => _openGithubSelector(i),
                              tooltip: 'GitHub Release',
                              visualDensity: VisualDensity.compact,
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                }),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    OutlinedButton(onPressed: () => setState(() => _showDialog = false), child: const Text('取消')),
                    const SizedBox(width: 12),
                    FilledButton(
                      onPressed: _submitting ? null : _submit,
                      child: _submitting
                          ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                          : Text(_editingVersion != null ? '保存' : '创建'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    ),
    ),
    );
  }

  Widget _buildGrayDialog() {
    if (!_showGrayDialog) return const SizedBox.shrink();
    return Dialog(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('灰度发布配置'),
            const SizedBox(height: 20),
            Text('灰度百分比: ${_grayPercentage.round()}%'),
            Slider(
              value: _grayPercentage,
              min: 0,
              max: 100,
              divisions: 100,
              label: '${_grayPercentage.round()}%',
              onChanged: (v) => setState(() => _grayPercentage = v),
            ),
            Text(
              _grayPercentage == 0 ? '不发布' : _grayPercentage == 100 ? '全量发布' : '仅 ${_grayPercentage.round()}% 的用户会收到更新',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                OutlinedButton(onPressed: () => setState(() => _showGrayDialog = false), child: const Text('取消')),
                const SizedBox(width: 12),
                FilledButton(onPressed: _setGray, child: const Text('保存')),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStorageSelector() {
    if (!_showStorageSelector) return const SizedBox.shrink();
    return Material(
      color: Colors.black26,
      child: Center(
        child: Dialog(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 500, maxHeight: 500),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('从存储选择文件', style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: _selectedStorageId,
                    decoration: const InputDecoration(labelText: '选择存储', border: OutlineInputBorder()),
                    items: _storages.map((s) => DropdownMenuItem(value: s.id, child: Text(s.name))).toList(),
                    onChanged: (v) {
                      setState(() => _selectedStorageId = v);
                      _loadStorageFiles();
                    },
                  ),
                  const SizedBox(height: 12),
                  if (_selectedStorageId != null)
                    Expanded(
                      child: _loadingStorageFiles
                          ? const Center(child: CircularProgressIndicator())
                          : _storageFiles.isEmpty
                              ? Center(child: Text('当前目录为空', style: TextStyle(color: Colors.grey.shade500)))
                              : ListView.builder(
                                  itemCount: _storageFiles.length,
                                  itemBuilder: (_, i) {
                                    final file = _storageFiles[i];
                                    final selected = _selectedStorageFile?.key == file.key;
                                    return ListTile(
                                      dense: true,
                                      selected: selected,
                                      leading: Icon(file.isDirectory ? Icons.folder : Icons.insert_drive_file, size: 18),
                                      title: Text(file.name, style: const TextStyle(fontSize: 14)),
                                      trailing: file.isDirectory ? null : Text(file.sizeFormatted, style: const TextStyle(fontSize: 12)),
                                      onTap: () {
                                        if (file.isDirectory) {
                                          _storagePath = file.path;
                                          _loadStorageFiles();
                                        } else {
                                          setState(() => _selectedStorageFile = file);
                                        }
                                      },
                                    );
                                  },
                                ),
                    ),
                  const SizedBox(height: 16),
                  Row(mainAxisAlignment: MainAxisAlignment.end, children: [
                    OutlinedButton(onPressed: _closeStorageSelector, child: const Text('取消')),
                    const SizedBox(width: 12),
                    FilledButton(
                      onPressed: _selectedStorageFile != null ? _confirmStorageFile : null,
                      child: const Text('确认选择'),
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

  Widget _buildGithubSelector() {
    if (!_showGithubSelector) return const SizedBox.shrink();
    return Material(
      color: Colors.black26,
      child: Center(
        child: Dialog(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 500, maxHeight: 500),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('选择 GitHub Release', style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 16),
                  if (_githubAccount == null)
                    Center(
                      child: Column(
                        children: [
                          Icon(Icons.code, size: 48, color: Colors.grey.shade300),
                          const SizedBox(height: 8),
                          Text('请先在设置中绑定 GitHub 账号', style: TextStyle(color: Colors.grey.shade500)),
                          const SizedBox(height: 12),
                          OutlinedButton(
                            onPressed: () {
                              _closeGithubSelector();
                              context.go('/dashboard/settings');
                            },
                            child: const Text('前往设置'),
                          ),
                        ],
                      ),
                    )
                  else ...[
                    DropdownButtonFormField<String>(
                      value: _selectedGithubRepo,
                      decoration: const InputDecoration(labelText: '选择仓库', border: OutlineInputBorder()),
                      items: _githubRepos.map((r) => DropdownMenuItem(value: r['full_name'] as String?, child: Text(r['name'] as String? ?? ''))).toList(),
                      onChanged: (v) {
                        setState(() => _selectedGithubRepo = v);
                        _onGithubRepoChanged();
                      },
                    ),
                    if (_selectedGithubRepo != null) ...[
                      const SizedBox(height: 12),
                      Expanded(
                        child: _githubReleases.isEmpty
                            ? Center(child: Text('暂无 Release', style: TextStyle(color: Colors.grey.shade500)))
                            : ListView.builder(
                                itemCount: _githubReleases.length,
                                itemBuilder: (_, i) {
                                  final release = _githubReleases[i];
                                  final tag = release['tag_name'] as String? ?? '';
                                  final name = release['name'] as String? ?? '';
                                  final assets = release['assets'] as List? ?? [];
                                  final selected = _selectedGithubRelease == release;
                                  return Card(
                                    margin: const EdgeInsets.only(bottom: 4),
                                    color: selected ? Theme.of(context).colorScheme.primaryContainer : null,
                                    child: InkWell(
                                      onTap: () => setState(() {
                                        _selectedGithubRelease = release;
                                        _selectedGithubAsset = null;
                                      }),
                                      child: Padding(
                                        padding: const EdgeInsets.all(12),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(tag, style: const TextStyle(fontWeight: FontWeight.w600)),
                                            if (name.isNotEmpty) Text(name, style: const TextStyle(fontSize: 13)),
                                            Text('${assets.length} 个附件', style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
                                          ],
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                      ),
                    ],
                    if (_selectedGithubRelease != null) ...[
                      const SizedBox(height: 8),
                      const Text('选择附件', style: TextStyle(fontWeight: FontWeight.w500)),
                      const SizedBox(height: 4),
                      ...(_selectedGithubRelease!['assets'] as List? ?? []).map<Widget>((asset) {
                        final a = asset as Map<String, dynamic>;
                        final assetName = a['name'] as String? ?? '';
                        final assetSize = a['size'] as int? ?? 0;
                        final selected = _selectedGithubAsset == a;
                        return ListTile(
                          dense: true,
                          selected: selected,
                          title: Text(assetName, style: const TextStyle(fontSize: 13)),
                          trailing: Text(_formatFileSize(assetSize), style: const TextStyle(fontSize: 12)),
                          onTap: () => setState(() => _selectedGithubAsset = a),
                        );
                      }),
                    ],
                  ],
                  const SizedBox(height: 16),
                  Row(mainAxisAlignment: MainAxisAlignment.end, children: [
                    OutlinedButton(onPressed: _closeGithubSelector, child: const Text('取消')),
                    const SizedBox(width: 12),
                    FilledButton(
                      onPressed: _selectedGithubAsset != null ? _confirmGithubAsset : null,
                      child: const Text('确认选择'),
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
