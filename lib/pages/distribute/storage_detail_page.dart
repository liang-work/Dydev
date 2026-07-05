import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../models/storage_backend.dart';
import '../../models/storage_file.dart';
import '../../providers/auth_provider.dart';
import '../../services/logger_service.dart';

class StorageDetailPage extends StatefulWidget {
  final String storageId;
  const StorageDetailPage({super.key, required this.storageId});

  @override
  State<StorageDetailPage> createState() => _StorageDetailPageState();
}

class _StorageDetailPageState extends State<StorageDetailPage> {
  StorageBackend? _storage;
  List<StorageFile> _files = [];
  String _currentPath = '';
  bool _loadingStorage = true;
  bool _loadingFiles = false;

  // Dialogs
  bool _showEditDialog = false;
  bool _submitting = false;
  final _editNameCtrl = TextEditingController();
  String _editLinkType = 'direct';
  final _editCdnCtrl = TextEditingController();

  // Upload
  bool _showUploadDialog = false;
  String? _selectedFilePath;
  String? _selectedFileName;
  final _uploadNameCtrl = TextEditingController();
  bool _uploading = false;
  double _uploadProgress = 0;

  // Create folder
  bool _showFolderDialog = false;
  final _folderNameCtrl = TextEditingController();
  bool _creatingFolder = false;

  // Rename
  bool _showRenameDialog = false;
  StorageFile? _renameFile;
  final _renameCtrl = TextEditingController();
  bool _renaming = false;

  // Generate URL
  bool _showUrlDialog = false;
  StorageFile? _urlFile;
  String _urlLinkType = 'direct';
  String? _generatedUrl;
  bool _generatingUrl = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _editNameCtrl.dispose();
    _editCdnCtrl.dispose();
    _uploadNameCtrl.dispose();
    _folderNameCtrl.dispose();
    _renameCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    await Future.wait([_loadStorage(), _loadFiles()]);
  }

  Future<void> _loadStorage() async {
    setState(() => _loadingStorage = true);
    try {
      final api = context.read<AuthProvider>().apiService;
      _storage = await api.getStorage(widget.storageId);
      _editNameCtrl.text = _storage!.name;
      _editLinkType = _storage!.defaultLinkType;
      _editCdnCtrl.text = _storage!.cdnDomain ?? '';
    } catch (e, s) {
      LoggerService.e('_StorageDetailPageState', 'load storage', e, s);
    }
    if (mounted) setState(() => _loadingStorage = false);
  }

  Future<void> _loadFiles() async {
    setState(() => _loadingFiles = true);
    try {
      final api = context.read<AuthProvider>().apiService;
      _files = await api.getStorageFiles(widget.storageId, prefix: _currentPath);
    } catch (e, s) {
      LoggerService.e('_StorageDetailPageState', 'load files', e, s);
    }
    if (mounted) setState(() => _loadingFiles = false);
  }

  void _enterDir(String path) {
    setState(() => _currentPath = path);
    _loadFiles();
  }

  void _goUp() {
    final parts = _currentPath.split('/').where((p) => p.isNotEmpty).toList();
    if (parts.isNotEmpty) parts.removeLast();
    setState(() => _currentPath = parts.join('/'));
    _loadFiles();
  }

  Future<void> _saveStorage() async {
    setState(() => _submitting = true);
    try {
      final api = context.read<AuthProvider>().apiService;
      await api.updateStorage(widget.storageId, {
        'name': _editNameCtrl.text,
        'default_link_type': _editLinkType,
        'cdn_domain': _editCdnCtrl.text,
      });
      setState(() => _showEditDialog = false);
      _loadStorage();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('保存失败: $e')));
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  String _formatDate(String d) {
    try {
      return DateTime.parse(d).toLocal().toString().substring(0, 19);
    } catch (_) {
      return d;
    }
  }

  Color _typeColor(ColorScheme cs, String type) {
    switch (type) {
      case 's3': return cs.secondary;
      case 'webdav': return cs.primary;
      case 'direct': return cs.tertiary;
      default: return cs.onSurfaceVariant;
    }
  }

  IconData _typeIcon(String type) {
    switch (type) {
      case 's3': return Icons.cloud;
      case 'webdav': return Icons.dns;
      default: return Icons.link;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    return Stack(children: [Scaffold(
      appBar: AppBar(
        leading: Navigator.of(context).canPop()
            ? IconButton(icon: Icon(Icons.arrow_back), onPressed: () => context.pop())
            : null,
        title: Text(_storage?.name ?? '存储详情'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            tooltip: '编辑',
            onPressed: () {
              _editNameCtrl.text = _storage?.name ?? '';
              _editLinkType = _storage?.defaultLinkType ?? 'direct';
              _editCdnCtrl.text = _storage?.cdnDomain ?? '';
              setState(() => _showEditDialog = true);
            },
          ),
          IconButton(
            icon: const Icon(Icons.upload),
            tooltip: '上传文件',
            onPressed: () {
              _selectedFilePath = null;
              _selectedFileName = null;
              _uploadNameCtrl.clear();
              _uploadProgress = 0;
              setState(() => _showUploadDialog = true);
            },
          ),
        ],
      ),
      body: _loadingStorage
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Storage info header
                Container(
                  padding: const EdgeInsets.all(16),
                  color: cs.surfaceContainerLow,
                  child: Row(
                    children: [
                      Container(
                        width: 48, height: 48,
                        decoration: BoxDecoration(
                          color: _typeColor(cs, _storage!.storageType).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(_typeIcon(_storage!.storageType), color: _typeColor(cs, _storage!.storageType)),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(_storage!.name, style: theme.textTheme.titleMedium),
                            Text(_storage!.storageType == 's3' ? 'S3 - ${_storage!.s3Bucket}' : _storage!.storageType == 'webdav' ? 'WebDAV 存储' : '直接链接模式',
                                style: TextStyle(color: cs.onSurfaceVariant, fontSize: 13)),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: _storage!.isActive ? cs.tertiaryContainer : cs.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(_storage!.isActive ? '已启用' : '已禁用', style: TextStyle(fontSize: 12, color: _storage!.isActive ? cs.tertiary : cs.onSurfaceVariant)),
                      ),
                    ],
                  ),
                ),
                // File browser toolbar
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    children: [
                      if (_currentPath.isNotEmpty)
                        IconButton(
                          icon: const Icon(Icons.arrow_upward),
                          tooltip: '上级目录',
                          onPressed: _goUp,
                        ),
                      Expanded(
                        child: Text('路径: /${_currentPath}', style: TextStyle(color: cs.onSurfaceVariant, fontSize: 13)),
                      ),
                      IconButton(
                        icon: const Icon(Icons.refresh),
                        onPressed: _loadFiles,
                      ),
                    ],
                  ),
                ),
                // File list
                Expanded(
                  child: _loadingFiles
                      ? const Center(child: CircularProgressIndicator())
                      : _files.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.folder_open, size: 48, color: cs.surfaceContainerHigh),
                                  const SizedBox(height: 12),
                                  Text('当前目录为空', style: TextStyle(color: cs.onSurfaceVariant)),
                                ],
                              ),
                            )
                          : ListView.builder(
                              itemCount: _files.length,
                              itemBuilder: (_, i) {
                                final f = _files[i];
                                return ListTile(
                                  leading: Icon(f.isDirectory ? Icons.folder : Icons.insert_drive_file,
                                      color: f.isDirectory ? cs.primary : cs.onSurfaceVariant),
                                  title: Text(f.isDirectory ? f.name : f.name, style: const TextStyle(fontSize: 14)),
                                  subtitle: Row(
                                    children: [
                                      if (f.sizeFormatted.isNotEmpty) Text('${f.sizeFormatted}  '),
                                      if (f.lastModified.isNotEmpty) Text(_formatDate(f.lastModified)),
                                    ].map((w) => DefaultTextStyle(style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant), child: w)).toList(),
                                  ),
                                  onTap: f.isDirectory ? () => _enterDir(f.path) : null,
                                  trailing: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton(
                                        icon: const Icon(Icons.drive_file_rename_outline, size: 18),
                                        tooltip: '重命名',
                                        onPressed: () {
                                          _renameFile = f;
                                          _renameCtrl.text = f.name;
                                          setState(() => _showRenameDialog = true);
                                        },
                                      ),
                                      if (!f.isDirectory) ...[
                                        IconButton(
                                          icon: const Icon(Icons.link, size: 18),
                                          tooltip: '复制链接',
                                          onPressed: () async {
                                            try {
                                              final api = context.read<AuthProvider>().apiService;
                                              final url = await api.generateStorageUrl(
                                                  widget.storageId, f.key, _storage?.defaultLinkType ?? 'direct');
                                              await Clipboard.setData(ClipboardData(text: url));
                                              if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('链接已复制')));
                                            } catch (e) {
                                              if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('生成链接失败: $e')));
                                            }
                                          },
                                        ),
                                        IconButton(
                                          icon: const Icon(Icons.publish, size: 18),
                                          tooltip: '用于发版',
                                          onPressed: () {
                                            _urlFile = f;
                                            _urlLinkType = _storage?.defaultLinkType ?? 'direct';
                                            _generatedUrl = null;
                                            setState(() => _showUrlDialog = true);
                                          },
                                        ),
                                      ],
                                      IconButton(
                                        icon: Icon(Icons.delete, size: 18, color: cs.error),
                                        tooltip: '删除',
                                        onPressed: () async {
                                          final confirm = await showDialog<bool>(
                                            context: context,
                                            builder: (ctx) => AlertDialog(
                                              title: const Text('确认删除'),
                                              content: Text(f.isDirectory ? '确定要删除文件夹 "${f.name}" 及其所有内容吗？此操作不可恢复！' : '确定要删除 ${f.name} 吗？'),
                                              actions: [
                                                TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('取消')),
                                                TextButton(onPressed: () => Navigator.pop(ctx, true), child: Text('删除', style: TextStyle(color: Theme.of(ctx).colorScheme.error))),
                                              ],
                                            ),
                                          );
                                          if (confirm != true) return;
                                          try {
                                            final api = context.read<AuthProvider>().apiService;
                                            await api.deleteStorageFile(widget.storageId, f.key);
                                            _loadFiles();
                                          } catch (e) {
                                            if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('删除失败: $e')));
                                          }
                                        },
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                ),
              ],
            ),
      ),
      _buildEditDialog(),
      _buildUploadDialog(),
      _buildFolderDialog(),
      _buildRenameDialog(),
      _buildUrlDialog(),
    ]);
  }

  Widget _buildEditDialog() {
    if (!_showEditDialog) return const SizedBox.shrink();
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    return Material(
      color: cs.scrim.withValues(alpha: 0.26),
      child: Center(
        child: Dialog(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('编辑存储', style: theme.textTheme.titleLarge),
            const SizedBox(height: 20),
            TextField(
              controller: _editNameCtrl,
              decoration: const InputDecoration(labelText: '存储名称', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _editLinkType,
              decoration: const InputDecoration(labelText: '默认链接类型', border: OutlineInputBorder()),
              items: const [
                DropdownMenuItem(value: 'direct', child: Text('直接链接（带签名）')),
                DropdownMenuItem(value: 'unsigned', child: Text('直接链接（无签名）')),
                DropdownMenuItem(value: 'proxy', child: Text('平台代理')),
                DropdownMenuItem(value: 'cdn', child: Text('CDN 加速')),
              ],
              onChanged: (v) => setState(() => _editLinkType = v ?? 'direct'),
            ),
            if (_editLinkType == 'cdn') ...[
              const SizedBox(height: 12),
              TextField(
                controller: _editCdnCtrl,
                decoration: const InputDecoration(labelText: 'CDN 域名', border: OutlineInputBorder(), hintText: 'cdn.example.com'),
              ),
            ],
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                OutlinedButton(onPressed: () => setState(() => _showEditDialog = false), child: const Text('取消')),
                const SizedBox(width: 12),
                FilledButton(
                  onPressed: _submitting ? null : _saveStorage,
                  child: _submitting
                      ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Text('保存'),
                ),
              ],
            ),
          ],
        ),
      ),
      ),
      ),
    );
  }

  Widget _buildUploadDialog() {
    if (!_showUploadDialog) return const SizedBox.shrink();
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    return Material(
      color: cs.scrim.withValues(alpha: 0.26),
      child: Center(
        child: Dialog(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('上传文件', style: theme.textTheme.titleLarge),
            const SizedBox(height: 4),
            Text('上传文件到当前目录: /$_currentPath', style: TextStyle(color: cs.onSurfaceVariant, fontSize: 13)),
            const SizedBox(height: 20),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                border: Border.all(color: cs.outlineVariant, style: BorderStyle.solid),
                borderRadius: BorderRadius.circular(8),
              ),
              child: _selectedFilePath == null
                  ? GestureDetector(
                      onTap: () async {
                        // In a real app we'd use file_picker
                      },
                      child: Column(
                        children: [
                          Icon(Icons.cloud_upload, size: 48, color: cs.onSurfaceVariant.withValues(alpha: 0.6)),
                          const SizedBox(height: 8),
                          Text('请选择文件', style: TextStyle(color: cs.onSurfaceVariant)),
                          TextButton(
                            onPressed: () {
                              // Simulate file selection
                            },
                            child: const Text('选择文件'),
                          ),
                        ],
                      ),
                    )
                  : Column(
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.insert_drive_file),
                            const SizedBox(width: 8),
                            Expanded(child: Text(_selectedFileName ?? '')),
                            IconButton(
                              icon: const Icon(Icons.close),
                              onPressed: () => setState(() { _selectedFilePath = null; _selectedFileName = null; }),
                            ),
                          ],
                        ),
                      ],
                    ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _uploadNameCtrl,
              decoration: const InputDecoration(
                labelText: '自定义文件名（可选）',
                border: OutlineInputBorder(),
                hintText: '留空使用原文件名',
              ),
            ),
            if (_uploading) ...[
              const SizedBox(height: 16),
              LinearProgressIndicator(value: _uploadProgress / 100),
              const SizedBox(height: 8),
              Text('上传中: ${_uploadProgress.toInt()}%', style: TextStyle(color: theme.colorScheme.primary)),
            ],
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                OutlinedButton(onPressed: () => setState(() => _showUploadDialog = false), child: const Text('取消')),
                const SizedBox(width: 12),
                FilledButton(
                  onPressed: _selectedFilePath == null || _uploading ? null : () {
                    // Upload implementation would go here with file_picker
                    setState(() => _uploading = true);
                    // Simulate progress
                    Future.delayed(const Duration(seconds: 2), () {
                      setState(() { _uploading = false; _showUploadDialog = false; });
                      _loadFiles();
                    });
                  },
                  child: const Text('上传'),
                ),
              ],
            ),
          ],
        ),
      ),
    ),
    ),
    );
  }

  Widget _buildFolderDialog() {
    if (!_showFolderDialog) return const SizedBox.shrink();
    return Dialog(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('新建文件夹'),
            const SizedBox(height: 20),
            TextField(
              controller: _folderNameCtrl,
              decoration: const InputDecoration(labelText: '文件夹名称', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                OutlinedButton(onPressed: () => setState(() => _showFolderDialog = false), child: const Text('取消')),
                const SizedBox(width: 12),
                FilledButton(
                  onPressed: _creatingFolder ? null : () async {
                    setState(() => _creatingFolder = true);
                    try {
                      final api = context.read<AuthProvider>().apiService;
                      await api.createFolder(widget.storageId, _currentPath, _folderNameCtrl.text);
                      setState(() { _showFolderDialog = false; _folderNameCtrl.clear(); });
                      _loadFiles();
                    } catch (e) {
                      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('创建失败: $e')));
                    } finally {
                      if (mounted) setState(() => _creatingFolder = false);
                    }
                  },
                  child: const Text('创建'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRenameDialog() {
    if (!_showRenameDialog) return const SizedBox.shrink();
    return Dialog(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('重命名'),
            const SizedBox(height: 20),
            TextField(
              controller: _renameCtrl,
              decoration: const InputDecoration(labelText: '新名称', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                OutlinedButton(onPressed: () => setState(() { _showRenameDialog = false; _renameFile = null; }), child: const Text('取消')),
                const SizedBox(width: 12),
                FilledButton(
                  onPressed: _renaming ? null : () async {
                    setState(() => _renaming = true);
                    try {
                      final api = context.read<AuthProvider>().apiService;
                      await api.renameFile(widget.storageId, _renameFile!.key, _renameCtrl.text);
                      setState(() { _showRenameDialog = false; _renameFile = null; });
                      _loadFiles();
                    } catch (e) {
                      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('重命名失败: $e')));
                    } finally {
                      if (mounted) setState(() => _renaming = false);
                    }
                  },
                  child: const Text('确认'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUrlDialog() {
    if (!_showUrlDialog) return const SizedBox.shrink();
    final cs = Theme.of(context).colorScheme;
    return Dialog(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('用于版本发布'),
            const SizedBox(height: 4),
            Text('选择链接类型并生成下载链接', style: TextStyle(color: cs.onSurfaceVariant, fontSize: 13)),
            const SizedBox(height: 20),
            if (_urlFile != null) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: cs.surfaceContainerHighest, borderRadius: BorderRadius.circular(8)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(_urlFile!.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                    Text(_urlFile!.sizeFormatted, style: TextStyle(color: cs.onSurfaceVariant, fontSize: 13)),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],
            DropdownButtonFormField<String>(
              value: _urlLinkType,
              decoration: const InputDecoration(labelText: '链接类型', border: OutlineInputBorder()),
              items: [
                const DropdownMenuItem(value: 'direct', child: Text('直接链接（带签名）')),
                const DropdownMenuItem(value: 'unsigned', child: Text('直接链接（无签名）')),
                const DropdownMenuItem(value: 'proxy', child: Text('平台代理')),
                if (_storage?.cdnDomain != null && _storage!.cdnDomain!.isNotEmpty)
                  DropdownMenuItem(value: 'cdn', child: Text('CDN 加速 (${_storage!.cdnDomain})')),
              ],
              onChanged: (v) => setState(() => _urlLinkType = v ?? 'direct'),
            ),
            if (_generatedUrl != null) ...[
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: cs.surfaceContainerHighest, borderRadius: BorderRadius.circular(8)),
                child: SelectableText(_generatedUrl!, style: const TextStyle(fontFamily: 'monospace', fontSize: 13)),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: _generatedUrl!));
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('链接已复制')));
                  },
                  icon: const Icon(Icons.copy, size: 16),
                  label: const Text('复制链接'),
                ),
              ),
            ],
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                OutlinedButton(onPressed: () => setState(() => _showUrlDialog = false), child: const Text('取消')),
                const SizedBox(width: 12),
                FilledButton(
                  onPressed: _generatingUrl ? null : () async {
                    if (_urlFile == null) return;
                    setState(() => _generatingUrl = true);
                    try {
                      final api = context.read<AuthProvider>().apiService;
final url = await api.generateStorageUrl(
    widget.storageId, _urlFile!.key, _urlLinkType, expires: 86400);
                      setState(() => _generatedUrl = url);
                    } catch (e) {
                      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('生成链接失败: $e')));
                    } finally {
                      if (mounted) setState(() => _generatingUrl = false);
                    }
                  },
                  child: const Text('生成链接'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
