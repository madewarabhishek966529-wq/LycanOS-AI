import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../inventory/domain/entities/product_entity.dart';
import '../../domain/entities/cart_item_entity.dart';

class CartState {
  const CartState({this.items = const []});
  final List<CartItemEntity> items;

  double get subtotal => items.fold(0, (sum, item) => sum + item.lineNet);
  double get estimatedGst => items.fold(0, (sum, item) => sum + item.estimatedGst);
  double get estimatedTotal => items.fold(0, (sum, item) => sum + item.estimatedTotal);
  int get itemCount => items.fold(0, (sum, item) => sum + item.quantity);
  bool get isEmpty => items.isEmpty;

  CartState copyWith({List<CartItemEntity>? items}) => CartState(items: items ?? this.items);
}

/// Owns the in-progress sale. Deliberately a plain (non-autoDispose)
/// provider so the cart survives navigating from the product-picker screen
/// to the checkout screen and back — it's only cleared explicitly, on a
/// successful checkout or an explicit "clear cart" action.
class CartNotifier extends StateNotifier<CartState> {
  CartNotifier() : super(const CartState());

  /// Returns an error message if the product couldn't be added (e.g. out
  /// of stock), or null on success.
  String? addProduct(ProductEntity product, {int quantity = 1}) {
    final existingIndex = state.items.indexWhere((item) => item.productId == product.id);

    if (existingIndex != -1) {
      final existing = state.items[existingIndex];
      final newQuantity = existing.quantity + quantity;
      if (newQuantity > product.quantityInStock) {
        return 'Only ${product.quantityInStock} ${product.unit} of "${product.name}" in stock';
      }
      _replaceAt(existingIndex, existing.copyWith(quantity: newQuantity));
      return null;
    }

    if (quantity > product.quantityInStock) {
      return 'Only ${product.quantityInStock} ${product.unit} of "${product.name}" in stock';
    }

    state = state.copyWith(items: [
      ...state.items,
      CartItemEntity(
        productId: product.id,
        productName: product.name,
        sku: product.sku,
        unitPrice: product.sellingPrice,
        gstRate: product.gstRate,
        availableStock: product.quantityInStock,
        quantity: quantity,
      ),
    ]);
    return null;
  }

  String? setQuantity(String productId, int quantity) {
    final index = state.items.indexWhere((item) => item.productId == productId);
    if (index == -1) return null;
    final item = state.items[index];

    if (quantity <= 0) {
      removeItem(productId);
      return null;
    }
    if (quantity > item.availableStock) {
      return 'Only ${item.availableStock} available';
    }
    _replaceAt(index, item.copyWith(quantity: quantity));
    return null;
  }

  void setLineDiscount(String productId, double discount) {
    final index = state.items.indexWhere((item) => item.productId == productId);
    if (index == -1) return;
    _replaceAt(index, state.items[index].copyWith(lineDiscountAmount: discount));
  }

  void removeItem(String productId) {
    state = state.copyWith(items: state.items.where((item) => item.productId != productId).toList());
  }

  void clear() => state = const CartState();

  void _replaceAt(int index, CartItemEntity item) {
    final updated = [...state.items];
    updated[index] = item;
    state = state.copyWith(items: updated);
  }
}

final cartProvider = StateNotifierProvider<CartNotifier, CartState>((ref) => CartNotifier());
