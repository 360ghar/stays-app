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

The project follows a clean, layered GetX-based architecture:

```
lib/
├── config/                 # AppConfig and environment providers
├── app/
│   ├── bindings/           # GetX dependency injection bindings
│   ├── controllers/        # GetX controllers (business logic)
│   │   ├── auth/          # Authentication controllers
│   │   ├── booking/       # Booking flow controllers
│   │   ├── listing/       # Property listing controllers
│   │   ├── messaging/     # Chat and inbox controllers
│   │   ├── payment/       # Payment processing controllers
│   │   └── ...
│   ├── data/
│   │   ├── models/        # Data models with JSON serialization
│   │   ├── providers/     # Network providers (GetConnect)
│   │   ├── repositories/  # Repository pattern implementation
│   │   └── services/      # External services (Supabase, storage)
│   ├── middlewares/       # Route guards and middleware
│   ├── routes/            # Route definitions and page bindings
│   ├── ui/
│   │   ├── theme/         # Material 3 theming, colors, text styles
│   │   ├── views/         # Screen implementations
│   │   │   ├── auth/      # Login, registration screens
│   │   │   ├── booking/   # Booking flow screens
│   │   │   ├── home/      # Main app screens with bottom nav
│   │   │   ├── listing/   # Property details and search
│   │   │   ├── messaging/ # Chat and inbox screens
│   │   │   ├── payment/   # Payment methods and processing
│   │   │   └── ...
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
│       └── logger/        # Logging configuration
├── l10n/                  # Localization (EN, ES, FR)
└── main*.dart             # Environment-specific entry points
```

## Key Technology Stack

- **Framework**: Flutter 3.35+ with Dart 3.9+
- **State Management**: GetX (routing, dependency injection, state management)
- **Backend**: Supabase integration scaffolded
- **Storage**: GetStorage for local data persistence
- **Networking**: GetConnect for API communication
- **UI**: Material 3 theming with custom components
- **Localization**: GetX Translations with JSON resource files
- **Environment Management**: flutter_dotenv for configuration

## Environment Configuration

The app supports three environments with corresponding entry points:
- **Development**: `lib/main_dev.dart` (uses `.env.dev`)
- **Staging**: `lib/main_staging.dart` (uses `.env.staging`)
- **Production**: `lib/main_prod.dart` (uses `.env.prod`)

Required environment variables in `.env.*` files:
- `API_BASE_URL`: Backend API endpoint
- `SUPABASE_URL`: Supabase project URL
- `SUPABASE_ANON_KEY`: Supabase anonymous key
- `ENABLE_ANALYTICS`: Analytics toggle (true/false)

## Navigation Structure

- **Initial Route**: `/` (Splash) → middleware redirects to `/login` or `/home`
- **Bottom Navigation**: Available under `/home`
  - Explore: Property search and listings
  - Trips: User bookings and travel history
  - Inbox: Messaging with hosts/guests
  - Profile: User account management
- **Additional Routes**:
  - `/search`, `/search-results`: Search functionality
  - `/listing/:id`: Property detail pages
  - `/booking`: Booking flow screens
  - `/payment`, `/payment-methods`: Payment processing
  - `/chat/:conversationId`: Individual chat conversations

## Development Guidelines

### State Management Pattern
- Use GetX controllers for business logic
- Implement repository pattern for data access
- Controllers should not directly call providers; use repositories
- Use GetX bindings for dependency injection

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
- Widget tests for UI components
- Unit tests for controllers and repositories
- Integration tests for complete user flows
- Use Mockito for mocking dependencies

## Current Implementation Status

- ✅ Authentication flow with GetX state management
- ✅ Bottom navigation shell architecture
- ✅ Booking flow screens (UI skeleton)
- ✅ Payment methods screen (UI only)
- ✅ Messaging UI with local state
- ✅ Theming and responsive design system
- ✅ Localization scaffolding
- ✅ Clean architecture foundation
- 🚧 API integration (providers scaffolded)
- 🚧 Supabase service integration
- ❌ 360° media viewer integration
- ❌ Token refresh flow implementation

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
- API integration points are scaffolded but not fully wired
- Token refresh flow needs implementation in `BaseProvider`
- Supabase configuration requires valid credentials in environment files
- 360° viewer integration is not included and needs third-party solution