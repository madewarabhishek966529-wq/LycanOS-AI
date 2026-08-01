import '../../../../core/errors/failures.dart';
import '../../../pos/domain/entities/invoice_entity.dart';
import '../entities/customer_entity.dart';

abstract class CustomerRepository {
  Future<Result<CustomerEntity>> createCustomer({
    required String name,
    String? phone,
    String? email,
    String? address,
    String? notes,
  });

  Future<Result<List<CustomerEntity>>> getCustomers({String? search});

  Future<Result<CustomerEntity>> getCustomer(String id);

  Future<Result<CustomerEntity>> updateCustomer({
    required String id,
    String? name,
    String? phone,
    String? email,
    String? address,
    String? notes,
  });

  Future<Result<void>> deleteCustomer(String id);

  Future<Result<CustomerEntity>> repayCredit({required String customerId, required double amount});

  Future<Result<List<InvoiceEntity>>> getPurchaseHistory(String customerId);
}
