# Repository Guidelines for Agentic Coding

> **Canonical guide: [CLAUDE.md](./CLAUDE.md).** Read it first for stack, structure, commands, and conventions.

## Project Structure & Module Organization
Flutter source is split across `lib/core/` (go_router router + `AppPaths`, theme tokens, Riverpod providers including the `data_providers.dart` graph, boot, l10n helpers), `lib/features/` (per-feature `views/*_screen.dart` screens plus `providers/` Riverpod state), and `lib/app/` (Dio data providers, repositories, services, route literals, theme, widgets, utilities). Configuration resides in `lib/config/` with environment-specific settings under `environments/`. Localization strings are JSON tables in `l10n/` (`en.json`, `hi.json`) with the loader in `lib/l10n/`. `localeProvider` lives in `lib/core/providers/` and the `tr`/`trOf` helpers in `lib/core/l10n/`. Entrypoints select flavors via `lib/main_dev.dart`, `lib/main_staging.dart`, and `lib/main_prod.dart`. Tests mirror the structure in `test/unit` and `test/widget`, keeping `_test.dart` suffixes aligned with source paths.

## Build, Test, and Development Commands
- `flutter pub get`: Install or refresh package dependencies.
- `flutter analyze`: Lint the project using `flutter_lints`.
- `flutter analyze lib/`: Lint only the lib directory.
- `dart format .`: Apply repository formatting rules (2-space indentation).
- `dart run build_runner build --delete-conflicting-outputs`: Regenerate codegen outputs cleanly.
- `flutter run -t lib/main_dev.dart`: Launch the dev flavor locally.
- `flutter test`: Run all tests.
- `flutter test --coverage`: Execute full test suite with coverage metrics.
- `flutter test test/unit/token_service_test.dart`: Run a single test file.
- `flutter test test/unit/token_service_test.dart --plain-name "starts unauthenticated"`: Run a specific test by name.
- `flutter test --update-goldens`: Update widget test golden files.
- `flutter test --coverage --coverage-path=coverage/lcov.info`: Generate coverage in lcov format.
- `flutter build apk --flavor prod -t lib/main_prod.dart`: Produce a production Android build.
- `flutter build ios --flavor prod -t lib/main_prod.dart`: Produce a production iOS build.

## Coding Style & Naming Conventions
Follow `analysis_options.yaml` and `flutter_lints` defaults. Use 2-space indentation. Keep Dart files in `lower_snake_case.dart`, types and widgets in `PascalCase`, members in `camelCase`, and constants in `SCREAMING_SNAKE_CASE`. Private members use underscore prefix (`_privateMember`). Avoid `print()`; use `AppLogger` from `lib/app/utils/logger/` instead. Format frequently with `dart format .` and resolve analyzer warnings before committing.

## Import Organization
Organize imports in this order: Dart core → Flutter packages → Riverpod/third-party packages → Local application imports. Use relative imports for intra-package imports (`package:stays_app/...`).

## Riverpod State Management
Feature state lives in `Notifier` subclasses exposed via `NotifierProvider` (use `.autoDispose` for form/search/chat-scoped state). Use `StateProvider` for simple value state (e.g. locale), `StreamProvider` for streams (e.g. Supabase auth state), and `FutureProvider` for one-shot async loads (e.g. search results). Read state with `ref.watch` inside builds/providers and trigger work with `ref.read(<provider>.notifier)`. The shared dependency graph lives in `lib/core/providers/data_providers.dart` (services → Dio API providers → repositories). Services are app-wide singletons via `factory .shared()` / static `I` accessors. Service-level observables use `ValueNotifier`. Navigate with go_router (`context.push`/`context.go` with `AppPaths`; objects via `state.extra`, ids via `state.pathParameters`). Surface errors with `ScaffoldMessenger`, dialogs with `showDialog`/`showModalBottomSheet`; style with `Theme.of`.

## Architecture Layers
**Providers**: shared Riverpod dependency graph in `lib/core/providers/data_providers.dart` (services → Dio API clients → repositories). **Notifiers**: feature business logic and UI state organized by domain (`features/auth/providers/`, `features/explore/providers/`, …). **Data**: Models (POJOs with `@JsonSerializable`), Providers (Dio-based API clients behind `BaseProvider`, returning `ApiResponse`), Repositories (data access abstraction), Services (external SDK integrations). **UI**: Screens (`*_screen.dart` per feature), Widgets (reusable components), Theme (styling + tokens). **Utils**: Constants, helpers, extensions, exceptions, logger, shared services.

## Error Handling
Use the exception hierarchy: `AppException` → `NetworkException` → `ApiException`, plus `AuthException` (incl. `TokenExpiredException`) and `ValidationException`. Always wrap async operations in try/catch/finally blocks. Log errors with `AppLogger.error(message, error, stackTrace)`. Convert failed Dio responses with `ErrorService.I.toApiException(ApiResponse)` (see `BaseProvider`), which returns `ApiException`. Display errors via `ScaffoldMessenger` with user-friendly messages. Surface field-level validation errors through local widget/form state.

## Testing Guidelines
Use `flutter_test` and `mockito` for unit and widget tests. Mirror source directories when adding tests (e.g., `test/unit/...`, `test/widget/...`). CI runs `flutter test --coverage` with a 60% line-coverage gate (currently non-blocking; see `.github/workflows/ci.yml`). Mock external dependencies with `@GenerateMocks([])` and build_runner. Widget tests pump a plain `MaterialApp` under `flutter_test` — no `GetMaterialApp` or `Get.testMode` (see `test/widget_test.dart`).

## Commit & Pull Request Guidelines
Write Conventional Commits: `feat(auth): add social login`, `fix(booking): resolve date selection bug`. PRs must include description, linked issues, testing instructions, screenshots for UI changes, and pass `flutter analyze`, `dart format .`, and `flutter test`. Branch naming: `feature/user-auth`, `fix/payment-validation`, `hotfix/crash-on-launch`.

## Security & Configuration
Never commit secrets; use `.env.dev`, `.env.staging`, `.env.prod` with `API_BASE_URL`, `SUPABASE_URL`, and `SUPABASE_PUBLISHABLE_KEY`. The `AppConfig` loader selects environment per entrypoint. Add new environment keys consistently across all `.env` files.
Use Supabase SDK as the session source of truth; do not add backend `/api/v1/auth/*` user-session dependencies.

## Code Generation
After modifying annotated classes (e.g., `@JsonSerializable`), run: `dart run build_runner build --delete-conflicting-outputs`. Regenerate mocks after interface changes: `dart run build_runner build`.

## Key Files Reference
- Exception classes: `lib/app/utils/exceptions/` (+ `ErrorService`: `lib/app/utils/services/error_service.dart`)
- Logger: `lib/app/utils/logger/app_logger.dart`
- Route definitions: `lib/core/router/app_router.dart` (`AppPaths`, `buildV2Router`)
- Provider graph: `lib/core/providers/data_providers.dart`
- Notifier pattern example: `lib/features/auth/providers/auth_providers.dart`
