import 'dart:async';

import 'package:get/get.dart';

import '../../utils/logger/app_logger.dart';

class AnalyticsService extends GetxService {
  static AnalyticsService get I => Get.find<AnalyticsService>();

  final bool enabled;
  final List<AnalyticsEvent> _eventQueue = [];
  final _eventsController = StreamController<AnalyticsEvent>.broadcast();
  Stream<AnalyticsEvent> get events => _eventsController.stream;

  AnalyticsService({required this.enabled}) {
    if (enabled) {
      AppLogger.info('AnalyticsService initialized');
    }
  }

  @override
  void onClose() {
    _eventsController.close();
    super.onClose();
  }

  void log(AnalyticsEvent event) {
    if (!enabled) return;

    _eventQueue.add(event);
    _eventsController.add(event);

    AppLogger.info('Analytics: ${event.name}', event.params);
  }

  void logEvent(String name, [Map<String, dynamic>? params]) {
    log(AnalyticsEvent(name: name, params: params ?? {}));
  }

  void logScreenView(String screenName, [Map<String, dynamic>? params]) {
    log(
      AnalyticsEvent(
        name: AnalyticsEventNames.screenView,
        params: {'screen_name': screenName, ...?params},
      ),
    );
  }

  void logSearch(String query, [Map<String, dynamic>? params]) {
    log(
      AnalyticsEvent(
        name: AnalyticsEventNames.search,
        params: {
          'search_query': query,
          'query_length': query.length,
          ...?params,
        },
      ),
    );
  }

  void logPropertyView(String propertyId, String propertyName) {
    log(
      AnalyticsEvent(
        name: AnalyticsEventNames.viewProperty,
        params: {'property_id': propertyId, 'property_name': propertyName},
      ),
    );
  }

  void logBookingStarted(String propertyId, double price) {
    log(
      AnalyticsEvent(
        name: AnalyticsEventNames.bookingStarted,
        params: {'property_id': propertyId, 'price': price},
      ),
    );
  }

  void logBookingCompleted(
    String bookingId,
    double amount,
    String paymentMethod,
  ) {
    log(
      AnalyticsEvent(
        name: AnalyticsEventNames.bookingCompleted,
        params: {
          'booking_id': bookingId,
          'amount': amount,
          'payment_method': paymentMethod,
        },
      ),
    );
  }

  void logBookingCancelled(String bookingId, String reason) {
    log(
      AnalyticsEvent(
        name: AnalyticsEventNames.bookingCancelled,
        params: {'booking_id': bookingId, 'cancellation_reason': reason},
      ),
    );
  }

  void logWishlistAdded(String propertyId) {
    log(
      AnalyticsEvent(
        name: AnalyticsEventNames.addToWishlist,
        params: {'property_id': propertyId},
      ),
    );
  }

  void logWishlistRemoved(String propertyId) {
    log(
      AnalyticsEvent(
        name: AnalyticsEventNames.removeFromWishlist,
        params: {'property_id': propertyId},
      ),
    );
  }

  void logLogin(String method) {
    log(
      AnalyticsEvent(
        name: AnalyticsEventNames.login,
        params: {'login_method': method},
      ),
    );
  }

  void logSignup(String method) {
    log(
      AnalyticsEvent(
        name: AnalyticsEventNames.signup,
        params: {'signup_method': method},
      ),
    );
  }

  void logLogout() {
    log(AnalyticsEvent(name: AnalyticsEventNames.logout));
  }

  void logFilterApplied(Map<String, dynamic> filters) {
    log(
      AnalyticsEvent(name: AnalyticsEventNames.filterApplied, params: filters),
    );
  }

  void logError(
    String errorType,
    String message, [
    Map<String, dynamic>? params,
  ]) {
    log(
      AnalyticsEvent(
        name: AnalyticsEventNames.error,
        params: {'error_type': errorType, 'error_message': message, ...?params},
      ),
    );
  }

  void logPerformance(String metric, double value, [String? label]) {
    log(
      AnalyticsEvent(
        name: AnalyticsEventNames.performance,
        params: {
          'metric': metric,
          'value': value,
          if (label != null) 'label': label,
        },
      ),
    );
  }

  void logDeepLinkOpened(String url) {
    log(
      AnalyticsEvent(
        name: AnalyticsEventNames.deepLinkOpened,
        params: {'url': url},
      ),
    );
  }

  void logShare(String contentType, String contentId) {
    log(
      AnalyticsEvent(
        name: AnalyticsEventNames.share,
        params: {'content_type': contentType, 'content_id': contentId},
      ),
    );
  }

  void logReviewSubmitted(String propertyId, double rating) {
    log(
      AnalyticsEvent(
        name: AnalyticsEventNames.reviewSubmitted,
        params: {'property_id': propertyId, 'rating': rating},
      ),
    );
  }

  void logContactHost(String propertyId) {
    log(
      AnalyticsEvent(
        name: AnalyticsEventNames.contactHost,
        params: {'property_id': propertyId},
      ),
    );
  }

  void flush() async {
    if (_eventQueue.isNotEmpty) {
      AppLogger.info('Flushing ${_eventQueue.length} analytics events');
      _eventQueue.clear();
    }
  }
}

class AnalyticsEvent {
  final String name;
  final Map<String, dynamic> params;
  final DateTime timestamp;

  AnalyticsEvent({
    required this.name,
    this.params = const {},
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'params': params,
      'timestamp': timestamp.toIso8601String(),
    };
  }
}

class AnalyticsEventNames {
  AnalyticsEventNames._();

  static const String screenView = 'screen_view';
  static const String search = 'search';
  static const String viewProperty = 'view_property';
  static const String bookingStarted = 'booking_started';
  static const String bookingCompleted = 'booking_completed';
  static const String bookingCancelled = 'booking_cancelled';
  static const String addToWishlist = 'add_to_wishlist';
  static const String removeFromWishlist = 'remove_from_wishlist';
  static const String login = 'login';
  static const String signup = 'signup';
  static const String logout = 'logout';
  static const String filterApplied = 'filter_applied';
  static const String error = 'error';
  static const String performance = 'performance';
  static const String deepLinkOpened = 'deep_link_opened';
  static const String share = 'share';
  static const String reviewSubmitted = 'review_submitted';
  static const String contactHost = 'contact_host';
}
