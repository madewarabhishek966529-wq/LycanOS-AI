import '../../../../core/errors/failures.dart';
import '../entities/employee_entity.dart';

abstract class EmployeeRepository {
  Future<Result<EmployeeEntity>> createEmployee({
    required String email,
    required String password,
    required String fullName,
    required String role,
    String? phone,
    double? salary,
    DateTime? hireDate,
    String? notes,
  });

  Future<Result<List<EmployeeEntity>>> getEmployees();

  Future<Result<EmployeeEntity>> getEmployee(String id);

  Future<Result<EmployeeEntity>> updateEmployee({
    required String id,
    String? fullName,
    String? role,
    bool? isActive,
    String? phone,
    double? salary,
    DateTime? hireDate,
    String? notes,
  });

  Future<Result<AttendanceEntity>> checkIn();

  Future<Result<AttendanceEntity>> checkOut();

  Future<Result<List<AttendanceEntity>>> getAttendanceHistory(String employeeId, {int sinceDays = 30});

  Future<Result<List<SalesPerformanceEntity>>> getSalesPerformance({int sinceDays = 30});

  Future<Result<List<ActivityLogEntryEntity>>> getActivityLog({int limit = 100});
}
