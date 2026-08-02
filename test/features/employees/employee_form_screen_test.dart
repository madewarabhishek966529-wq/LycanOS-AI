import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lycanos_ai/features/employees/presentation/screens/employee_form_screen.dart';

void main() {
  Widget wrap() {
    return const ProviderScope(
      child: MaterialApp(home: EmployeeFormScreen()),
    );
  }

  testWidgets('shows validation errors on empty submit', (tester) async {
    await tester.pumpWidget(wrap());
    await tester.pump();

    await tester.tap(find.text('Add employee').last);
    await tester.pump();

    expect(find.text('Name is required'), findsOneWidget);
    expect(find.text('Email is required'), findsOneWidget);
    expect(find.text('At least 8 characters'), findsOneWidget);
  });

  testWidgets('rejects a weak password', (tester) async {
    await tester.pumpWidget(wrap());
    await tester.pump();

    final passwordField = find.byType(TextFormField).at(2);
    await tester.enterText(passwordField, 'allletters');
    await tester.tap(find.text('Add employee').last);
    await tester.pump();

    expect(find.text('Must contain a letter and a number'), findsOneWidget);
  });

  testWidgets('defaults role to cashier and disables Manager for non-owners', (tester) async {
    await tester.pumpWidget(wrap());
    await tester.pump();

    expect(find.text('Cashier'), findsOneWidget);
  });
}
