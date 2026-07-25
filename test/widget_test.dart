// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:lms/main.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const ExcelerateApp());

    // Verify that we are on the login placeholder screen.
    expect(find.text('Login Screen Placeholder'), findsOneWidget);
    
    // Tap the 'Login' button and trigger a frame.
    await tester.tap(find.byType(ElevatedButton));
    await tester.pumpAndSettle();

    // Verify that we are on the Home screen.
    expect(find.text('Welcome back 👋'), findsOneWidget);
  });
}
