import 'package:dio/dio.dart';
import '../../../../core/errors/exceptions.dart';
import '../models/employee_model.dart';

class EmployeeRemoteDataSource {
  const EmployeeRemoteDataSource(this._dio);
  final Dio _dio;

  Future<EmployeeModel> createEmployee(Map<String, dynamic> payload) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>('/employees', data: payload);
      return EmployeeModel.fromJson(response.data!);
    } on DioException catch (e) {
      throw _mapError(e);
    }
  }

  Future<List<EmployeeModel>> getEmployees() async {
    try {
      final response = await _dio.get<List<dynamic>>('/employees');
      return response.data!.map((e) => EmployeeModel.fromJson(e as Map<String, dynamic>)).toList();
    } on DioException catch (e) {
      throw _mapError(e);
    }
  }

  Future<EmployeeModel> getEmployee(String id) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>('/employees/$id');
      return EmployeeModel.fromJson(response.data!);
    } on DioException catch (e) {
      throw _mapError(e);
    }
  }

  Future<EmployeeModel> updateEmployee(String id, Map<String, dynamic> payload) async {
    try {
      final response = await _dio.patch<Map<String, dynamic>>('/employees/$id', data: payload);
      return EmployeeModel.fromJson(response.data!);
    } on DioException catch (e) {
      throw _mapError(e);
    }
  }

  Future<AttendanceModel> checkIn() async {
    try {
      final response = await _dio.post<Map<String, dynamic>>('/employees/attendance/check-in');
      return AttendanceModel.fromJson(response.data!);
    } on DioException catch (e) {
      throw _mapError(e);
    }
  }

  Future<AttendanceModel> checkOut() async {
    try {
      final response = await _dio.post<Map<String, dynamic>>('/employees/attendance/check-out');
      return AttendanceModel.fromJson(response.data!);
    } on DioException catch (e) {
      throw _mapError(e);
    }
  }

  Future<List<AttendanceModel>> getAttendanceHistory(String employeeId, {int sinceDays = 30}) async {
    try {
      final response = await _dio.get<List<dynamic>>(
        '/employees/$employeeId/attendance',
        queryParameters: {'since_days': sinceDays},
      );
      return response.data!.map((e) => AttendanceModel.fromJson(e as Map<String, dynamic>)).toList();
    } on DioException catch (e) {
      throw _mapError(e);
    }
  }

  Future<List<SalesPerformanceModel>> getSalesPerformance({int sinceDays = 30}) async {
    try {
      final response = await _dio.get<List<dynamic>>(
        '/employees/performance',
        queryParameters: {'since_days': sinceDays},
      );
      return response.data!.map((e) => SalesPerformanceModel.fromJson(e as Map<String, dynamic>)).toList();
    } on DioException catch (e) {
      throw _mapError(e);
    }
  }

  Future<List<ActivityLogEntryModel>> getActivityLog({int limit = 100}) async {
    try {
      final response = await _dio.get<List<dynamic>>('/employees/activity-log', queryParameters: {'limit': limit});
      return response.data!.map((e) => ActivityLogEntryModel.fromJson(e as Map<String, dynamic>)).toList();
    } on DioException catch (e) {
      throw _mapError(e);
    }
  }

  Exception _mapError(DioException e) {
    if (e.type == DioExceptionType.connectionError ||
        e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout) {
      return const NetworkException();
    }
    final statusCode = e.response?.statusCode;
    final data = e.response?.data;
    final detail = data is Map<String, dynamic> ? data['detail'] : null;

    if (statusCode == 422 && detail is List) {
      final fieldErrors = <String, String>{};
      for (final item in detail) {
        if (item is Map<String, dynamic>) {
          final loc = (item['loc'] as List?)?.last?.toString() ?? 'field';
          fieldErrors[loc] = item['msg']?.toString() ?? 'Invalid value';
        }
      }
      return ValidationException('Please check the highlighted fields', fieldErrors: fieldErrors);
    }
    if (statusCode == 401 || statusCode == 403) {
      return AuthException(detail?.toString() ?? 'Not authorized');
    }
    return ServerException(detail?.toString() ?? 'Something went wrong', statusCode: statusCode);
  }
}
