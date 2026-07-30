import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lycanos_ai/app.dart';

void main() {
  testWidgets('App boots and shows the splash screen first', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: LycanOSApp()));
    await tester.pump();

    expect(find.text('LycanOS AI'), findsOneWidget);
  });

  testWidgets('Unauthenticated session redirects to the login screen', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: LycanOSApp()));

    // Allow the auth state's async _restoreSession() to resolve and the
    // router's redirect to fire.
    await tester.pumpAndSettle();

    expect(find.text('Welcome back'), findsOneWidget);
  });
}
