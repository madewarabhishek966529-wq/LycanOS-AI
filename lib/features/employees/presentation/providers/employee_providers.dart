import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/errors/failures.dart';
import '../../data/datasources/employee_remote_datasource.dart';
import '../../data/repositories/employee_repository_impl.dart';
import '../../domain/entities/employee_entity.dart';
import '../../domain/repositories/employee_repository.dart';

final employeeRemoteDataSourceProvider = Provider<EmployeeRemoteDataSource>((ref) {
  return EmployeeRemoteDataSource(ref.watch(dioClientProvider).client);
});

final employeeRepositoryProvider = Provider<EmployeeRepository>((ref) {
  return EmployeeRepositoryImpl(ref.watch(employeeRemoteDataSourceProvider));
});

class EmployeeListState {
  const EmployeeListState({this.employees = const [], this.isLoading = false, this.errorMessage});

  final List<EmployeeEntity> employees;
  final bool isLoading;
  final String? errorMessage;

  EmployeeListState copyWith({List<EmployeeEntity>? employees, bool? isLoading, String? errorMessage, bool clearError = false}) {
    return EmployeeListState(
      employees: employees ?? this.employees,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

class EmployeeListNotifier extends StateNotifier<EmployeeListState> {
  EmployeeListNotifier(this._repository) : super(const EmployeeListState()) {
    loadEmployees();
  }

  final EmployeeRepository _repository;

  Future<void> loadEmployees() async {
    state = state.copyWith(isLoading: true, clearError: true);
    final result = await _repository.getEmployees();
    switch (result) {
      case Success(:final data):
        state = state.copyWith(employees: data, isLoading: false);
      case Error(:final failure):
        state = state.copyWith(isLoading: false, errorMessage: failure.message);
    }
  }
}

final employeeListProvider = StateNotifierProvider.autoDispose<EmployeeListNotifier, EmployeeListState>((ref) {
  return EmployeeListNotifier(ref.watch(employeeRepositoryProvider));
});

final salesPerformanceProvider = FutureProvider.autoDispose((ref) async {
  final result = await ref.watch(employeeRepositoryProvider).getSalesPerformance();
  return switch (result) {
    Success(:final data) => data,
    Error(:final failure) => throw failure,
  };
});
