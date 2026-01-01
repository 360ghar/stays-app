# 360ghar stays

Check in before you book in.

Hotels, Airbnbs, homestays—see the exact space before you arrive. Whether it’s a cozy homestay or a luxury suite, explore it in 360° and feel at home, anywhere.

## Features

- Explore listings, view details, amenities, and pricing
- Auth flow (login UI) wired with GetX state management
- Booking flow screens (skeleton) with date and guest inputs
- Payment methods screen (add/remove, UI only)
- Messaging (Inbox + Chat UI) with basic local state
- Bottom navigation shell (Explore, Trips, Inbox, Profile)
- Location-aware explore + map view (Flutter Map markers, Google Places autocomplete)
- **In-app update prompts** with optional and force update support ([docs](docs/app-updates.md))
- Theming (Material 3), responsive helpers, reusable widgets
- Localization scaffolding (EN/ES/FR) via GetX Translations
- Clean, layered architecture (providers → repositories → controllers → views)

## Tech Stack

- Flutter 3.35+, Dart 3.9+
- GetX (routing, DI, state) + GetConnect for APIs
- Supabase (service scaffolded), GetStorage (tokens/cache)
- Logger, intl, cached_network_image, shimmer

## Getting Started

1. Install dependencies: `flutter pub get`
2. Generate JSON serializers (run after touching files under `lib/app/data/models/`):
   `dart run build_runner build --delete-conflicting-outputs`
   - Use `dart run build_runner watch --delete-conflicting-outputs` while developing models.
3. Launch the dev flavor: `flutter run -t lib/main_dev.dart`

## Project Structure

```
lib/
  config/                # AppConfig and env providers
  app/
    bindings/            # GetX dependency bindings
    controllers/         # GetX controllers (business logic)
    data/
      models/            # Models (POJOs)
      providers/         # Network providers (GetConnect)
      repositories/      # Repository layer
      services/          # External services (supabase, storage, etc.)
    middlewares/         # Route guards
    routes/              # Routes + pages
    ui/
      theme/             # Theme, colors, text styles
      views/             # Screens
      widgets/           # Reusable widgets
    utils/               # Helpers, errors, logger, constants
  l10n/                  # Translations + service
main.dart                # Default entry (dev)
main_dev.dart|main_staging.dart|main_prod.dart
```

## Environment & Configuration

Update your environment keys in:

- `.env.dev`, `.env.staging`, `.env.prod` at repo root
  - `API_BASE_URL`
  - `SUPABASE_URL`
  - `SUPABASE_ANON_KEY`
  - `GOOGLE_MAPS_API_KEY` *(alias: `GOOGLE_PLACES_API_KEY`)* — required for Places autocomplete & map search
  - `ENABLE_ANALYTICS` (true/false)
  - Optional: `DEFAULT_COUNTRY` (ISO code) for phone helpers

App reads env files via `flutter_dotenv` in the entrypoints and builds `AppConfig` from them.

Google Places autocomplete needs billing-enabled Places API access on the key above. Keep the value consistent across all environments.

Switch environments by launching with the corresponding entrypoint:

- Dev: `lib/main_dev.dart`
- Staging: `lib/main_staging.dart`
- Prod: `lib/main_prod.dart`

## Run

Development without flavors (uses `AppConfig.dev()`):

```
flutter run -t lib/main_dev.dart
```

With Android flavors configured:

```
# Dev
flutter run --flavor dev -t lib/main_dev.dart

# Staging
flutter run --flavor staging -t lib/main_staging.dart

# Production
flutter run --flavor prod -t lib/main_prod.dart
```

Android app names per flavor are configured in `android/app/build.gradle.kts`. iOS uses a single display name in `ios/Runner/Info.plist` (adjust Schemes if you add iOS flavors).
 
### iOS Flavors (Schemes)

- Xcode schemes added: `dev`, `staging`, `prod` (shared)
- These target the `Runner` app with default Debug/Release/Profile configurations.

Run on iOS with schemes:

```
# Dev
flutter run --flavor dev -t lib/main_dev.dart

# Staging
flutter run --flavor staging -t lib/main_staging.dart

# Production
flutter run --flavor prod -t lib/main_prod.dart
```

Note: `-t` selects the Dart entrypoint; schemes do not override `FLUTTER_TARGET` by default.

## Location & Maps

- `LocateView` and explore map cards rely on `flutter_map`, `geolocator`, and the in-house `PlacesService` (Google Places REST).
- Make sure `GOOGLE_MAPS_API_KEY`/`GOOGLE_PLACES_API_KEY` is set; the key needs the **Places API** (Autocomplete & Details) enabled.
- Android location permissions are already declared in `android/app/src/main/AndroidManifest.xml`; update rationale strings if needed.
- iOS usage descriptions live in `ios/Runner/Info.plist` (`NSLocationWhenInUseUsageDescription`, `NSLocationAlwaysAndWhenInUseUsageDescription`, `NSLocationTemporaryUsageDescriptionDictionary`). Adjust the copy to match your release build.

## Navigation

- Initial route: `/` (Splash) → middleware redirects to `/login` or `/home`
- Bottom tabs available under `/home` (Explore, Trips, Inbox, Profile)
- Other routes:
  - `/search`, `/search-results`
  - `/listing/:id`
  - `/booking`
  - `/payment`, `/payment-methods`
  - `/inbox`, `/chat/:conversationId`
  - `/profile`

## Testing

```
flutter test
flutter test --coverage
```

Current widget tests validate root app bootstrapping. You can extend unit/widget/integration tests under `test/`.

Recommended local checks before you push:

- `flutter analyze`
- `dart format .`

## Localization

- GetX-based translations in `lib/l10n/localization_service.dart`
- Resource files in `l10n/en.json`, `l10n/es.json`, `l10n/fr.json`

## Notes & TODOs

- API integration points (providers) are scaffolded; wire them to your real backend endpoints.
- Token refresh flow is left as a TODO in `BaseProvider`.
- Supabase is initialized via `SupabaseService`; replace placeholders in `AppConfig`.
- A 360° media viewer is not included; integrate your preferred viewer in listing detail.

## Known Local Build Issues

If you encounter an Android NDK error:

> [CXX1101] NDK at .../ndk/<version> did not have a source.properties file

Fix by deleting the malformed NDK and letting Gradle re-download it:

```
rm -rf /opt/homebrew/share/android-commandlinetools/ndk/27.0.12077973
```

Then retry your build.

## License

Proprietary — 360ghar stays.
