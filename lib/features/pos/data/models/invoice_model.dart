import '../../domain/entities/invoice_entity.dart';

class InvoiceLineItemModel extends InvoiceLineItemEntity {
  const InvoiceLineItemModel({
    required super.productId,
    required super.productName,
    required super.unitPrice,
    required super.gstRate,
    required super.quantity,
    required super.lineDiscountAmount,
    required super.lineTotal,
  });

  factory InvoiceLineItemModel.fromJson(Map<String, dynamic> json) {
    return InvoiceLineItemModel(
      productId: json['product_id'] as String,
      productName: json['product_name'] as String,
      unitPrice: double.parse(json['unit_price'].toString()),
      gstRate: double.parse(json['gst_rate'].toString()),
      quantity: json['quantity'] as int,
      lineDiscountAmount: double.parse(json['line_discount_amount'].toString()),
      lineTotal: double.parse(json['line_total'].toString()),
    );
  }
}

class PaymentSplitModel extends PaymentSplitEntity {
  const PaymentSplitModel({required super.method, required super.amount});

  factory PaymentSplitModel.fromJson(Map<String, dynamic> json) {
    return PaymentSplitModel(
      method: json['method'] as String,
      amount: double.parse(json['amount'].toString()),
    );
  }
}

class InvoiceModel extends InvoiceEntity {
  const InvoiceModel({
    required super.id,
    required super.invoiceNumber,
    required super.subtotal,
    required super.discountAmount,
    required super.gstAmount,
    required super.totalAmount,
    required super.paymentMethod,
    required super.isSplitPayment,
    required super.status,
    required super.lineItems,
    required super.paymentSplits,
    required super.createdAt,
  });

  factory InvoiceModel.fromJson(Map<String, dynamic> json) {
    return InvoiceModel(
      id: json['id'] as String,
      invoiceNumber: json['invoice_number'] as String,
      subtotal: double.parse(json['subtotal'].toString()),
      discountAmount: double.parse(json['discount_amount'].toString()),
      gstAmount: double.parse(json['gst_amount'].toString()),
      totalAmount: double.parse(json['total_amount'].toString()),
      paymentMethod: json['payment_method'] as String,
      isSplitPayment: json['is_split_payment'] as bool,
      status: json['status'] as String,
      lineItems: (json['line_items'] as List)
          .map((e) => InvoiceLineItemModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      paymentSplits: (json['payment_splits'] as List)
          .map((e) => PaymentSplitModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
}
