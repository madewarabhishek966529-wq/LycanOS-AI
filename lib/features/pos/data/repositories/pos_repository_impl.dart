import '../../../../core/errors/exceptions.dart';
import '../../../../core/errors/failures.dart';
import '../../domain/entities/cart_item_entity.dart';
import '../../domain/entities/invoice_entity.dart';
import '../../domain/repositories/pos_repository.dart';
import '../datasources/pos_remote_datasource.dart';

class PosRepositoryImpl implements PosRepository {
  const PosRepositoryImpl(this._remote);
  final PosRemoteDataSource _remote;

  @override
  Future<Result<InvoiceEntity>> checkout({
    required List<CartItemEntity> items,
    double invoiceDiscountAmount = 0,
    String? couponCode,
    String? paymentMethod,
    List<({String method, double amount})>? paymentSplits,
  }) async {
    try {
      final payload = {
        'items': items
            .map((item) => {
                  'product_id': item.productId,
                  'quantity': item.quantity,
                  'line_discount_amount': item.lineDiscountAmount,
                })
            .toList(),
        if (invoiceDiscountAmount > 0) 'invoice_discount_amount': invoiceDiscountAmount,
        if (couponCode != null && couponCode.isNotEmpty) 'coupon_code': couponCode,
        if (paymentMethod != null) 'payment_method': paymentMethod,
        if (paymentSplits != null)
          'payment_splits': paymentSplits.map((s) => {'method': s.method, 'amount': s.amount}).toList(),
      };
      return Success(await _remote.checkout(payload));
    } on Exception catch (e) {
      return Error(_mapException(e));
    }
  }

  @override
  Future<Result<InvoiceEntity>> getInvoice(String id) async {
    try {
      return Success(await _remote.getInvoice(id));
    } on Exception catch (e) {
      return Error(_mapException(e));
    }
  }

  @override
  Future<Result<List<InvoiceEntity>>> listInvoices({int limit = 50, int offset = 0}) async {
    try {
      return Success(await _remote.listInvoices(limit: limit, offset: offset));
    } on Exception catch (e) {
      return Error(_mapException(e));
    }
  }

  @override
  Future<Result<List<int>>> getReceiptBytes(String invoiceId) async {
    try {
      return Success(await _remote.getReceiptBytes(invoiceId));
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
