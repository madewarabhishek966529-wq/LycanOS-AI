import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/di/injection.dart';

/// Represents what the app shell / router needs to know about the current
/// session. The real login/register/refresh flow (calling
/// [ApiEndpoints.login] etc. through a repository) is built in Phase 2 —
/// this Phase 1 stub only checks whether a token already exists on disk so
/// [AppRouter] has real redirect logic to build against from day one.
enum AuthStatus { unknown, authenticated, unauthenticated }

class AuthState {
  const AuthState({this.status = AuthStatus.unknown, this.role});
  final AuthStatus status;
  final String? role;

  AuthState copyWith({AuthStatus? status, String? role}) {
    return AuthState(status: status ?? this.status, role: role ?? this.role);
  }
}

class AuthStateNotifier extends StateNotifier<AuthState> {
  AuthStateNotifier(this._secureStorage) : super(const AuthState()) {
    _restoreSession();
  }

  final FlutterSecureStorage _secureStorage;

  Future<void> _restoreSession() async {
    final token = await _secureStorage.read(key: AppConstants.keyAccessToken);
    final role = await _secureStorage.read(key: AppConstants.keyUserRole);
    state = AuthState(
      status: token != null ? AuthStatus.authenticated : AuthStatus.unauthenticated,
      role: role,
    );
  }

  Future<void> signOut() async {
    await _secureStorage.delete(key: AppConstants.keyAccessToken);
    await _secureStorage.delete(key: AppConstants.keyRefreshToken);
    await _secureStorage.delete(key: AppConstants.keyUserRole);
    state = const AuthState(status: AuthStatus.unauthenticated);
  }
}

final authStateProvider = StateNotifierProvider<AuthStateNotifier, AuthState>((ref) {
  return AuthStateNotifier(ref.watch(secureStorageProvider));
});
