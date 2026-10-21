import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:stays_app/features/auth/views/login_screen.dart';

Future<void> _pump(WidgetTester tester) async {
  await tester.pumpWidget(
    const ProviderScope(child: MaterialApp(home: LoginScreen())),
  );
}

void main() {
  testWidgets('login shows the identifier and password fields', (tester) async {
    await _pump(tester);
    expect(find.text('Email or phone'), findsOneWidget);
    expect(find.text('Password'), findsOneWidget);
    expect(find.text('Log in'), findsOneWidget);
    expect(find.text('Full name'), findsNothing);
  });

  testWidgets('a new guest can switch to account creation and back', (
    tester,
  ) async {
    await _pump(tester);
    await tester.tap(find.text('New here? Create an account'));
    await tester.pump();
    expect(find.text('Full name'), findsOneWidget);
    expect(find.text('Email'), findsOneWidget);
    expect(find.text('Send code'), findsOneWidget);

    await tester.tap(find.text('Have an account? Log in'));
    await tester.pump();
    expect(find.text('Full name'), findsNothing);
    expect(find.text('Log in'), findsOneWidget);
  });
}
