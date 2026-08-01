import 'package:dio/dio.dart';
import '../../../../core/errors/exceptions.dart';
import '../models/invoice_model.dart';

class PosRemoteDataSource {
  const PosRemoteDataSource(this._dio);
  final Dio _dio;

  Future<InvoiceModel> checkout(Map<String, dynamic> payload) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>('/pos/checkout', data: payload);
      return InvoiceModel.fromJson(response.data!);
    } on DioException catch (e) {
      throw _mapError(e);
    }
  }

  Future<InvoiceModel> getInvoice(String id) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>('/pos/invoices/$id');
      return InvoiceModel.fromJson(response.data!);
    } on DioException catch (e) {
      throw _mapError(e);
    }
  }

  Future<List<InvoiceModel>> listInvoices({int limit = 50, int offset = 0}) async {
    try {
      final response = await _dio.get<List<dynamic>>(
        '/pos/invoices',
        queryParameters: {'limit': limit, 'offset': offset},
      );
      return response.data!.map((e) => InvoiceModel.fromJson(e as Map<String, dynamic>)).toList();
    } on DioException catch (e) {
      throw _mapError(e);
    }
  }

  Future<List<int>> getReceiptBytes(String invoiceId) async {
    try {
      final response = await _dio.get<List<int>>(
        '/pos/invoices/$invoiceId/receipt',
        options: Options(responseType: ResponseType.bytes),
      );
      return response.data!;
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
