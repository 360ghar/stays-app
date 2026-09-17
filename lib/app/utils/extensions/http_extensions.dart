extension QueryParams on Map {
  /// Convert dynamic map to `Map<String, String>` for query parameters.
  /// - Removes nulls
  /// - Joins lists with comma
  Map<String, String> asQueryParams() {
    final out = <String, String>{};
    forEach((key, value) {
      if (value == null) return;
      final name = key.toString();
      if (value is List) {
        if (value.isNotEmpty) out[name] = value.join(',');
      } else {
        out[name] = value.toString();
      }
    });
    return out;
  }
}
