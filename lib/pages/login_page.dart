import 'dart:io';

import 'package:dio/dio.dart' hide Response;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;
import 'package:url_launcher/url_launcher.dart';
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
  final _refreshTokenController = TextEditingController();
  WebViewController? _controller;
  bool _webViewLoading = true;
  String? _webViewError;
  bool _tokenLoading = false;
  bool _useTokenLogin = false;
  bool _desktopOAuthLoading = false;
  String? _desktopOAuthError;

  bool get _isMobile => Platform.isAndroid || Platform.isIOS;

  @override
  void initState() {
    super.initState();
    if (_isMobile) {
      _initWebView();
    }
  }

  void _initWebView() {
    try {
      final controller = WebViewController()
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
        ..loadRequest(Uri.parse(_oidcLoginUrl));
      _controller = controller;
    } catch (_) {
      _controller = null;
      _webViewLoading = false;
      _useTokenLogin = true;
    }
  }

  @override
  void dispose() {
    _tokenController.dispose();
    _refreshTokenController.dispose();
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
      final errorParam = uri.queryParameters['error'];

      if (errorParam != null) {
        _showError('登录失败: $errorParam');
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

  Future<void> _loginWithToken() async {
    final token = _tokenController.text.trim();
    if (token.isEmpty) return;

    setState(() => _tokenLoading = true);

    final refresh = _refreshTokenController.text.trim();
    final auth = context.read<AuthProvider>();
    final success = await auth.loginWithToken(token,
        refreshToken: refresh.isNotEmpty ? refresh : null);

    if (!mounted) return;
    setState(() => _tokenLoading = false);

    if (success) {
      if (!mounted) return;
      context.go('/dashboard');
      return;
    }

    _showError(auth.error ?? '登录失败');
  }

  // ---- Desktop OAuth device login ----

  Future<void> _desktopOAuthLogin() async {
    setState(() {
      _desktopOAuthLoading = true;
      _desktopOAuthError = null;
    });

    try {
      // 1. Start local HTTP server on random port
      final server = await shelf_io.serve(
        (Request request) async {
          if (request.requestedUri.path == '/callback') {
            final params = request.requestedUri.queryParameters;
            if (params.containsKey('error')) {
              _showError('登录失败: ${params['error']}');
              return Response.ok(
                '<html><body><h3>登录失败</h3><p>${params['error']}</p><p>请关闭此页面返回客户端重试。</p></body></html>',
                headers: {'Content-Type': 'text/html; charset=utf-8'},
              );
            }
            final access = params['access_token'];
            final refresh = params['refresh_token'];
            if (access != null && refresh != null) {
              await AuthService()
                  .saveTokens(accessToken: access, refreshToken: refresh);
              if (mounted) {
                await context.read<AuthProvider>().refreshState();
              }
              return Response.ok(
                '<html><body><h3>登录成功</h3><p>请返回客户端。</p></body></html>',
                headers: {'Content-Type': 'text/html; charset=utf-8'},
              );
            }
          }
          return Response.notFound('Not Found');
        },
        'localhost',
        0,
      );

      final port = server.port;
      final redirectUri = 'http://localhost:$port/callback';

      // 2. Get login URL from backend
      final dio = Dio(BaseOptions(baseUrl: ApiConfig.baseUrl));
      final resp = await dio.get(
        ApiConfig.oauthDeviceLogin,
        queryParameters: {
          'redirect_uri': redirectUri,
          'client': 'flutter-desktop-developer',
        },
      );

      final loginUrl = resp.data['login_url'] as String;

      // 3. Open system browser
      final uri = Uri.parse(loginUrl);
      if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
        throw Exception('无法打开浏览器');
      }

      if (!mounted) return;

      // Show info to user while waiting
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('请在打开的浏览器中完成登录...'),
          duration: Duration(seconds: 3),
        ),
      );

      setState(() => _desktopOAuthLoading = false);
    } catch (e) {
      setState(() {
        _desktopOAuthLoading = false;
        _desktopOAuthError = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    if (_isMobile) {
      return _buildMobileBody(cs);
    }
    return _buildDesktopBody(cs);
  }

  // ---- Mobile: WebView ----

  Widget _buildMobileBody(ColorScheme cs) {
    if (_useTokenLogin) {
      return _buildScaffold(cs, _buildTokenLogin(cs));
    }

    if (_controller == null) {
      return _buildScaffold(cs, _buildTokenLogin(cs));
    }

    if (_webViewError != null) {
      return _buildScaffold(cs, _buildErrorView(cs));
    }

    return _buildScaffold(cs, _buildWebView());
  }

  Widget _buildScaffold(ColorScheme cs, Widget child) {
    return Scaffold(
      appBar: AppBar(title: const Text('开发者平台登录')),
      body: child,
    );
  }

  Widget _buildWebView() {
    return Column(
      children: [
        Expanded(child: WebViewWidget(controller: _controller!)),
        if (_webViewLoading) const LinearProgressIndicator(),
      ],
    );
  }

  Widget _buildErrorView(ColorScheme cs) {
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
            onPressed: () => setState(() => _useTokenLogin = true),
            child: const Text('使用 Token 登录'),
          ),
        ],
      ),
    );
  }

  // ---- Desktop: OAuth device login ----

  Widget _buildDesktopBody(ColorScheme cs) {
    return Scaffold(
      appBar: AppBar(title: const Text('开发者平台登录')),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Card(
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 32, vertical: 40),
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
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        icon: _desktopOAuthLoading
                            ? SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2, color: cs.onPrimary),
                              )
                            : const Icon(Icons.open_in_browser),
                        onPressed:
                            _desktopOAuthLoading ? null : _desktopOAuthLogin,
                        label: Text(_desktopOAuthLoading ? '启动中...' : '浏览器登录'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                      ),
                    ),
                    if (_desktopOAuthError != null) ...[
                      const SizedBox(height: 12),
                      Text(
                        _desktopOAuthError!,
                        style: TextStyle(
                            color: cs.error,
                            fontSize: 12),
                        textAlign: TextAlign.center,
                      ),
                    ],
                    const SizedBox(height: 8),
                    Text(
                      '将在系统浏览器中打开登录页面，登录后自动返回',
                      style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
                      textAlign: TextAlign.center,
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
                    // Token login fallback
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
                    const SizedBox(height: 16),
                    TextField(
                      controller: _refreshTokenController,
                      decoration: InputDecoration(
                        labelText: 'Refresh Token（可选）',
                        hintText: '输入刷新令牌（可选，用于自动续期）',
                        prefixIcon: const Icon(Icons.refresh),
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
                            ? SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: cs.onPrimary,
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
      ),
    );
  }

  // ---- Common: Token login UI ----

  Widget _buildTokenLogin(ColorScheme cs) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Card(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 40),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.code, size: 48, color: cs.primary),
                  const SizedBox(height: 12),
                  Text(
                    'Access Token 登录',
                    style: Theme.of(context)
                        .textTheme
                        .headlineSmall
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '输入访问令牌以登录',
                    style: TextStyle(color: cs.onSurfaceVariant),
                  ),
                  const SizedBox(height: 32),
                  TextField(
                    controller: _tokenController,
                    decoration: InputDecoration(
                      labelText: 'Access Token',
                      hintText: '输入访问令牌',
                      prefixIcon: const Icon(Icons.key),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    obscureText: true,
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _refreshTokenController,
                    decoration: InputDecoration(
                      labelText: 'Refresh Token（可选）',
                      hintText: '输入刷新令牌（可选，用于自动续期）',
                      prefixIcon: const Icon(Icons.refresh),
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
                          ? SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: cs.onPrimary,
                              ),
                            )
                          : const Text('登录'),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: () => setState(() {
                      _useTokenLogin = false;
                      _webViewError = null;
                      _webViewLoading = true;
                      _initWebView();
                    }),
                    child: const Text('返回 Web 登录'),
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
