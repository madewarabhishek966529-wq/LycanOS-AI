import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lycanos_ai/features/dashboard/domain/entities/dashboard_summary_entity.dart';
import 'package:lycanos_ai/features/dashboard/presentation/widgets/revenue_chart.dart';

void main() {
  testWidgets('renders the chart title with data points', (tester) async {
    final points = [
      RevenuePointEntity(day: DateTime(2026, 1, 1), revenue: 100, invoiceCount: 2),
      RevenuePointEntity(day: DateTime(2026, 1, 2), revenue: 200, invoiceCount: 3),
    ];

    await tester.pumpWidget(
      MaterialApp(home: Scaffold(body: RevenueChart(points: points))),
    );

    expect(find.text('Revenue — last 7 days'), findsOneWidget);
  });

  testWidgets('renders nothing for an empty series', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: RevenueChart(points: []))),
    );

    expect(find.text('Revenue — last 7 days'), findsNothing);
  });
}
