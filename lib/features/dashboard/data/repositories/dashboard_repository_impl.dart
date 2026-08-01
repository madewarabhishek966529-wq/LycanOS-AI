import '../../../../core/errors/exceptions.dart';
import '../../../../core/errors/failures.dart';
import '../../domain/entities/dashboard_summary_entity.dart';
import '../../domain/repositories/dashboard_repository.dart';
import '../datasources/dashboard_remote_datasource.dart';

class DashboardRepositoryImpl implements DashboardRepository {
  const DashboardRepositoryImpl(this._remote);
  final DashboardRemoteDataSource _remote;

  @override
  Future<Result<DashboardSummaryEntity>> getSummary({int bestSellersDays = 30}) async {
    try {
      return Success(await _remote.getSummary(bestSellersDays: bestSellersDays));
    } on Exception catch (e) {
      return Error(_mapException(e));
    }
  }

  @override
  Future<Result<List<RevenuePointEntity>>> getRevenueSeries({int days = 7}) async {
    try {
      return Success(await _remote.getRevenueSeries(days: days));
    } on Exception catch (e) {
      return Error(_mapException(e));
    }
  }

  Failure _mapException(Exception e) {
    return switch (e) {
      NetworkException() => NetworkFailure(e.message),
      AuthException(:final message) => AuthFailure(message),
      ServerException(:final message, :final statusCode) => ServerFailure(message, statusCode: statusCode),
      _ => UnknownFailure(e.toString()),
    };
  }
}
