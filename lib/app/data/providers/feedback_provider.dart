import '../../utils/services/error_service.dart';
import '../models/feedback_model.dart';
import 'base_provider.dart';

class FeedbackProvider extends BaseProvider {
  /// Submits a bug report / feature request to the shared backend.
  ///
  /// A feature request is sent as `bug_type: "feature_request"`, a bug as
  /// `bug_type: "functionality_bug"` — both via `POST /api/v1/bugs`.
  Future<void> submitBugReport(BugReportRequest request) async {
    final response = await post('/api/v1/bugs', request.toJson());
    if (!response.isOk) {
      throw ErrorService.I.toApiException(response);
    }
  }
}
