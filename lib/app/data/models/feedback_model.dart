/// Request payload for submitting a bug report or feature request.
///
/// Maps to the shared backend contract `POST /api/v1/bugs`.
/// A feature request is represented as `bug_type: "feature_request"`,
/// a bug as `bug_type: "functionality_bug"` — there is no separate endpoint.
class BugReportRequest {
  const BugReportRequest({
    required this.bugType,
    required this.title,
    required this.description,
    this.source = 'mobile',
    this.severity = 'medium',
    this.appVersion,
    this.deviceInfo,
    this.tags,
  });

  factory BugReportRequest.fromMap(Map<String, dynamic> map) {
    return BugReportRequest(
      source: map['source'] as String? ?? 'mobile',
      bugType: map['bug_type'] as String? ?? 'other',
      severity: map['severity'] as String? ?? 'medium',
      title: map['title'] as String? ?? '',
      description: map['description'] as String? ?? '',
      appVersion: map['app_version'] as String?,
      deviceInfo: map['device_info'] is Map<String, dynamic>
          ? Map<String, dynamic>.from(map['device_info'] as Map)
          : null,
      tags: map['tags'] is List
          ? (map['tags'] as List).map((e) => e.toString()).toList()
          : null,
    );
  }

  /// Where the report originated from (always `"mobile"` for this app).
  final String source;

  /// One of `ui_bug|functionality_bug|performance_issue|crash|feature_request|other`.
  final String bugType;

  /// One of `low|medium|high|critical` (defaults to `"medium"`).
  final String severity;

  /// Short summary (1–200 chars).
  final String title;

  /// Detailed description (required).
  final String description;

  /// Optional app version string.
  final String? appVersion;

  /// Optional device metadata.
  final Map<String, dynamic>? deviceInfo;

  /// Optional tags (this app always sends `["stays"]`).
  final List<String>? tags;

  /// Builds the JSON map, omitting null/empty optional fields.
  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{
      'source': source,
      'bug_type': bugType,
      'severity': severity,
      'title': title,
      'description': description,
    };

    final version = appVersion?.trim();
    if (version != null && version.isNotEmpty) {
      map['app_version'] = version;
    }

    final info = deviceInfo;
    if (info != null && info.isNotEmpty) {
      map['device_info'] = info;
    }

    final tagList = tags;
    if (tagList != null && tagList.isNotEmpty) {
      map['tags'] = tagList;
    }

    return map;
  }

  /// Alias used by the provider when posting the request.
  Map<String, dynamic> toJson() => toMap();
}
