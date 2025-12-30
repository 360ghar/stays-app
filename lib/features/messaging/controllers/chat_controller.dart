import 'package:get/get.dart';

import '../../../app/controllers/base/base_controller.dart';
import '../../../app/data/models/message_model.dart';
import '../../../app/data/providers/message_provider.dart';
import '../../../app/utils/logger/app_logger.dart';

class ChatController extends BaseController {
  ChatController({
    required MessageProvider messageProvider,
  }) : _messageProvider = messageProvider;

  final MessageProvider _messageProvider;

  /// Current conversation ID
  final conversationId = ''.obs;

  /// List of messages in the current conversation
  final RxList<MessageModel> messages = <MessageModel>[].obs;

  /// Flag indicating if more messages are being loaded (pagination)
  final isLoadingMore = false.obs;

  /// Flag indicating if a message is being sent
  final isSending = false.obs;

  /// Flag indicating if there are more messages to load
  final hasMoreMessages = true.obs;

  /// Current page for pagination
  int _currentPage = 1;
  static const int _pageSize = 20;

  @override
  void onInit() {
    super.onInit();
    // Get conversation ID from route parameters
    final id = Get.parameters['conversationId'];
    if (id != null && id.isNotEmpty) {
      conversationId.value = id;
      loadMessages();
    }
  }

  /// Load messages for the current conversation
  Future<void> loadMessages() async {
    if (conversationId.value.isEmpty) {
      errorMessage.value = 'No conversation selected';
      return;
    }

    _currentPage = 1;
    hasMoreMessages.value = true;

    await executeWithErrorHandling(() async {
      final result = await _messageProvider.getMessages(
        conversationId.value,
        page: _currentPage,
        limit: _pageSize,
      );
      messages.assignAll(result);
      hasMoreMessages.value = result.length >= _pageSize;
    });
  }

  /// Load more messages (pagination)
  Future<void> loadMoreMessages() async {
    if (isLoadingMore.value || !hasMoreMessages.value) return;

    isLoadingMore.value = true;
    try {
      _currentPage++;
      final result = await _messageProvider.getMessages(
        conversationId.value,
        page: _currentPage,
        limit: _pageSize,
      );
      messages.addAll(result);
      hasMoreMessages.value = result.length >= _pageSize;
    } catch (e, s) {
      _currentPage--; // Revert page on failure
      AppLogger.error('Failed to load more messages', e, s);
    } finally {
      isLoadingMore.value = false;
    }
  }

  /// Send a new message
  Future<void> sendMessage(String content) async {
    if (content.trim().isEmpty || isSending.value) return;

    isSending.value = true;
    try {
      final message = await _messageProvider.sendMessage(
        conversationId.value,
        content.trim(),
      );
      messages.add(message);
    } catch (e, s) {
      AppLogger.error('Failed to send message', e, s);
      errorMessage.value = 'Failed to send message. Please try again.';
    } finally {
      isSending.value = false;
    }
  }

  /// Mark conversation as read
  Future<void> markAsRead() async {
    if (conversationId.value.isEmpty) return;

    try {
      await _messageProvider.markAsRead(conversationId.value);
    } catch (e, s) {
      AppLogger.error('Failed to mark conversation as read', e, s);
      // Non-critical error, don't show to user
    }
  }

  /// Refresh messages
  Future<void> refreshMessages() async {
    await loadMessages();
  }

  /// Clear error message
  @override
  void clearError() {
    errorMessage.value = '';
  }
}
