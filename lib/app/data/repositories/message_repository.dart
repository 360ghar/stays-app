import '../providers/message_provider.dart';

class MessageRepository {
  final MessageProvider _provider;
  MessageRepository({required MessageProvider provider}) : _provider = provider;

  // Placeholder to use the provider and avoid unused field warning
  Future<void> ping() async {
    // In real impl, call conversation endpoints via _provider
    // Touch provider to avoid unused field warning
    // ignore: unnecessary_statements
    _provider.hashCode;
  }
}
