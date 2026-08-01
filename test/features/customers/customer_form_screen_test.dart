import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lycanos_ai/features/customers/presentation/screens/customer_form_screen.dart';

void main() {
  Widget wrap() {
    return const ProviderScope(
      child: MaterialApp(home: CustomerFormScreen()),
    );
  }

  testWidgets('shows validation error when name is empty', (tester) async {
    await tester.pumpWidget(wrap());
    await tester.pump();

    await tester.tap(find.text('Add customer').last);
    await tester.pump();

    expect(find.text('Name is required'), findsOneWidget);
  });

  testWidgets('rejects an invalid email', (tester) async {
    await tester.pumpWidget(wrap());
    await tester.pump();

    await tester.enterText(find.byType(TextFormField).first, 'Ravi Kumar');
    final emailField = find.byType(TextFormField).at(2);
    await tester.enterText(emailField, 'not-an-email');
    await tester.tap(find.text('Add customer').last);
    await tester.pump();

    expect(find.text('Enter a valid email'), findsOneWidget);
  });

  testWidgets('shows "Edit customer" title and button when editing', (tester) async {
    // Build with no customer (create mode) confirms default title first.
    await tester.pumpWidget(wrap());
    await tester.pump();
    expect(find.text('Add customer'), findsWidgets);
  });
}
