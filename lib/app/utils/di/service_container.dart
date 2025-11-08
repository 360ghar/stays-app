import 'package:get/get.dart';

import '../logger/app_logger.dart';
import '../services/error_service.dart';
import '../services/validation_service.dart';

/// Service container for managing dependency injection with proper scoping.
/// Replaces direct Get.find calls with typed, safe dependency resolution.
class ServiceContainer {
  static final ServiceContainer _instance = ServiceContainer._internal();
  factory ServiceContainer() => _instance;
  ServiceContainer._internal();

  /// Core services that should be permanent and app-wide
  void registerCoreServices() {
    if (!Get.isRegistered<ErrorService>()) {
      Get.put<ErrorService>(ErrorService(), permanent: true);
    }
    if (!Get.isRegistered<ValidationService>()) {
      Get.put<ValidationService>(ValidationService(), permanent: true);
    }
  }

  /// Register a service with lazy loading (not permanent)
  void registerLazy<T>(T Function() factory) {
    if (!Get.isRegistered<T>()) {
      Get.lazyPut<T>(factory);
    }
  }

  /// Register a service instance
  void put<T>(T service, {bool permanent = false}) {
    if (!Get.isRegistered<T>()) {
      Get.put<T>(service, permanent: permanent);
      AppLogger.debug('Service registered: $T (permanent: $permanent)');
    } else {
      AppLogger.warning('Service $T already registered, skipping registration.');
    }
  }

  /// Get a service dependency with type safety
  T get<T>() {
    if (!Get.isRegistered<T>()) {
      throw Exception('Service $T is not registered. Register it using ServiceContainer().put() or registerLazy().');
    }
    return Get.find<T>();
  }

  /// Check if a service is registered
  bool isRegistered<T>() {
    return Get.isRegistered<T>();
  }

  /// Delete a service instance
  void delete<T>() {
    if (Get.isRegistered<T>()) {
      Get.delete<T>();
    }
  }

  /// Clear all services and re-register core ones
  /// Note: Get.reset() clears both permanent and non-permanent services.
  /// If you need to clear only scoped services, consider tracking them
  /// explicitly and deleting them individually.
  void resetAll() {
    Get.reset();
    registerCoreServices();
  }
}
