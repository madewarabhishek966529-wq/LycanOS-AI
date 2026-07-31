import '../../domain/entities/product_entity.dart';
import 'category_model.dart';

class ProductModel extends ProductEntity {
  const ProductModel({
    required super.id,
    required super.name,
    required super.sku,
    super.barcode,
    required super.unit,
    super.category,
    super.supplier,
    required super.costPrice,
    required super.sellingPrice,
    required super.gstRate,
    required super.quantityInStock,
    required super.reorderLevel,
    super.batchNumber,
    super.expiryDate,
    required super.isActive,
    required super.isLowStock,
    required super.createdAt,
    required super.updatedAt,
  });

  /// Backend serializes `Decimal` fields as JSON numbers via FastAPI's
  /// default encoder, but this parses strings too defensively — a Decimal
  /// occasionally round-trips as a string depending on serializer config,
  /// and failing to parse a price is worse than being lenient about its
  /// wire format.
  static double _parseDouble(dynamic value) {
    if (value is num) return value.toDouble();
    if (value is String) return double.parse(value);
    throw FormatException('Expected a numeric value, got: $value');
  }

  factory ProductModel.fromJson(Map<String, dynamic> json) {
    return ProductModel(
      id: json['id'] as String,
      name: json['name'] as String,
      sku: json['sku'] as String,
      barcode: json['barcode'] as String?,
      unit: json['unit'] as String,
      category: json['category'] != null
          ? CategoryModel.fromJson(json['category'] as Map<String, dynamic>)
          : null,
      supplier: json['supplier'] != null
          ? SupplierModel.fromJson(json['supplier'] as Map<String, dynamic>)
          : null,
      costPrice: _parseDouble(json['cost_price']),
      sellingPrice: _parseDouble(json['selling_price']),
      gstRate: _parseDouble(json['gst_rate']),
      quantityInStock: json['quantity_in_stock'] as int,
      reorderLevel: json['reorder_level'] as int,
      batchNumber: json['batch_number'] as String?,
      expiryDate: json['expiry_date'] != null ? DateTime.parse(json['expiry_date'] as String) : null,
      isActive: json['is_active'] as bool,
      isLowStock: json['is_low_stock'] as bool,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }
}
