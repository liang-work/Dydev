import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../models/storage_backend.dart';
import '../../providers/auth_provider.dart';
import '../../services/logger_service.dart';

class StorageListPage extends StatefulWidget {
  const StorageListPage({super.key});

  @override
  State<StorageListPage> createState() => _StorageListPageState();
}

class _StorageListPageState extends State<StorageListPage> {
  List<StorageBackend> _storages = [];
  bool _loading = true;
  bool _showDialog = false;
  StorageBackend? _editing;
  bool _submitting = false;

  // Form fields
  final _nameCtrl = TextEditingController();
  String _storageType = 's3';
  final _s3EndpointCtrl = TextEditingController();
  final _s3BucketCtrl = TextEditingController();
  final _s3RegionCtrl = TextEditingController(text: 'us-east-1');
  final _s3AccessKeyCtrl = TextEditingController();
  final _s3SecretKeyCtrl = TextEditingController();
  final _s3PathPrefixCtrl = TextEditingController();
  final _webdavUrlCtrl = TextEditingController();
  final _webdavUsernameCtrl = TextEditingController();
  final _webdavPasswordCtrl = TextEditingController();
  final _webdavPathPrefixCtrl = TextEditingController();
  String _defaultLinkType = 'direct';
  final _cdnDomainCtrl = TextEditingController();
  final _cdnPathPrefixCtrl = TextEditingController();
  bool _isActive = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _s3EndpointCtrl.dispose();
    _s3BucketCtrl.dispose();
    _s3RegionCtrl.dispose();
    _s3AccessKeyCtrl.dispose();
    _s3SecretKeyCtrl.dispose();
    _s3PathPrefixCtrl.dispose();
    _webdavUrlCtrl.dispose();
    _webdavUsernameCtrl.dispose();
    _webdavPasswordCtrl.dispose();
    _webdavPathPrefixCtrl.dispose();
    _cdnDomainCtrl.dispose();
    _cdnPathPrefixCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final api = context.read<AuthProvider>().apiService;
      _storages = await api.getStorages();
    } catch (e, s) {
      LoggerService.e('_StorageListPageState', 'load storages', e, s);
    }
    if (mounted) setState(() => _loading = false);
  }

  void _openCreate() {
    _editing = null;
    _resetForm();
    setState(() => _showDialog = true);
  }

  void _openEdit(StorageBackend s) {
    _editing = s;
    _nameCtrl.text = s.name;
    _storageType = s.storageType;
    _s3EndpointCtrl.text = s.s3Endpoint ?? '';
    _s3BucketCtrl.text = s.s3Bucket ?? '';
    _s3RegionCtrl.text = s.s3Region ?? 'us-east-1';
    _s3AccessKeyCtrl.clear();
    _s3SecretKeyCtrl.clear();
    _s3PathPrefixCtrl.text = s.s3PathPrefix ?? '';
    _webdavUrlCtrl.text = s.webdavUrl ?? '';
    _webdavUsernameCtrl.text = s.webdavUsername ?? '';
    _webdavPasswordCtrl.clear();
    _webdavPathPrefixCtrl.text = s.webdavPathPrefix ?? '';
    _defaultLinkType = s.defaultLinkType;
    _cdnDomainCtrl.text = s.cdnDomain ?? '';
    _cdnPathPrefixCtrl.text = s.cdnPathPrefix ?? '';
    _isActive = s.isActive;
    setState(() => _showDialog = true);
  }

  void _resetForm() {
    _nameCtrl.clear();
    _storageType = 's3';
    _s3EndpointCtrl.clear();
    _s3BucketCtrl.clear();
    _s3RegionCtrl.text = 'us-east-1';
    _s3AccessKeyCtrl.clear();
    _s3SecretKeyCtrl.clear();
    _s3PathPrefixCtrl.clear();
    _webdavUrlCtrl.clear();
    _webdavUsernameCtrl.clear();
    _webdavPasswordCtrl.clear();
    _webdavPathPrefixCtrl.clear();
    _defaultLinkType = 'direct';
    _cdnDomainCtrl.clear();
    _cdnPathPrefixCtrl.clear();
    _isActive = true;
  }

  Map<String, dynamic> _buildFormData() {
    return {
      'name': _nameCtrl.text,
      'storage_type': _storageType,
      's3_endpoint': _s3EndpointCtrl.text,
      's3_bucket': _s3BucketCtrl.text,
      's3_region': _s3RegionCtrl.text,
      's3_access_key': _s3AccessKeyCtrl.text,
      's3_secret_key': _s3SecretKeyCtrl.text,
      's3_path_prefix': _s3PathPrefixCtrl.text,
      'webdav_url': _webdavUrlCtrl.text,
      'webdav_username': _webdavUsernameCtrl.text,
      'webdav_password': _webdavPasswordCtrl.text,
      'webdav_path_prefix': _webdavPathPrefixCtrl.text,
      'default_link_type': _defaultLinkType,
      'cdn_domain': _cdnDomainCtrl.text,
      'cdn_path_prefix': _cdnPathPrefixCtrl.text,
      'is_active': _isActive,
    };
  }

  Future<void> _submit() async {
    setState(() => _submitting = true);
    try {
      final data = _buildFormData();
      final api = context.read<AuthProvider>().apiService;
      if (_editing != null) {
        await api.updateStorage(_editing!.id, data);
      } else {
        await api.createStorage(data);
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

  Future<void> _testConnection(StorageBackend s) async {
    try {
      final api = context.read<AuthProvider>().apiService;
      final result = await api.testStorageConnection(s.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(result['message'] as String? ?? '连接成功')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('连接失败: $e')));
      }
    }
  }

  Future<void> _delete(String id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('确认删除'),
        content: const Text('确定要删除这个存储配置吗？'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('取消')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: Text('删除', style: TextStyle(color: Theme.of(ctx).colorScheme.error))),
        ],
      ),
    );
    if (confirm != true) return;
    if (!mounted) return;
    try {
      final api = context.read<AuthProvider>().apiService;
      await api.deleteStorage(id);
      _load();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('删除失败: $e')));
      }
    }
  }

  IconData _storageIcon(String type) {
    switch (type) {
      case 's3': return Icons.cloud;
      case 'webdav': return Icons.dns;
      case 'direct': return Icons.link;
      default: return Icons.storage;
    }
  }

  Color _storageColor(ColorScheme cs, String type) {
    switch (type) {
      case 's3': return cs.secondary;
      case 'webdav': return cs.primary;
      case 'direct': return cs.tertiary;
      default: return cs.onSurfaceVariant;
    }
  }

  String _storageDesc(StorageBackend s) {
    if (s.storageType == 's3') return 'S3 兼容存储 - ${s.s3Bucket}';
    if (s.storageType == 'webdav') return 'WebDAV 存储';
    return '直接链接模式';
  }

  String _linkTypeName(String t) {
    const map = {'direct': '直接链接(签名)', 'unsigned': '直接链接(无签名)', 'proxy': '平台代理', 'cdn': 'CDN加速'};
    return map[t] ?? t;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    return Stack(
      children: [
        Scaffold(
          appBar: AppBar(
            leading: Navigator.of(context).canPop()
                ? IconButton(icon: Icon(Icons.arrow_back), onPressed: () => context.pop())
                : null,
            title: const Text('存储管理'),
            actions: [
              FilledButton.tonalIcon(
                onPressed: _openCreate,
                icon: const Icon(Icons.add, size: 18),
                label: const Text('添加存储'),
              ),
              const SizedBox(width: 8),
            ],
          ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _storages.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.storage, size: 48, color: cs.surfaceContainerHigh),
                      const SizedBox(height: 12),
                      Text('还没有存储配置，点击上方按钮添加', style: TextStyle(color: cs.onSurfaceVariant)),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _storages.length,
                  itemBuilder: (_, i) {
                    final s = _storages[i];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: InkWell(
                        onTap: () => context.push('/dashboard/storages/${s.id}'),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            children: [
                              Container(
                                width: 40, height: 40,
                                decoration: BoxDecoration(
                                    color: _storageColor(cs, s.storageType).withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(_storageIcon(s.storageType), color: _storageColor(cs, s.storageType)),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Text(s.name, style: theme.textTheme.titleSmall),
                                        const SizedBox(width: 8),
                                  Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: s.isActive ? cs.tertiaryContainer : cs.surfaceContainerHighest,
                                              borderRadius: BorderRadius.circular(4),
                                            ),
                                            child: Text(s.isActive ? '启用' : '禁用', style: TextStyle(fontSize: 11, color: s.isActive ? cs.tertiary : cs.onSurfaceVariant)),
                                        ),
                                        const SizedBox(width: 6),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: cs.surfaceContainerHighest,
                                            borderRadius: BorderRadius.circular(4),
                                          ),
                                          child: Text(_linkTypeName(s.defaultLinkType), style: const TextStyle(fontSize: 11)),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Text(_storageDesc(s), style: TextStyle(color: cs.onSurfaceVariant, fontSize: 13)),
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        if (s.storageType == 's3' && s.s3Bucket != null)
                                          Text('${s.s3Bucket} ${s.s3Endpoint != null && s.s3Endpoint!.isNotEmpty ? '@ ${s.s3Endpoint}' : '@ AWS S3'}',
                                              style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant)),
                                        if (s.storageType == 'webdav' && s.webdavUrl != null)
                                          Text(s.webdavUrl!, style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant)),
                                        if (s.cdnDomain != null && s.cdnDomain!.isNotEmpty)
                                          Text('  CDN: ${s.cdnDomain}', style: TextStyle(fontSize: 12, color: theme.colorScheme.primary)),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.wifi_tethering, size: 18),
                                tooltip: '测试连接',
                                onPressed: () => _testConnection(s),
                              ),
                              IconButton(
                                icon: const Icon(Icons.edit, size: 18),
                                onPressed: () => _openEdit(s),
                              ),
                              IconButton(
                                icon: Icon(Icons.delete, size: 18, color: cs.error),
                                onPressed: () => _delete(s.id),
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
    final cs = theme.colorScheme;
    return Material(
      color: cs.scrim.withValues(alpha: 0.26),
      child: Center(
        child: Dialog(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600, maxHeight: 600),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(_editing != null ? '编辑存储' : '添加存储', style: theme.textTheme.titleLarge),
                    const SizedBox(height: 4),
                    const Text('配置 S3 或 WebDAV 存储后端'),
                    const SizedBox(height: 20),
                    TextField(controller: _nameCtrl, decoration: const InputDecoration(labelText: '存储名称 *', border: OutlineInputBorder(), hintText: '例如：阿里云 OSS')),
                    const SizedBox(height: 16),
                    const Text('存储类型 *'),
                    const SizedBox(height: 8),
                    Row(
                      children: ['s3', 'webdav', 'direct'].map((t) {
                        final selected = _storageType == t;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: ChoiceChip(label: Text(t == 's3' ? 'S3' : t == 'webdav' ? 'WebDAV' : '直接链接'), selected: selected, onSelected: (_) => setState(() => _storageType = t)),
                        );
                      }).toList(),
                    ),
                    if (_storageType == 's3') ...[
                      const SizedBox(height: 16), const Divider(), const Text('S3 配置', style: TextStyle(fontWeight: FontWeight.w600)),
                      const SizedBox(height: 8),
                      Row(children: [
                        Expanded(child: TextField(controller: _s3EndpointCtrl, decoration: const InputDecoration(labelText: 'Endpoint', border: OutlineInputBorder(), hintText: '留空使用 AWS S3'))),
                        const SizedBox(width: 12),
                        Expanded(child: TextField(controller: _s3RegionCtrl, decoration: const InputDecoration(labelText: 'Region', border: OutlineInputBorder(), hintText: 'us-east-1'))),
                      ]),
                      const SizedBox(height: 12),
                      TextField(controller: _s3BucketCtrl, decoration: const InputDecoration(labelText: 'Bucket 名称 *', border: OutlineInputBorder(), hintText: 'my-bucket')),
                      const SizedBox(height: 12),
                      Row(children: [
                        Expanded(child: TextField(controller: _s3AccessKeyCtrl, obscureText: true, decoration: const InputDecoration(labelText: 'Access Key', border: OutlineInputBorder(), hintText: 'AKIA...'))),
                        const SizedBox(width: 12),
                        Expanded(child: TextField(controller: _s3SecretKeyCtrl, obscureText: true, decoration: const InputDecoration(labelText: 'Secret Key', border: OutlineInputBorder(), hintText: '密钥'))),
                      ]),
                      const SizedBox(height: 12),
                      TextField(controller: _s3PathPrefixCtrl, decoration: const InputDecoration(labelText: '路径前缀', border: OutlineInputBorder(), hintText: 'releases/', helperText: '文件上传的路径前缀')),
                    ],
                    if (_storageType == 'webdav') ...[
                      const SizedBox(height: 16), const Divider(), const Text('WebDAV 配置', style: TextStyle(fontWeight: FontWeight.w600)),
                      const SizedBox(height: 8),
                      TextField(controller: _webdavUrlCtrl, decoration: const InputDecoration(labelText: 'WebDAV URL *', border: OutlineInputBorder(), hintText: 'https://dav.example.com/')),
                      const SizedBox(height: 12),
                      Row(children: [
                        Expanded(child: TextField(controller: _webdavUsernameCtrl, decoration: const InputDecoration(labelText: '用户名', border: OutlineInputBorder()))),
                        const SizedBox(width: 12),
                        Expanded(child: TextField(controller: _webdavPasswordCtrl, obscureText: true, decoration: const InputDecoration(labelText: '密码', border: OutlineInputBorder()))),
                      ]),
                      const SizedBox(height: 12),
                      TextField(controller: _webdavPathPrefixCtrl, decoration: const InputDecoration(labelText: '路径前缀', border: OutlineInputBorder(), hintText: '/releases/')),
                    ],
                    const SizedBox(height: 16), const Divider(), const Text('链接配置', style: TextStyle(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      initialValue: _defaultLinkType,
                      decoration: const InputDecoration(labelText: '默认链接类型', border: OutlineInputBorder()),
                      items: const [
                        DropdownMenuItem(value: 'direct', child: Text('直接链接（带签名，有过期时间）')),
                        DropdownMenuItem(value: 'unsigned', child: Text('直接链接（无签名，需存储桶公开）')),
                        DropdownMenuItem(value: 'proxy', child: Text('平台代理（通过平台转发）')),
                        DropdownMenuItem(value: 'cdn', child: Text('CDN 加速（自定义 CDN 域名）')),
                      ],
                      onChanged: (v) => setState(() => _defaultLinkType = v ?? 'direct'),
                    ),
                    if (_defaultLinkType == 'cdn') ...[
                      const SizedBox(height: 12),
                      TextField(controller: _cdnDomainCtrl, decoration: const InputDecoration(labelText: 'CDN 域名', border: OutlineInputBorder(), hintText: 'cdn.example.com', helperText: '不带 https://')),
                      const SizedBox(height: 12),
                      TextField(controller: _cdnPathPrefixCtrl, decoration: const InputDecoration(labelText: 'CDN 路径前缀', border: OutlineInputBorder(), hintText: '/releases/')),
                    ],
                    const SizedBox(height: 12),
                    CheckboxListTile(value: _isActive, onChanged: (v) => setState(() => _isActive = v ?? true), title: const Text('启用此存储'), controlAffinity: ListTileControlAffinity.leading, contentPadding: EdgeInsets.zero),
                    const SizedBox(height: 20),
                    Row(mainAxisAlignment: MainAxisAlignment.end, children: [
                      OutlinedButton(onPressed: () => setState(() => _showDialog = false), child: const Text('取消')),
                      const SizedBox(width: 12),
                      FilledButton(
                        onPressed: _submitting ? null : _submit,
                        child: _submitting ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)) : Text(_editing != null ? '保存' : '创建'),
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
