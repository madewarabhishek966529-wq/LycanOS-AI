import '../../../../core/errors/failures.dart';
import '../repositories/auth_repository.dart';

class ForgotPasswordUseCase {
  const ForgotPasswordUseCase(this._repository);
  final AuthRepository _repository;

  Future<Result<void>> call({required String email}) {
    return _repository.forgotPassword(email: email);
  }
}

class ResetPasswordUseCase {
  const ResetPasswordUseCase(this._repository);
  final AuthRepository _repository;

  Future<Result<void>> call({required String resetToken, required String newPassword}) {
    return _repository.resetPassword(resetToken: resetToken, newPassword: newPassword);
  }
}
