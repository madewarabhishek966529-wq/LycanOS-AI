import 'package:dio/dio.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../core/network/api_endpoints.dart';
import '../models/category_model.dart';
import '../models/product_model.dart';

/// Talks to `/inventory/*` over Dio. Follows the same error-mapping
/// discipline as [AuthRemoteDataSource]: never lets a raw [DioException]
/// escape this class.
class InventoryRemoteDataSource {
  const InventoryRemoteDataSource(this._dio);
  final Dio _dio;

  // --- Categories -----------------------------------------------------

  Future<List<CategoryModel>> getCategories() async {
    try {
      final response = await _dio.get<List<dynamic>>(ApiEndpoints.categories);
      return response.data!.map((e) => CategoryModel.fromJson(e as Map<String, dynamic>)).toList();
    } on DioException catch (e) {
      throw _mapError(e);
    }
  }

  Future<CategoryModel> createCategory({required String name, String? description}) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        ApiEndpoints.categories,
        data: {'name': name, if (description != null) 'description': description},
      );
      return CategoryModel.fromJson(response.data!);
    } on DioException catch (e) {
      throw _mapError(e);
    }
  }

  // --- Suppliers --------------------------------------------------------

  Future<List<SupplierModel>> getSuppliers() async {
    try {
      final response = await _dio.get<List<dynamic>>(ApiEndpoints.suppliers);
      return response.data!.map((e) => SupplierModel.fromJson(e as Map<String, dynamic>)).toList();
    } on DioException catch (e) {
      throw _mapError(e);
    }
  }

  Future<SupplierModel> createSupplier({
    required String name,
    String? contactPhone,
    String? contactEmail,
    String? address,
  }) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        ApiEndpoints.suppliers,
        data: {
          'name': name,
          if (contactPhone != null) 'contact_phone': contactPhone,
          if (contactEmail != null) 'contact_email': contactEmail,
          if (address != null) 'address': address,
        },
      );
      return SupplierModel.fromJson(response.data!);
    } on DioException catch (e) {
      throw _mapError(e);
    }
  }

  // --- Products -----------------------------------------------------------

  Future<List<ProductModel>> getProducts({String? search, String? categoryId, bool lowStockOnly = false}) async {
    try {
      final response = await _dio.get<List<dynamic>>(
        ApiEndpoints.products,
        queryParameters: {
          if (search != null && search.isNotEmpty) 'search': search,
          if (categoryId != null) 'category_id': categoryId,
          if (lowStockOnly) 'low_stock_only': true,
        },
      );
      return response.data!.map((e) => ProductModel.fromJson(e as Map<String, dynamic>)).toList();
    } on DioException catch (e) {
      throw _mapError(e);
    }
  }

  Future<ProductModel> getProduct(String id) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(ApiEndpoints.withId(ApiEndpoints.products, id));
      return ProductModel.fromJson(response.data!);
    } on DioException catch (e) {
      throw _mapError(e);
    }
  }

  Future<ProductModel> createProduct(Map<String, dynamic> payload) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(ApiEndpoints.products, data: payload);
      return ProductModel.fromJson(response.data!);
    } on DioException catch (e) {
      throw _mapError(e);
    }
  }

  Future<ProductModel> updateProduct(String id, Map<String, dynamic> payload) async {
    try {
      final response = await _dio.patch<Map<String, dynamic>>(ApiEndpoints.withId(ApiEndpoints.products, id), data: payload);
      return ProductModel.fromJson(response.data!);
    } on DioException catch (e) {
      throw _mapError(e);
    }
  }

  Future<ProductModel> adjustStock({required String productId, required int delta, required String reason}) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        ApiEndpoints.adjustStock(productId),
        data: {'delta': delta, 'reason': reason},
      );
      return ProductModel.fromJson(response.data!);
    } on DioException catch (e) {
      throw _mapError(e);
    }
  }

  Future<void> deleteProduct(String id) async {
    try {
      await _dio.delete<void>(ApiEndpoints.withId(ApiEndpoints.products, id));
    } on DioException catch (e) {
      throw _mapError(e);
    }
  }

  Exception _mapError(DioException e) {
    if (e.type == DioExceptionType.connectionError ||
        e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout) {
      return const NetworkException();
    }

    final statusCode = e.response?.statusCode;
    final data = e.response?.data;
    final detail = data is Map<String, dynamic> ? data['detail'] : null;

    if (statusCode == 422 && detail is List) {
      final fieldErrors = <String, String>{};
      for (final item in detail) {
        if (item is Map<String, dynamic>) {
          final loc = (item['loc'] as List?)?.last?.toString() ?? 'field';
          fieldErrors[loc] = item['msg']?.toString() ?? 'Invalid value';
        }
      }
      return ValidationException('Please check the highlighted fields', fieldErrors: fieldErrors);
    }

    if (statusCode == 401 || statusCode == 403) {
      return AuthException(detail?.toString() ?? 'Not authorized');
    }

    return ServerException(detail?.toString() ?? 'Something went wrong', statusCode: statusCode);
  }
}
