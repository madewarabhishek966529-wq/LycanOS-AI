import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lycanos_ai/features/inventory/domain/entities/category_entity.dart';
import 'package:lycanos_ai/features/inventory/domain/entities/product_entity.dart';
import 'package:lycanos_ai/features/inventory/presentation/widgets/product_list_tile.dart';

ProductEntity _product({
  int quantityInStock = 10,
  int reorderLevel = 5,
  DateTime? expiryDate,
  CategoryEntity? category,
}) {
  final now = DateTime.now();
  return ProductEntity(
    id: 'p1',
    name: 'Amul Butter',
    sku: 'AMUL-1',
    unit: 'pcs',
    category: category,
    costPrice: 200,
    sellingPrice: 250,
    gstRate: 5,
    quantityInStock: quantityInStock,
    reorderLevel: reorderLevel,
    expiryDate: expiryDate,
    isActive: true,
    isLowStock: quantityInStock <= reorderLevel,
    createdAt: now,
    updatedAt: now,
  );
}

void main() {
  Future<void> pumpTile(WidgetTester tester, ProductEntity product) async {
    await tester.pumpWidget(
      MaterialApp(home: Scaffold(body: ProductListTile(product: product, onTap: () {}))),
    );
  }

  testWidgets('shows product name, SKU, and price', (tester) async {
    await pumpTile(tester, _product());

    expect(find.text('Amul Butter'), findsOneWidget);
    expect(find.textContaining('AMUL-1'), findsOneWidget);
    expect(find.textContaining('₹250.00'), findsOneWidget);
  });

  testWidgets('shows "Low stock" badge when at or below reorder level', (tester) async {
    await pumpTile(tester, _product(quantityInStock: 2, reorderLevel: 5));
    expect(find.text('Low stock'), findsOneWidget);
  });

  testWidgets('shows "In stock" badge when well above reorder level', (tester) async {
    await pumpTile(tester, _product(quantityInStock: 100, reorderLevel: 5));
    expect(find.text('In stock'), findsOneWidget);
  });

  testWidgets('shows "Expired" badge for a past expiry date', (tester) async {
    await pumpTile(
      tester,
      _product(quantityInStock: 100, reorderLevel: 5, expiryDate: DateTime.now().subtract(const Duration(days: 1))),
    );
    expect(find.text('Expired'), findsOneWidget);
  });

  testWidgets('invokes onTap when tapped', (tester) async {
    var tapped = false;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: ProductListTile(product: _product(), onTap: () => tapped = true)),
      ),
    );
    await tester.tap(find.byType(ListTile));
    expect(tapped, isTrue);
  });
}
