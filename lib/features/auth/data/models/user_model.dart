import '../../domain/entities/user_entity.dart';

/// Data-layer representation of a user, matching the backend's
/// `UserResponse` schema (see backend/app/schemas/auth.py) exactly.
/// Converts to/from JSON and up-casts cleanly to [UserEntity] for the
/// domain/presentation layers.
class UserModel extends UserEntity {
  const UserModel({
    required super.id,
    required super.email,
    required super.fullName,
    required super.role,
    required super.businessId,
    required super.isActive,
    required super.createdAt,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as String,
      email: json['email'] as String,
      fullName: json['full_name'] as String,
      role: json['role'] as String,
      businessId: json['business_id'] as String,
      isActive: json['is_active'] as bool,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'full_name': fullName,
      'role': role,
      'business_id': businessId,
      'is_active': isActive,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
