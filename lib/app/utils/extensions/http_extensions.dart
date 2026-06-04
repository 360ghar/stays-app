import 'dart:convert';
import 'package:get/get.dart';

extension QueryParams on Map<String, dynamic> {
  /// Convert dynamic map to `Map<String, String>` for query parameters.
  /// - Removes nulls
  /// - Joins lists with comma
  Map<String, String> asQueryParams() {
    final out = <String, String>{};
    forEach((key, value) {
      if (value == null) return;
      if (value is List) {
        if (value.isNotEmpty) out[key] = value.join(',');
      } else {
        out[key] = value.toString();
      }
    });
    return out;
  }
}

extension ResponseParsing on Response {
  /// Safely coerce a response body into a JSON map.
  /// Returns empty map if not decodable.
  Map<String, dynamic> bodyAsMap() {
    final b = body;
    if (b is Map) return Map<String, dynamic>.from(b);
    final s = bodyString;
    if (s != null && s.isNotEmpty) {
      try {
        final decoded = jsonDecode(s);
        if (decoded is Map) return Map<String, dynamic>.from(decoded);
      } catch (_) {}
    }
    return <String, dynamic>{};
  }
}
