import 'package:get/get.dart';

import '../../../config/app_config.dart';
import '../../utils/logger/app_logger.dart';
import '../services/storage_service.dart';
import '../../utils/exceptions/app_exceptions.dart';

abstract class BaseProvider extends GetConnect {
  final StorageService _storage = Get.find<StorageService>();

  @override
  void onInit() {
    httpClient.baseUrl = AppConfig.I.apiBaseUrl;
    httpClient.timeout = const Duration(seconds: 30);

    httpClient.addRequestModifier<Object?>((request) async {
      final token = await _storage.getAccessToken();
      if (token != null) {
        request.headers['Authorization'] = 'Bearer $token';
      }
      request.headers['Content-Type'] = 'application/json';
      AppLogger.logRequest({'method': request.method, 'url': request.url.toString()});
      return request;
    });

    httpClient.addResponseModifier<Object?>((request, response) async {
      AppLogger.logResponse({'status': response.statusCode, 'url': request.url.toString()});
      if (response.statusCode == 401) {
        // TODO: refresh token
      }
      return response;
    });
    super.onInit();
  }

  T handleResponse<T>(Response response, T Function(dynamic) parser) {
    if (response.hasError) {
      throw ApiException(
        message: response.body is Map && response.body['message'] != null
            ? response.body['message'] as String
            : 'Unknown error',
        statusCode: response.statusCode,
      );
    }
    return parser(response.body);
  }
}

