extension QueryParams on Map {
  /// Convert a dynamic map to query parameters.
  /// - Removes nulls and empty lists
  /// - Keeps a list as a list. Dio sends it as repeated keys (`a=1&a=2`),
  ///   which is how the backend reads a list filter. A comma-joined value
  ///   would arrive as one wrong value.
  Map<String, dynamic> asQueryParams() {
    final out = <String, dynamic>{};
    forEach((key, value) {
      if (value == null) return;
      final name = key.toString();
      if (value is List) {
        if (value.isNotEmpty) out[name] = [for (final v in value) v.toString()];
      } else {
        out[name] = value.toString();
      }
    });
    return out;
  }
}
