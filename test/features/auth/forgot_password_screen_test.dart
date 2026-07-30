import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lycanos_ai/features/auth/presentation/screens/forgot_password_screen.dart';

void main() {
  Widget wrap() {
    return const ProviderScope(
      child: MaterialApp(home: ForgotPasswordScreen()),
    );
  }

  testWidgets('starts on the request-reset step', (tester) async {
    await tester.pumpWidget(wrap());
    await tester.pump();

    expect(find.text('Reset your password'), findsOneWidget);
    expect(find.text('Send reset instructions'), findsOneWidget);
  });

  testWidgets('requires a valid email before sending the request', (tester) async {
    await tester.pumpWidget(wrap());
    await tester.pump();

    await tester.tap(find.text('Send reset instructions'));
    await tester.pump();

    expect(find.text('Email is required'), findsOneWidget);
  });

  testWidgets('switches to the token+new-password step', (tester) async {
    await tester.pumpWidget(wrap());
    await tester.pump();

    await tester.tap(find.text('Already have a reset token?'));
    await tester.pump();

    expect(find.text('Enter your reset token'), findsOneWidget);
    expect(find.text('Reset password'), findsOneWidget);
  });
}
