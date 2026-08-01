import '../../../../core/errors/failures.dart';
import '../entities/dashboard_summary_entity.dart';

abstract class DashboardRepository {
  Future<Result<DashboardSummaryEntity>> getSummary({int bestSellersDays = 30});
  Future<Result<List<RevenuePointEntity>>> getRevenueSeries({int days = 7});
}
