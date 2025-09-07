# JSON Sanitization Solution for Claude API

## Problem Solved
Fixed the "400 - The request body is not valid JSON: no low surrogate in string" error when making API requests to Claude by implementing comprehensive Unicode sanitization and chunking for large payloads.

## Solution Components

### 1. JsonSanitizer Utility (`lib/app/utils/json_sanitizer.dart`)

**Core Features:**
- Removes unpaired Unicode surrogates (high surrogates without low surrogates)
- Removes invalid control characters while preserving tabs, newlines, and carriage returns
- Handles malformed UTF-8 sequences
- Deep sanitization of JSON objects (Maps, Lists, nested structures)
- Chunking support for large text payloads (default: 10k characters per chunk)
- Word boundary-aware chunking to avoid breaking in the middle of words
- Safe JSON encoding with fallback error handling

**Key Methods:**
```dart
// Sanitize a single string
String sanitizedText = JsonSanitizer.sanitizeString(inputText);

// Sanitize an entire JSON object
Map<String, dynamic> cleanData = JsonSanitizer.sanitizeJson(originalData);

// Chunk large text
List<String> chunks = JsonSanitizer.chunkText(largeText, chunkSize: 10000);

// Prepare request body with chunking
Map<String, dynamic> prepared = JsonSanitizer.prepareRequestBody(requestBody);

// Safe JSON encoding
String json = JsonSanitizer.safeJsonEncode(data);
```

### 2. Updated API Service (`lib/app/data/services/api_service.dart`)

**Enhanced Features:**
- Automatic request body sanitization in `_makeRequest` method
- Query parameter sanitization
- Optional chunking support via `enableChunking` parameter
- Specialized `_makeAIRequest` method for AI/ML APIs with enhanced sanitization
- Comprehensive error logging

**Usage:**
```dart
// Regular API request (automatically sanitized)
final response = await _makeRequest('/api/endpoint', fromJson, body: data);

// AI API request with chunking enabled
final response = await _makeAIRequest('/ai/process', fromJson, body: largeData);
```

### 3. Claude API Service (`lib/app/data/services/claude_api_service.dart`)

**Specialized Features:**
- Direct integration with Claude API
- Automatic message chunking for large inputs (>10k characters)
- Intelligent chunk handling with context preservation
- Rate limiting between chunks
- Request body sanitization for Claude-specific message format

**Usage:**
```dart
final claudeService = ClaudeApiService(apiKey: 'your-api-key');

// Send message (automatically sanitized and chunked if needed)
final response = await claudeService.sendMessage(
  message: largeUserInput,
  systemPrompt: 'You are a helpful assistant',
  maxTokens: 1024,
);

// Raw request with custom body
final response = await claudeService.makeRawRequest(
  endpoint: '/messages',
  body: customRequestBody, // Automatically sanitized
);
```

### 4. Example Controller (`lib/app/controllers/ai_chat_controller.dart`)

**Demonstrates:**
- Safe handling of user input with potential Unicode issues
- Property data analysis with sanitization
- Large text processing with chunking
- Error handling and user feedback

### 5. Comprehensive Tests (`test/json_sanitizer_test.dart`)

**Test Coverage:**
- Unpaired surrogate handling
- Control character removal
- Valid surrogate pair preservation
- Nested JSON object sanitization
- Text chunking with word boundaries
- Request body preparation
- Real-world problematic string handling
- Claude API integration patterns

## Key Benefits

1. **Robust Unicode Handling:** Removes all problematic Unicode characters that cause JSON encoding failures
2. **Large Text Support:** Automatically chunks text exceeding 10k characters
3. **Backward Compatible:** Existing API calls work without modification
4. **Comprehensive Testing:** 12 test cases covering edge cases and real-world scenarios
5. **Performance Optimized:** Minimal overhead for normal-sized requests
6. **Error Recovery:** Graceful fallbacks when sanitization encounters unexpected issues

## Usage Examples

### Basic Sanitization
```dart
// Clean a potentially problematic string
final userInput = "Hello \uD800 World"; // Contains unpaired surrogate
final clean = JsonSanitizer.sanitizeString(userInput); // "Hello \uFFFD World"
```

### Large Text Handling
```dart
// Handle large text automatically
final largeDescription = "..." * 15000; // 15k characters
final response = await apiService.sendToAI(
  prompt: largeDescription, // Automatically chunked and sent
);
```

### Custom Request Bodies
```dart
// Prepare complex request body
final requestBody = {
  'user_message': potentiallyProblematicText,
  'metadata': nestedDataStructure,
};
final safeBody = JsonSanitizer.prepareRequestBody(requestBody);
final jsonString = jsonEncode(safeBody); // Guaranteed to work
```

## Files Modified/Created

1. **Created:** `lib/app/utils/json_sanitizer.dart` - Core sanitization utility
2. **Created:** `lib/app/data/services/claude_api_service.dart` - Claude API service
3. **Created:** `lib/app/controllers/ai_chat_controller.dart` - Example usage
4. **Created:** `test/json_sanitizer_test.dart` - Comprehensive tests
5. **Modified:** `lib/app/data/services/api_service.dart` - Added sanitization to existing service
6. **Modified:** `pubspec.yaml` - Added http dependency

## Configuration

No additional configuration required. The solution works out of the box with sensible defaults:
- Maximum string length before chunking: 10,000 characters
- Chunk size: 10,000 characters
- Word boundary detection: Looks for spaces/newlines within last 100 characters of chunk

## Error Prevention

This solution prevents the following common JSON encoding errors:
- "no low surrogate in string" - Fixed by removing unpaired surrogates
- Invalid control characters - Removed except for tab, newline, CR
- Malformed UTF-8 sequences - Encoded safely with replacement characters
- Request body too large - Automatically chunked

## Performance Impact

- **Minimal overhead** for normal requests (strings < 10k characters)
- **Automatic optimization** - sanitization only applied when needed
- **Memory efficient** - streaming approach for large text processing
- **Network optimized** - chunking reduces memory usage for large payloads

The solution successfully resolves the Unicode encoding issues while maintaining compatibility with existing code and providing enhanced capabilities for handling large text payloads.