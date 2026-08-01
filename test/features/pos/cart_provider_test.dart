import 'package:flutter_test/flutter_test.dart';
import 'package:lycanos_ai/features/inventory/domain/entities/product_entity.dart';
import 'package:lycanos_ai/features/pos/presentation/providers/cart_provider.dart';

ProductEntity _product({String id = 'p1', int quantityInStock = 10, double sellingPrice = 20, double gstRate = 12}) {
  final now = DateTime.now();
  return ProductEntity(
    id: id,
    name: 'Test Product $id',
    sku: 'SKU-$id',
    unit: 'pcs',
    costPrice: 10,
    sellingPrice: sellingPrice,
    gstRate: gstRate,
    quantityInStock: quantityInStock,
    reorderLevel: 5,
    isActive: true,
    isLowStock: false,
    createdAt: now,
    updatedAt: now,
  );
}

void main() {
  group('CartNotifier', () {
    test('adding a product adds it to the cart', () {
      final notifier = CartNotifier();
      final error = notifier.addProduct(_product());

      expect(error, isNull);
      expect(notifier.state.items.length, 1);
      expect(notifier.state.items.first.quantity, 1);
    });

    test('adding the same product twice increments quantity instead of duplicating', () {
      final notifier = CartNotifier();
      notifier.addProduct(_product());
      notifier.addProduct(_product());

      expect(notifier.state.items.length, 1);
      expect(notifier.state.items.first.quantity, 2);
    });

    test('refuses to add more than available stock', () {
      final notifier = CartNotifier();
      final error = notifier.addProduct(_product(quantityInStock: 2), quantity: 5);

      expect(error, isNotNull);
      expect(notifier.state.items, isEmpty);
    });

    test('refuses to increment past available stock', () {
      final notifier = CartNotifier();
      notifier.addProduct(_product(quantityInStock: 2));
      final error = notifier.addProduct(_product(quantityInStock: 2), quantity: 5);

      expect(error, isNotNull);
      expect(notifier.state.items.first.quantity, 1); // unchanged
    });

    test('setQuantity to zero removes the item', () {
      final notifier = CartNotifier();
      notifier.addProduct(_product());
      notifier.setQuantity('p1', 0);

      expect(notifier.state.items, isEmpty);
    });

    test('removeItem removes only the targeted product', () {
      final notifier = CartNotifier();
      notifier.addProduct(_product(id: 'p1'));
      notifier.addProduct(_product(id: 'p2'));
      notifier.removeItem('p1');

      expect(notifier.state.items.length, 1);
      expect(notifier.state.items.first.productId, 'p2');
    });

    test('clear empties the cart', () {
      final notifier = CartNotifier();
      notifier.addProduct(_product());
      notifier.clear();

      expect(notifier.state.isEmpty, isTrue);
    });

    test('subtotal and estimated GST are computed correctly', () {
      final notifier = CartNotifier();
      notifier.addProduct(_product(sellingPrice: 100, gstRate: 10), quantity: 2);

      expect(notifier.state.subtotal, 200);
      expect(notifier.state.estimatedGst, 20);
      expect(notifier.state.estimatedTotal, 220);
    });

    test('line discount reduces subtotal and GST base', () {
      final notifier = CartNotifier();
      notifier.addProduct(_product(sellingPrice: 100, gstRate: 10), quantity: 2);
      notifier.setLineDiscount('p1', 50);

      expect(notifier.state.subtotal, 150); // 200 - 50
      expect(notifier.state.estimatedGst, 15); // 10% of 150
    });
  });
}
