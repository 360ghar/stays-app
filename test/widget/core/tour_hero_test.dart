import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stays_app/core/ui/tour_hero.dart';

Widget _wrap(Widget child) {
  return MaterialApp(home: Scaffold(body: child));
}

void main() {
  testWidgets('shows tour pill when hasTour', (tester) async {
    var toured = false;
    var gallery = false;
    await tester.pumpWidget(
      _wrap(
        TourHero(
          imageUrl: null,
          hasTour: true,
          onTourTap: () => toured = true,
          onGalleryTap: () => gallery = true,
        ),
      ),
    );
    expect(find.text('View 360 Tour'), findsOneWidget);
    await tester.tap(find.text('View 360 Tour'));
    expect(toured, isTrue);
    expect(gallery, isFalse);
  });

  testWidgets('hides tour pill without tour', (tester) async {
    await tester.pumpWidget(
      _wrap(
        TourHero(
          imageUrl: null,
          hasTour: false,
          onTourTap: () {},
          onGalleryTap: () {},
        ),
      ),
    );
    expect(find.text('View 360 Tour'), findsNothing);
    expect(find.text('Photos'), findsOneWidget);
  });
}
