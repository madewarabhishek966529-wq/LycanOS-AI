import '../../../../core/errors/exceptions.dart';
import '../../../../core/errors/failures.dart';
import '../../../pos/domain/entities/invoice_entity.dart';
import '../../domain/entities/customer_entity.dart';
import '../../domain/repositories/customer_repository.dart';
import '../datasources/customer_remote_datasource.dart';

class CustomerRepositoryImpl implements CustomerRepository {
  const CustomerRepositoryImpl(this._remote);
  final CustomerRemoteDataSource _remote;

  @override
  Future<Result<CustomerEntity>> createCustomer({
    required String name,
    String? phone,
    String? email,
    String? address,
    String? notes,
  }) async {
    try {
      final payload = {
        'name': name,
        if (phone != null) 'phone': phone,
        if (email != null) 'email': email,
        if (address != null) 'address': address,
        if (notes != null) 'notes': notes,
      };
      return Success(await _remote.createCustomer(payload));
    } on Exception catch (e) {
      return Error(_mapException(e));
    }
  }

  @override
  Future<Result<List<CustomerEntity>>> getCustomers({String? search}) async {
    try {
      return Success(await _remote.getCustomers(search: search));
    } on Exception catch (e) {
      return Error(_mapException(e));
    }
  }

  @override
  Future<Result<CustomerEntity>> getCustomer(String id) async {
    try {
      return Success(await _remote.getCustomer(id));
    } on Exception catch (e) {
      return Error(_mapException(e));
    }
  }

  @override
  Future<Result<CustomerEntity>> updateCustomer({
    required String id,
    String? name,
    String? phone,
    String? email,
    String? address,
    String? notes,
  }) async {
    try {
      final payload = {
        if (name != null) 'name': name,
        if (phone != null) 'phone': phone,
        if (email != null) 'email': email,
        if (address != null) 'address': address,
        if (notes != null) 'notes': notes,
      };
      return Success(await _remote.updateCustomer(id, payload));
    } on Exception catch (e) {
      return Error(_mapException(e));
    }
  }

  @override
  Future<Result<void>> deleteCustomer(String id) async {
    try {
      await _remote.deleteCustomer(id);
      return const Success(null);
    } on Exception catch (e) {
      return Error(_mapException(e));
    }
  }

  @override
  Future<Result<CustomerEntity>> repayCredit({required String customerId, required double amount}) async {
    try {
      return Success(await _remote.repayCredit(customerId, amount));
    } on Exception catch (e) {
      return Error(_mapException(e));
    }
  }

  @override
  Future<Result<List<InvoiceEntity>>> getPurchaseHistory(String customerId) async {
    try {
      return Success(await _remote.getPurchaseHistory(customerId));
    } on Exception catch (e) {
      return Error(_mapException(e));
    }
  }

  Failure _mapException(Exception e) {
    return switch (e) {
      NetworkException() => NetworkFailure(e.message),
      ValidationException(:final message, :final fieldErrors) =>
        ValidationFailure(message, fieldErrors: fieldErrors),
      AuthException(:final message) => AuthFailure(message),
      ServerException(:final message, :final statusCode) => ServerFailure(message, statusCode: statusCode),
      _ => UnknownFailure(e.toString()),
    };
  }
}
