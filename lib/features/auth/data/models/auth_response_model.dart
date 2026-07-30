import 'user_model.dart';

/// Matches the backend's `AuthResponse` schema: `{ user: {...}, tokens: {...} }`.
class AuthResponseModel {
  const AuthResponseModel({required this.user, required this.accessToken, required this.refreshToken});

  final UserModel user;
  final String accessToken;
  final String refreshToken;

  factory AuthResponseModel.fromJson(Map<String, dynamic> json) {
    final tokens = json['tokens'] as Map<String, dynamic>;
    return AuthResponseModel(
      user: UserModel.fromJson(json['user'] as Map<String, dynamic>),
      accessToken: tokens['access_token'] as String,
      refreshToken: tokens['refresh_token'] as String,
    );
  }
}
