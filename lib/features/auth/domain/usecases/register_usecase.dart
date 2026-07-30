import '../../../../core/errors/failures.dart';
import '../entities/user_entity.dart';
import '../repositories/auth_repository.dart';

class RegisterUseCase {
  const RegisterUseCase(this._repository);
  final AuthRepository _repository;

  Future<Result<UserEntity>> call({
    required String email,
    required String password,
    required String fullName,
    required String businessName,
  }) {
    return _repository.register(
      email: email,
      password: password,
      fullName: fullName,
      businessName: businessName,
    );
  }
}
