import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../utils/json_sanitizer.dart';
import '../../utils/debug_logger.dart';

class ClaudeApiService {
  final String apiKey;
  final String baseUrl;
  static const int maxTokensPerRequest = 4096;
  static const int maxInputLength = 10000;
  
  ClaudeApiService({
    required this.apiKey,
    this.baseUrl = 'https://api.anthropic.com/v1',
  });
  
  /// Makes a request to Claude API with automatic text sanitization and chunking
  Future<String> sendMessage({
    required String message,
    String model = 'claude-3-sonnet-20240229',
    int maxTokens = 1024,
    double temperature = 0.7,
    String? systemPrompt,
  }) async {
    try {
      // Sanitize the input message
      final sanitizedMessage = JsonSanitizer.sanitizeString(message);
      
      // Check if we need to chunk the message
      if (sanitizedMessage.length > maxInputLength) {
        return await _sendChunkedMessage(
          message: sanitizedMessage,
          model: model,
          maxTokens: maxTokens,
          temperature: temperature,
          systemPrompt: systemPrompt,
        );
      }
      
      // Single message request
      return await _sendSingleMessage(
        message: sanitizedMessage,
        model: model,
        maxTokens: maxTokens,
        temperature: temperature,
        systemPrompt: systemPrompt,
      );
    } catch (e) {
      DebugLogger.error('Claude API request failed', e);
      rethrow;
    }
  }
  
  /// Sends a single message to Claude API
  Future<String> _sendSingleMessage({
    required String message,
    required String model,
    required int maxTokens,
    required double temperature,
    String? systemPrompt,
  }) async {
    final Map<String, dynamic> requestBody = {
      'model': model,
      'max_tokens': maxTokens,
      'temperature': temperature,
      'messages': [
        if (systemPrompt != null) {
          'role': 'system',
          'content': JsonSanitizer.sanitizeString(systemPrompt),
        },
        {
          'role': 'user',
          'content': message,
        },
      ],
    };
    
    // Sanitize the entire request body
    final sanitizedBody = JsonSanitizer.sanitizeJson(requestBody);
    
    // Encode to JSON with additional safety check
    final jsonBody = JsonSanitizer.safeJsonEncode(sanitizedBody);
    
    DebugLogger.api('🤖 Claude API Request: ${jsonBody.length} chars');
    
    final response = await http.post(
      Uri.parse('$baseUrl/messages'),
      headers: {
        'Content-Type': 'application/json',
        'x-api-key': apiKey,
        'anthropic-version': '2023-06-01',
      },
      body: jsonBody,
    );
    
    if (response.statusCode == 200) {
      final responseData = jsonDecode(response.body);
      final content = responseData['content']?[0]?['text'] ?? '';
      return content;
    } else {
      DebugLogger.error('Claude API Error: ${response.statusCode} - ${response.body}', null);
      throw ClaudeApiException(
        'API request failed',
        statusCode: response.statusCode,
        response: response.body,
      );
    }
  }
  
  /// Sends a chunked message to Claude API
  Future<String> _sendChunkedMessage({
    required String message,
    required String model,
    required int maxTokens,
    required double temperature,
    String? systemPrompt,
  }) async {
    DebugLogger.api('📦 Chunking large message (${message.length} chars)');
    
    final chunks = JsonSanitizer.chunkText(message, chunkSize: maxInputLength);
    final responses = <String>[];
    
    for (int i = 0; i < chunks.length; i++) {
      DebugLogger.api('📤 Sending chunk ${i + 1}/${chunks.length}');
      
      String chunkPrompt = '';
      if (i == 0 && systemPrompt != null) {
        chunkPrompt = '$systemPrompt\n\n';
      }
      
      if (chunks.length > 1) {
        chunkPrompt += 'This is part ${i + 1} of ${chunks.length}. ';
        if (i == 0) {
          chunkPrompt += 'Please wait for all parts before responding fully. ';
        } else if (i == chunks.length - 1) {
          chunkPrompt += 'This is the final part. Please provide your complete response. ';
        } else {
          chunkPrompt += 'More parts will follow. ';
        }
      }
      
      final response = await _sendSingleMessage(
        message: '$chunkPrompt${chunks[i]}',
        model: model,
        maxTokens: maxTokens,
        temperature: temperature,
        systemPrompt: null, // Already included in chunkPrompt for first chunk
      );
      
      responses.add(response);
      
      // Add a small delay between chunks to avoid rate limiting
      if (i < chunks.length - 1) {
        await Future.delayed(const Duration(milliseconds: 500));
      }
    }
    
    // Combine responses
    return responses.join('\n\n');
  }
  
  /// Validates and sanitizes a request body for Claude API
  static Map<String, dynamic> prepareClaudeRequest(Map<String, dynamic> body) {
    // Special handling for Claude API structure
    final prepared = Map<String, dynamic>.from(body);
    
    // Sanitize messages array if present
    if (prepared['messages'] is List) {
      final messages = prepared['messages'] as List;
      prepared['messages'] = messages.map((msg) {
        if (msg is Map<String, dynamic>) {
          final sanitizedMsg = Map<String, dynamic>.from(msg);
          if (sanitizedMsg['content'] is String) {
            sanitizedMsg['content'] = JsonSanitizer.sanitizeString(
              sanitizedMsg['content'] as String
            );
          }
          return sanitizedMsg;
        }
        return msg;
      }).toList();
    }
    
    // Sanitize system prompt if present
    if (prepared['system'] is String) {
      prepared['system'] = JsonSanitizer.sanitizeString(
        prepared['system'] as String
      );
    }
    
    return prepared;
  }
  
  /// Makes a raw request with custom body (with sanitization)
  Future<Map<String, dynamic>> makeRawRequest({
    required String endpoint,
    required Map<String, dynamic> body,
    String method = 'POST',
  }) async {
    try {
      // Prepare and sanitize the request body
      final preparedBody = prepareClaudeRequest(body);
      final jsonBody = JsonSanitizer.safeJsonEncode(preparedBody);
      
      DebugLogger.api('🤖 Claude Raw API Request to $endpoint: ${jsonBody.length} chars');
      
      final uri = Uri.parse('$baseUrl$endpoint');
      late http.Response response;
      
      switch (method.toUpperCase()) {
        case 'POST':
          response = await http.post(
            uri,
            headers: {
              'Content-Type': 'application/json',
              'x-api-key': apiKey,
              'anthropic-version': '2023-06-01',
            },
            body: jsonBody,
          );
          break;
        case 'GET':
          response = await http.get(
            uri,
            headers: {
              'x-api-key': apiKey,
              'anthropic-version': '2023-06-01',
            },
          );
          break;
        default:
          throw ArgumentError('Unsupported method: $method');
      }
      
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      } else {
        DebugLogger.error('Claude API Error: ${response.statusCode} - ${response.body}', null);
        throw ClaudeApiException(
          'API request failed',
          statusCode: response.statusCode,
          response: response.body,
        );
      }
    } catch (e) {
      if (e is ClaudeApiException) {
        rethrow;
      }
      DebugLogger.error('Claude API request failed', e);
      throw ClaudeApiException('Request failed: $e');
    }
  }
}

class ClaudeApiException implements Exception {
  final String message;
  final int? statusCode;
  final String? response;
  
  ClaudeApiException(this.message, {this.statusCode, this.response});
  
  @override
  String toString() {
    if (statusCode != null) {
      return 'ClaudeApiException: $message (Status: $statusCode)';
    }
    return 'ClaudeApiException: $message';
  }
}