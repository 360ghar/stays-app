import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import 'package:stays_app/app/data/models/booking_model.dart';
import 'package:stays_app/core/router/app_router.dart';
import 'package:stays_app/core/theme/tokens.dart';
import 'package:stays_app/core/ui/async_state.dart';
import 'package:stays_app/features/trips/providers/trips_providers.dart';

/// V2 inbox. The chat of a stay is the thread of its booking, so the inbox
/// lists the bookings, newest first. Tap opens the chat with the host.
class InboxScreen extends ConsumerWidget {
  const InboxScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(tripsProvider);
    final notifier = ref.read(tripsProvider.notifier);
    return Scaffold(
      backgroundColor: StayTokens.paper,
      appBar: AppBar(title: const Text('Inbox')),
      body: Builder(
        builder: (context) {
          if (state.isLoading && state.bookings.isEmpty) {
            return const AsyncState.loading(message: 'Loading inbox…');
          }
          if (state.error.isNotEmpty && state.bookings.isEmpty) {
            return AsyncState.error(state.error, onRetry: notifier.refresh);
          }
          if (state.bookings.isEmpty) {
            return const AsyncState.empty(
              message:
                  'No conversations yet. Request a stay to message a host.',
            );
          }
          return RefreshIndicator(
            onRefresh: notifier.refresh,
            child: NotificationListener<ScrollNotification>(
              onNotification: (info) {
                if (info.metrics.pixels >= info.metrics.maxScrollExtent - 400) {
                  notifier.loadMore().ignore();
                }
                return false;
              },
              child: ListView.separated(
                itemCount: state.bookings.length,
                separatorBuilder: (_, _) =>
                    const Divider(height: 1, indent: 72),
                itemBuilder: (context, i) =>
                    _ConversationRow(booking: state.bookings[i]),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _ConversationRow extends StatelessWidget {
  const _ConversationRow({required this.booking});
  final Booking booking;

  @override
  Widget build(BuildContext context) {
    final dates =
        '${DateFormat.MMMd().format(booking.checkInDate)} – '
        '${DateFormat.MMMd().format(booking.checkOutDate)}';
    return ListTile(
      leading: const CircleAvatar(
        backgroundColor: StayTokens.paperWarm,
        child: Icon(Icons.person_outline, color: StayTokens.inkSecondary),
      ),
      title: Text(
        booking.displayTitle,
        style: StayTokens.body.copyWith(fontWeight: FontWeight.w600),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(
        dates,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: StayTokens.bodySecondary,
      ),
      onTap: () => context.push(AppPaths.chat('${booking.id}')),
    );
  }
}
