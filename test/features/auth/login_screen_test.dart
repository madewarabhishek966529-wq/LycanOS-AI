import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lycanos_ai/features/auth/presentation/screens/login_screen.dart';

void main() {
  Widget wrap() {
    return const ProviderScope(
      child: MaterialApp(home: LoginScreen()),
    );
  }

  testWidgets('shows validation errors when submitting an empty form', (tester) async {
    await tester.pumpWidget(wrap());
    await tester.pump();

    await tester.tap(find.text('Sign In'));
    await tester.pump();

    expect(find.text('Email is required'), findsOneWidget);
    expect(find.text('Password must be at least 6 characters'), findsOneWidget);
  });

  testWidgets('rejects an email missing an @', (tester) async {
    await tester.pumpWidget(wrap());
    await tester.pump();

    await tester.enterText(find.byType(TextFormField).first, 'not-an-email');
    await tester.tap(find.text('Sign In'));
    await tester.pump();

    expect(find.text('Enter a valid email'), findsOneWidget);
  });

  testWidgets('toggles password visibility', (tester) async {
    await tester.pumpWidget(wrap());
    await tester.pump();

    expect(find.byIcon(Icons.visibility_off), findsOneWidget);
    await tester.tap(find.byIcon(Icons.visibility_off));
    await tester.pump();
    expect(find.byIcon(Icons.visibility), findsOneWidget);
  });
}
