import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import 'package:stays_app/app/data/models/message_model.dart';
import 'package:stays_app/core/router/app_router.dart';
import 'package:stays_app/core/theme/tokens.dart';
import 'package:stays_app/core/ui/async_state.dart';
import 'package:stays_app/features/messaging/providers/inbox_providers.dart';

/// V2 inbox. Newest first. Tap opens the conversation.
class InboxScreen extends ConsumerWidget {
  const InboxScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(inboxProvider);
    final notifier = ref.read(inboxProvider.notifier);
    return Scaffold(
      backgroundColor: StayTokens.paper,
      appBar: AppBar(title: const Text('Inbox')),
      body: Builder(
        builder: (context) {
          if (state.isLoading && state.conversations.isEmpty) {
            return const AsyncState.loading(message: 'Loading inbox…');
          }
          if (state.error.isNotEmpty && state.conversations.isEmpty) {
            return AsyncState.error(state.error, onRetry: notifier.load);
          }
          if (state.conversations.isEmpty) {
            return const AsyncState.empty(message: 'No conversations yet.');
          }
          return RefreshIndicator(
            onRefresh: notifier.refresh,
            child: ListView.separated(
              itemCount: state.conversations.length,
              separatorBuilder: (_, _) => const Divider(height: 1, indent: 72),
              itemBuilder: (context, i) =>
                  _ConversationRow(conversation: state.conversations[i]),
            ),
          );
        },
      ),
    );
  }
}

class _ConversationRow extends StatelessWidget {
  const _ConversationRow({required this.conversation});
  final ConversationModel conversation;

  @override
  Widget build(BuildContext context) {
    final when = conversation.lastMessageAt ?? conversation.createdAt;
    return ListTile(
      leading: const CircleAvatar(
        backgroundColor: StayTokens.paperWarm,
        child: Icon(Icons.person_outline, color: StayTokens.inkSecondary),
      ),
      title: Text(
        'Stay #${conversation.propertyId ?? conversation.bookingId ?? '–'}',
        style: StayTokens.body.copyWith(fontWeight: FontWeight.w600),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(
        conversation.lastMessage ?? 'Say hello to your host.',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: StayTokens.bodySecondary,
      ),
      trailing: Text(DateFormat.MMMd().format(when), style: StayTokens.label),
      onTap: () => context.push(AppPaths.chat(conversation.id)),
    );
  }
}
