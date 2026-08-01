import 'package:dio/dio.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../pos/data/models/invoice_model.dart';
import '../models/customer_model.dart';

class CustomerRemoteDataSource {
  const CustomerRemoteDataSource(this._dio);
  final Dio _dio;

  Future<CustomerModel> createCustomer(Map<String, dynamic> payload) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>('/customers', data: payload);
      return CustomerModel.fromJson(response.data!);
    } on DioException catch (e) {
      throw _mapError(e);
    }
  }

  Future<List<CustomerModel>> getCustomers({String? search}) async {
    try {
      final response = await _dio.get<List<dynamic>>(
        '/customers',
        queryParameters: {if (search != null && search.isNotEmpty) 'search': search},
      );
      return response.data!.map((e) => CustomerModel.fromJson(e as Map<String, dynamic>)).toList();
    } on DioException catch (e) {
      throw _mapError(e);
    }
  }

  Future<CustomerModel> getCustomer(String id) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>('/customers/$id');
      return CustomerModel.fromJson(response.data!);
    } on DioException catch (e) {
      throw _mapError(e);
    }
  }

  Future<CustomerModel> updateCustomer(String id, Map<String, dynamic> payload) async {
    try {
      final response = await _dio.patch<Map<String, dynamic>>('/customers/$id', data: payload);
      return CustomerModel.fromJson(response.data!);
    } on DioException catch (e) {
      throw _mapError(e);
    }
  }

  Future<void> deleteCustomer(String id) async {
    try {
      await _dio.delete<void>('/customers/$id');
    } on DioException catch (e) {
      throw _mapError(e);
    }
  }

  Future<CustomerModel> repayCredit(String customerId, double amount) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/customers/$customerId/repay-credit',
        data: {'amount': amount},
      );
      return CustomerModel.fromJson(response.data!);
    } on DioException catch (e) {
      throw _mapError(e);
    }
  }

  Future<List<InvoiceModel>> getPurchaseHistory(String customerId) async {
    try {
      final response = await _dio.get<List<dynamic>>('/customers/$customerId/purchases');
      return response.data!.map((e) => InvoiceModel.fromJson(e as Map<String, dynamic>)).toList();
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
