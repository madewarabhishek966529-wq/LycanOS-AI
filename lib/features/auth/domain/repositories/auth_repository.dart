import '../../../../core/errors/failures.dart';
import '../entities/user_entity.dart';

/// Domain-facing contract for authentication. `presentation` depends only
/// on this interface, never on [AuthRepositoryImpl] or Dio directly, so the
/// provider layer is trivially testable with a fake implementation.
abstract class AuthRepository {
  Future<Result<UserEntity>> register({
    required String email,
    required String password,
    required String fullName,
    required String businessName,
  });

  Future<Result<UserEntity>> login({
    required String email,
    required String password,
  });

  Future<Result<void>> forgotPassword({required String email});

  Future<Result<void>> resetPassword({
    required String resetToken,
    required String newPassword,
  });

  /// Restores a session from tokens already persisted on disk (app
  /// restart), returning null (not a [Failure]) if there's no session to
  /// restore — that's an expected, non-error state.
  Future<UserEntity?> restoreSession();

  Future<void> logout();
}
