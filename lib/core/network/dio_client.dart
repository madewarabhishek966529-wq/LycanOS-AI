import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:logger/logger.dart';
import '../config/env_config.dart';
import '../constants/app_constants.dart';
import 'api_endpoints.dart';

/// Wraps a configured [Dio] instance with:
///  - base URL + timeouts from [EnvConfig]
///  - automatic bearer token attachment from secure storage
///  - single-flight refresh-token handling on 401 responses
///  - request/response logging (dev only)
class DioClient {
  DioClient({
    required FlutterSecureStorage secureStorage,
    Dio? dio,
  })  : _secureStorage = secureStorage,
        _dio = dio ?? Dio() {
    _configure();
  }

  final FlutterSecureStorage _secureStorage;
  final Dio _dio;
  final Logger _logger = Logger();

  bool _isRefreshing = false;
  final List<void Function()> _pendingRequests = [];

  Dio get client => _dio;

  void _configure() {
    _dio.options = BaseOptions(
      baseUrl: EnvConfig.apiBaseUrl,
      connectTimeout: AppConstants.connectTimeout,
      receiveTimeout: AppConstants.receiveTimeout,
      headers: {'Content-Type': 'application/json'},
    );

    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await _secureStorage.read(key: AppConstants.keyAccessToken);
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          return handler.next(options);
        },
        onError: (DioException error, handler) async {
          final isUnauthorized = error.response?.statusCode == 401;
          final isRefreshCall = error.requestOptions.path == ApiEndpoints.refreshToken;

          if (isUnauthorized && !isRefreshCall) {
            final refreshed = await _handleTokenRefresh();
            if (refreshed) {
              try {
                final clonedResponse = await _retry(error.requestOptions);
                return handler.resolve(clonedResponse);
              } catch (_) {
                // fall through to reject below
              }
            }
          }
          return handler.next(error);
        },
      ),
    );

    if (EnvConfig.enableLogging && EnvConfig.isDevelopment) {
      _dio.interceptors.add(
        LogInterceptor(
          requestBody: true,
          responseBody: true,
          logPrint: (obj) => _logger.d(obj),
        ),
      );
    }
  }

  Future<bool> _handleTokenRefresh() async {
    if (_isRefreshing) {
      // Wait for the in-flight refresh instead of firing a duplicate call.
      await Future<void>.delayed(const Duration(milliseconds: 300));
      return _secureStorage.read(key: AppConstants.keyAccessToken).then((t) => t != null);
    }

    _isRefreshing = true;
    try {
      final refreshToken = await _secureStorage.read(key: AppConstants.keyRefreshToken);
      if (refreshToken == null) return false;

      final response = await Dio(BaseOptions(baseUrl: EnvConfig.apiBaseUrl)).post<Map<String, dynamic>>(
        ApiEndpoints.refreshToken,
        data: {'refresh_token': refreshToken},
      );

      final newAccessToken = response.data?['access_token'] as String?;
      final newRefreshToken = response.data?['refresh_token'] as String?;

      if (newAccessToken == null) return false;

      await _secureStorage.write(key: AppConstants.keyAccessToken, value: newAccessToken);
      if (newRefreshToken != null) {
        await _secureStorage.write(key: AppConstants.keyRefreshToken, value: newRefreshToken);
      }
      return true;
    } catch (e) {
      _logger.e('Token refresh failed', error: e);
      return false;
    } finally {
      _isRefreshing = false;
    }
  }

  Future<Response<dynamic>> _retry(RequestOptions requestOptions) async {
    final token = await _secureStorage.read(key: AppConstants.keyAccessToken);
    final options = Options(method: requestOptions.method, headers: {
      ...requestOptions.headers,
      'Authorization': 'Bearer $token',
    });
    return _dio.request<dynamic>(
      requestOptions.path,
      data: requestOptions.data,
      queryParameters: requestOptions.queryParameters,
      options: options,
    );
  }
}
