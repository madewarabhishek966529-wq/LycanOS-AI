import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/errors/failures.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/repositories/auth_repository.dart';
import 'auth_providers.dart';

/// Represents what the app shell / router / screens need to know about the
/// current session.
enum AuthStatus { unknown, authenticated, unauthenticated }

class AuthState {
  const AuthState({
    this.status = AuthStatus.unknown,
    this.user,
    this.isSubmitting = false,
    this.errorMessage,
  });

  final AuthStatus status;
  final UserEntity? user;
  final bool isSubmitting;
  final String? errorMessage;

  AuthState copyWith({
    AuthStatus? status,
    UserEntity? user,
    bool? isSubmitting,
    String? errorMessage,
    bool clearError = false,
  }) {
    return AuthState(
      status: status ?? this.status,
      user: user ?? this.user,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

/// Owns the session lifecycle: restoring it on launch, driving
/// login/register/logout, and exposing submit/error state so screens don't
/// need their own separate loading flags.
class AuthStateNotifier extends StateNotifier<AuthState> {
  AuthStateNotifier(this._repository) : super(const AuthState()) {
    _restoreSession();
  }

  final AuthRepository _repository;

  Future<void> _restoreSession() async {
    final user = await _repository.restoreSession();
    state = AuthState(
      status: user != null ? AuthStatus.authenticated : AuthStatus.unauthenticated,
      user: user,
    );
  }

  Future<bool> login({required String email, required String password}) async {
    state = state.copyWith(isSubmitting: true, clearError: true);
    final result = await _repository.login(email: email, password: password);

    switch (result) {
      case Success(:final data):
        state = AuthState(status: AuthStatus.authenticated, user: data);
        return true;
      case Error(:final failure):
        state = state.copyWith(isSubmitting: false, errorMessage: _messageFor(failure));
        return false;
    }
  }

  Future<bool> register({
    required String email,
    required String password,
    required String fullName,
    required String businessName,
  }) async {
    state = state.copyWith(isSubmitting: true, clearError: true);
    final result = await _repository.register(
      email: email,
      password: password,
      fullName: fullName,
      businessName: businessName,
    );

    switch (result) {
      case Success(:final data):
        state = AuthState(status: AuthStatus.authenticated, user: data);
        return true;
      case Error(:final failure):
        state = state.copyWith(isSubmitting: false, errorMessage: _messageFor(failure));
        return false;
    }
  }

  Future<void> signOut() async {
    await _repository.logout();
    state = const AuthState(status: AuthStatus.unauthenticated);
  }

  void clearError() => state = state.copyWith(clearError: true);

  String _messageFor(Failure failure) {
    // Validation failures carry field-level detail the form itself should
    // display inline; the banner/snackbar just needs the summary message.
    return failure.message;
  }
}

final authStateProvider = StateNotifierProvider<AuthStateNotifier, AuthState>((ref) {
  return AuthStateNotifier(ref.watch(authRepositoryProvider));
});
