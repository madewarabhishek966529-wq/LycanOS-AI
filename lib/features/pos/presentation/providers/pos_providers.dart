import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/di/injection.dart';
import '../../data/datasources/pos_remote_datasource.dart';
import '../../data/repositories/pos_repository_impl.dart';
import '../../domain/repositories/pos_repository.dart';

final posRemoteDataSourceProvider = Provider<PosRemoteDataSource>((ref) {
  return PosRemoteDataSource(ref.watch(dioClientProvider).client);
});

final posRepositoryProvider = Provider<PosRepository>((ref) {
  return PosRepositoryImpl(ref.watch(posRemoteDataSourceProvider));
});
