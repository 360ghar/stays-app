import '../../utils/logger/app_logger.dart';
import '../models/visit_model.dart';
import '../providers/visit_provider.dart';

class VisitRepository {
  VisitRepository({required VisitProvider provider}) : _provider = provider;

  final VisitProvider _provider;

  Future<Visit> createVisit(Map<String, dynamic> payload) async {
    try {
      final response = await _provider.createVisit(payload);
      return Visit.fromJson(response);
    } catch (error, stackTrace) {
      AppLogger.error('Failed to create visit', error, stackTrace);
      rethrow;
    }
  }

  Future<List<Visit>> getUserVisits() async {
    try {
      final response = await _provider.listUserVisits();
      return response.map(Visit.fromJson).toList();
    } catch (error, stackTrace) {
      AppLogger.error('Failed to fetch visits', error, stackTrace);
      rethrow;
    }
  }
}
