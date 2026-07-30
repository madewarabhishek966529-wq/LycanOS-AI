import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../core/errors/failures.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_remote_datasource.dart';

class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl({
    required AuthRemoteDataSource remoteDataSource,
    required FlutterSecureStorage secureStorage,
  })  : _remote = remoteDataSource,
        _secureStorage = secureStorage;

  final AuthRemoteDataSource _remote;
  final FlutterSecureStorage _secureStorage;

  Future<void> _persistSession({
    required String accessToken,
    required String refreshToken,
    required String role,
  }) async {
    await Future.wait([
      _secureStorage.write(key: AppConstants.keyAccessToken, value: accessToken),
      _secureStorage.write(key: AppConstants.keyRefreshToken, value: refreshToken),
      _secureStorage.write(key: AppConstants.keyUserRole, value: role),
    ]);
  }

  @override
  Future<Result<UserEntity>> register({
    required String email,
    required String password,
    required String fullName,
    required String businessName,
  }) async {
    try {
      final result = await _remote.register(
        email: email,
        password: password,
        fullName: fullName,
        businessName: businessName,
      );
      await _persistSession(
        accessToken: result.accessToken,
        refreshToken: result.refreshToken,
        role: result.user.role,
      );
      return Success(result.user);
    } on Exception catch (e) {
      return Error(_mapException(e));
    }
  }

  @override
  Future<Result<UserEntity>> login({required String email, required String password}) async {
    try {
      final result = await _remote.login(email: email, password: password);
      await _persistSession(
        accessToken: result.accessToken,
        refreshToken: result.refreshToken,
        role: result.user.role,
      );
      return Success(result.user);
    } on Exception catch (e) {
      return Error(_mapException(e));
    }
  }

  @override
  Future<Result<void>> forgotPassword({required String email}) async {
    try {
      await _remote.forgotPassword(email: email);
      return const Success(null);
    } on Exception catch (e) {
      return Error(_mapException(e));
    }
  }

  @override
  Future<Result<void>> resetPassword({required String resetToken, required String newPassword}) async {
    try {
      await _remote.resetPassword(resetToken: resetToken, newPassword: newPassword);
      return const Success(null);
    } on Exception catch (e) {
      return Error(_mapException(e));
    }
  }

  @override
  Future<UserEntity?> restoreSession() async {
    final token = await _secureStorage.read(key: AppConstants.keyAccessToken);
    if (token == null) return null;

    try {
      return await _remote.getCurrentUser();
    } on Exception {
      // Token expired/invalid and DioClient's refresh interceptor couldn't
      // salvage it (no valid refresh token either) — treat as logged out
      // rather than surfacing an error on app launch.
      await logout();
      return null;
    }
  }

  @override
  Future<void> logout() async {
    await Future.wait([
      _secureStorage.delete(key: AppConstants.keyAccessToken),
      _secureStorage.delete(key: AppConstants.keyRefreshToken),
      _secureStorage.delete(key: AppConstants.keyUserRole),
    ]);
  }

  Failure _mapException(Exception e) {
    return switch (e) {
      NetworkException() => NetworkFailure(e.message),
      ValidationException(:final message, :final fieldErrors) =>
        ValidationFailure(message, fieldErrors: fieldErrors),
      AuthException(:final message) => AuthFailure(message),
      ServerException(:final message, :final statusCode) => ServerFailure(message, statusCode: statusCode),
      _ => UnknownFailure(e.toString()),
    };
  }
}
