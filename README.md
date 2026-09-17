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
- Localization (EN/HI) via GetX Translations (`l10n/en.json`, `l10n/hi.json`)
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
  - `SUPABASE_PUBLISHABLE_KEY`
  - `GOOGLE_MAPS_API_KEY` *(alias: `GOOGLE_PLACES_API_KEY`)* — required for Places autocomplete & map search
  - `ENABLE_ANALYTICS` (true/false)
  - Optional: `DEFAULT_COUNTRY` (ISO code) for phone helpers

App reads env files via `flutter_dotenv` in the entrypoints and builds `AppConfig` from them.

### Build-time overrides (`--dart-define`)

CI/prod builds may pass `--dart-define` overrides which take **precedence over the bundled `.env.*` files**, so release builds never depend on values baked into the APK bundle:

```bash
flutter build apk --flavor prod -t lib/main_prod.dart \
  --dart-define=API_BASE_URL=https://api.360ghar.com \
  --dart-define=SUPABASE_URL=https://your-project.supabase.co \
  --dart-define=SUPABASE_PUBLISHABLE_KEY=your-key \
  --dart-define=GOOGLE_PLACES_API_KEY=your-key \
  --dart-define=ENABLE_ANALYTICS=true \
  --dart-define=DEFAULT_COUNTRY=IN
```

Supported keys: `API_BASE_URL`, `SUPABASE_URL`, `SUPABASE_PUBLISHABLE_KEY`, `GOOGLE_MAPS_API_KEY` / `GOOGLE_PLACES_API_KEY`, `GOOGLE_WEB_CLIENT_ID`, `GOOGLE_IOS_CLIENT_ID`, `ENABLE_ANALYTICS` (`true`/`false`), and `DEFAULT_COUNTRY`.

Resolution order per key: **`--dart-define` → `.env.<env>` file → built-in default**. Required keys (`API_BASE_URL`, `SUPABASE_URL`, `SUPABASE_PUBLISHABLE_KEY`) still fail fast with `MissingEnvironmentException` when neither a define nor a dotenv value is present. Local development continues to use the `.env.dev` / `.env.staging` / `.env.prod` files; no defines are required.

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
- Other routes (canonical list in `lib/app/routes/app_routes.dart`):
  - `/force-update`, `/onboarding`, `/login`, `/register`, `/verification`, `/reset-password`, `/set-password`, `/profile-completion`
  - `/search-results`, `/listing/:id`, `/location-search`
  - `/inquiry`, `/inquiry-confirmation` (booking flow)
  - `/payment`, `/payment-methods`
  - `/inbox`, `/chat/:conversationId`
  - `/tour` (360° virtual tour), `/wishlist`
  - `/profile`, `/profile/edit`, `/profile/preferences`, `/profile/notifications`, `/profile/privacy`, `/profile/help`, `/profile/about`, `/profile/legal`, `/profile/feedback/bug`, `/profile/feedback/feature`, `/account-settings`, `/inquiries`

### Canonical paths: `AppPaths` (V2) vs `Routes` (legacy)

New code uses `AppPaths` (`lib/core/router/app_router.dart`, go_router + Riverpod). `Routes` (`lib/app/routes/app_routes.dart`, GetX) is legacy; its 12 aliases are deprecated since 1.0.1 and removed in 1.1.0.

| V2 (`AppPaths`) | Legacy (`Routes`) | Notes |
| --- | --- | --- |
| `/explore` | `/home` | V2 shell hub; legacy bottom-nav host |
| `/trips` | `/inquiries` (`trips`, `enquiries` aliases) | Same hub, renamed |
| `/inquiry` | `/inquiry` (`enquiry`, `booking` aliases) | Booking flow entry |
| `/inquiry-confirmation` | `/inquiry-confirmation` (`enquiryConfirmation`, `bookingConfirmation`) | Post-inquiry receipt |
| `/listing/:id` | `/listing/:id` | Identical in both routers |
| `/chat/:id` | `/chat/:conversationId` | Identical shape, param renamed |
| `/login`, `/search`, `/search-results`, `/payment`, `/payment-methods`, `/inbox`, `/profile`, `/wishlist`, `/tour/:id` | Same literals | Pass through `mapLegacyPathToV2` unchanged |

### V2 rollback

The V2 boot is gated by `useV2Router` in `lib/core/router/app_router.dart` (currently `true`). Rollback to the legacy GetX boot: set `useV2Router = false` in that file and relaunch any entrypoint (`lib/main*.dart`); no other changes needed. Deep links keep working because `mapLegacyPathToV2` translates renamed hubs while concrete paths (`/listing/42`, `/chat/abc`) are identical in both routers.

## Testing

```
flutter test
flutter test --coverage
```

Current unit/widget tests live under `test/`:
- `test/unit/controllers/auth/auth_controller_test.dart` — auth controller + form validation
- `test/unit/controllers/settings/theme_controller_test.dart`
- `test/unit/utils/services/token_info_test.dart` — token expiry/refresh semantics
- `test/unit/utils/extensions/dynamic_extensions_test.dart`
- `test/unit/supabase_auth_error_mapper_test.dart`
- `test/app/utils/helpers/json_helpers_test.dart`, `test/user_model_contract_test.dart`
- `test/widget_test.dart` — root app bootstrapping

Mocks are generated (gitignored): run `dart run build_runner build --delete-conflicting-outputs` after touching `@GenerateMocks`/`@JsonSerializable` files.

Recommended local checks before you push:

- `flutter analyze`
- `dart format .`

## Localization

- GetX-based translations in `lib/l10n/localization_service.dart`
- Resource files in `l10n/en.json`, `l10n/hi.json` (EN + HI only)

## Notes & TODOs

- `.env.dev` / `.env.staging` / `.env.prod` are gitignored but declared as pubspec assets — a fresh clone must create them from `.env.example` before `flutter run`/`flutter build`.
- Session/token refresh uses the Supabase SDK session lifecycle; avoid custom refresh-token flows.
- Supabase is initialized via `SupabaseService` from `AppConfig` values.
- 360° tours render via the in-app Kuula webview (`WebViewHelper`).

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
