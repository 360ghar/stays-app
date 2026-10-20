import '../../utils/exceptions/app_exceptions.dart';
import 'wire_enums.dart';

/// Request payload for submitting a bug report or feature request.
///
/// Maps to the shared backend contract `POST /api/v1/bugs`.
/// A feature request is `BugType.featureRequest`, a bug is
/// `BugType.functionalityBug` — there is no separate endpoint.
class BugReportRequest {
  const BugReportRequest({
    required this.bugType,
    required this.title,
    required this.description,
    this.source = 'mobile',
    this.severity = BugSeverity.medium,
    this.appVersion,
    this.deviceInfo,
    this.tags,
  });

  /// Where the report originated from (always `"mobile"` for this app).
  final String source;

  /// The backend `BugType`.
  final BugType bugType;

  /// The backend `BugSeverity` (defaults to `medium`).
  final BugSeverity severity;

  /// Short summary. [toMap] trims it and keeps the first 200 characters.
  final String title;

  /// Detailed description. [toMap] trims it and rejects an empty one.
  final String description;

  /// Optional app version string. [toMap] keeps the first 50 characters.
  final String? appVersion;

  /// Optional device metadata.
  final Map<String, dynamic>? deviceInfo;

  /// Optional tags (this app always sends `["stays"]`).
  final List<String>? tags;

  /// The first [max] characters (code points, as the backend counts them).
  static String _clamp(String value, int max) =>
      String.fromCharCodes(value.runes.take(max));

  /// Builds the JSON map, omitting null/empty optional fields. Throws a
  /// [ValidationException] for an empty title or description: the backend
  /// would answer 422 (`BugReportCreate`: title 1 to 200, description at least
  /// 1, app_version at most 50).
  Map<String, dynamic> toMap() {
    final cleanTitle = _clamp(title.trim(), 200);
    final cleanDescription = description.trim();
    if (cleanTitle.isEmpty || cleanDescription.isEmpty) {
      throw ValidationException(
        message: 'Enter a title and a description.',
        errors: {
          if (cleanTitle.isEmpty) 'title': ['Enter a title.'],
          if (cleanDescription.isEmpty) 'description': ['Enter a description.'],
        },
        component: 'feedback',
        operation: 'submitBugReport',
      );
    }
    final map = <String, dynamic>{
      'source': source,
      'bug_type': bugType.wire,
      'severity': severity.wire,
      'title': cleanTitle,
      'description': cleanDescription,
    };

    final version = appVersion == null ? null : _clamp(appVersion!.trim(), 50);
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
