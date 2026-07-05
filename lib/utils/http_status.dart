import 'package:flutter/material.dart';
import 'global_keys.dart';

/// Returns a user-friendly Chinese label for the HTTP status code,
/// with the English phrase in parentheses.
String httpStatusMessage(int code) {
  switch (code) {
    case 400: return '错误请求 (400 Bad Request)';
    case 401: return '未授权 (401 Unauthorized)';
    case 403: return '禁止访问 (403 Forbidden)';
    case 404: return '未找到 (404 Not Found)';
    case 405: return '方法不允许 (405 Method Not Allowed)';
    case 408: return '请求超时 (408 Request Timeout)';
    case 409: return '冲突 (409 Conflict)';
    case 422: return '不可处理的实体 (422 Unprocessable Entity)';
    case 429: return '请求过多 (429 Too Many Requests)';
    case 500: return '服务器内部错误 (500 Internal Server Error)';
    case 502: return '网关错误 (502 Bad Gateway)';
    case 503: return '服务不可用 (503 Service Unavailable)';
    case 504: return '网关超时 (504 Gateway Timeout)';
    default:
      if (code >= 400 && code < 500) return '客户端错误 ($code)';
      if (code >= 500) return '服务器错误 ($code)';
      return '未知错误 ($code)';
  }
}

/// Show an error dialog with the HTTP status code message.
/// Uses the global [navigatorKey] so it can be called from outside widgets.
void showHttpErrorDialog(int statusCode, {String? extra}) {
  final ctx = navigatorKey.currentContext;
  if (ctx == null) return;
  showDialog(
    context: ctx,
    builder: (context) => AlertDialog(
      title: const Text('请求失败'),
      content: Text(
        extra != null ? '${httpStatusMessage(statusCode)}\n\n$extra' : httpStatusMessage(statusCode),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('确定')),
      ],
    ),
  );
}

/// Show a simple message dialog (used for token expiry etc.).
void showMessageDialog(String title, String message) {
  final ctx = navigatorKey.currentContext;
  if (ctx == null) return;
  showDialog(
    context: ctx,
    builder: (context) => AlertDialog(
      title: Text(title),
      content: Text(message),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('确定')),
      ],
    ),
  );
}
