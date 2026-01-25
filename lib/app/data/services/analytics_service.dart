import 'dart:async';

import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:get/get.dart';

import '../../utils/logger/app_logger.dart';

class AnalyticsService extends GetxService {
  AnalyticsService({required this.enabled}) {
    if (enabled) {
      _initializeFirebaseAnalytics();
      AppLogger.info('AnalyticsService initialized with Firebase Analytics');
    }
  }

  final bool enabled;
  final List<AnalyticsEvent> _eventQueue = [];
  final _eventsController = StreamController<AnalyticsEvent>.broadcast();
  Stream<AnalyticsEvent> get events => _eventsController.stream;

  FirebaseAnalytics? _analytics;
  FirebaseAnalyticsObserver? _observer;

  /// Get the Firebase Analytics observer for navigation tracking
  FirebaseAnalyticsObserver? get observer => _observer;

  static AnalyticsService get I => Get.find<AnalyticsService>();

  void _initializeFirebaseAnalytics() {
    try {
      _analytics = FirebaseAnalytics.instance;
      _observer = FirebaseAnalyticsObserver(analytics: _analytics!);

      // Enable analytics collection
      unawaited(_analytics!.setAnalyticsCollectionEnabled(true));
    } catch (e) {
      AppLogger.warning('Failed to initialize Firebase Analytics: $e');
    }
  }

  @override
  void onClose() {
    unawaited(_eventsController.close());
    super.onClose();
  }

  void log(AnalyticsEvent event) {
    if (!enabled) return;

    _eventQueue.add(event);
    _eventsController.add(event);

    // Send to Firebase Analytics
    unawaited(_sendToFirebase(event));

    AppLogger.info('Analytics: ${event.name}', event.params);
  }

  Future<void> _sendToFirebase(AnalyticsEvent event) async {
    if (_analytics == null) return;

    try {
      // Convert params to ensure all values are valid types for Firebase
      final sanitizedParams = _sanitizeParams(event.params);

      await _analytics!.logEvent(
        name: event.name,
        parameters: sanitizedParams,
      );
    } catch (e) {
      AppLogger.warning('Failed to send event to Firebase Analytics: $e');
    }
  }

  /// Sanitize params to ensure they're valid for Firebase Analytics
  Map<String, Object>? _sanitizeParams(Map<String, dynamic> params) {
    if (params.isEmpty) return null;

    final sanitized = <String, Object>{};
    for (final entry in params.entries) {
      final key = entry.key.replaceAll(RegExp(r'[^a-zA-Z0-9_]'), '_');
      final value = entry.value;

      // Firebase Analytics only accepts String, int, or double
      if (value is String) {
        // Truncate strings longer than 100 chars (Firebase limit)
        sanitized[key] = value.length > 100 ? value.substring(0, 100) : value;
      } else if (value is int || value is double) {
        sanitized[key] = value;
      } else if (value is bool) {
        sanitized[key] = value ? 1 : 0;
      } else if (value != null) {
        sanitized[key] = value.toString();
      }
    }
    return sanitized.isEmpty ? null : sanitized;
  }

  /// Set user ID for analytics
  Future<void> setUserId(String? userId) async {
    if (_analytics == null) return;
    await _analytics!.setUserId(id: userId);
  }

  /// Set user property
  Future<void> setUserProperty(String name, String? value) async {
    if (_analytics == null) return;
    await _analytics!.setUserProperty(name: name, value: value);
  }

  void logEvent(String name, [Map<String, dynamic>? params]) {
    log(AnalyticsEvent(name: name, params: params ?? {}));
  }

  void logScreenView(String screenName, [Map<String, dynamic>? params]) {
    if (_analytics != null) {
      // Use Firebase's built-in screen view logging
      unawaited(_analytics!.logScreenView(
        screenName: screenName,
        screenClass: params?['screen_class'] ?? screenName,
      ));
    }

    log(
      AnalyticsEvent(
        name: AnalyticsEventNames.screenView,
        params: {'screen_name': screenName, ...?params},
      ),
    );
  }

  void logSearch(String query, [Map<String, dynamic>? params]) {
    if (_analytics != null) {
      unawaited(_analytics!.logSearch(searchTerm: query));
    }

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
    if (_analytics != null) {
      unawaited(_analytics!.logViewItem(
        items: [
          AnalyticsEventItem(
            itemId: propertyId,
            itemName: propertyName,
            itemCategory: 'property',
          ),
        ],
      ));
    }

    log(
      AnalyticsEvent(
        name: AnalyticsEventNames.viewProperty,
        params: {'property_id': propertyId, 'property_name': propertyName},
      ),
    );
  }

  void logBookingStarted(String propertyId, double price) {
    if (_analytics != null) {
      unawaited(_analytics!.logBeginCheckout(
        value: price,
        currency: 'INR',
        items: [
          AnalyticsEventItem(
            itemId: propertyId,
            itemCategory: 'property',
            price: price,
          ),
        ],
      ));
    }

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
    if (_analytics != null) {
      unawaited(_analytics!.logPurchase(
        transactionId: bookingId,
        value: amount,
        currency: 'INR',
      ));
    }

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
    if (_analytics != null) {
      unawaited(_analytics!.logRefund(
        transactionId: bookingId,
      ));
    }

    log(
      AnalyticsEvent(
        name: AnalyticsEventNames.bookingCancelled,
        params: {'booking_id': bookingId, 'cancellation_reason': reason},
      ),
    );
  }

  void logWishlistAdded(String propertyId) {
    if (_analytics != null) {
      unawaited(_analytics!.logAddToWishlist(
        items: [
          AnalyticsEventItem(
            itemId: propertyId,
            itemCategory: 'property',
          ),
        ],
      ));
    }

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
    if (_analytics != null) {
      unawaited(_analytics!.logLogin(loginMethod: method));
    }

    log(
      AnalyticsEvent(
        name: AnalyticsEventNames.login,
        params: {'login_method': method},
      ),
    );
  }

  void logSignup(String method) {
    if (_analytics != null) {
      unawaited(_analytics!.logSignUp(signUpMethod: method));
    }

    log(
      AnalyticsEvent(
        name: AnalyticsEventNames.signup,
        params: {'signup_method': method},
      ),
    );
  }

  void logLogout() {
    // Clear user ID on logout
    unawaited(setUserId(null));

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
    if (_analytics != null) {
      unawaited(_analytics!.logShare(
        contentType: contentType,
        itemId: contentId,
        method: 'app',
      ));
    }

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

  void flush() {
    if (_eventQueue.isNotEmpty) {
      AppLogger.info('Flushing ${_eventQueue.length} analytics events');
      _eventQueue.clear();
    }
  }
}

class AnalyticsEvent {
  AnalyticsEvent({
    required this.name,
    this.params = const {},
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  final String name;
  final Map<String, dynamic> params;
  final DateTime timestamp;

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
