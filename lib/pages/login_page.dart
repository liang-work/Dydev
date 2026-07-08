import 'dart:io';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../config/api_config.dart';
import '../providers/auth_provider.dart';
import '../services/auth_service.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _tokenController = TextEditingController();
  final _callbackUrlController = TextEditingController();
  bool _tokenLoading = false;
  bool _callbackLoading = false;

  // WebView (mobile only)
  late final WebViewController? _controller;
  bool _webViewLoading = true;
  String? _webViewError;

  bool get _isMobile => Platform.isAndroid || Platform.isIOS;

  @override
  void initState() {
    super.initState();
    if (_isMobile) {
      _controller = WebViewController()
        ..setJavaScriptMode(JavaScriptMode.unrestricted)
        ..setNavigationDelegate(NavigationDelegate(
          onNavigationRequest: (request) {
            final url = request.url;
            if (_isCallbackUrl(url)) {
              _handleCallback(url);
              return NavigationDecision.prevent;
            }
            return NavigationDecision.navigate;
          },
          onPageFinished: (_) {
            if (_webViewLoading) setState(() => _webViewLoading = false);
          },
          onWebResourceError: (error) {
            setState(() {
              _webViewError = error.description;
              _webViewLoading = false;
            });
          },
        ))
        ..loadRequest(Uri.parse('${ApiConfig.baseUrl}${ApiConfig.oidcLogin}'));
    } else {
      _controller = null;
    }
  }

  @override
  void dispose() {
    _tokenController.dispose();
    _callbackUrlController.dispose();
    super.dispose();
  }

  String get _oidcLoginUrl => '${ApiConfig.baseUrl}${ApiConfig.oidcLogin}';

  bool _isCallbackUrl(String url) =>
      url.startsWith(ApiConfig.callbackUrl) &&
      url.contains('access_token=') &&
      url.contains('refresh_token=');

  Future<void> _handleCallback(String url) async {
    try {
      final uri = Uri.parse(url);
      final access = uri.queryParameters['access_token'];
      final refresh = uri.queryParameters['refresh_token'];
      final error = uri.queryParameters['error'];

      if (error != null) {
        _showError('登录失败: $error');
        return;
      }

      if (access == null || refresh == null) {
        _showError('回调缺少 token 参数');
        return;
      }

      await AuthService().saveTokens(accessToken: access, refreshToken: refresh);
      if (!mounted) return;
      await context.read<AuthProvider>().refreshState();
    } catch (e) {
      _showError('处理回调失败: $e');
    }
  }

  void _showError(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: Theme.of(context).colorScheme.error,
      ),
    );
  }

  // ---- Desktop: browser login ----

  Future<void> _openBrowser() async {
    final uri = Uri.parse(_oidcLoginUrl);
    try {
      if (Platform.isWindows) {
        await Process.run('start', [uri.toString()], runInShell: true);
      } else if (Platform.isMacOS) {
        await Process.run('open', [uri.toString()], runInShell: true);
      } else if (Platform.isLinux) {
        await Process.run('xdg-open', [uri.toString()], runInShell: true);
      }
    } catch (e) {
      _showError('无法打开浏览器: $e');
    }
  }

  Future<void> _loginWithCallbackUrl() async {
    final url = _callbackUrlController.text.trim();
    if (url.isEmpty) return;
    if (!_isCallbackUrl(url)) {
      _showError('无效的回调 URL，请粘贴完整的地址栏 URL');
      return;
    }

    setState(() => _callbackLoading = true);
    await _handleCallback(url);
    if (!mounted) return;
    setState(() => _callbackLoading = false);
  }

  // ---- Common: token login ----

  Future<void> _loginWithToken() async {
    final token = _tokenController.text.trim();
    if (token.isEmpty) return;

    setState(() => _tokenLoading = true);

    final auth = context.read<AuthProvider>();
    final success = await auth.loginWithToken(token);

    if (!mounted) return;
    setState(() => _tokenLoading = false);

    if (success) {
      if (!mounted) return;
      context.go('/dashboard');
      return;
    }

    _showError(auth.error ?? '登录失败');
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('开发者平台登录')),
      body: _isMobile ? _buildMobileBody(cs) : _buildDesktopBody(cs),
    );
  }

  Widget _buildMobileBody(ColorScheme cs) {
    if (_webViewError != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 48, color: cs.error),
            const SizedBox(height: 16),
            Text(_webViewError!, style: TextStyle(color: cs.error)),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: () {
                setState(() {
                  _webViewError = null;
                  _webViewLoading = true;
                });
                _controller?.loadRequest(Uri.parse(_oidcLoginUrl));
              },
              child: const Text('重试'),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () {
                // Show token input on mobile as fallback
              },
              child: const Text('使用 Token 登录'),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        Expanded(child: WebViewWidget(controller: _controller!)),
        if (_webViewLoading) const LinearProgressIndicator(),
      ],
    );
  }

  Widget _buildDesktopBody(ColorScheme cs) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 40),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.code, size: 48, color: cs.primary),
                  const SizedBox(height: 12),
                  Text(
                    '开发者平台',
                    style: Theme.of(context)
                        .textTheme
                        .headlineSmall
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '登录以管理您的应用',
                    style: TextStyle(color: cs.onSurfaceVariant),
                  ),
                  const SizedBox(height: 32),

                  // Step 1: Open browser
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.open_in_browser),
                      onPressed: _openBrowser,
                      label: const Text('浏览器登录'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '在弹出的浏览器中完成登录后，复制地址栏完整 URL 粘贴到下方',
                    style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),

                  // Step 2: Paste callback URL
                  TextField(
                    controller: _callbackUrlController,
                    decoration: InputDecoration(
                      labelText: '登录回调 URL',
                      hintText: '粘贴浏览器地址栏的完整 URL',
                      prefixIcon: const Icon(Icons.link),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: _callbackLoading ? null : _loginWithCallbackUrl,
                      child: _callbackLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text('登录'),
                    ),
                  ),

                  // Divider
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(child: Divider(color: cs.outlineVariant)),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Text('或者',
                            style: TextStyle(color: cs.onSurfaceVariant)),
                      ),
                      Expanded(child: Divider(color: cs.outlineVariant)),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Alternative: token login
                  TextField(
                    controller: _tokenController,
                    decoration: InputDecoration(
                      labelText: 'Access Token',
                      hintText: '直接输入访问令牌',
                      prefixIcon: const Icon(Icons.key),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    obscureText: true,
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: _tokenLoading ? null : _loginWithToken,
                      child: _tokenLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text('Token 登录'),
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
}
