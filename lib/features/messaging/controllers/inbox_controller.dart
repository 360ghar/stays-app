import 'dart:async';

import 'package:get/get.dart';

import 'package:stays_app/app/controllers/base/base_controller.dart';
import 'package:stays_app/app/data/models/message_model.dart';
import 'package:stays_app/app/data/repositories/message_repository.dart';
import 'package:stays_app/app/utils/helpers/app_snackbar.dart';
import 'package:stays_app/app/utils/logger/app_logger.dart';

/// Lists all conversations for the current user (the "Inbox").
class InboxController extends BaseController {
  InboxController({required MessageRepository repository})
    : _repository = repository;

  final MessageRepository _repository;
  final RxList<ConversationModel> conversations = <ConversationModel>[].obs;

  @override
  void onInit() {
    super.onInit();
    unawaited(loadConversations());
  }

  Future<void> loadConversations() async {
    isLoading.value = true;
    errorMessage.value = '';
    try {
      final list = await _repository.listConversations();
      conversations.assignAll(list);
    } catch (e, s) {
      AppLogger.error('Failed to load conversations', e, s);
      errorMessage.value = 'Could not load conversations';
      AppSnackbar.warning(
        title: 'Inbox',
        message: 'Could not load conversations. Pull to retry.',
      );
    } finally {
      isLoading.value = false;
    }
  }

  void openConversation(String conversationId) {
    Get.toNamed('/chat/$conversationId');
  }
}
