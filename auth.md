# Flutter 客户端认证登录文档

> 适用对象：开发者平台（`frontend/`）的 Flutter 客户端
> 后端 API：`https://dev-api.dy.ci`
> 认证体系：基于 Logto OIDC + Django SimpleJWT

---

## 一、认证体系概览

开发者平台采用 **服务端 OIDC 流程**，整体架构如下：

```
┌──────────┐      ┌──────────────┐      ┌──────────────┐
│  Flutter │      │  Django 后端 │      │  Logto IdP   │
│  客户端  │      │   dev-api.   │      │  auth.yun    │
│          │      │   dy.ci      │      │              │
└─────┬────┘      └──────┬───────┘      └──────┬───────┘
      │                  │                     │
      │  1. GET /api/accounts/oidc/login/       │
      │────────────────▶│                     │
      │                  │  2. 302 重定向 ──────▶│
      │                  │                     │
      │  3. WebView 加载 Logto 登录页           │
      │◀────────────────────────────────────────│
      │                  │                     │
      │  4. 用户输入账号密码登录                 │
      │────────────────────────────────────────▶│
      │                  │                     │
      │                  │  5. 302 回调 ────────│
      │                  │  /api/accounts/oidc/callback/?code=xxx
      │                  │                     │
      │                  │  6. 后端用 code 换 token → userinfo → 建用户 → 签 SimpleJWT
      │                  │                     │
      │                  │  7. 302 重定向到 ────│
      │  https://developer.dy.ci/callback?access_token=xxx&refresh_token=xxx
      │                  │                     │
      │  8. WebView 拦截这个跳转，提取 token    │
      │                  │                     │
      │  9. 存 token 到 secure_storage         │
      │                  │                     │
      │  10. 后续业务 API 请求带 Authorization: Bearer <access_token>
      │────────────────▶│                     │
```

### 关键设计点

- **后端零改动**：后端登录流程对客户端类型透明，Flutter 完全复用 Web 端流程
- **Token 分层**：Logto 负责身份认证，后端 SimpleJWT 负责业务 API 认证

---

## 二、关键配置

### 2.1 后端配置（生产环境已就绪）

| 配置项 | 值 | 说明 |
|---|---|---|
| `OIDC_REDIRECT_AFTER_AUTH` | `https://developer.dy.ci/callback` | 登录成功后重定向地址 |
| `OIDC_OP_AUTHORIZATION_ENDPOINT` | `https://auth.yun/oidc/auth` | Logto 授权端点 |
| `OIDC_OP_TOKEN_ENDPOINT` | `https://auth.yun/oidc/token` | Logto token 端点 |
| `OIDC_OP_USER_ENDPOINT` | `https://auth.yun/oidc/me` | Logto 用户信息端点 |

### 2.2 Flutter 端配置

```dart
// lib/core/api_config.dart
class ApiConfig {
  // 后端 API
  static const String backendBaseUrl = 'https://dev-api.dy.ci';
  static const String backendApiBase  = '$backendBaseUrl/api';

  // SSO 登录入口（WebView 加载此 URL，后端会 302 到 Logto）
  static const String oidcLoginUrl = '$backendApiBase/accounts/oidc/login/';

  // 登录成功后，后端会 302 到此 URL（带 access_token / refresh_token 查询参数）
  // 必须与后端 OIDC_REDIRECT_AFTER_AUTH 保持一致
  static const String callbackUrl = 'https://developer.dy.ci/callback';

  // 涉及的后端接口
  static const String userMeUrl      = '$backendApiBase/accounts/user/me/';
  static const String tokenRefreshUrl = '$backendApiBase/accounts/token/refresh/';
  static const String oidcLogoutUrl   = '$backendApiBase/accounts/oidc/logout/';
}
```

---

## 三、依赖与权限

### 3.1 pubspec.yaml

```yaml
dependencies:
  flutter:
    sdk: flutter
  webview_flutter: ^4.10.0          # WebView 登录页
  flutter_secure_storage: ^9.2.2     # 安全存储 token
  dio: ^5.7.0                        # HTTP 客户端
```

### 3.2 Android 权限

`android/app/src/main/AndroidManifest.xml`：

```xml
<uses-permission android:name="android.permission.INTERNET"/>
```

### 3.3 iOS 配置

iOS 默认允许 HTTPS 请求，无需额外配置。

---

## 四、Token 存储与刷新

### 4.1 Token 存储服务

```dart
// lib/features/auth/auth_service.dart
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../core/api_config.dart';

class AuthService {
  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  static const _kAccess  = 'access_token';
  static const _kRefresh = 'refresh_token';

  /// 保存后端 SimpleJWT
  static Future<void> saveTokens(String access, String refresh) async {
    await _storage.write(key: _kAccess,  value: access);
    await _storage.write(key: _kRefresh, value: refresh);
  }

  /// 获取 access_token
  static Future<String?> getAccessToken() => _storage.read(key: _kAccess);

  /// 是否已登录
  static Future<bool> isLoggedIn() async => (await _storage.read(key: _kAccess)) != null;

  /// 刷新 token
  /// 对应后端 POST /api/accounts/token/refresh/
  static Future<String> refresh() async {
    final refresh = await _storage.read(key: _kRefresh);
    if (refresh == null) throw Exception('No refresh token');

    final dio = Dio();
    final resp = await dio.post(
      ApiConfig.tokenRefreshUrl,
      data: {'refresh': refresh},
      options: Options(
        headers: {'Content-Type': 'application/json'},
        validateStatus: (_) => true,
      ),
    );

    if (resp.statusCode != 200) {
      throw Exception('Refresh failed: ${resp.data}');
    }

    final newAccess = resp.data['access'] as String;
    await _storage.write(key: _kAccess, value: newAccess);
    return newAccess;
  }

  /// 登出（清本地 token）
  static Future<void> logout() async {
    await _storage.deleteAll();
  }
}
```

### 4.2 Dio 拦截器（自动带 token + 自动刷新）

```dart
// lib/features/auth/auth_interceptor.dart
import 'package:dio/dio.dart';
import 'auth_service.dart';

class AuthInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    final token = await AuthService.getAccessToken();
    if (token != null) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    // 401 时自动尝试刷新 token 并重试
    if (err.response?.statusCode == 401) {
      try {
        final newToken = await AuthService.refresh();
        err.requestOptions.headers['Authorization'] = 'Bearer $newToken';
        final resp = await Dio().fetch(err.requestOptions);
        handler.resolve(resp);
        return;
      } catch (_) {
        // 刷新失败，需要引导用户重新登录
      }
    }
    handler.next(err);
  }
}
```

---

## 五、登录流程实现

### 5.1 WebView 登录页

```dart
// lib/features/auth/login_page.dart
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../../core/api_config.dart';
import 'auth_service.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  late final WebViewController _controller;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(NavigationDelegate(
        onNavigationRequest: (request) async {
          final url = request.url;

          // 拦截登录成功回调
          // 后端会 302 到 https://developer.dy.ci/callback?access_token=xxx&refresh_token=xxx
          if (_isCallbackUrl(url)) {
            await _handleCallback(url);
            return NavigationDecision.prevent;  // 阻止真正加载这个 URL
          }
          return NavigationDecision.navigate;
        },
        onPageFinished: (_) {
          if (_loading) setState(() => _loading = false);
        },
      ))
      ..loadRequest(Uri.parse(ApiConfig.oidcLoginUrl));
  }

  /// 判断 URL 是否是登录成功回调
  bool _isCallbackUrl(String url) {
    return url.startsWith(ApiConfig.callbackUrl) &&
           url.contains('access_token=') &&
           url.contains('refresh_token=');
  }

  /// 从 URL 提取 token 并保存
  Future<void> _handleCallback(String url) async {
    try {
      final uri = Uri.parse(url);
      final access  = uri.queryParameters['access_token'];
      final refresh = uri.queryParameters['refresh_token'];
      final error   = uri.queryParameters['error'];

      if (error != null) {
        setState(() {
          _error = '登录失败: $error';
          _loading = false;
        });
        return;
      }

      if (access == null || refresh == null) {
        setState(() {
          _error = '回调缺少 token 参数';
          _loading = false;
        });
        return;
      }

      await AuthService.saveTokens(access, refresh);

      if (mounted) Navigator.of(context).pop(true);  // 返回 true 表示登录成功
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = '处理回调失败: $e';
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('开发者平台登录'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(false),
        ),
      ),
      body: Stack(
        children: [
          WebViewWidget(controller: _controller),
          if (_loading && _error == null)
            const Center(child: CircularProgressIndicator()),
          if (_error != null)
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(_error!, style: const TextStyle(color: Colors.red)),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    child: const Text('关闭'),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
```

### 5.2 登录入口

```dart
// lib/features/auth/login_gate.dart
import 'package:flutter/material.dart';
import 'login_page.dart';

class LoginGate extends StatelessWidget {
  const LoginGate({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: ElevatedButton.icon(
          icon: const Icon(Icons.login),
          label: const Text('云认证登录'),
          onPressed: () async {
            final ok = await Navigator.of(context).push<bool>(
              MaterialPageRoute(builder: (_) => const LoginPage()),
            );
            if (ok == true) {
              // 登录成功，刷新 UI（建议用 Provider/Riverpod 触发状态重建）
            }
          },
        ),
      ),
    );
  }
}
```

---

## 六、用户信息获取

登录成功后，调用 `/api/accounts/user/me/` 获取用户信息。

### 6.1 用户模型

```dart
// lib/features/user/user.dart
class User {
  final int id;
  final String username;
  final String email;
  final String nickname;
  final String avatar;
  final String phone;
  final String bio;
  final bool isActive;
  final bool isStaff;
  final DateTime? dateJoined;
  final DateTime? lastLogin;

  User({
    required this.id,
    required this.username,
    required this.email,
    required this.nickname,
    required this.avatar,
    required this.phone,
    required this.bio,
    required this.isActive,
    required this.isStaff,
    this.dateJoined,
    this.lastLogin,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as int,
      username: json['username'] as String? ?? '',
      email: json['email'] as String? ?? '',
      nickname: json['nickname'] as String? ?? '',
      avatar: json['avatar'] as String? ?? '',
      phone: json['phone'] as String? ?? '',
      bio: json['bio'] as String? ?? '',
      isActive: json['is_active'] as bool? ?? false,
      isStaff: json['is_staff'] as bool? ?? false,
      dateJoined: json['date_joined'] != null
          ? DateTime.parse(json['date_joined'])
          : null,
      lastLogin: json['last_login'] != null
          ? DateTime.parse(json['last_login'])
          : null,
    );
  }
}
```

### 6.2 用户 API

```dart
// lib/features/user/user_api.dart
import 'package:dio/dio.dart';
import '../../core/api_config.dart';
import '../auth/auth_interceptor.dart';
import 'user.dart';

final _dio = Dio()..interceptors.add(AuthInterceptor());

/// 获取当前登录用户信息
/// 对应后端 GET /api/accounts/user/me/
Future<User> fetchCurrentUser() async {
  final resp = await _dio.get(ApiConfig.userMeUrl);
  return User.fromJson(resp.data);
}

/// 更新当前用户信息
/// 对应后端 PUT /api/accounts/user/me/
/// 可更新字段: nickname, bio, avatar, phone
Future<User> updateUser(Map<String, dynamic> data) async {
  final resp = await _dio.put(ApiConfig.userMeUrl, data: data);
  return User.fromJson(resp.data);
}
```

---

## 七、登出流程

### 7.1 仅清本地 token（推荐）

```dart
Future<void> logoutLocal() async {
  await AuthService.logout();
  // 跳转到登录页
}
```

### 7.2 同时登出 Logto SSO（彻底登出）

```dart
// lib/features/auth/logout_service.dart
import 'package:webview_flutter/webview_flutter.dart';
import '../../core/api_config.dart';
import 'auth_service.dart';

/// 调用后端登出接口获取 Logto 退出 URL，再用 WebView 打开
Future<void> logoutWithSSO() async {
  // 1. 清本地 token
  await AuthService.logout();

  // 2. 调用后端 /api/accounts/oidc/logout/?next=<回调地址>
  //    后端返回 { logout_url: "https://auth.yun/oidc/session/end?...", redirect_url: "..." }
  // 用 WebView 打开 logout_url，让 Logto 清掉 SSO session
  // 注意：这一步是可选的，仅当你希望用户在所有端都登出时才需要
}
```

参考后端 [accounts/views.py:140-178](file:///c:/Users/Administrator/Documents/code/ddc/accounts/views.py#L140-L178) 的 `OIDCLogoutView`。

---

## 八、主入口示例

```dart
// lib/main.dart
import 'package:flutter/material.dart';
import 'features/auth/auth_service.dart';
import 'features/auth/login_gate.dart';
import 'features/auth/login_page.dart';
import 'features/user/user_api.dart';
import 'features/user/user.dart';

void main() => runApp(const DeveloperApp());

class DeveloperApp extends StatelessWidget {
  const DeveloperApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '开发者平台',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const AuthGate(),
    );
  }
}

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: AuthService.isLoggedIn(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        return snapshot.data! ? const HomePage() : const LoginGate();
      },
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  User? _user;

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    try {
      final user = await fetchCurrentUser();
      setState(() => _user = user);
    } catch (e) {
      // 处理错误
    }
  }

  Future<void> _logout() async {
    await AuthService.logout();
    // 触发 AuthGate 重建（实际用状态管理库）
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('开发者平台'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _logout,
          ),
        ],
      ),
      body: Center(
        child: _user == null
            ? const CircularProgressIndicator()
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('欢迎, ${_user!.nickname.isNotEmpty ? _user!.nickname : _user!.username}'),
                  const SizedBox(height: 8),
                  Text('邮箱: ${_user!.email}'),
                ],
              ),
      ),
    );
  }
}
```

---

## 九、错误码与异常处理

### 9.1 登录回调错误码

后端在登录失败时会重定向到 callback URL 并附带 error 参数（参考 [accounts/views.py:46-138](file:///c:/Users/Administrator/Documents/code/ddc/accounts/views.py#L46-L138)）：

| 错误码 | 说明 | 处理建议 |
|---|---|---|
| `invalid_state` | state 参数验证失败（CSRF 攻击） | 重新登录 |
| `no_code` | Logto 未返回授权码 | 重新登录 |
| `token_exchange_failed` | 后端用 code 换 token 失败 | 检查网络，重新登录 |
| `userinfo_failed` | 后端获取用户信息失败 | 检查 Logto 服务状态 |
| `user_creation_failed` | 用户创建失败 | 联系管理员 |

### 9.2 API 401 处理

```
请求业务 API → 401 Unauthorized
  ↓
拦截器自动调用 refresh() 刷新 access_token
  ↓
刷新成功 → 用新 token 重试原请求
刷新失败 → 清空 token，跳转到登录页
```

参考 [frontend/src/api/client.ts:18-30](file:///c:/Users/Administrator/Documents/code/ddc/frontend/src/api/client.ts#L18-L30) 的逻辑。

---

## 十、注意事项

### 10.1 安全性

- ✅ **Token 存储**：必须使用 `flutter_secure_storage`，不要用 `shared_preferences`（明文存储）
- ✅ **不暴露 client_secret**：服务端 OIDC 流程下，`client_secret` 留在后端，Flutter 完全接触不到
- ⚠️ **WebView 不要开启 `withLocalUrl`**：避免 Logto 页面调用 Flutter 本地接口

### 10.2 与后端配置同步

Flutter 端 `ApiConfig.callbackUrl` 必须与后端 `OIDC_REDIRECT_AFTER_AUTH` 环境变量保持一致。如果后端修改了这个值，Flutter 端必须同步修改。

### 10.3 Token 有效期

后端 SimpleJWT 默认配置（可在 `settings.py` 中调整）：

| Token | 默认有效期 |
|---|---|
| access_token | 5 分钟 |
| refresh_token | 1 天 |

- access_token 过期 → 拦截器自动用 refresh_token 刷新
- refresh_token 过期 → 需要用户重新走 WebView 登录流程

### 10.4 平台差异

- **Android**：确保 `AndroidManifest.xml` 有 INTERNET 权限
- **iOS**：HTTPS 默认允许，无需 ATS 配置
- **桌面端**：`webview_flutter` 支持 Windows/macOS/Linux（需 v4.x+）

### 10.5 用户体验优化

- WebView 加载时显示 loading 动画
- 提供关闭按钮，允许用户取消登录
- 登录失败时显示友好错误信息并提供重试按钮
- 启动时检查 token 有效性，避免已登录用户重复登录

---

## 十一、API 接口清单

| 接口 | 方法 | 说明 | 认证 |
|---|---|---|---|
| `/api/accounts/oidc/login/` | GET | 发起 SSO 登录（WebView 加载） | 无 |
| `/api/accounts/oidc/callback/` | GET | SSO 登录回调（后端内部处理） | 无 |
| `/api/accounts/oidc/logout/` | GET | 登出，返回 Logto 退出 URL | 无 |
| `/api/accounts/oidc/config/` | GET | 获取 OIDC 公开配置 | 无 |
| `/api/accounts/token/refresh/` | POST | 刷新 JWT Token | 无（需 refresh_token） |
| `/api/accounts/user/me/` | GET | 获取当前用户信息 | 需认证 |
| `/api/accounts/user/me/` | PUT | 更新当前用户信息 | 需认证 |

---

## 十二、完整文件结构

```
lib/
├── core/
│   └── api_config.dart              # API 配置常量
├── features/
│   ├── auth/
│   │   ├── auth_service.dart        # Token 存储与刷新
│   │   ├── auth_interceptor.dart    # Dio 请求拦截器
│   │   ├── login_page.dart          # WebView 登录页
│   │   └── login_gate.dart          # 登录入口
│   └── user/
│       ├── user.dart                # 用户模型
│       └── user_api.dart            # 用户相关 API
├── main.dart                        # 主入口
```

---

## 十三、总结

### 方案核心

**Flutter WebView 复用 Web 端服务端 OIDC 流程，拦截最终重定向提取 token。**

### 优势

- ✅ **后端零改动**：完全复用 Web 端登录流程
- ✅ **无需 client_secret**：所有密钥留在后端
- ✅ **行为与 Web 端一致**：登录体验、token 格式、API 调用方式完全相同
- ✅ **自动 token 刷新**：拦截器自动处理 access_token 过期

### 关键流程

1. WebView 加载 `/api/accounts/oidc/login/`
2. 用户在 WebView 内完成 Logto 登录
3. 后端 callback 处理完成后 302 到 `https://developer.dy.ci/callback?access_token=xxx&refresh_token=xxx`
4. Flutter WebView 拦截这个跳转，提取 token
5. 存入 `flutter_secure_storage`
6. 后续所有 API 请求通过 `AuthInterceptor` 自动带 `Authorization: Bearer <access_token>`