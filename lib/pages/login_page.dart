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
  bool _tokenLoading = false;

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
            if (_webViewLoading) {
              setState(() => _webViewLoading = false);
            }
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
    super.dispose();
  }

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
        setState(() {
          _webViewError = '登录失败: $error';
          _webViewLoading = false;
        });
        return;
      }

      if (access == null || refresh == null) {
        setState(() {
          _webViewError = '回调缺少 token 参数';
          _webViewLoading = false;
        });
        return;
      }

      await AuthService().saveTokens(accessToken: access, refreshToken: refresh);
      if (!mounted) return;
      await context.read<AuthProvider>().refreshState();
    } catch (e) {
      if (mounted) {
        setState(() {
          _webViewError = '处理回调失败: $e';
          _webViewLoading = false;
        });
      }
    }
  }

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

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(auth.error ?? '登录失败'),
        backgroundColor: Theme.of(context).colorScheme.error,
      ),
    );
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
                _controller?.loadRequest(
                  Uri.parse('${ApiConfig.baseUrl}${ApiConfig.oidcLogin}'),
                );
              },
              child: const Text('重试'),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () => _tokenController.text.isNotEmpty
                  ? _loginWithToken()
                  : null,
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
          constraints: const BoxConstraints(maxWidth: 400),
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
                    '请从 Web 端获取 Access Token 后登录',
                    style: TextStyle(color: cs.onSurfaceVariant),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '访问 ${ApiConfig.baseUrl} 并登录后，在设置中复制您的 Access Token',
                    style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  TextField(
                    controller: _tokenController,
                    decoration: InputDecoration(
                      labelText: 'Access Token',
                      hintText: '粘贴您的访问令牌',
                      prefixIcon: const Icon(Icons.key),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    obscureText: true,
                  ),
                  const SizedBox(height: 16),
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
                          : const Text('登录'),
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
