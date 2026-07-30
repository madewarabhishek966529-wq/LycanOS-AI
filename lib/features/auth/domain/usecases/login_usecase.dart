import '../../../../core/errors/failures.dart';
import '../entities/user_entity.dart';
import '../repositories/auth_repository.dart';

/// Callable use case: `await LoginUseCase(repo)(email: ..., password: ...)`.
///
/// For auth this is a thin pass-through today, but keeping it as a
/// separate use case (rather than calling `AuthRepository.login` directly
/// from the provider) means when Phase 7 adds e.g. "log failed login
/// attempts for security auditing", that rule lives here without touching
/// the repository or the provider.
class LoginUseCase {
  const LoginUseCase(this._repository);
  final AuthRepository _repository;

  Future<Result<UserEntity>> call({required String email, required String password}) {
    return _repository.login(email: email, password: password);
  }
}
