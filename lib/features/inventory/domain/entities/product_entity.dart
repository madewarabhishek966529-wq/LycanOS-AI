import 'package:equatable/equatable.dart';
import 'category_entity.dart';

class ProductEntity extends Equatable {
  const ProductEntity({
    required this.id,
    required this.name,
    required this.sku,
    this.barcode,
    required this.unit,
    this.category,
    this.supplier,
    required this.costPrice,
    required this.sellingPrice,
    required this.gstRate,
    required this.quantityInStock,
    required this.reorderLevel,
    this.batchNumber,
    this.expiryDate,
    required this.isActive,
    required this.isLowStock,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String name;
  final String sku;
  final String? barcode;
  final String unit;
  final CategoryEntity? category;
  final SupplierEntity? supplier;
  final double costPrice;
  final double sellingPrice;
  final double gstRate;
  final int quantityInStock;
  final int reorderLevel;
  final String? batchNumber;
  final DateTime? expiryDate;
  final bool isActive;
  final bool isLowStock;
  final DateTime createdAt;
  final DateTime updatedAt;

  /// Price including GST for a single unit — what a POS screen (Phase 4)
  /// actually charges the customer.
  double get priceInclGst => sellingPrice * (1 + gstRate / 100);

  bool get isExpiringSoon {
    if (expiryDate == null) return false;
    final daysUntilExpiry = expiryDate!.difference(DateTime.now()).inDays;
    return daysUntilExpiry <= 30 && daysUntilExpiry >= 0;
  }

  bool get isExpired {
    if (expiryDate == null) return false;
    return expiryDate!.isBefore(DateTime.now());
  }

  @override
  List<Object?> get props => [
        id,
        name,
        sku,
        barcode,
        unit,
        category,
        supplier,
        costPrice,
        sellingPrice,
        gstRate,
        quantityInStock,
        reorderLevel,
        batchNumber,
        expiryDate,
        isActive,
        isLowStock,
        createdAt,
        updatedAt,
      ];
}
