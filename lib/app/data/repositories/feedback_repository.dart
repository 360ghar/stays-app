import '../models/feedback_model.dart';
import '../providers/feedback_provider.dart';

class FeedbackRepository {
  FeedbackRepository({required FeedbackProvider provider})
    : _provider = provider;

  final FeedbackProvider _provider;

  Future<void> submitBugReport(BugReportRequest request) =>
      _provider.submitBugReport(request);
}
