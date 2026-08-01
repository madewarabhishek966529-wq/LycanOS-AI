import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lycanos_ai/features/dashboard/presentation/widgets/kpi_tile.dart';

void main() {
  testWidgets('renders label, value, and subtitle', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: KpiTile(
            label: "Today's Sales",
            value: '₹1,200',
            subtitle: '5 invoices',
            icon: Icons.point_of_sale_rounded,
          ),
        ),
      ),
    );

    expect(find.text("Today's Sales"), findsOneWidget);
    expect(find.text('₹1,200'), findsOneWidget);
    expect(find.text('5 invoices'), findsOneWidget);
    expect(find.byIcon(Icons.point_of_sale_rounded), findsOneWidget);
  });

  testWidgets('renders without a subtitle', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: KpiTile(label: 'Low Stock', value: '3', icon: Icons.warning_amber_rounded),
        ),
      ),
    );

    expect(find.text('Low Stock'), findsOneWidget);
    expect(find.text('3'), findsOneWidget);
  });
}
