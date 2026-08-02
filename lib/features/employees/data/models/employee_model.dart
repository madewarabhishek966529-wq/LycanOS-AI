import '../../domain/entities/employee_entity.dart';

class EmployeeModel extends EmployeeEntity {
  const EmployeeModel({
    required super.id,
    required super.email,
    required super.fullName,
    required super.role,
    required super.isActive,
    super.phone,
    super.salary,
    super.hireDate,
    super.notes,
    required super.createdAt,
  });

  factory EmployeeModel.fromJson(Map<String, dynamic> json) {
    return EmployeeModel(
      id: json['id'] as String,
      email: json['email'] as String,
      fullName: json['full_name'] as String,
      role: json['role'] as String,
      isActive: json['is_active'] as bool,
      phone: json['phone'] as String?,
      salary: json['salary'] != null ? double.parse(json['salary'].toString()) : null,
      hireDate: json['hire_date'] != null ? DateTime.parse(json['hire_date'] as String) : null,
      notes: json['notes'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
}

class AttendanceModel extends AttendanceEntity {
  const AttendanceModel({
    required super.id,
    required super.userId,
    required super.date,
    super.checkInAt,
    super.checkOutAt,
    required super.status,
  });

  factory AttendanceModel.fromJson(Map<String, dynamic> json) {
    return AttendanceModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      date: DateTime.parse(json['date'] as String),
      checkInAt: json['check_in_at'] != null ? DateTime.parse(json['check_in_at'] as String) : null,
      checkOutAt: json['check_out_at'] != null ? DateTime.parse(json['check_out_at'] as String) : null,
      status: json['status'] as String,
    );
  }
}

class SalesPerformanceModel extends SalesPerformanceEntity {
  const SalesPerformanceModel({
    required super.employeeId,
    required super.employeeName,
    required super.invoiceCount,
    required super.totalSales,
  });

  factory SalesPerformanceModel.fromJson(Map<String, dynamic> json) {
    return SalesPerformanceModel(
      employeeId: json['employee_id'] as String,
      employeeName: json['employee_name'] as String,
      invoiceCount: json['invoice_count'] as int,
      totalSales: double.parse(json['total_sales'].toString()),
    );
  }
}

class ActivityLogEntryModel extends ActivityLogEntryEntity {
  const ActivityLogEntryModel({
    required super.id,
    required super.actorUserId,
    required super.action,
    required super.description,
    required super.createdAt,
  });

  factory ActivityLogEntryModel.fromJson(Map<String, dynamic> json) {
    return ActivityLogEntryModel(
      id: json['id'] as String,
      actorUserId: json['actor_user_id'] as String,
      action: json['action'] as String,
      description: json['description'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
}
