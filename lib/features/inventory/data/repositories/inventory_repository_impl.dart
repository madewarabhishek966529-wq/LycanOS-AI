import '../../../../core/errors/exceptions.dart';
import '../../../../core/errors/failures.dart';
import '../../domain/entities/category_entity.dart';
import '../../domain/entities/product_entity.dart';
import '../../domain/repositories/inventory_repository.dart';
import '../datasources/inventory_remote_datasource.dart';

class InventoryRepositoryImpl implements InventoryRepository {
  const InventoryRepositoryImpl(this._remote);
  final InventoryRemoteDataSource _remote;

  @override
  Future<Result<List<CategoryEntity>>> getCategories() async {
    try {
      return Success(await _remote.getCategories());
    } on Exception catch (e) {
      return Error(_mapException(e));
    }
  }

  @override
  Future<Result<CategoryEntity>> createCategory({required String name, String? description}) async {
    try {
      return Success(await _remote.createCategory(name: name, description: description));
    } on Exception catch (e) {
      return Error(_mapException(e));
    }
  }

  @override
  Future<Result<List<SupplierEntity>>> getSuppliers() async {
    try {
      return Success(await _remote.getSuppliers());
    } on Exception catch (e) {
      return Error(_mapException(e));
    }
  }

  @override
  Future<Result<SupplierEntity>> createSupplier({
    required String name,
    String? contactPhone,
    String? contactEmail,
    String? address,
  }) async {
    try {
      return Success(await _remote.createSupplier(
        name: name,
        contactPhone: contactPhone,
        contactEmail: contactEmail,
        address: address,
      ));
    } on Exception catch (e) {
      return Error(_mapException(e));
    }
  }

  @override
  Future<Result<List<ProductEntity>>> getProducts({
    String? search,
    String? categoryId,
    bool lowStockOnly = false,
  }) async {
    try {
      return Success(await _remote.getProducts(search: search, categoryId: categoryId, lowStockOnly: lowStockOnly));
    } on Exception catch (e) {
      return Error(_mapException(e));
    }
  }

  @override
  Future<Result<ProductEntity>> getProduct(String id) async {
    try {
      return Success(await _remote.getProduct(id));
    } on Exception catch (e) {
      return Error(_mapException(e));
    }
  }

  @override
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
  }) async {
    try {
      final payload = {
        'name': name,
        'sku': sku,
        if (barcode != null) 'barcode': barcode,
        'unit': unit,
        if (categoryId != null) 'category_id': categoryId,
        if (supplierId != null) 'supplier_id': supplierId,
        'cost_price': costPrice,
        'selling_price': sellingPrice,
        'gst_rate': gstRate,
        'quantity_in_stock': quantityInStock,
        'reorder_level': reorderLevel,
        if (batchNumber != null) 'batch_number': batchNumber,
        if (expiryDate != null) 'expiry_date': _formatDate(expiryDate),
      };
      return Success(await _remote.createProduct(payload));
    } on Exception catch (e) {
      return Error(_mapException(e));
    }
  }

  @override
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
  }) async {
    try {
      final payload = {
        if (name != null) 'name': name,
        if (barcode != null) 'barcode': barcode,
        if (unit != null) 'unit': unit,
        if (categoryId != null) 'category_id': categoryId,
        if (supplierId != null) 'supplier_id': supplierId,
        if (costPrice != null) 'cost_price': costPrice,
        if (sellingPrice != null) 'selling_price': sellingPrice,
        if (gstRate != null) 'gst_rate': gstRate,
        if (reorderLevel != null) 'reorder_level': reorderLevel,
        if (batchNumber != null) 'batch_number': batchNumber,
        if (expiryDate != null) 'expiry_date': _formatDate(expiryDate),
        if (isActive != null) 'is_active': isActive,
      };
      return Success(await _remote.updateProduct(id, payload));
    } on Exception catch (e) {
      return Error(_mapException(e));
    }
  }

  @override
  Future<Result<ProductEntity>> adjustStock({
    required String productId,
    required int delta,
    required String reason,
  }) async {
    try {
      return Success(await _remote.adjustStock(productId: productId, delta: delta, reason: reason));
    } on Exception catch (e) {
      return Error(_mapException(e));
    }
  }

  @override
  Future<Result<void>> deleteProduct(String id) async {
    try {
      await _remote.deleteProduct(id);
      return const Success(null);
    } on Exception catch (e) {
      return Error(_mapException(e));
    }
  }

  String _formatDate(DateTime date) {
    return '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
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
