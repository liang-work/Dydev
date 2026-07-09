import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/github_account.dart';
import '../../models/gitea_account.dart';
import '../../providers/auth_provider.dart';
import '../../services/database_service.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  // Profile form
  final _nicknameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _bioCtrl = TextEditingController();
  bool _savingProfile = false;

  // GitHub
  GitHubAccount? _githubAccount;
  bool _loadingGithub = false;
  bool _githubLinking = false;
  bool _githubUnlinking = false;

  // Gitea
  GiteaAccount? _giteaAccount;
  bool _loadingGitea = false;
  bool _giteaLinking = false;
  bool _giteaUnlinking = false;

  // Mirrors
  List<GitHubMirror> _mirrors = [];
  bool _loadingMirrors = false;
  bool _showMirrorDialog = false;
  GitHubMirror? _editingMirror;
  bool _savingMirror = false;
  final _mirrorNameCtrl = TextEditingController();
  final _mirrorUrlCtrl = TextEditingController();
  final _mirrorPriorityCtrl = TextEditingController(text: '0');
  bool _mirrorActive = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = context.read<AuthProvider>().user;
      if (user != null) {
        _nicknameCtrl.text = user.nickname;
        _phoneCtrl.text = user.phone;
        _bioCtrl.text = user.bio;
      }
    });
    _loadGithub();
    _loadGitea();
    _loadMirrors();
  }

  @override
  void dispose() {
    _nicknameCtrl.dispose();
    _phoneCtrl.dispose();
    _bioCtrl.dispose();
    _mirrorNameCtrl.dispose();
    _mirrorUrlCtrl.dispose();
    _mirrorPriorityCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadGithub() async {
    setState(() => _loadingGithub = true);
    try {
      _githubAccount = await context.read<AuthProvider>().apiService.getGithubAccount();
    } catch (_) {}
    if (mounted) setState(() => _loadingGithub = false);
  }

  Future<void> _loadGitea() async {
    setState(() => _loadingGitea = true);
    try {
      _giteaAccount = await context.read<AuthProvider>().apiService.getGiteaAccount();
    } catch (_) {}
    if (mounted) setState(() => _loadingGitea = false);
  }

  Future<void> _loadMirrors() async {
    setState(() => _loadingMirrors = true);
    try {
      _mirrors = await context.read<AuthProvider>().apiService.getGithubMirrors();
    } catch (_) {}
    if (mounted) setState(() => _loadingMirrors = false);
  }

  Future<void> _saveProfile() async {
    setState(() => _savingProfile = true);
    try {
      final auth = context.read<AuthProvider>();
      final api = auth.apiService;
      final updated = await api.updateProfile({
        'nickname': _nicknameCtrl.text,
        'phone': _phoneCtrl.text,
        'bio': _bioCtrl.text,
      });
      await DatabaseService.saveUser(updated);
      auth.updateUser(updated);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('保存成功')));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('保存失败: $e')));
    } finally {
      if (mounted) setState(() => _savingProfile = false);
    }
  }

  Future<void> _bindGithub() async {
    setState(() => _githubLinking = true);
    try {
      final result = await context.read<AuthProvider>().apiService.getGithubOAuthUrl();
      final url = result['auth_url'] as String;
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('请在浏览器中打开: $url')));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('获取授权链接失败: $e')));
    } finally {
      if (mounted) setState(() => _githubLinking = false);
    }
  }

  Future<void> _unbindGithub() async {
    final confirm = await showDialog<bool>(context: context, builder: (ctx) => AlertDialog(
      title: const Text('确认'), content: const Text('确定要解绑 GitHub 账号吗？'),
      actions: [TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('取消')),
        TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('解绑'))],
    ));
    if (confirm != true) return;
    if (!mounted) return;
    setState(() => _githubUnlinking = true);
    try {
      await context.read<AuthProvider>().apiService.unbindGithub();
      _githubAccount = null;
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('解绑成功')));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('解绑失败: $e')));
    } finally {
      if (mounted) setState(() => _githubUnlinking = false);
    }
  }

  Future<void> _bindGitea() async {
    setState(() => _giteaLinking = true);
    try {
      final result = await context.read<AuthProvider>().apiService.getGiteaAuthUrl();
      final url = result['auth_url'] as String;
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('请在浏览器中打开: $url')));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('获取授权链接失败: $e')));
    } finally {
      if (mounted) setState(() => _giteaLinking = false);
    }
  }

  Future<void> _unbindGitea() async {
    final confirm = await showDialog<bool>(context: context, builder: (ctx) => AlertDialog(
      title: const Text('确认'), content: const Text('确定要解绑 Gitea 账号吗？'),
      actions: [TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('取消')),
        TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('解绑'))],
    ));
    if (confirm != true) return;
    if (!mounted) return;
    setState(() => _giteaUnlinking = true);
    try {
      await context.read<AuthProvider>().apiService.unbindGitea();
      _giteaAccount = null;
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('解绑成功')));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('解绑失败: $e')));
    } finally {
      if (mounted) setState(() => _giteaUnlinking = false);
    }
  }

  void _openMirrorDialog([GitHubMirror? m]) {
    _editingMirror = m;
    _mirrorNameCtrl.text = m?.name ?? '';
    _mirrorUrlCtrl.text = m?.baseUrl ?? '';
    _mirrorPriorityCtrl.text = (m?.priority ?? 0).toString();
    _mirrorActive = m?.isActive ?? true;
    setState(() => _showMirrorDialog = true);
  }

  Future<void> _saveMirror() async {
    final data = {
      'name': _mirrorNameCtrl.text,
      'base_url': _mirrorUrlCtrl.text,
      'is_active': _mirrorActive,
      'priority': int.tryParse(_mirrorPriorityCtrl.text) ?? 0,
    };
    if (data['name'] == null || (data['name'] as String).isEmpty || data['base_url'] == null || (data['base_url'] as String).isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('请填写完整信息')));
      return;
    }
    setState(() => _savingMirror = true);
    try {
      final api = context.read<AuthProvider>().apiService;
      if (_editingMirror != null) {
        await api.updateGithubMirror(_editingMirror!.id, data);
      } else {
        await api.createGithubMirror(data);
      }
      setState(() => _showMirrorDialog = false);
      _loadMirrors();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('保存失败: $e')));
    } finally {
      if (mounted) setState(() => _savingMirror = false);
    }
  }

  Future<void> _deleteMirror(String id) async {
    final confirm = await showDialog<bool>(context: context, builder: (ctx) => AlertDialog(
      title: const Text('确认'), content: const Text('确定要删除这个镜像吗？'),
      actions: [TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('取消')),
        TextButton(onPressed: () => Navigator.pop(ctx, true), child: Text('删除', style: TextStyle(color: Theme.of(context).colorScheme.error)))],
    ));
    if (confirm != true) return;
    if (!mounted) return;
    try {
      await context.read<AuthProvider>().apiService.deleteGithubMirror(id);
      _loadMirrors();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('删除失败: $e')));
    }
  }

  String _formatDate(String? d) {
    if (d == null) return '-';
    try { return DateTime.parse(d).toLocal().toString().substring(0, 16); } catch (_) { return d; }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final user = context.watch<AuthProvider>().user;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 640),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // User header
            Card(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 32,
                      backgroundColor: theme.colorScheme.primaryContainer,
                      child: Text(user != null && user.username.isNotEmpty ? user.username[0].toUpperCase() : 'U',
                          style: TextStyle(fontSize: 24, color: theme.colorScheme.primary)),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(user?.nickname ?? user?.username ?? '用户', style: theme.textTheme.titleLarge),
                          Text(user?.email ?? '', style: TextStyle(color: cs.onSurfaceVariant)),
                        ],
                      ),
                    ),
                    OutlinedButton.icon(
                      onPressed: () => context.read<AuthProvider>().logout(),
                      icon: const Icon(Icons.logout, size: 16),
                      label: const Text('退出登录'),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Profile edit
            Card(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('settings.profile'.tr(), style: theme.textTheme.titleMedium),
                    const SizedBox(height: 4),
                    Text('settings.profile.description'.tr(), style: TextStyle(color: cs.onSurfaceVariant, fontSize: 13)),
                    const SizedBox(height: 20),
                    TextField(controller: TextEditingController(text: user?.username ?? ''), decoration: const InputDecoration(labelText: '用户名', border: OutlineInputBorder()), enabled: false),
                    const SizedBox(height: 12),
                    TextField(controller: TextEditingController(text: user?.email ?? ''), decoration: const InputDecoration(labelText: '邮箱', border: OutlineInputBorder()), enabled: false),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(child: TextField(controller: _nicknameCtrl, decoration: const InputDecoration(labelText: '昵称', border: OutlineInputBorder()))),
                        const SizedBox(width: 12),
                        Expanded(child: TextField(controller: _phoneCtrl, decoration: const InputDecoration(labelText: '手机号', border: OutlineInputBorder()))),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextField(controller: _bioCtrl, maxLines: 3, decoration: const InputDecoration(labelText: '个人简介', border: OutlineInputBorder())),
                    const SizedBox(height: 16),
                    Align(
                      alignment: Alignment.centerRight,
                      child: FilledButton.icon(
                        onPressed: _savingProfile ? null : _saveProfile,
                        icon: const Icon(Icons.save, size: 16),
                        label: Text(_savingProfile ? '保存中...' : '保存修改'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            // GitHub binding
            Card(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.code, color: cs.onSurface),
                        const SizedBox(width: 8),
                        Text('GitHub 账号绑定', style: theme.textTheme.titleMedium),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text('绑定 GitHub 账号后可选择仓库 Release 作为更新包', style: TextStyle(color: cs.onSurfaceVariant, fontSize: 13)),
                    const SizedBox(height: 16),
                    if (_loadingGithub)
                      const Center(child: CircularProgressIndicator())
                    else if (_githubAccount != null)
                      Column(
                        children: [
                          Row(
                            children: [
                              CircleAvatar(
                                radius: 20,
                                backgroundImage: _githubAccount!.githubAvatar != null
                                    ? NetworkImage(_githubAccount!.githubAvatar!) : null,
                                child: _githubAccount!.githubAvatar == null
                                    ? const Icon(Icons.person, size: 20) : null,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(_githubAccount!.githubName ?? _githubAccount!.githubLogin,
                                        style: const TextStyle(fontWeight: FontWeight.w600)),
                                    Text('@${_githubAccount!.githubLogin}',
                                        style: TextStyle(color: cs.onSurfaceVariant, fontSize: 13)),
                                  ],
                                ),
                              ),
                              OutlinedButton.icon(
                                onPressed: _githubUnlinking ? null : _unbindGithub,
                                icon: const Icon(Icons.link_off, size: 16),
                                label: const Text('解绑'),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text('绑定时间: ${_formatDate(_githubAccount!.createdAt)}',
                              style: TextStyle(color: cs.onSurfaceVariant, fontSize: 12)),
                        ],
                      )
                    else
                      Center(
                        child: Column(
                          children: [
                            Icon(Icons.code, size: 48, color: cs.surfaceContainerHigh),
                            const SizedBox(height: 8),
                            Text('绑定 GitHub 账号以使用仓库 Release 功能',
                                style: TextStyle(color: cs.onSurfaceVariant)),
                            const SizedBox(height: 12),
                            FilledButton.icon(
                              onPressed: _githubLinking ? null : _bindGithub,
                              icon: _githubLinking
                                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                                  : const Icon(Icons.link, size: 16),
                              label: const Text('绑定 GitHub'),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Gitea binding
            Card(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.source, color: cs.onSurface),
                        const SizedBox(width: 8),
                        Text('OSGame.net 账号绑定', style: theme.textTheme.titleMedium),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text('绑定 OSGame.net 账号后可选择仓库作为游戏源码',
                        style: TextStyle(color: cs.onSurfaceVariant, fontSize: 13)),
                    const SizedBox(height: 16),
                    if (_loadingGitea)
                      const Center(child: CircularProgressIndicator())
                    else if (_giteaAccount?.connected == true)
                      Column(
                        children: [
                          Row(
                            children: [
                              CircleAvatar(
                                radius: 20,
                                child: Icon(Icons.source, size: 20, color: theme.colorScheme.primary),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(_giteaAccount!.giteaUsername ?? '',
                                        style: const TextStyle(fontWeight: FontWeight.w600)),
                                    Text('OSGame.net ID: ${_giteaAccount!.giteaId ?? ''}',
                                        style: TextStyle(color: cs.onSurfaceVariant, fontSize: 13)),
                                  ],
                                ),
                              ),
                              OutlinedButton.icon(
                                onPressed: _giteaUnlinking ? null : _unbindGitea,
                                icon: const Icon(Icons.link_off, size: 16),
                                label: const Text('解绑'),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                        Text('绑定时间: ${_formatDate(_giteaAccount!.giteaConnectedAt)}',
                            style: TextStyle(color: cs.onSurfaceVariant, fontSize: 12)),
                        ],
                      )
                    else
                      Center(
                        child: Column(
                          children: [
                            Icon(Icons.source, size: 48, color: cs.surfaceContainerHigh),
                            const SizedBox(height: 8),
                            Text('绑定 开源游戏仓库 账号以使用仓库功能',
                                style: TextStyle(color: cs.onSurfaceVariant)),
                            const SizedBox(height: 12),
                            FilledButton.icon(
                              onPressed: _giteaLinking ? null : _bindGitea,
                              icon: _giteaLinking
                                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                                  : const Icon(Icons.link, size: 16),
                              label: const Text('绑定 OSGame.net'),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            // GitHub mirrors
            Card(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('GitHub 加速镜像', style: theme.textTheme.titleMedium),
                            Text('配置自定义加速域名，加快 GitHub 文件下载速度',
                                style: TextStyle(color: cs.onSurfaceVariant, fontSize: 13)),
                          ],
                        ),
                        FilledButton.tonalIcon(
                          onPressed: () => _openMirrorDialog(),
                          icon: const Icon(Icons.add, size: 16),
                          label: const Text('添加镜像'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    if (_loadingMirrors)
                      const Center(child: CircularProgressIndicator())
                    else if (_mirrors.isEmpty)
                      Center(
                        child: Column(
                          children: [
                            Icon(Icons.dns, size: 48, color: cs.surfaceContainerHigh),
                            const SizedBox(height: 8),
                            Text('暂无加速镜像配置', style: TextStyle(color: cs.onSurfaceVariant)),
                          ],
                        ),
                      )
                    else
                      ..._mirrors.map((m) => Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(border: Border.all(color: cs.outlineVariant), borderRadius: BorderRadius.circular(8)),
                        child: Row(
                          children: [
                            Container(
                              width: 8, height: 8,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: m.isActive ? cs.tertiary : cs.onSurfaceVariant,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(m.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                                  Text(m.baseUrl, style: TextStyle(color: cs.onSurfaceVariant, fontSize: 13)),
                                ],
                              ),
                            ),
                            Text('优先级: ${m.priority}', style: const TextStyle(fontSize: 12)),
                            IconButton(
                              icon: const Icon(Icons.edit, size: 16),
                              onPressed: () => _openMirrorDialog(m),
                            ),
                            IconButton(
                              icon: Icon(Icons.delete, size: 16, color: cs.error),
                              onPressed: () => _deleteMirror(m.id),
                            ),
                          ],
                        ),
                      )),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Account security
            Card(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('账号安全', style: theme.textTheme.titleMedium),
                        TextButton.icon(
                          onPressed: () {
                            // Open auth center URL
                          },
                          icon: const Icon(Icons.open_in_new, size: 14),
                          label: const Text('云认证账号管理'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.shield, color: theme.colorScheme.primary),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              '为了您的账号安全，修改邮箱或登录密码请前往云认证中心进行操作。',
                              style: TextStyle(color: theme.colorScheme.primary, fontSize: 13),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    _infoRow('注册时间', _formatDate(user?.dateJoined)),
                    _infoRow('最后登录', _formatDate(user?.lastLogin)),
                    _infoRow('账号状态', user?.isActive == true ? '正常' : '禁用'),
                  ],
                ),
              ),
            ),
            // Mirror dialog
            if (_showMirrorDialog)
              Dialog(
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.85),
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: SingleChildScrollView(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(_editingMirror != null ? '编辑镜像' : '添加镜像', style: theme.textTheme.titleLarge),
                          const SizedBox(height: 20),
                          TextField(controller: _mirrorNameCtrl, decoration: const InputDecoration(labelText: '镜像名称', border: OutlineInputBorder(), hintText: '如: ghproxy')),
                          const SizedBox(height: 12),
                          TextField(controller: _mirrorUrlCtrl, decoration: const InputDecoration(labelText: '基础 URL', border: OutlineInputBorder(), hintText: 'https://mirror.ghproxy.com')),
                          const SizedBox(height: 12),
                          TextField(controller: _mirrorPriorityCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: '优先级', border: OutlineInputBorder(), helperText: '数字越小越优先')),
                          const SizedBox(height: 12),
                          CheckboxListTile(
                            value: _mirrorActive,
                            onChanged: (v) => setState(() => _mirrorActive = v ?? true),
                            title: const Text('启用'),
                            controlAffinity: ListTileControlAffinity.leading,
                            contentPadding: EdgeInsets.zero,
                          ),
                          const SizedBox(height: 20),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              OutlinedButton(onPressed: () => setState(() => _showMirrorDialog = false), child: const Text('取消')),
                              const SizedBox(width: 12),
                              FilledButton(
                                onPressed: _savingMirror ? null : _saveMirror,
                                child: _savingMirror
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
              ),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
