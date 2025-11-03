import 'base_provider.dart';

class VisitProvider extends BaseProvider {
  Future<Map<String, dynamic>> createVisit(Map<String, dynamic> payload) async {
    final response = await post('/api/v1/visits/', payload);
    return handleResponse(
      response,
      (json) {
        if (json is Map<String, dynamic>) {
          if (json['visit'] is Map<String, dynamic>) {
            return Map<String, dynamic>.from(
              json['visit'] as Map<String, dynamic>,
            );
          }
          if (json['data'] is Map<String, dynamic>) {
            return Map<String, dynamic>.from(
              json['data'] as Map<String, dynamic>,
            );
          }
          return Map<String, dynamic>.from(json);
        }
        return <String, dynamic>{};
      },
    );
  }

  Future<List<Map<String, dynamic>>> listUserVisits() async {
    final response = await get('/api/v1/visits/');
    return handleResponse(
      response,
      (json) {
        dynamic payload = json;
        if (json is Map<String, dynamic>) {
          payload =
              json['visits'] ??
              json['data'] ??
              json['results'] ??
              json['items'] ??
              json.values.firstWhere(
                (value) => value is List,
                orElse: () => <dynamic>[],
              );
        }
        if (payload is List) {
          return payload
              .whereType<Map>()
              .map(
                (item) => Map<String, dynamic>.from(item as Map),
              )
              .toList();
        }
        return <Map<String, dynamic>>[];
      },
    );
  }
}
