import 'package:get/get.dart';
import '../data/services/claude_api_service.dart';
import '../utils/json_sanitizer.dart';
import '../utils/debug_logger.dart';

/// Example controller showing how to use the Claude API with sanitization
class AiChatController extends GetxController {
  late final ClaudeApiService _claudeService;
  
  final RxList<ChatMessage> messages = <ChatMessage>[].obs;
  final RxBool isLoading = false.obs;
  final RxString errorMessage = ''.obs;
  
  @override
  void onInit() {
    super.onInit();
    // Initialize with API key (would come from secure storage in production)
    _claudeService = ClaudeApiService(
      apiKey: 'your-api-key-here', // TODO: Get from secure storage
    );
  }
  
  /// Sends a message to Claude with automatic sanitization
  Future<void> sendMessage(String userMessage) async {
    if (userMessage.trim().isEmpty) return;
    
    try {
      isLoading.value = true;
      errorMessage.value = '';
      
      // Add user message to chat
      messages.add(ChatMessage(
        text: userMessage,
        isUser: true,
        timestamp: DateTime.now(),
      ));
      
      // Log original message for debugging
      DebugLogger.api('📝 Original message length: ${userMessage.length} chars');
      
      // The ClaudeApiService will automatically sanitize and chunk if needed
      final response = await _claudeService.sendMessage(
        message: userMessage,
        systemPrompt: 'You are a helpful assistant for a property booking app.',
        maxTokens: 1024,
        temperature: 0.7,
      );
      
      // Add Claude's response to chat
      messages.add(ChatMessage(
        text: response,
        isUser: false,
        timestamp: DateTime.now(),
      ));
      
    } catch (e) {
      DebugLogger.error('Failed to send message to Claude', e);
      errorMessage.value = 'Failed to send message: ${e.toString()}';
      
      // Add error message to chat
      messages.add(ChatMessage(
        text: 'Sorry, I encountered an error processing your message.',
        isUser: false,
        isError: true,
        timestamp: DateTime.now(),
      ));
    } finally {
      isLoading.value = false;
    }
  }
  
  /// Example of sending a property description with potential Unicode issues
  Future<void> analyzeProperty(Map<String, dynamic> propertyData) async {
    try {
      isLoading.value = true;
      errorMessage.value = '';
      
      // Sanitize property data before creating the prompt
      final sanitizedData = JsonSanitizer.sanitizeJson(propertyData);
      
      // Create a prompt from the sanitized data
      final prompt = '''
      Please analyze this property listing and provide insights:
      
      Title: ${sanitizedData['title'] ?? 'N/A'}
      Description: ${sanitizedData['description'] ?? 'N/A'}
      Price: ${sanitizedData['price'] ?? 'N/A'}
      Location: ${sanitizedData['location'] ?? 'N/A'}
      Features: ${sanitizedData['features'] ?? 'N/A'}
      
      Provide:
      1. A summary of key selling points
      2. Potential concerns or red flags
      3. Suggested questions for the seller
      ''';
      
      final response = await _claudeService.sendMessage(
        message: prompt,
        model: 'claude-3-sonnet-20240229',
        maxTokens: 2048,
      );
      
      messages.add(ChatMessage(
        text: response,
        isUser: false,
        timestamp: DateTime.now(),
      ));
      
    } catch (e) {
      DebugLogger.error('Failed to analyze property', e);
      errorMessage.value = 'Failed to analyze property: ${e.toString()}';
    } finally {
      isLoading.value = false;
    }
  }
  
  /// Example of handling large text input (like terms and conditions)
  Future<void> summarizeLargeText(String largeText) async {
    try {
      isLoading.value = true;
      errorMessage.value = '';
      
      DebugLogger.api('📄 Processing large text: ${largeText.length} chars');
      
      // Check if text needs chunking
      if (largeText.length > 10000) {
        messages.add(ChatMessage(
          text: 'Processing large document in chunks...',
          isUser: false,
          isSystem: true,
          timestamp: DateTime.now(),
        ));
      }
      
      // The service will automatically chunk if needed
      final response = await _claudeService.sendMessage(
        message: 'Please summarize the following text in bullet points:\n\n$largeText',
        maxTokens: 2048,
      );
      
      messages.add(ChatMessage(
        text: response,
        isUser: false,
        timestamp: DateTime.now(),
      ));
      
    } catch (e) {
      DebugLogger.error('Failed to summarize text', e);
      errorMessage.value = 'Failed to summarize: ${e.toString()}';
    } finally {
      isLoading.value = false;
    }
  }
  
  /// Example of making a raw API request with custom parameters
  Future<void> makeCustomRequest(Map<String, dynamic> requestBody) async {
    try {
      isLoading.value = true;
      errorMessage.value = '';
      
      // The service will sanitize the request body automatically
      final response = await _claudeService.makeRawRequest(
        endpoint: '/messages',
        body: requestBody,
      );
      
      // Extract the response text
      final content = response['content']?[0]?['text'] ?? 'No response';
      
      messages.add(ChatMessage(
        text: content,
        isUser: false,
        timestamp: DateTime.now(),
      ));
      
    } catch (e) {
      DebugLogger.error('Custom request failed', e);
      errorMessage.value = 'Request failed: ${e.toString()}';
    } finally {
      isLoading.value = false;
    }
  }
  
  void clearMessages() {
    messages.clear();
    errorMessage.value = '';
  }
}

class ChatMessage {
  final String text;
  final bool isUser;
  final bool isError;
  final bool isSystem;
  final DateTime timestamp;
  
  ChatMessage({
    required this.text,
    required this.isUser,
    this.isError = false,
    this.isSystem = false,
    required this.timestamp,
  });
}