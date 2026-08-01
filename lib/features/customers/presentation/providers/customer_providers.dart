import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/errors/failures.dart';
import '../../data/datasources/customer_remote_datasource.dart';
import '../../data/repositories/customer_repository_impl.dart';
import '../../domain/entities/customer_entity.dart';
import '../../domain/repositories/customer_repository.dart';

final customerRemoteDataSourceProvider = Provider<CustomerRemoteDataSource>((ref) {
  return CustomerRemoteDataSource(ref.watch(dioClientProvider).client);
});

final customerRepositoryProvider = Provider<CustomerRepository>((ref) {
  return CustomerRepositoryImpl(ref.watch(customerRemoteDataSourceProvider));
});

class CustomerListState {
  const CustomerListState({this.customers = const [], this.isLoading = false, this.errorMessage, this.searchQuery = ''});

  final List<CustomerEntity> customers;
  final bool isLoading;
  final String? errorMessage;
  final String searchQuery;

  CustomerListState copyWith({
    List<CustomerEntity>? customers,
    bool? isLoading,
    String? errorMessage,
    bool clearError = false,
    String? searchQuery,
  }) {
    return CustomerListState(
      customers: customers ?? this.customers,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      searchQuery: searchQuery ?? this.searchQuery,
    );
  }
}

class CustomerListNotifier extends StateNotifier<CustomerListState> {
  CustomerListNotifier(this._repository) : super(const CustomerListState()) {
    loadCustomers();
  }

  final CustomerRepository _repository;

  Future<void> loadCustomers() async {
    state = state.copyWith(isLoading: true, clearError: true);
    final result = await _repository.getCustomers(search: state.searchQuery.isEmpty ? null : state.searchQuery);
    switch (result) {
      case Success(:final data):
        state = state.copyWith(customers: data, isLoading: false);
      case Error(:final failure):
        state = state.copyWith(isLoading: false, errorMessage: failure.message);
    }
  }

  void setSearchQuery(String query) {
    state = state.copyWith(searchQuery: query);
    loadCustomers();
  }

  Future<bool> deleteCustomer(String id) async {
    final result = await _repository.deleteCustomer(id);
    switch (result) {
      case Success():
        state = state.copyWith(customers: state.customers.where((c) => c.id != id).toList());
        return true;
      case Error(:final failure):
        state = state.copyWith(errorMessage: failure.message);
        return false;
    }
  }
}

final customerListProvider = StateNotifierProvider.autoDispose<CustomerListNotifier, CustomerListState>((ref) {
  return CustomerListNotifier(ref.watch(customerRepositoryProvider));
});
