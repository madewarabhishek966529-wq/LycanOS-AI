import 'package:equatable/equatable.dart';

/// Represents one line of the in-progress sale, before checkout. Distinct
/// from [InvoiceLineItemEntity] (which is a *historical record* of what
/// was actually sold) — this one is mutable client-side state and carries
/// [availableStock] purely for client-side validation before hitting the
/// checkout API (the server re-validates regardless).
class CartItemEntity extends Equatable {
  const CartItemEntity({
    required this.productId,
    required this.productName,
    required this.sku,
    required this.unitPrice,
    required this.gstRate,
    required this.availableStock,
    required this.quantity,
    this.lineDiscountAmount = 0,
  });

  final String productId;
  final String productName;
  final String sku;
  final double unitPrice;
  final double gstRate;
  final int availableStock;
  final int quantity;
  final double lineDiscountAmount;

  double get lineGross => unitPrice * quantity;
  double get lineNet => lineGross - lineDiscountAmount;
  double get estimatedGst => lineNet * gstRate / 100;
  double get estimatedTotal => lineNet + estimatedGst;

  CartItemEntity copyWith({int? quantity, double? lineDiscountAmount}) {
    return CartItemEntity(
      productId: productId,
      productName: productName,
      sku: sku,
      unitPrice: unitPrice,
      gstRate: gstRate,
      availableStock: availableStock,
      quantity: quantity ?? this.quantity,
      lineDiscountAmount: lineDiscountAmount ?? this.lineDiscountAmount,
    );
  }

  @override
  List<Object?> get props => [productId, quantity, lineDiscountAmount];
}
