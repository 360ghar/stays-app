import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:stays_app/app/data/models/booking_model.dart';
import 'package:stays_app/app/data/models/property_model.dart';
import 'package:stays_app/app/utils/logger/app_logger.dart';
import 'package:stays_app/features/auth/views/login_screen.dart';
import 'package:stays_app/features/explore/views/explore_screen.dart';
import 'package:stays_app/features/inquiry/views/inquiry_confirmation_screen.dart';
import 'package:stays_app/features/inquiry/views/inquiry_screen.dart';
import 'package:stays_app/features/listing/views/detail_screen.dart';
import 'package:stays_app/features/listing/views/search_results_screen.dart';
import 'package:stays_app/features/listing/views/search_screen.dart';
import 'package:stays_app/features/messaging/views/chat_screen.dart';
import 'package:stays_app/features/messaging/views/inbox_screen.dart';
import 'package:stays_app/features/payment/views/payment_methods_screen.dart';
import 'package:stays_app/features/payment/views/payment_screen.dart';
import 'package:stays_app/features/profile/views/profile_screen.dart';
import 'package:stays_app/features/splash/views/splash_screen.dart';
import 'package:stays_app/features/tour/views/tour_viewer.dart';
import 'package:stays_app/features/trips/views/trips_screen.dart';
import 'package:stays_app/features/wishlist/views/wishlist_screen.dart';

/// Strangler flag. `true` boots the Riverpod + go_router app.
/// Rollback: set `false` to restore the legacy GetX boot.
///
/// REBUILD REQUIREMENT: this is a `const` evaluated at compile time. Toggling
/// it needs a full restart (`flutter run` again / fresh build). Hot reload or
/// hot restart alone will NOT switch routers; every entry point (`main*.dart`)
/// branches on this value at startup via [v2RouterInstance].
const bool useV2Router = true;

GoRouter? _sharedInstance;

/// Shared v2 router. Built once Supabase is initialized; every entry point
/// and every navigation bridge uses this instance so there is exactly one.
GoRouter v2RouterInstance() => _sharedInstance ??= buildV2Router();

/// Maps a legacy GetX path to its v2 equivalent. Concrete deep-link paths
/// (`/listing/42`, `/chat/abc`) are identical in both routers and pass
/// through; renamed hubs are translated.
String mapLegacyPathToV2(String path) {
  if (path == '/inquiries' ||
      path == '/enquiries' ||
      path == '/trips' ||
      path == '/booking' ||
      path == '/bookings') {
    return AppPaths.trips;
  }
  if (path == '/enquiry' || path == '/inquiry') return AppPaths.inquiry;
  if (path == '/enquiry-confirmation' ||
      path == '/inquiry-confirmation' ||
      path == '/booking-confirmation') {
    return AppPaths.inquiryConfirmation;
  }
  if (path == '/payment-methods') return AppPaths.paymentMethods;
  if (path == '/profile') return AppPaths.profile;
  if (path == '/wishlist') return AppPaths.wishlist;
  if (path == '/inbox') return AppPaths.inbox;
  if (path == '/home' || path == '/explore') return AppPaths.explore;
  return path;
}

/// V2 path table. Mirrors legacy `Routes` without the deprecated aliases.
class AppPaths {
  AppPaths._();

  static const String splash = '/';
  static const String login = '/login';
  static const String explore = '/explore';
  static const String wishlist = '/wishlist';
  static const String trips = '/trips';
  static const String inbox = '/inbox';
  static const String profile = '/profile';
  static const String search = '/search';
  static const String searchResults = '/search-results';
  static const String payment = '/payment';
  static const String paymentMethods = '/payment-methods';
  static const String inquiry = '/inquiry';
  static const String inquiryConfirmation = '/inquiry-confirmation';

  static String listing(String id) => '/listing/$id';
  static String tour(String id) => '/tour/$id';
  static String chat(String id) => '/chat/$id';
}

/// Public routes reachable logged-out (mirrors legacy listing deep links).
bool _isPublic(String path) {
  return path == AppPaths.splash ||
      path == AppPaths.login ||
      path.startsWith('/listing/');
}

bool _isAuthenticated() {
  try {
    final session = Supabase.instance.client.auth.currentSession;
    return session != null && session.accessToken.isNotEmpty;
  } catch (_) {
    return false;
  }
}

/// Refreshes go_router redirect when Supabase auth changes.
class _AuthListenable extends ChangeNotifier {
  _AuthListenable() {
    _sub = Supabase.instance.client.auth.onAuthStateChange.listen((_) {
      notifyListeners();
    });
  }
  StreamSubscription<AuthState>? _sub;

  @override
  void dispose() {
    unawaited(_sub?.cancel());
    super.dispose();
  }
}

/// V2 router. All primary routes are Riverpod screens.
GoRouter buildV2Router() {
  return GoRouter(
    initialLocation: AppPaths.splash,
    refreshListenable: _AuthListenable(),
    redirect: (context, state) {
      final path = state.uri.path;
      final authed = _isAuthenticated();
      if (path == AppPaths.splash) return null;
      if (!authed && !_isPublic(path)) {
        // Preserve the target so login can resume it (see LoginScreen).
        final from = Uri.encodeComponent(state.uri.toString());
        return '${AppPaths.login}?from=$from';
      }
      if (authed && path == AppPaths.login) return AppPaths.explore;
      return null;
    },
    routes: [
      GoRoute(path: AppPaths.splash, builder: (_, _) => const SplashScreen()),
      GoRoute(path: AppPaths.login, builder: (_, _) => const LoginScreen()),
      GoRoute(path: AppPaths.search, builder: (_, _) => const SearchScreen()),
      GoRoute(
        path: AppPaths.searchResults,
        builder: (context, state) {
          final extra = state.extra;
          final map = extra is Map ? extra : null;
          final lat = map?['lat'];
          final lng = map?['lng'];
          if (lat is! num || lng is! num) {
            AppLogger.warning(
              'v2 router: /search-results missing numeric lat/lng in extra; '
              'showing error instead of silently falling back to SearchScreen.',
              state.extra,
            );
            return const RouteErrorScreen(
              message: 'Missing search location. Please search again.',
              recoveryLabel: 'Back to search',
              recoveryLocation: AppPaths.search,
            );
          }
          return SearchResultsScreen(lat: lat.toDouble(), lng: lng.toDouble());
        },
      ),
      GoRoute(
        path: '/listing/:id',
        builder: (context, state) {
          final rawId = state.pathParameters['id'] ?? '';
          final id = int.tryParse(rawId);
          if (id == null) {
            AppLogger.warning(
              'v2 router: /listing/$rawId is not a numeric id; '
              'showing error instead of silently loading id 0.',
              state.uri.toString(),
            );
            return RouteErrorScreen(message: 'Invalid listing id "$rawId".');
          }
          final extra = state.extra;
          return DetailScreen(
            propertyId: id,
            initialProperty: extra is Property ? extra : null,
          );
        },
      ),
      GoRoute(
        path: '/tour/:id',
        builder: (context, state) {
          final extra = state.extra;
          final map = extra is Map ? extra : null;
          final url = map?['url'];
          final title = map?['title'];
          return TourViewer(
            initialUrl: url is String ? url : null,
            title: title is String && title.isNotEmpty ? title : '360 Tour',
          );
        },
      ),
      GoRoute(
        path: AppPaths.inquiry,
        builder: (context, state) {
          final extra = state.extra;
          return InquiryScreen(property: extra is Property ? extra : null);
        },
      ),
      GoRoute(
        path: AppPaths.inquiryConfirmation,
        builder: (context, state) {
          final extra = state.extra;
          if (extra is! Booking) {
            AppLogger.warning(
              'v2 router: /inquiry-confirmation reached without a Booking in '
              'extra; showing error instead of silently looping to SplashScreen.',
              state.extra,
            );
            return const RouteErrorScreen(
              message: 'Missing booking details. Please retry your inquiry.',
            );
          }
          return InquiryConfirmationScreen(booking: extra);
        },
      ),
      GoRoute(
        path: AppPaths.payment,
        builder: (context, state) {
          final extra = state.extra;
          final map = extra is Map ? extra : null;
          final bookingId = map?['bookingId'];
          final amount = map?['amount'];
          if (bookingId is! int || amount is! num) {
            AppLogger.warning(
              'v2 router: /payment missing valid bookingId/amount in extra; '
              'showing error instead of silently falling back to 0.',
              state.extra,
            );
            return const RouteErrorScreen(
              message: 'Missing payment details. Please retry from your trips.',
              recoveryLabel: 'Back to trips',
              recoveryLocation: AppPaths.trips,
            );
          }
          return PaymentScreen(bookingId: bookingId, amount: amount.toDouble());
        },
      ),
      GoRoute(
        path: AppPaths.paymentMethods,
        builder: (_, _) => const PaymentMethodsScreen(),
      ),
      GoRoute(
        path: '/chat/:id',
        builder: (context, state) {
          final id = state.pathParameters['id'] ?? '';
          return ChatScreen(conversationId: id);
        },
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, shell) => _V2Shell(shell: shell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppPaths.explore,
                builder: (_, _) => const ExploreScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppPaths.wishlist,
                builder: (_, _) => const WishlistScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppPaths.trips,
                builder: (_, _) => const TripsScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppPaths.inbox,
                builder: (_, _) => const InboxScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppPaths.profile,
                builder: (_, _) => const ProfileScreen(),
              ),
            ],
          ),
        ],
      ),
    ],
  );
}

/// Explicit error page for malformed v2 navigation (bad deep link, missing
/// `extra`). Replaces the old silent fallbacks (SearchScreen / id 0 /
/// SplashScreen) so bad routes are visible in logs instead of masquerading
/// as valid screens.
class RouteErrorScreen extends StatelessWidget {
  const RouteErrorScreen({
    required this.message,
    super.key,
    this.recoveryLabel = 'Back to explore',
    this.recoveryLocation = AppPaths.explore,
  });
  final String message;
  final String recoveryLabel;
  final String recoveryLocation;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Something went wrong')),
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline, size: 48),
                const SizedBox(height: 16),
                Text(message, textAlign: TextAlign.center),
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: () => context.go(recoveryLocation),
                  child: Text(recoveryLabel),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _V2Shell extends StatelessWidget {
  const _V2Shell({required this.shell});
  final StatefulNavigationShell shell;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: shell,
      bottomNavigationBar: NavigationBar(
        selectedIndex: shell.currentIndex,
        onDestinationSelected: shell.goBranch,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.explore_outlined),
            selectedIcon: Icon(Icons.explore),
            label: 'Explore',
          ),
          NavigationDestination(
            icon: Icon(Icons.favorite_border),
            selectedIcon: Icon(Icons.favorite),
            label: 'Wishlist',
          ),
          NavigationDestination(
            icon: Icon(Icons.card_travel_outlined),
            selectedIcon: Icon(Icons.card_travel),
            label: 'Trips',
          ),
          NavigationDestination(
            icon: Icon(Icons.inbox_outlined),
            selectedIcon: Icon(Icons.inbox),
            label: 'Inbox',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
