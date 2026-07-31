import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lycanos_ai/features/inventory/domain/entities/product_entity.dart';
import 'package:lycanos_ai/features/inventory/presentation/widgets/stock_adjustment_dialog.dart';

ProductEntity _testProduct({int quantityInStock = 10}) {
  final now = DateTime.now();
  return ProductEntity(
    id: 'p1',
    name: 'Test Product',
    sku: 'SKU-1',
    unit: 'pcs',
    costPrice: 5,
    sellingPrice: 10,
    gstRate: 0,
    quantityInStock: quantityInStock,
    reorderLevel: 5,
    isActive: true,
    isLowStock: false,
    createdAt: now,
    updatedAt: now,
  );
}

void main() {
  Future<void> pumpDialog(WidgetTester tester, ProductEntity product) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () => showDialog<StockAdjustmentResult>(
                context: context,
                builder: (_) => StockAdjustmentDialog(product: product),
              ),
              child: const Text('open'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
  }

  testWidgets('requires a positive quantity', (tester) async {
    await pumpDialog(tester, _testProduct());

    await tester.tap(find.text('Confirm'));
    await tester.pump();

    expect(find.text('Enter a positive whole number'), findsOneWidget);
  });

  testWidgets('requires a reason', (tester) async {
    await pumpDialog(tester, _testProduct());

    await tester.enterText(find.byType(TextFormField).first, '5');
    await tester.tap(find.text('Confirm'));
    await tester.pump();

    expect(find.text('Reason is required'), findsOneWidget);
  });

  testWidgets('rejects removing more than available stock', (tester) async {
    await pumpDialog(tester, _testProduct(quantityInStock: 3));

    await tester.tap(find.text('Remove'));
    await tester.pump();
    await tester.enterText(find.byType(TextFormField).first, '10');
    await tester.tap(find.text('Confirm'));
    await tester.pump();

    expect(find.text('Only 3 in stock'), findsOneWidget);
  });

  testWidgets('returns a positive delta when receiving stock', (tester) async {
    StockAdjustmentResult? capturedResult;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () async {
                capturedResult = await showDialog<StockAdjustmentResult>(
                  context: context,
                  builder: (_) => StockAdjustmentDialog(product: _testProduct()),
                );
              },
              child: const Text('open'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextFormField).first, '5');
    await tester.enterText(find.byType(TextFormField).last, 'Purchase order received');
    await tester.tap(find.text('Confirm'));
    await tester.pumpAndSettle();

    expect(capturedResult?.delta, 5);
    expect(capturedResult?.reason, 'Purchase order received');
  });
}
