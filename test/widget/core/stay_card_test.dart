import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stays_app/app/data/models/property_model.dart';
import 'package:stays_app/app/data/models/wire_enums.dart';
import 'package:stays_app/core/ui/stay_card.dart';

Property _stay({int id = 1, String? tourUrl, double? price = 2500}) {
  return Property(
    id: id,
    name: 'Sea View $id',
    propertyType: PropertyType.villa,
    city: 'Goa',
    country: 'India',
    pricePerNight: price,
    virtualTourUrl: tourUrl,
  );
}

Widget _wrap(Widget child) {
  return MaterialApp(home: Scaffold(body: child));
}

void main() {
  testWidgets('shows name, address, price', (tester) async {
    await tester.pumpWidget(_wrap(StayCard(property: _stay(), onTap: () {})));
    expect(find.text('Sea View 1'), findsOneWidget);
    expect(find.textContaining('Goa, India'), findsOneWidget);
    expect(find.textContaining('2500'), findsOneWidget);
  });

  testWidgets('shows a plain notice and no unit without a nightly rate', (
    tester,
  ) async {
    await tester.pumpWidget(
      _wrap(StayCard(property: _stay(price: null), onTap: () {})),
    );
    expect(find.text('Price on request'), findsOneWidget);
    expect(find.textContaining('/ night'), findsNothing);
  });

  testWidgets('never shows a rating (the backend sends none)', (tester) async {
    await tester.pumpWidget(_wrap(StayCard(property: _stay(), onTap: () {})));
    expect(find.byIcon(Icons.star), findsNothing);
    expect(find.text('New'), findsNothing);
  });

  testWidgets('shows 360 badge only with tour url', (tester) async {
    await tester.pumpWidget(_wrap(StayCard(property: _stay(), onTap: () {})));
    expect(find.text('360 Tour'), findsNothing);

    await tester.pumpWidget(
      _wrap(
        StayCard(
          property: _stay(id: 2, tourUrl: 'https://kuula.co/share/x'),
          onTap: () {},
        ),
      ),
    );
    expect(find.text('360 Tour'), findsOneWidget);
  });

  testWidgets('tap opens detail, heart toggles favorite', (tester) async {
    var opened = false;
    var toggled = false;
    await tester.pumpWidget(
      _wrap(
        StayCard(
          property: _stay(),
          onTap: () => opened = true,
          onFavoriteToggle: () => toggled = true,
        ),
      ),
    );
    await tester.tap(find.byType(StayCard));
    expect(opened, isTrue);
    await tester.tap(find.byIcon(Icons.favorite_border));
    expect(toggled, isTrue);
  });

  testWidgets('filled heart when favorite', (tester) async {
    await tester.pumpWidget(
      _wrap(StayCard(property: _stay(), onTap: () {}, isFavorite: true)),
    );
    expect(find.byIcon(Icons.favorite), findsOneWidget);
  });
}
