import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/errors/failures.dart';
import '../../data/datasources/inventory_remote_datasource.dart';
import '../../data/repositories/inventory_repository_impl.dart';
import '../../domain/repositories/inventory_repository.dart';

final inventoryRemoteDataSourceProvider = Provider<InventoryRemoteDataSource>((ref) {
  return InventoryRemoteDataSource(ref.watch(dioClientProvider).client);
});

final inventoryRepositoryProvider = Provider<InventoryRepository>((ref) {
  return InventoryRepositoryImpl(ref.watch(inventoryRemoteDataSourceProvider));
});

/// Categories and suppliers change rarely relative to products, so they're
/// exposed as simple `FutureProvider`s (auto-cached, re-fetch on
/// `ref.invalidate`) rather than needing their own StateNotifier.
final categoriesProvider = FutureProvider.autoDispose((ref) async {
  final result = await ref.watch(inventoryRepositoryProvider).getCategories();
  return switch (result) {
    Success(:final data) => data,
    Error(:final failure) => throw failure,
  };
});

final suppliersProvider = FutureProvider.autoDispose((ref) async {
  final result = await ref.watch(inventoryRepositoryProvider).getSuppliers();
  return switch (result) {
    Success(:final data) => data,
    Error(:final failure) => throw failure,
  };
});
