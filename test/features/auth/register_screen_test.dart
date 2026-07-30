import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lycanos_ai/features/auth/presentation/screens/register_screen.dart';

void main() {
  Widget wrap() {
    return const ProviderScope(
      child: MaterialApp(home: RegisterScreen()),
    );
  }

  testWidgets('shows validation errors when submitting an empty form', (tester) async {
    await tester.pumpWidget(wrap());
    await tester.pump();

    await tester.tap(find.text('Create account'));
    await tester.pump();

    expect(find.text('Business name is required'), findsOneWidget);
    expect(find.text('Your name is required'), findsOneWidget);
    expect(find.text('Email is required'), findsOneWidget);
    expect(find.text('At least 8 characters'), findsOneWidget);
  });

  testWidgets('rejects a password with no digit', (tester) async {
    await tester.pumpWidget(wrap());
    await tester.pump();

    final passwordField = find.byType(TextFormField).last;
    await tester.enterText(passwordField, 'allletters');
    await tester.tap(find.text('Create account'));
    await tester.pump();

    expect(find.text('Must contain a letter and a number'), findsOneWidget);
  });

  testWidgets('rejects an email without an @', (tester) async {
    await tester.pumpWidget(wrap());
    await tester.pump();

    final emailField = find.byType(TextFormField).at(2);
    await tester.enterText(emailField, 'not-an-email');
    await tester.tap(find.text('Create account'));
    await tester.pump();

    expect(find.text('Enter a valid email'), findsOneWidget);
  });
}
