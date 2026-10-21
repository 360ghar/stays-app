// The generated wire enums carry exactly the values the backend publishes
// (test/fixtures/api/enums.json, written by tool/gen_enums.py). An unknown
// value reads as null. It is never turned into a real member.

import 'package:flutter_test/flutter_test.dart';
import 'package:stays_app/app/data/models/wire_enums.dart';

import 'support/wire.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(useTestConfig);

  final published = fixture('enums');

  final generated = <String, List<WireEnum>>{
    'PropertyType': PropertyType.values,
    'PropertyPurpose': PropertyPurpose.values,
    'PropertyStatus': PropertyStatus.values,
    'SortBy': SortBy.values,
    'BookingStatus': BookingStatus.values,
    'PaymentStatus': PaymentStatus.values,
    'ImageCategory': ImageCategory.values,
    'UserRole': UserRole.values,
    'AppKey': AppKey.values,
    'DevicePlatform': DevicePlatform.values,
    'AuthMethod': AuthMethod.values,
    'BugType': BugType.values,
    'BugSeverity': BugSeverity.values,
    'IdentifierChannel': IdentifierChannel.values,
    'IdentifierNextStep': IdentifierNextStep.values,
    'AuthGateStage': AuthGateStage.values,
    'AuthGateAction': AuthGateAction.values,
  };

  test('every published enum has a generated counterpart', () {
    expect(generated.keys.toSet(), published.keys.toSet());
  });

  for (final entry in generated.entries) {
    test('${entry.key} has the backend wire values', () {
      expect(
        entry.value.map((e) => e.wire).toList(),
        (published[entry.key] as List).cast<String>(),
      );
    });
  }

  test('a known value round-trips through fromJson and toJson', () {
    expect(PropertyPurpose.fromJson('short_stay'), PropertyPurpose.shortStay);
    expect(PropertyPurpose.shortStay.toJson(), 'short_stay');
    expect(SortBy.fromJson('price_low'), SortBy.priceLow);
    expect(BookingStatus.fromJson('checked_in'), BookingStatus.checkedIn);
    expect(AppKey.stays.wire, 'stays');
  });

  test('an unknown or missing value reads as null', () {
    expect(PropertyType.fromJson('castle'), isNull);
    expect(PropertyType.fromJson(null), isNull);
    expect(PropertyType.fromJson(3), isNull);
    expect(SortBy.fromJson('rating'), isNull);
    expect(BookingStatus.fromJson(''), isNull);
    expect(const PropertyTypeConverter().fromJson('castle'), isNull);
    expect(const PropertyTypeConverter().toJson(null), isNull);
  });

  test('the retired app key is not an AppKey', () {
    expect(AppKey.fromJson('ghar360'), isNull);
  });
}
