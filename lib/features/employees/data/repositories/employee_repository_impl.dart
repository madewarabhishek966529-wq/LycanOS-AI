import '../../../../core/errors/exceptions.dart';
import '../../../../core/errors/failures.dart';
import '../../domain/entities/employee_entity.dart';
import '../../domain/repositories/employee_repository.dart';
import '../datasources/employee_remote_datasource.dart';

class EmployeeRepositoryImpl implements EmployeeRepository {
  const EmployeeRepositoryImpl(this._remote);
  final EmployeeRemoteDataSource _remote;

  String _formatDate(DateTime date) {
    return '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  @override
  Future<Result<EmployeeEntity>> createEmployee({
    required String email,
    required String password,
    required String fullName,
    required String role,
    String? phone,
    double? salary,
    DateTime? hireDate,
    String? notes,
  }) async {
    try {
      final payload = {
        'email': email,
        'password': password,
        'full_name': fullName,
        'role': role,
        if (phone != null) 'phone': phone,
        if (salary != null) 'salary': salary,
        if (hireDate != null) 'hire_date': _formatDate(hireDate),
        if (notes != null) 'notes': notes,
      };
      return Success(await _remote.createEmployee(payload));
    } on Exception catch (e) {
      return Error(_mapException(e));
    }
  }

  @override
  Future<Result<List<EmployeeEntity>>> getEmployees() async {
    try {
      return Success(await _remote.getEmployees());
    } on Exception catch (e) {
      return Error(_mapException(e));
    }
  }

  @override
  Future<Result<EmployeeEntity>> getEmployee(String id) async {
    try {
      return Success(await _remote.getEmployee(id));
    } on Exception catch (e) {
      return Error(_mapException(e));
    }
  }

  @override
  Future<Result<EmployeeEntity>> updateEmployee({
    required String id,
    String? fullName,
    String? role,
    bool? isActive,
    String? phone,
    double? salary,
    DateTime? hireDate,
    String? notes,
  }) async {
    try {
      final payload = {
        if (fullName != null) 'full_name': fullName,
        if (role != null) 'role': role,
        if (isActive != null) 'is_active': isActive,
        if (phone != null) 'phone': phone,
        if (salary != null) 'salary': salary,
        if (hireDate != null) 'hire_date': _formatDate(hireDate),
        if (notes != null) 'notes': notes,
      };
      return Success(await _remote.updateEmployee(id, payload));
    } on Exception catch (e) {
      return Error(_mapException(e));
    }
  }

  @override
  Future<Result<AttendanceEntity>> checkIn() async {
    try {
      return Success(await _remote.checkIn());
    } on Exception catch (e) {
      return Error(_mapException(e));
    }
  }

  @override
  Future<Result<AttendanceEntity>> checkOut() async {
    try {
      return Success(await _remote.checkOut());
    } on Exception catch (e) {
      return Error(_mapException(e));
    }
  }

  @override
  Future<Result<List<AttendanceEntity>>> getAttendanceHistory(String employeeId, {int sinceDays = 30}) async {
    try {
      return Success(await _remote.getAttendanceHistory(employeeId, sinceDays: sinceDays));
    } on Exception catch (e) {
      return Error(_mapException(e));
    }
  }

  @override
  Future<Result<List<SalesPerformanceEntity>>> getSalesPerformance({int sinceDays = 30}) async {
    try {
      return Success(await _remote.getSalesPerformance(sinceDays: sinceDays));
    } on Exception catch (e) {
      return Error(_mapException(e));
    }
  }

  @override
  Future<Result<List<ActivityLogEntryEntity>>> getActivityLog({int limit = 100}) async {
    try {
      return Success(await _remote.getActivityLog(limit: limit));
    } on Exception catch (e) {
      return Error(_mapException(e));
    }
  }

  Failure _mapException(Exception e) {
    return switch (e) {
      NetworkException() => NetworkFailure(e.message),
      ValidationException(:final message, :final fieldErrors) =>
        ValidationFailure(message, fieldErrors: fieldErrors),
      AuthException(:final message) => AuthFailure(message),
      ServerException(:final message, :final statusCode) => ServerFailure(message, statusCode: statusCode),
      _ => UnknownFailure(e.toString()),
    };
  }
}
