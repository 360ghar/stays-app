/// Utility class for safe JSON parsing and serialization.
///
/// Provides type-safe methods to extract values from JSON maps, with proper
/// null handling and type coercion. Use these methods in models and providers
/// to handle inconsistent API responses gracefully.
class JsonHelpers {
  JsonHelpers._();

  // ===== String Helpers =====

  /// Safely extracts a String from a JSON value.
  /// Returns null if the value cannot be converted to a String.
  static String? getString(dynamic value) {
    if (value == null) return null;
    if (value is String) return value.isEmpty ? null : value;
    return value.toString();
  }

  /// Extracts a String from a JSON value with a default fallback.
  static String getStringOrDefault(dynamic value, [String defaultValue = '']) {
    return getString(value) ?? defaultValue;
  }

  // ===== Integer Helpers =====

  /// Safely extracts an int from a JSON value.
  /// Handles strings that represent integers (e.g., "123").
  static int? getInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) return int.tryParse(value);
    return null;
  }

  /// Extracts an int from a JSON value with a default fallback.
  static int getIntOrDefault(dynamic value, [int defaultValue = 0]) {
    return getInt(value) ?? defaultValue;
  }

  // ===== Double Helpers =====

  /// Safely extracts a double from a JSON value.
  /// Handles strings that represent numbers (e.g., "123.45").
  static double? getDouble(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }

  /// Extracts a double from a JSON value with a default fallback.
  static double getDoubleOrDefault(dynamic value, [double defaultValue = 0.0]) {
    return getDouble(value) ?? defaultValue;
  }

  // ===== Boolean Helpers =====

  /// Safely extracts a bool from a JSON value.
  /// Handles common string representations ("true", "false", "1", "0").
  static bool? getBool(dynamic value) {
    if (value == null) return null;
    if (value is bool) return value;
    if (value is int) return value != 0;
    if (value is String) {
      final lower = value.toLowerCase().trim();
      if (lower == 'true' || lower == '1' || lower == 'yes') return true;
      if (lower == 'false' || lower == '0' || lower == 'no') return false;
    }
    return null;
  }

  /// Extracts a bool from a JSON value with a default fallback.
  static bool getBoolOrDefault(dynamic value, {bool defaultValue = false}) {
    return getBool(value) ?? defaultValue;
  }

  // ===== DateTime Helpers =====

  /// Safely extracts a DateTime from a JSON value.
  /// Handles ISO 8601 strings and Unix timestamps (milliseconds or seconds).
  static DateTime? getDateTime(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    if (value is String) {
      return DateTime.tryParse(value);
    }
    if (value is int) {
      // Assume milliseconds if value is large, seconds otherwise
      if (value > 1e12) {
        return DateTime.fromMillisecondsSinceEpoch(value);
      }
      return DateTime.fromMillisecondsSinceEpoch(value * 1000);
    }
    return null;
  }

  /// Converts a DateTime to ISO 8601 string for JSON serialization.
  static String? toIso8601(DateTime? value) {
    return value?.toIso8601String();
  }

  // ===== List Helpers =====

  /// Safely extracts a List<String> from a JSON value.
  /// Handles: List, comma-separated String, or single String.
  static List<String>? getStringList(dynamic value) {
    if (value == null) return null;
    if (value is List) {
      return value.map((e) => e?.toString()).whereType<String>().toList();
    }
    if (value is String && value.isNotEmpty) {
      if (value.contains(',')) {
        return value.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
      }
      return [value];
    }
    return null;
  }

  /// Safely extracts a List<int> from a JSON value.
  static List<int>? getIntList(dynamic value) {
    if (value == null) return null;
    if (value is List) {
      return value.map((e) => getInt(e)).whereType<int>().toList();
    }
    if (value is String && value.isNotEmpty) {
      return value.split(',').map((e) => int.tryParse(e.trim())).whereType<int>().toList();
    }
    return null;
  }

  /// Safely extracts a List<Map<String, dynamic>> from a JSON value.
  static List<Map<String, dynamic>>? getMapList(dynamic value) {
    if (value == null) return null;
    if (value is List) {
      return value
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
    }
    return null;
  }

  /// Maps a JSON list to a typed list using a converter function.
  /// Returns an empty list if the value is null or not a list.
  static List<T> mapList<T>(
    dynamic value,
    T Function(Map<String, dynamic>) converter,
  ) {
    if (value == null) return <T>[];
    if (value is! List) return <T>[];
    return value
        .whereType<Map>()
        .map((e) => converter(Map<String, dynamic>.from(e)))
        .toList();
  }

  // ===== Map Helpers =====

  /// Safely extracts a Map<String, dynamic> from a JSON value.
  static Map<String, dynamic>? getMap(dynamic value) {
    if (value == null) return null;
    if (value is Map<String, dynamic>) return value;
    if (value is Map) return Map<String, dynamic>.from(value);
    return null;
  }

  /// Extracts a nested value from a JSON map using a path.
  /// Example: getNestedValue(json, ['user', 'profile', 'name'])
  static T? getNestedValue<T>(Map<String, dynamic>? json, List<String> path) {
    if (json == null || path.isEmpty) return null;

    dynamic current = json;
    for (final key in path) {
      if (current is! Map) return null;
      current = current[key];
      if (current == null) return null;
    }

    if (current is T) return current;
    return null;
  }

  // ===== Response Unwrapping =====

  /// Unwraps a standard API response to get the data field.
  /// Handles: { data: {...} } or { data: [...] } or direct data.
  static dynamic unwrapData(dynamic response) {
    if (response == null) return null;
    if (response is Map<String, dynamic>) {
      // Try common envelope patterns
      if (response.containsKey('data')) {
        return response['data'];
      }
      if (response.containsKey('result')) {
        return response['result'];
      }
      if (response.containsKey('results')) {
        return response['results'];
      }
      // Return the map itself if no envelope
      return response;
    }
    return response;
  }

  /// Unwraps a paginated response and returns both data and metadata.
  static ({
    List<Map<String, dynamic>> items,
    int currentPage,
    int totalPages,
    int totalCount,
    int pageSize,
  }) unwrapPaginatedResponse(Map<String, dynamic>? response) {
    if (response == null) {
      return (
        items: <Map<String, dynamic>>[],
        currentPage: 1,
        totalPages: 1,
        totalCount: 0,
        pageSize: 20,
      );
    }

    final data = unwrapData(response);
    final List<Map<String, dynamic>> items;

    if (data is List) {
      items = data.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
    } else {
      items = <Map<String, dynamic>>[];
    }

    return (
      items: items,
      currentPage: getIntOrDefault(response['current_page'] ?? response['page'], 1),
      totalPages: getIntOrDefault(response['total_pages'] ?? response['pages'], 1),
      totalCount: getIntOrDefault(response['total_count'] ?? response['total'] ?? response['count'], items.length),
      pageSize: getIntOrDefault(response['page_size'] ?? response['limit'] ?? response['per_page'], 20),
    );
  }

  // ===== ID Helpers =====

  /// Safely extracts an ID that could be int or String.
  /// Returns as String for flexibility.
  static String? getId(dynamic value) {
    if (value == null) return null;
    if (value is String) return value.isEmpty ? null : value;
    if (value is int) return value.toString();
    return value.toString();
  }

  /// Safely extracts an ID as int.
  static int? getIdAsInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is String) return int.tryParse(value);
    return null;
  }
}
