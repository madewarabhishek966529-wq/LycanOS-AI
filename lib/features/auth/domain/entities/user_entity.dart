import 'package:equatable/equatable.dart';

/// Pure domain representation of the signed-in user. Deliberately has no
/// `fromJson`/`toJson` — that's [UserModel]'s job in the data layer, so the
/// domain layer stays independent of the API's wire format.
class UserEntity extends Equatable {
  const UserEntity({
    required this.id,
    required this.email,
    required this.fullName,
    required this.role,
    required this.businessId,
    required this.isActive,
    required this.createdAt,
  });

  final String id;
  final String email;
  final String fullName;
  final String role;
  final String businessId;
  final bool isActive;
  final DateTime createdAt;

  bool get isOwner => role == 'owner';
  bool get isManager => role == 'manager';
  bool get isCashier => role == 'cashier';
  bool get isEmployee => role == 'employee';

  /// Owner + Manager are the two roles allowed to see business-wide
  /// financials, manage staff, etc. Kept as a getter here so every screen
  /// checking this permission stays in sync if the rule ever changes.
  bool get canManageBusiness => isOwner || isManager;

  @override
  List<Object?> get props => [id, email, fullName, role, businessId, isActive, createdAt];
}
