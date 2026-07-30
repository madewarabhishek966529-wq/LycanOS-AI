import 'package:dio/dio.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../core/network/api_endpoints.dart';
import '../models/auth_response_model.dart';
import '../models/user_model.dart';

/// Talks to `/auth/*` over Dio and translates HTTP/Dio failures into the
/// app's [ServerException]/[ValidationException]/[NetworkException] types.
/// Never throws a raw [DioException] out of this class — the repository
/// layer should only ever have to catch our own exception hierarchy.
class AuthRemoteDataSource {
  const AuthRemoteDataSource(this._dio);
  final Dio _dio;

  Future<AuthResponseModel> register({
    required String email,
    required String password,
    required String fullName,
    required String businessName,
  }) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        ApiEndpoints.register,
        data: {
          'email': email,
          'password': password,
          'full_name': fullName,
          'business_name': businessName,
        },
      );
      return AuthResponseModel.fromJson(response.data!);
    } on DioException catch (e) {
      throw _mapError(e);
    }
  }

  Future<AuthResponseModel> login({required String email, required String password}) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        ApiEndpoints.login,
        data: {'email': email, 'password': password},
      );
      return AuthResponseModel.fromJson(response.data!);
    } on DioException catch (e) {
      throw _mapError(e);
    }
  }

  Future<UserModel> getCurrentUser() async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(ApiEndpoints.me);
      return UserModel.fromJson(response.data!);
    } on DioException catch (e) {
      throw _mapError(e);
    }
  }

  Future<void> forgotPassword({required String email}) async {
    try {
      await _dio.post<void>(ApiEndpoints.forgotPassword, data: {'email': email});
    } on DioException catch (e) {
      throw _mapError(e);
    }
  }

  Future<void> resetPassword({required String resetToken, required String newPassword}) async {
    try {
      await _dio.post<void>(
        ApiEndpoints.resetPassword,
        data: {'reset_token': resetToken, 'new_password': newPassword},
      );
    } on DioException catch (e) {
      throw _mapError(e);
    }
  }

  Exception _mapError(DioException e) {
    if (e.type == DioExceptionType.connectionError ||
        e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout) {
      return const NetworkException();
    }

    final statusCode = e.response?.statusCode;
    final data = e.response?.data;
    final detail = data is Map<String, dynamic> ? data['detail'] : null;

    if (statusCode == 422 && detail is List) {
      // FastAPI/Pydantic validation error format: a list of {loc, msg, ...}.
      final fieldErrors = <String, String>{};
      for (final item in detail) {
        if (item is Map<String, dynamic>) {
          final loc = (item['loc'] as List?)?.last?.toString() ?? 'field';
          fieldErrors[loc] = item['msg']?.toString() ?? 'Invalid value';
        }
      }
      return ValidationException('Please check the highlighted fields', fieldErrors: fieldErrors);
    }

    if (statusCode == 401 || statusCode == 403) {
      return AuthException(detail?.toString() ?? 'Authentication failed');
    }

    return ServerException(detail?.toString() ?? 'Something went wrong', statusCode: statusCode);
  }
}
