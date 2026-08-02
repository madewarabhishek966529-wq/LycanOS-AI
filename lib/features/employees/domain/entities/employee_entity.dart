import 'package:equatable/equatable.dart';

class EmployeeEntity extends Equatable {
  const EmployeeEntity({
    required this.id,
    required this.email,
    required this.fullName,
    required this.role,
    required this.isActive,
    this.phone,
    this.salary,
    this.hireDate,
    this.notes,
    required this.createdAt,
  });

  final String id;
  final String email;
  final String fullName;
  final String role;
  final bool isActive;
  final String? phone;
  final double? salary;
  final DateTime? hireDate;
  final String? notes;
  final DateTime createdAt;

  bool get isOwner => role == 'owner';
  bool get isManager => role == 'manager';

  @override
  List<Object?> get props => [id, email, fullName, role, isActive];
}

class AttendanceEntity extends Equatable {
  const AttendanceEntity({
    required this.id,
    required this.userId,
    required this.date,
    this.checkInAt,
    this.checkOutAt,
    required this.status,
  });

  final String id;
  final String userId;
  final DateTime date;
  final DateTime? checkInAt;
  final DateTime? checkOutAt;
  final String status;

  bool get isCheckedIn => checkInAt != null && checkOutAt == null;
  bool get isComplete => checkInAt != null && checkOutAt != null;

  Duration? get hoursWorked {
    if (checkInAt == null || checkOutAt == null) return null;
    return checkOutAt!.difference(checkInAt!);
  }

  @override
  List<Object?> get props => [id, date, checkInAt, checkOutAt];
}

class SalesPerformanceEntity extends Equatable {
  const SalesPerformanceEntity({
    required this.employeeId,
    required this.employeeName,
    required this.invoiceCount,
    required this.totalSales,
  });

  final String employeeId;
  final String employeeName;
  final int invoiceCount;
  final double totalSales;

  @override
  List<Object?> get props => [employeeId, totalSales];
}

class ActivityLogEntryEntity extends Equatable {
  const ActivityLogEntryEntity({
    required this.id,
    required this.actorUserId,
    required this.action,
    required this.description,
    required this.createdAt,
  });

  final String id;
  final String actorUserId;
  final String action;
  final String description;
  final DateTime createdAt;

  @override
  List<Object?> get props => [id, createdAt];
}
