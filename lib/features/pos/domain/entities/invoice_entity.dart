import 'package:equatable/equatable.dart';

class InvoiceLineItemEntity extends Equatable {
  const InvoiceLineItemEntity({
    required this.productId,
    required this.productName,
    required this.unitPrice,
    required this.gstRate,
    required this.quantity,
    required this.lineDiscountAmount,
    required this.lineTotal,
  });

  final String productId;
  final String productName;
  final double unitPrice;
  final double gstRate;
  final int quantity;
  final double lineDiscountAmount;
  final double lineTotal;

  @override
  List<Object?> get props => [productId, productName, unitPrice, gstRate, quantity, lineDiscountAmount, lineTotal];
}

class PaymentSplitEntity extends Equatable {
  const PaymentSplitEntity({required this.method, required this.amount});
  final String method;
  final double amount;

  @override
  List<Object?> get props => [method, amount];
}

class InvoiceEntity extends Equatable {
  const InvoiceEntity({
    required this.id,
    required this.invoiceNumber,
    this.customerId,
    required this.subtotal,
    required this.discountAmount,
    required this.gstAmount,
    required this.totalAmount,
    required this.paymentMethod,
    required this.isSplitPayment,
    required this.status,
    required this.lineItems,
    required this.paymentSplits,
    required this.createdAt,
  });

  final String id;
  final String invoiceNumber;
  final String? customerId;
  final double subtotal;
  final double discountAmount;
  final double gstAmount;
  final double totalAmount;
  final String paymentMethod;
  final bool isSplitPayment;
  final String status;
  final List<InvoiceLineItemEntity> lineItems;
  final List<PaymentSplitEntity> paymentSplits;
  final DateTime createdAt;

  @override
  List<Object?> get props => [id, invoiceNumber, totalAmount, status, createdAt];
}
