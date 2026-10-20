import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:stays_app/app/data/providers/auth_api_provider.dart';
import 'package:stays_app/app/data/providers/bookings_provider.dart';
import 'package:stays_app/app/data/providers/properties_provider.dart';
import 'package:stays_app/app/data/providers/supabase_auth_provider.dart';
import 'package:stays_app/app/data/providers/swipes_provider.dart';
import 'package:stays_app/app/data/providers/users_provider.dart';
import 'package:stays_app/app/data/repositories/auth_repository.dart';
import 'package:stays_app/app/data/repositories/booking_repository.dart';
import 'package:stays_app/app/data/repositories/profile_repository.dart';
import 'package:stays_app/app/data/repositories/properties_repository.dart';
import 'package:stays_app/app/data/repositories/wishlist_repository.dart';
import 'package:stays_app/app/data/services/apple_sign_in_service.dart';
import 'package:stays_app/app/data/services/deep_link_service.dart';
import 'package:stays_app/app/data/services/google_sign_in_service.dart';
import 'package:stays_app/app/data/services/location_service.dart';
import 'package:stays_app/app/data/services/places_service.dart';
import 'package:stays_app/app/data/services/push_notification_service.dart';
import 'package:stays_app/app/data/services/property_cache_service.dart';
import 'package:stays_app/app/data/services/remember_me_service.dart';
import 'package:stays_app/app/data/services/storage_service.dart';
import 'package:stays_app/app/utils/services/connectivity_service.dart';
import 'package:stays_app/app/utils/services/token_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// ---------------------------------------------------------------------------
// Services (shared singleton instances, so there is exactly one of each
// stateful service app-wide).
// ---------------------------------------------------------------------------

final storageServiceProvider = Provider<StorageService>(
  (ref) => StorageService(),
);

final tokenServiceProvider = Provider<TokenService>(
  (ref) => TokenService.shared(),
);

final connectivityServiceProvider = Provider<ConnectivityService>(
  (ref) => ConnectivityService(),
);

final locationServiceProvider = Provider<LocationService>(
  (ref) => LocationService(),
);

final propertyCacheServiceProvider = Provider<PropertyCacheService>(
  (ref) => PropertyCacheService(),
);

final placesServiceProvider = Provider<PlacesService>((ref) => PlacesService());

final deepLinkServiceProvider = Provider<DeepLinkService>(
  (ref) => DeepLinkService(),
);

final pushNotificationServiceProvider = Provider<PushNotificationService>(
  (ref) => PushNotificationService.shared,
);

final rememberMeServiceProvider = Provider<RememberMeService>(
  (ref) => RememberMeService(),
);

final googleSignInServiceProvider = Provider<GoogleSignInService>(
  (ref) => GoogleSignInService(),
);

final appleSignInServiceProvider = Provider<AppleSignInService>(
  (ref) => AppleSignInService(),
);

// ---------------------------------------------------------------------------
// API providers (thin Dio clients; BaseProvider defaults pick up the shared
// services above for connectivity guard, token sync, and metrics).
// ---------------------------------------------------------------------------

final propertiesProviderProvider = Provider<PropertiesProvider>(
  (ref) => PropertiesProvider(),
);

final swipesProviderProvider = Provider<SwipesProvider>(
  (ref) => SwipesProvider(),
);

final usersProviderProvider = Provider<UsersProvider>((ref) => UsersProvider());

final bookingsProviderProvider = Provider<BookingsProvider>(
  (ref) => BookingsProvider(),
);

final authApiProvider = Provider<AuthApiProvider>((ref) => AuthApiProvider());

final supabaseAuthProviderProvider = Provider<SupabaseAuthProvider>(
  (ref) => SupabaseAuthProvider(
    client: Supabase.instance.client,
    storage: ref.watch(storageServiceProvider),
    google: ref.watch(googleSignInServiceProvider),
    apple: ref.watch(appleSignInServiceProvider),
  ),
);

// ---------------------------------------------------------------------------
// Repositories.
// ---------------------------------------------------------------------------

final propertiesRepositoryProvider = Provider<PropertiesRepository>(
  (ref) => PropertiesRepository(
    provider: ref.watch(propertiesProviderProvider),
    cacheService: ref.watch(propertyCacheServiceProvider),
    locationService: ref.watch(locationServiceProvider),
    connectivityService: ref.watch(connectivityServiceProvider),
  ),
);

final wishlistRepositoryProvider = Provider<WishlistRepository>(
  (ref) => WishlistRepository(provider: ref.watch(swipesProviderProvider)),
);

final profileRepositoryProvider = Provider<ProfileRepository>(
  (ref) => ProfileRepository(provider: ref.watch(usersProviderProvider)),
);

final bookingRepositoryProvider = Provider<BookingRepository>(
  (ref) => BookingRepository(provider: ref.watch(bookingsProviderProvider)),
);

final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => AuthRepository(
    provider: ref.watch(supabaseAuthProviderProvider),
    storage: ref.watch(storageServiceProvider),
    authApi: ref.watch(authApiProvider),
    tokenService: ref.watch(tokenServiceProvider),
  ),
);
