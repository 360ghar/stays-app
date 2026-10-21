import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:stays_app/app/data/models/booking_model.dart';
import 'package:stays_app/app/data/models/cursor_page.dart';
import 'package:stays_app/app/data/models/message_model.dart';
import 'package:stays_app/app/data/providers/bookings_provider.dart';
import 'package:stays_app/app/utils/exceptions/app_exceptions.dart';
import 'package:stays_app/core/providers/data_providers.dart';
import 'package:stays_app/features/messaging/providers/chat_providers.dart';

import '../contract/support/wire.dart';

MessageModel _message(int id, int sender, String body) => MessageModel(
  id: id,
  senderId: sender,
  body: body,
  createdAt: DateTime.utc(2026, 9, 30, 10, id % 60),
);

class _FakeChat extends BookingsProvider {
  final sent = <String>[];
  final cursors = <String?>[];
  Object? sendFailure;

  @override
  Future<Booking> getBooking(int id) async =>
      Booking.fromJson(obj(fixture('bookings')['created']));

  @override
  Future<CursorPage<MessageModel>> listMessages(
    int bookingId, {
    String? cursor,
    int limit = 50,
  }) async {
    cursors.add(cursor);
    // Newest first, like the backend.
    if (cursor == null) {
      return CursorPage(
        items: [_message(5, 7, 'Welcome'), _message(4, 50, 'Hello')],
        nextCursor: 'older',
        hasMore: true,
        limit: 2,
      );
    }
    return CursorPage(
      items: [_message(3, 7, 'Earlier'), _message(2, 50, 'First')],
      nextCursor: null,
      hasMore: false,
      limit: 2,
    );
  }

  @override
  Future<MessageModel> sendMessage(int bookingId, String body) async {
    sent.add(body);
    final failure = sendFailure;
    if (failure != null) throw failure;
    return _message(6, 50, body);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(useTestConfig);

  late _FakeChat fake;
  late ProviderContainer container;

  setUp(() async {
    fake = _FakeChat();
    container = ProviderContainer(
      overrides: [bookingsProviderProvider.overrideWithValue(fake)],
    );
    addTearDown(container.dispose);
    container.listen(chatProvider(14), (_, _) {});
    await pumpEventQueue();
  });

  ChatUiState state() => container.read(chatProvider(14));
  ChatNotifier notifier() => container.read(chatProvider(14).notifier);

  test('messages are shown oldest first and the guest is known', () {
    expect(state().isLoading, isFalse);
    expect(state().messages.map((m) => m.id), [4, 5]);
    // The booking in the fixture belongs to user 50.
    expect(state().myUserId, 50);
    expect(state().title, 'Sea View Villa 1');
    expect(state().hasOlder, isTrue);
    expect(state().messages.first.isMine(50), isTrue);
    expect(state().messages.last.isMine(50), isFalse);
  });

  test(
    'loadOlder sends the cursor and puts the page before the others',
    () async {
      await notifier().loadOlder();
      expect(fake.cursors, [null, 'older']);
      expect(state().messages.map((m) => m.id), [2, 3, 4, 5]);
      expect(state().hasOlder, isFalse);

      await notifier().loadOlder();
      expect(fake.cursors, [null, 'older']);
    },
  );

  test('send adds the saved message after the others', () async {
    await notifier().send('  Thanks!  ');
    expect(fake.sent, ['Thanks!']);
    expect(state().messages.map((m) => m.id), [4, 5, 6]);
    expect(state().messages.any((m) => m.pending), isFalse);
    expect(state().isSending, isFalse);
    expect(state().error, isEmpty);
  });

  test(
    'a failed send removes the pending message and shows the reason',
    () async {
      fake.sendFailure = ApiException(
        message: 'body: Message is too long',
        statusCode: 422,
        code: 'VALIDATION_ERROR',
      );
      await notifier().send('Hi');
      expect(state().messages.map((m) => m.id), [4, 5]);
      expect(state().error, 'body: Message is too long');
      expect(state().isSending, isFalse);
    },
  );

  test('a blank message is not sent', () async {
    await notifier().send('   ');
    expect(fake.sent, isEmpty);
  });

  test(
    'a message over 2000 characters is refused before the request',
    () async {
      await notifier().send('x' * (maxMessageLength + 1));
      expect(fake.sent, isEmpty);
      expect(state().error, contains('2000'));
    },
  );
}
