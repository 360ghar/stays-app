import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stays_app/core/ui/async_state.dart';

Widget _wrap(Widget child) {
  return MaterialApp(home: Scaffold(body: child));
}

void main() {
  testWidgets('loading shows message', (tester) async {
    await tester.pumpWidget(
      _wrap(const AsyncState.loading(message: 'Finding stays…')),
    );
    expect(find.text('Finding stays…'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets('error shows retry', (tester) async {
    var retried = false;
    await tester.pumpWidget(
      _wrap(AsyncState.error('Failed.', onRetry: () => retried = true)),
    );
    expect(find.text('Failed.'), findsOneWidget);
    await tester.tap(find.text('Retry'));
    expect(retried, isTrue);
  });

  testWidgets('empty shows message', (tester) async {
    await tester.pumpWidget(_wrap(const AsyncState.empty()));
    expect(find.text('Nothing here yet.'), findsOneWidget);
  });
}
