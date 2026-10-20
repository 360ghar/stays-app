import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stays_app/features/inquiry/providers/inquiry_providers.dart';

void main() {
  test('setGuests honors the listing limit and the minimum of one', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final notifier = container.read(inquiryFormProvider.notifier);

    notifier.setGuests(4, max: 4);
    expect(container.read(inquiryFormProvider).guests, 4);
    notifier.setGuests(5, max: 4);
    expect(container.read(inquiryFormProvider).guests, 4);
    notifier.setGuests(0);
    expect(container.read(inquiryFormProvider).guests, 4);
    notifier.setGuests(6);
    expect(container.read(inquiryFormProvider).guests, 6);
  });

  test('changing guests clears the price until it is loaded again', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    container.read(inquiryFormProvider.notifier).setGuests(3);
    expect(container.read(inquiryFormProvider).pricing, isNull);
    expect(container.read(inquiryFormProvider).canSubmit, isFalse);
  });
}
