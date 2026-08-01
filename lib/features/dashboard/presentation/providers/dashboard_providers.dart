import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/errors/failures.dart';
import '../../data/datasources/dashboard_remote_datasource.dart';
import '../../data/repositories/dashboard_repository_impl.dart';
import '../../domain/repositories/dashboard_repository.dart';

final dashboardRemoteDataSourceProvider = Provider<DashboardRemoteDataSource>((ref) {
  return DashboardRemoteDataSource(ref.watch(dioClientProvider).client);
});

final dashboardRepositoryProvider = Provider<DashboardRepository>((ref) {
  return DashboardRepositoryImpl(ref.watch(dashboardRemoteDataSourceProvider));
});

final dashboardSummaryProvider = FutureProvider.autoDispose((ref) async {
  final result = await ref.watch(dashboardRepositoryProvider).getSummary();
  return switch (result) {
    Success(:final data) => data,
    Error(:final failure) => throw failure,
  };
});

final revenueSeriesProvider = FutureProvider.autoDispose((ref) async {
  final result = await ref.watch(dashboardRepositoryProvider).getRevenueSeries(days: 7);
  return switch (result) {
    Success(:final data) => data,
    Error(:final failure) => throw failure,
  };
});
