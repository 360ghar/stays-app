// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:flutter/material.dart';

import 'package:stays_app/app/ui/theme/app_theme.dart';

void main() {
  testWidgets('App builds root GetMaterialApp', (WidgetTester tester) async {
    final app = GetMaterialApp(
      theme: AppTheme.lightTheme,
      home: const Scaffold(body: Center(child: Text('Hello'))),
    );
    await tester.pumpWidget(app);
    expect(find.text('Hello'), findsOneWidget);
  });
}
