import 'package:dio/dio.dart';
import 'auth_service.dart';
import 'logger_service.dart';

class AuthInterceptor extends Interceptor {
  static const _tag = 'AuthInterceptor';

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    final token = await AuthService().getAccessToken();
    if (token != null) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    if (err.response?.statusCode == 401) {
      try {
        final newToken = await AuthService().refresh();
        err.requestOptions.headers['Authorization'] = 'Bearer $newToken';
        final resp = await Dio().fetch(err.requestOptions);
        return handler.resolve(resp);
      } catch (_) {
        LoggerService.w(_tag, 'Token refresh failed in AuthInterceptor');
      }
    }
    handler.next(err);
  }
}
