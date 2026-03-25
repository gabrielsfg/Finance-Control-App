import 'dart:async';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:dio/io.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../config/app_config.dart';
import '../storage/token_storage.dart';
import '../../features/auth/providers/auth_provider.dart';
import 'api_endpoints.dart';

final apiClientProvider = Provider<ApiClient>((ref) {
  final storage = ref.read(tokenStorageProvider);
  return ApiClient(
    storage,
    onUnauthorized: () => ref.read(authNotifierProvider.notifier).logout(),
  );
});

class ApiClient {
  ApiClient(TokenStorage storage, {required Future<void> Function() onUnauthorized}) {
    _dio = Dio(
      BaseOptions(
        baseUrl: ApiEndpoints.baseUrl,
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 30),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    // Allow self-signed certificates on local dev only.
    if (AppConfig.allowBadCertificate) {
      (_dio.httpClientAdapter as IOHttpClientAdapter).createHttpClient = () {
        final client = HttpClient();
        client.badCertificateCallback = (cert, host, port) => true;
        return client;
      };
    }

    _dio.interceptors.addAll([
      _AuthInterceptor(_dio, storage, onUnauthorized: onUnauthorized),
      if (AppConfig.allowBadCertificate)
        LogInterceptor(requestBody: true, responseBody: true),
    ]);
  }

  late final Dio _dio;

  Dio get dio => _dio;
}

class _AuthInterceptor extends Interceptor {
  _AuthInterceptor(this._dio, this._storage, {required this.onUnauthorized});

  final Dio _dio;
  final TokenStorage _storage;
  final Future<void> Function() onUnauthorized;

  bool _isRefreshing = false;
  Completer<String?>? _refreshCompleter;

  // Separate Dio instance for refresh calls — no _AuthInterceptor to avoid recursion.
  late final Dio _refreshDio = Dio(
    BaseOptions(
      baseUrl: ApiEndpoints.baseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 30),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    ),
  )..interceptors.add(
      LogInterceptor(requestBody: true, responseBody: true),
    );

  static const _skipRefreshPaths = {
    ApiEndpoints.refresh,
    ApiEndpoints.login,
  };

  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final token = await _storage.getAccessToken();
    if (token != null) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    if (err.response?.statusCode != 401) {
      handler.next(err);
      return;
    }

    final path = err.requestOptions.path;
    // Also check uri in case Dio stores the full URL in path.
    final uri = err.requestOptions.uri.path;
    final isSkipped = _skipRefreshPaths.any((p) => path == p || uri == p);
    if (isSkipped) {
      // 401 on /refresh or /login — clear session and redirect to login.
      await onUnauthorized();
      handler.next(err);
      return;
    }

    // ── Refresh flow ────────────────────────────────────────────────────────

    if (_isRefreshing) {
      // Another request already triggered a refresh — capture completer locally
      // before the finally block of the first request can null it out.
      final completer = _refreshCompleter;
      if (completer == null) {
        handler.next(err);
        return;
      }
      final newToken = await completer.future;
      if (newToken == null) {
        handler.next(err);
        return;
      }
      handler.resolve(await _retry(err.requestOptions, newToken));
      return;
    }

    _isRefreshing = true;
    final completer = Completer<String?>();
    _refreshCompleter = completer;

    try {
      final refreshToken = await _storage.getRefreshToken();
      if (refreshToken == null) {
        completer.complete(null);
        await onUnauthorized();
        handler.next(err);
        return;
      }

      final response = await _refreshDio.post(
        ApiEndpoints.refresh,
        data: {'refreshToken': refreshToken},
      );

      final newAccessToken = response.data['accessToken'] as String;
      final newRefreshToken = response.data['refreshToken'] as String;
      await _storage.saveTokens(
        accessToken: newAccessToken,
        refreshToken: newRefreshToken,
      );

      completer.complete(newAccessToken);
      handler.resolve(await _retry(err.requestOptions, newAccessToken));
    } on DioException catch (refreshErr) {
      completer.complete(null);
      // Any 4xx from /refresh means the refresh token is invalid/expired.
      final status = refreshErr.response?.statusCode;
      if (status != null && status >= 400 && status < 500) {
        await onUnauthorized();
      }
      handler.next(err);
    } finally {
      _isRefreshing = false;
      _refreshCompleter = null;
    }
  }

  Future<Response<dynamic>> _retry(
    RequestOptions options,
    String accessToken,
  ) {
    return _dio.request<dynamic>(
      options.path,
      data: options.data,
      queryParameters: options.queryParameters,
      options: Options(
        method: options.method,
        headers: {
          ...options.headers,
          'Authorization': 'Bearer $accessToken',
        },
      ),
    );
  }
}
