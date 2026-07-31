import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/errors/failures.dart';
import '../../domain/entities/product_entity.dart';
import '../../domain/repositories/inventory_repository.dart';
import 'inventory_providers.dart';

class ProductListState {
  const ProductListState({
    this.products = const [],
    this.isLoading = false,
    this.errorMessage,
    this.searchQuery = '',
    this.lowStockOnly = false,
  });

  final List<ProductEntity> products;
  final bool isLoading;
  final String? errorMessage;
  final String searchQuery;
  final bool lowStockOnly;

  ProductListState copyWith({
    List<ProductEntity>? products,
    bool? isLoading,
    String? errorMessage,
    bool clearError = false,
    String? searchQuery,
    bool? lowStockOnly,
  }) {
    return ProductListState(
      products: products ?? this.products,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      searchQuery: searchQuery ?? this.searchQuery,
      lowStockOnly: lowStockOnly ?? this.lowStockOnly,
    );
  }
}

class ProductListNotifier extends StateNotifier<ProductListState> {
  ProductListNotifier(this._repository) : super(const ProductListState()) {
    loadProducts();
  }

  final InventoryRepository _repository;

  Future<void> loadProducts() async {
    state = state.copyWith(isLoading: true, clearError: true);
    final result = await _repository.getProducts(
      search: state.searchQuery.isEmpty ? null : state.searchQuery,
      lowStockOnly: state.lowStockOnly,
    );

    switch (result) {
      case Success(:final data):
        state = state.copyWith(products: data, isLoading: false);
      case Error(:final failure):
        state = state.copyWith(isLoading: false, errorMessage: failure.message);
    }
  }

  void setSearchQuery(String query) {
    state = state.copyWith(searchQuery: query);
    loadProducts();
  }

  void toggleLowStockOnly() {
    state = state.copyWith(lowStockOnly: !state.lowStockOnly);
    loadProducts();
  }

  Future<bool> adjustStock({required String productId, required int delta, required String reason}) async {
    final result = await _repository.adjustStock(productId: productId, delta: delta, reason: reason);
    switch (result) {
      case Success(:final data):
        state = state.copyWith(
          products: [for (final p in state.products) if (p.id == data.id) data else p],
        );
        return true;
      case Error(:final failure):
        state = state.copyWith(errorMessage: failure.message);
        return false;
    }
  }

  Future<bool> deleteProduct(String productId) async {
    final result = await _repository.deleteProduct(productId);
    switch (result) {
      case Success():
        state = state.copyWith(products: state.products.where((p) => p.id != productId).toList());
        return true;
      case Error(:final failure):
        state = state.copyWith(errorMessage: failure.message);
        return false;
    }
  }

  void clearError() => state = state.copyWith(clearError: true);
}

final productListProvider = StateNotifierProvider.autoDispose<ProductListNotifier, ProductListState>((ref) {
  return ProductListNotifier(ref.watch(inventoryRepositoryProvider));
});
