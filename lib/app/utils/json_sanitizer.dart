import 'dart:convert';

class JsonSanitizer {
  static const int _maxStringLength = 10000;
  
  /// Sanitizes a string by removing invalid Unicode characters
  static String sanitizeString(String input) {
    if (input.isEmpty) return input;
    
    try {
      // First pass: encode to UTF-8 and back to remove invalid sequences
      final utf8Bytes = utf8.encode(input);
      String cleaned = utf8.decode(utf8Bytes, allowMalformed: true);
      
      // Second pass: remove unpaired surrogates and invalid characters
      final StringBuffer buffer = StringBuffer();
      final int length = cleaned.length;
      
      for (int i = 0; i < length; i++) {
        final int char = cleaned.codeUnitAt(i);
        
        // Check for high surrogate (0xD800-0xDBFF)
        if (char >= 0xD800 && char <= 0xDBFF) {
          // Check if there's a valid low surrogate following
          if (i + 1 < length) {
            final int nextChar = cleaned.codeUnitAt(i + 1);
            if (nextChar >= 0xDC00 && nextChar <= 0xDFFF) {
              // Valid surrogate pair
              buffer.write(cleaned[i]);
              buffer.write(cleaned[i + 1]);
              i++; // Skip the low surrogate
              continue;
            }
          }
          // Invalid high surrogate - replace with replacement character
          buffer.write('\uFFFD');
        }
        // Check for orphaned low surrogate (0xDC00-0xDFFF)
        else if (char >= 0xDC00 && char <= 0xDFFF) {
          // Invalid low surrogate - replace with replacement character
          buffer.write('\uFFFD');
        }
        // Check for other invalid characters
        else if (_isValidUnicodeChar(char)) {
          buffer.write(cleaned[i]);
        } else {
          // Replace invalid character with replacement character
          buffer.write('\uFFFD');
        }
      }
      
      return buffer.toString();
    } catch (e) {
      // If all else fails, return a safe version
      return _createSafeString(input);
    }
  }
  
  /// Checks if a character code is a valid Unicode character
  static bool _isValidUnicodeChar(int char) {
    // Control characters (except tab, newline, carriage return)
    if (char < 0x20 && char != 0x09 && char != 0x0A && char != 0x0D) {
      return false;
    }
    // DEL character
    if (char == 0x7F) {
      return false;
    }
    // C1 control characters
    if (char >= 0x80 && char <= 0x9F) {
      return false;
    }
    // Non-characters
    if ((char >= 0xFDD0 && char <= 0xFDEF) ||
        (char & 0xFFFE) == 0xFFFE) {
      return false;
    }
    return true;
  }
  
  /// Creates a safe ASCII-only version of the string
  static String _createSafeString(String input) {
    final StringBuffer buffer = StringBuffer();
    for (int i = 0; i < input.length && i < _maxStringLength; i++) {
      final int char = input.codeUnitAt(i);
      if (char >= 0x20 && char <= 0x7E) {
        buffer.write(input[i]);
      } else if (char == 0x09 || char == 0x0A || char == 0x0D) {
        buffer.write(input[i]);
      } else {
        buffer.write('?');
      }
    }
    return buffer.toString();
  }
  
  /// Sanitizes an entire JSON object recursively
  static dynamic sanitizeJson(dynamic json) {
    if (json == null) {
      return null;
    } else if (json is String) {
      return sanitizeString(json);
    } else if (json is Map) {
      final Map<String, dynamic> result = <String, dynamic>{};
      json.forEach((key, value) {
        final sanitizedKey = sanitizeJson(key);
        final sanitizedValue = sanitizeJson(value);
        result[sanitizedKey.toString()] = sanitizedValue;
      });
      return result;
    } else if (json is List) {
      return json.map((item) => sanitizeJson(item)).toList();
    } else {
      // Numbers, booleans, etc. are safe
      return json;
    }
  }
  
  /// Chunks a large text into smaller pieces
  static List<String> chunkText(String text, {int chunkSize = 10000}) {
    if (text.length <= chunkSize) {
      return [sanitizeString(text)];
    }
    
    final List<String> chunks = [];
    final String sanitized = sanitizeString(text);
    
    for (int i = 0; i < sanitized.length; i += chunkSize) {
      final int end = (i + chunkSize < sanitized.length) 
          ? i + chunkSize 
          : sanitized.length;
      
      // Try to break at a word boundary if possible
      int actualEnd = end;
      if (end < sanitized.length) {
        // Look for the last space within the last 100 characters
        for (int j = end - 1; j >= end - 100 && j >= i; j--) {
          if (sanitized[j] == ' ' || sanitized[j] == '\n') {
            actualEnd = j + 1;
            break;
          }
        }
      }
      
      chunks.add(sanitized.substring(i, actualEnd));
      i = actualEnd - chunkSize; // Adjust i for the actual end position
    }
    
    return chunks;
  }
  
  /// Prepares a request body for JSON encoding
  static Map<String, dynamic> prepareRequestBody(Map<String, dynamic> body) {
    // Deep clone and sanitize the body
    final sanitized = sanitizeJson(body) as Map<String, dynamic>;
    
    // Check for large text fields and chunk them if necessary
    final keysToProcess = sanitized.keys.toList(); // Create a copy to avoid concurrent modification
    for (final key in keysToProcess) {
      final value = sanitized[key];
      if (value is String && value.length > _maxStringLength) {
        // Store chunks with a special key pattern
        final chunks = chunkText(value);
        if (chunks.length > 1) {
          sanitized[key] = chunks.first; // Keep first chunk in original field
          // Add additional chunks with indexed keys
          for (int i = 1; i < chunks.length; i++) {
            sanitized['${key}_chunk_$i'] = chunks[i];
          }
          // Add metadata about chunking
          sanitized['${key}_chunked'] = true;
          sanitized['${key}_chunk_count'] = chunks.length;
        }
      }
    }
    
    return sanitized;
  }
  
  /// Validates that a string can be safely encoded as JSON
  static bool isJsonSafe(String input) {
    try {
      final sanitized = sanitizeString(input);
      jsonEncode({'test': sanitized});
      return true;
    } catch (e) {
      return false;
    }
  }
  
  /// Encodes an object to JSON with sanitization
  static String safeJsonEncode(dynamic object) {
    try {
      final sanitized = sanitizeJson(object);
      return jsonEncode(sanitized);
    } catch (e) {
      // If encoding still fails, return a safe error message
      return jsonEncode({
        'error': 'Failed to encode data',
        'message': 'The data contained invalid characters that could not be sanitized'
      });
    }
  }
}