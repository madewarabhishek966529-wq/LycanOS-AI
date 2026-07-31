import '../../../../core/errors/failures.dart';
import '../entities/category_entity.dart';
import '../entities/product_entity.dart';

abstract class InventoryRepository {
  // Categories
  Future<Result<List<CategoryEntity>>> getCategories();
  Future<Result<CategoryEntity>> createCategory({required String name, String? description});

  // Suppliers
  Future<Result<List<SupplierEntity>>> getSuppliers();
  Future<Result<SupplierEntity>> createSupplier({
    required String name,
    String? contactPhone,
    String? contactEmail,
    String? address,
  });

  // Products
  Future<Result<List<ProductEntity>>> getProducts({
    String? search,
    String? categoryId,
    bool lowStockOnly = false,
  });

  Future<Result<ProductEntity>> getProduct(String id);

  Future<Result<ProductEntity>> createProduct({
    required String name,
    required String sku,
    String? barcode,
    String unit = 'pcs',
    String? categoryId,
    String? supplierId,
    double costPrice = 0,
    required double sellingPrice,
    double gstRate = 0,
    int quantityInStock = 0,
    int reorderLevel = 5,
    String? batchNumber,
    DateTime? expiryDate,
  });

  Future<Result<ProductEntity>> updateProduct({
    required String id,
    String? name,
    String? barcode,
    String? unit,
    String? categoryId,
    String? supplierId,
    double? costPrice,
    double? sellingPrice,
    double? gstRate,
    int? reorderLevel,
    String? batchNumber,
    DateTime? expiryDate,
    bool? isActive,
  });

  Future<Result<ProductEntity>> adjustStock({
    required String productId,
    required int delta,
    required String reason,
  });

  Future<Result<void>> deleteProduct(String id);
}
