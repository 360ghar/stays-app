# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

360ghar stays is a Flutter mobile application for exploring and booking accommodations (hotels, Airbnbs, homestays) with 360° viewing capabilities. The app supports multiple environments (dev, staging, prod) and features comprehensive booking, messaging, and user management functionality.

## Development Commands

### Running the App
```bash
# Development environment (default)
flutter run -t lib/main_dev.dart

# With Android flavors
flutter run --flavor dev -t lib/main_dev.dart
flutter run --flavor staging -t lib/main_staging.dart
flutter run --flavor prod -t lib/main_prod.dart

# iOS with schemes
flutter run --flavor dev -t lib/main_dev.dart
flutter run --flavor staging -t lib/main_staging.dart
flutter run --flavor prod -t lib/main_prod.dart
```

### Testing
```bash
# Run all tests
flutter test

# Run with coverage
flutter test --coverage

# Integration tests
flutter test integration_test/
```

### Code Generation
```bash
# Generate JSON serialization code
flutter packages pub run build_runner build

# Clean and rebuild
flutter packages pub run build_runner build --delete-conflicting-outputs
```

### Linting & Analysis
```bash
# Run static analysis
flutter analyze

# Check for outdated dependencies
flutter pub outdated
```

### Build Commands
```bash
# Build APK
flutter build apk --flavor dev -t lib/main_dev.dart

# Build iOS
flutter build ios --flavor dev -t lib/main_dev.dart
```

## Architecture Overview

The project follows a clean, layered architecture built on Riverpod + go_router:

```
lib/
├── config/                 # AppConfig and environment configuration
├── core/
│   ├── router/             # go_router setup (AppPaths, buildV2Router)
│   ├── theme/              # Theme tokens
│   ├── providers/          # Shared Riverpod providers (data_providers.dart graph, session, settings)
│   ├── l10n/               # localeProvider + tr(ref, key) helpers
│   ├── boot/               # App startup wiring
│   └── ui/                 # Shared core widgets
├── features/               # Feature slices: views/*_screen.dart + providers per feature
│   ├── auth/              # Login screen + auth providers
│   ├── explore/           # Explore screen + explore providers
│   ├── listing/           # Search, search results, property detail
│   ├── messaging/         # Inbox and chat (chat = the thread of a booking)
│   ├── trips/             # Trips
│   └── ...
├── app/
│   ├── data/
│   │   ├── models/        # Data models with JSON serialization
│   │   ├── providers/     # Dio API clients (BaseProvider, ApiResponse)
│   │   ├── repositories/  # Repository pattern implementation
│   │   └── services/      # External services (Supabase, storage)
│   ├── ui/
│   │   ├── theme/         # Material 3 theming, colors, text styles
│   │   └── widgets/       # Reusable UI components
│   │       ├── common/    # Generic widgets
│   │       ├── forms/     # Form components
│   │       ├── cards/     # Card layouts
│   │       └── dialogs/   # Modal dialogs
│   └── utils/             # Utilities and helpers
│       ├── constants/     # App constants
│       ├── exceptions/    # Custom exceptions
│       ├── extensions/    # Dart extensions
│       ├── helpers/       # Utility functions
│       ├── logger/        # Logging configuration
│       └── services/      # Shared services (token, error, connectivity)
├── l10n/                  # Localization JSON tables (en.json, hi.json) + loader
└── main*.dart             # Environment-specific entry points
```

## Key Technology Stack

- **Framework**: Flutter 3.35+ with Dart 3.9+
- **State Management**: Riverpod (flutter_riverpod: NotifierProvider, StateProvider, StreamProvider, FutureProvider)
- **Routing**: go_router (buildV2Router, AppPaths; StatefulShellRoute bottom navigation)
- **Backend**: Supabase integration scaffolded (Supabase SDK is the session source of truth)
- **Storage**: flutter_secure_storage for tokens/secrets, SharedPreferences for prefs/cache
- **Networking**: Dio API clients (BaseProvider, ApiResponse)
- **UI**: Material 3 theming with custom components
- **Localization**: JSON tables in `l10n/` (`en.json`, `hi.json`) with `localeProvider` + `tr(ref, key)`
- **Environment Management**: flutter_dotenv for configuration

## Environment Configuration

The app supports three environments with corresponding entry points:
- **Development**: `lib/main_dev.dart` (uses `.env.dev`)
- **Staging**: `lib/main_staging.dart` (uses `.env.staging`)
- **Production**: `lib/main_prod.dart` (uses `.env.prod`)

Required environment variables in `.env.*` files:
- `API_BASE_URL`: Backend API endpoint
- `SUPABASE_URL`: Supabase project URL
- `SUPABASE_PUBLISHABLE_KEY`: Supabase publishable key
- `ENABLE_ANALYTICS`: Analytics toggle (true/false)

## Navigation Structure

- **Initial Route**: `/` (Splash) → go_router redirect checks the Supabase session and sends logged-out users to `/login` (preserving the target via `?from=`)
- **Bottom Navigation**: `StatefulShellRoute.indexedStack` under the shell
  - Explore: Property search and listings
  - Wishlist: Saved properties
  - Trips: User bookings and travel history
  - Inbox: Messaging with hosts/guests
  - Profile: User account management
- **Additional Routes**:
  - `/search`, `/search-results`: Search functionality (location passed via `state.extra`)
  - `/listing/:id`: Property detail pages (numeric id via `state.pathParameters`, optional property via `state.extra`)
  - `/tour/:id`: 360° tour viewer
  - `/inquiry`, `/inquiry-confirmation`: Inquiry flow screens (booking passed via `state.extra`)
  - `/chat/:id`: Chat of one booking (`GET|POST /api/v1/bookings/{id}/messages`)

## Development Guidelines

### State Management Pattern
- Put feature business logic in Riverpod Notifiers (`features/<name>/providers/*_providers.dart`); read state with `ref.watch`, trigger actions with `ref.read(<provider>.notifier)`
- Implement repository pattern for data access
- Notifiers should not directly call Dio providers; use repositories
- Shared dependency graph lives in `lib/core/providers/data_providers.dart`: services → Dio API providers → repositories
- Most services are app-wide singletons via `factory .shared()` / static `I` accessors (the Google and Apple sign-in services are plain instances built by the auth providers)
- Service-level observables use `ValueNotifier`, not reactive `Obx`-style widgets
- Navigate with go_router (`context.push`/`context.go`, `AppPaths` literals; pass objects via `state.extra`, ids via `state.pathParameters`)
- Surface errors with `ScaffoldMessenger`, dialogs with `showDialog`/`showModalBottomSheet`; style with `Theme.of`

### UI Development
- Follow Material 3 design principles
- Use existing theme definitions in `app/ui/theme/`
- Create reusable widgets in appropriate subdirectories
- Implement responsive design using provided helpers

### Model Classes
- All models should extend from appropriate base classes
- Use `json_annotation` and `json_serializable` for JSON serialization
- Run code generation after modifying models

### Testing Approach
- Widget tests for UI components (plain `MaterialApp` under `flutter_test`)
- Unit tests for notifiers/providers and repositories
- Use Mockito for mocking dependencies (`@GenerateMocks` + build_runner)
- Contract tests in `test/contract` parse backend-generated fixtures (`test/fixtures/api`) with the app models and check the requests the providers send. See `docs/api-contract.md`
- `tool/check_contract.sh` regenerates the wire enums and fixtures from the backend and fails on drift (pre-commit hook `contract-codegen`, CI step; skips without a backend checkout)
- The providers that hold one account's lists (`tripsProvider`, `wishlistProvider`, `favoritesProvider`, `exploreProvider`) watch `accountIdProvider` in `build()` so they reset on sign-out and on a change of user

## Current Implementation Status

- ✅ Authentication flow with Riverpod state management (Supabase session source of truth)
- ✅ Bottom navigation shell architecture
- ✅ Booking flow screens (UI skeleton)
- ✅ Messaging on the backend booking-chat route (the open chat polls every 10 seconds)
- ✅ Theming and responsive design system
- ✅ Localization scaffolding
- ✅ Clean architecture foundation
- 🚧 API integration (providers scaffolded)
- 🚧 Supabase service integration
- ❌ 360° media viewer integration
- ✅ Token refresh flow (401 retry with Supabase session refresh in `BaseProvider`)

## Common Issues & Solutions

### Android NDK Build Error
If you encounter: `[CXX1101] NDK at .../ndk/<version> did not have a source.properties file`

Solution:
```bash
rm -rf /opt/homebrew/share/android-commandlinetools/ndk/27.0.12077973
# Then retry build
```

## Important Notes

- Always use the correct environment entry point for builds
- API integration points are scaffolded but not fully wired (401s retry once via Supabase session refresh)
- Supabase configuration requires valid credentials in environment files
- 360° viewer integration is not included and needs third-party solution
