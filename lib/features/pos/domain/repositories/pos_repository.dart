import '../../../../core/errors/failures.dart';
import '../entities/cart_item_entity.dart';
import '../entities/invoice_entity.dart';

abstract class PosRepository {
  Future<Result<InvoiceEntity>> checkout({
    required List<CartItemEntity> items,
    String? customerId,
    double invoiceDiscountAmount = 0,
    String? couponCode,
    String? paymentMethod,
    List<({String method, double amount})>? paymentSplits,
  });

  Future<Result<InvoiceEntity>> getInvoice(String id);

  Future<Result<List<InvoiceEntity>>> listInvoices({int limit = 50, int offset = 0});

  /// Returns raw PDF bytes for the receipt — the presentation layer hands
  /// these to the `printing` package to preview/print/share, rather than
  /// this repository knowing anything about PDF rendering UI.
  Future<Result<List<int>>> getReceiptBytes(String invoiceId);
}
