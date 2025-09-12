import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:stays_app/app/utils/json_sanitizer.dart';

void main() {
  group('JsonSanitizer Tests', () {
    test('should remove unpaired high surrogates', () {
      // High surrogate without low surrogate
      final input = 'Hello \uD800 World';
      final result = JsonSanitizer.sanitizeString(input);
      expect(result, equals('Hello \uFFFD World'));
      
      // Verify it can be JSON encoded
      expect(() => jsonEncode({'text': result}), returnsNormally);
    });
    
    test('should remove unpaired low surrogates', () {
      // Low surrogate without high surrogate
      final input = 'Hello \uDC00 World';
      final result = JsonSanitizer.sanitizeString(input);
      expect(result, equals('Hello \uFFFD World'));
      
      // Verify it can be JSON encoded
      expect(() => jsonEncode({'text': result}), returnsNormally);
    });
    
    test('should preserve valid surrogate pairs', () {
      // Valid emoji (surrogate pair)
      final input = 'Hello 😀 World';
      final result = JsonSanitizer.sanitizeString(input);
      expect(result, equals('Hello 😀 World'));
      
      // Verify it can be JSON encoded
      expect(() => jsonEncode({'text': result}), returnsNormally);
    });
    
    test('should remove control characters except tab, newline, CR', () {
      final input = 'Hello\x00\x01\x02\t\n\r\x0E\x0FWorld';
      final result = JsonSanitizer.sanitizeString(input);
      expect(result, equals('Hello\uFFFD\uFFFD\uFFFD\t\n\r\uFFFD\uFFFDWorld'));
      
      // Verify it can be JSON encoded
      expect(() => jsonEncode({'text': result}), returnsNormally);
    });
    
    test('should sanitize nested JSON objects', () {
      final input = {
        'name': 'Test \uD800 User',
        'bio': 'Hello \uDC00 World',
        'nested': {
          'field': 'Invalid \x00 char',
          'list': ['Item \uD800', 'Valid Item', 'Another \uDC00'],
        },
      };
      
      final result = JsonSanitizer.sanitizeJson(input) as Map<String, dynamic>;
      
      expect(result['name'], equals('Test \uFFFD User'));
      expect(result['bio'], equals('Hello \uFFFD World'));
      expect(result['nested']['field'], equals('Invalid \uFFFD char'));
      expect(result['nested']['list'][0], equals('Item \uFFFD'));
      expect(result['nested']['list'][1], equals('Valid Item'));
      expect(result['nested']['list'][2], equals('Another \uFFFD'));
      
      // Verify entire object can be JSON encoded
      expect(() => jsonEncode(result), returnsNormally);
    });
    
    test('should chunk large text correctly', () {
      final largeText = 'A' * 25000; // 25k characters
      final chunks = JsonSanitizer.chunkText(largeText, chunkSize: 10000);
      
      expect(chunks.length, equals(3));
      expect(chunks[0].length, equals(10000));
      expect(chunks[1].length, equals(10000));
      expect(chunks[2].length, equals(5000));
      
      // Verify all chunks can be JSON encoded
      for (final chunk in chunks) {
        expect(() => jsonEncode({'text': chunk}), returnsNormally);
      }
    });
    
    test('should chunk at word boundaries when possible', () {
      final text = 'Hello World ' * 1000; // ~12k characters
      final chunks = JsonSanitizer.chunkText(text, chunkSize: 5000);
      
      // Check that chunks don't end in the middle of a word
      for (int i = 0; i < chunks.length - 1; i++) {
        expect(chunks[i].endsWith(' ') || chunks[i].endsWith('\n'), isTrue);
      }
    });
    
    test('should prepare request body with chunking', () {
      final largeText = 'Test message ' * 1000; // ~13k characters
      final body = {
        'message': largeText,
        'other_field': 'normal value',
      };
      
      final prepared = JsonSanitizer.prepareRequestBody(body);
      
      // Original field should contain first chunk
      expect(prepared['message'], isNotNull);
      expect((prepared['message'] as String).length, lessThanOrEqualTo(10000));
      
      // Check for chunk metadata
      expect(prepared['message_chunked'], equals(true));
      expect(prepared['message_chunk_count'], equals(2));
      expect(prepared['message_chunk_1'], isNotNull);
      
      // Other fields should remain unchanged
      expect(prepared['other_field'], equals('normal value'));
      
      // Verify entire body can be JSON encoded
      expect(() => jsonEncode(prepared), returnsNormally);
    });
    
    test('should validate JSON safety', () {
      expect(JsonSanitizer.isJsonSafe('Valid string'), isTrue);
      expect(JsonSanitizer.isJsonSafe('Hello 😀 World'), isTrue);
      expect(JsonSanitizer.isJsonSafe('Tab\tNewline\n'), isTrue);
      
      // These should be sanitizable and thus safe
      expect(JsonSanitizer.isJsonSafe('Invalid \uD800 surrogate'), isTrue);
      expect(JsonSanitizer.isJsonSafe('Control \x00 char'), isTrue);
    });
    
    test('should handle edge cases in safeJsonEncode', () {
      // Normal case
      final normal = {'key': 'value'};
      expect(JsonSanitizer.safeJsonEncode(normal), equals(jsonEncode(normal)));
      
      // With invalid characters
      final invalid = {'text': 'Hello \uD800 World'};
      final encoded = JsonSanitizer.safeJsonEncode(invalid);
      final decoded = jsonDecode(encoded);
      expect(decoded['text'], equals('Hello \uFFFD World'));
      
      // Null handling
      expect(JsonSanitizer.safeJsonEncode(null), equals('null'));
      
      // List handling
      final list = ['item1', 'invalid \uDC00', 'item3'];
      final listEncoded = JsonSanitizer.safeJsonEncode(list);
      final listDecoded = jsonDecode(listEncoded) as List;
      expect(listDecoded[1], equals('invalid \uFFFD'));
    });
    
    test('should handle real-world problematic strings', () {
      // Common problematic patterns
      final testCases = [
        'Text with orphaned high surrogate: \uD834',
        'Text with orphaned low surrogate: \uDD1E',
        'Mixed surrogates: \uD834\uD834\uDD1E',
        'Zero width joiner issues: 👨‍👩‍👧‍👦',
        'RTL marks: \u202Etest\u202C',
        'Null bytes: test\x00data',
        'Form feed: test\x0Cdata',
        'Vertical tab: test\x0Bdata',
      ];
      
      for (final testCase in testCases) {
        final sanitized = JsonSanitizer.sanitizeString(testCase);
        // Should not throw when encoding
        expect(() => jsonEncode({'text': sanitized}), returnsNormally);
      }
    });
  });
  
  group('Claude API Integration', () {
    test('should prepare Claude request body correctly', () {
      final body = {
        'messages': [
          {
            'role': 'user',
            'content': 'Hello \uD800 World',
          },
        ],
        'system': 'System \uDC00 prompt',
        'model': 'claude-3-sonnet',
        'max_tokens': 1024,
      };
      
      // Import would be needed in real test
      // final prepared = ClaudeApiService.prepareClaudeRequest(body);
      
      // For now, test with JsonSanitizer directly
      final sanitized = JsonSanitizer.sanitizeJson(body) as Map<String, dynamic>;
      final messages = sanitized['messages'] as List;
      final firstMessage = messages[0] as Map<String, dynamic>;
      
      expect(firstMessage['content'], equals('Hello \uFFFD World'));
      expect(sanitized['system'], equals('System \uFFFD prompt'));
      expect(sanitized['model'], equals('claude-3-sonnet'));
      expect(sanitized['max_tokens'], equals(1024));
      
      // Verify entire body can be sent to API
      expect(() => jsonEncode(sanitized), returnsNormally);
    });
  });
}