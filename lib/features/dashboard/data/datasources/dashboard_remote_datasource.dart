import 'package:dio/dio.dart';
import '../../../../core/errors/exceptions.dart';
import '../models/dashboard_summary_model.dart';

class DashboardRemoteDataSource {
  const DashboardRemoteDataSource(this._dio);
  final Dio _dio;

  Future<DashboardSummaryModel> getSummary({int bestSellersDays = 30}) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '/dashboard/summary',
        queryParameters: {'best_sellers_days': bestSellersDays},
      );
      return DashboardSummaryModel.fromJson(response.data!);
    } on DioException catch (e) {
      throw _mapError(e);
    }
  }

  Future<List<RevenuePointModel>> getRevenueSeries({int days = 7}) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '/dashboard/revenue-series',
        queryParameters: {'days': days},
      );
      return (response.data!['points'] as List)
          .map((e) => RevenuePointModel.fromJson(e as Map<String, dynamic>))
          .toList();
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

    if (statusCode == 401 || statusCode == 403) {
      return AuthException(detail?.toString() ?? 'Not authorized');
    }
    return ServerException(detail?.toString() ?? 'Something went wrong', statusCode: statusCode);
  }
}
