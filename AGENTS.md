# Repository Guidelines for Agentic Coding

## Project Structure & Module Organization
Flutter source lives in `lib/app/`, split by bindings, controllers, data providers, domain repositories, routes, UI views/widgets, and utilities. Configuration resides in `lib/config/` with environment-specific settings under `environments/`. Localization strings are in `l10n/` (`en.json`, `hi.json`) with helper services. Entrypoints select flavors via `lib/main_dev.dart`, `lib/main_staging.dart`, and `lib/main_prod.dart`. Tests mirror the structure in `test/unit`, `test/widget`, and `test/integration`, keeping `_test.dart` suffixes aligned with source paths.

## Build, Test, and Development Commands
- `flutter pub get`: Install or refresh package dependencies.
- `flutter analyze`: Lint the project using `flutter_lints`.
- `flutter analyze lib/`: Lint only the lib directory.
- `dart format .`: Apply repository formatting rules (2-space indentation).
- `dart run build_runner build --delete-conflicting-outputs`: Regenerate codegen outputs cleanly.
- `flutter run -t lib/main_dev.dart`: Launch the dev flavor locally.
- `flutter test`: Run all tests.
- `flutter test --coverage`: Execute full test suite with coverage metrics.
- `flutter test test/unit/controllers/auth_controller_test.dart`: Run a single test file.
- `flutter test test/unit/controllers/auth_controller_test.dart -t "should login successfully"`: Run a specific test by name.
- `flutter test --update-goldens`: Update widget test golden files.
- `flutter test --coverage --coverage-path=coverage/lcov.info`: Generate coverage in lcov format.
- `flutter build apk --flavor prod -t lib/main_prod.dart`: Produce a production Android build.
- `flutter build ios --flavor prod -t lib/main_prod.dart`: Produce a production iOS build.

## Coding Style & Naming Conventions
Follow `analysis_options.yaml` and `flutter_lints` defaults. Use 2-space indentation. Keep Dart files in `lower_snake_case.dart`, types and widgets in `PascalCase`, members in `camelCase`, and constants in `SCREAMING_SNAKE_CASE`. Private members use underscore prefix (`_privateMember`). Avoid `print()`; use `AppLogger` from `lib/app/utils/logger/` instead. Format frequently with `dart format .` and resolve analyzer warnings before committing.

## Import Organization
Organize imports in this order: Dart core → Flutter packages → GetX → Third-party packages → Local application imports. Use relative imports for intra-package imports (`package:stays_app/...`).

## GetX State Management
Controllers extend `GetxController` with reactive observables using Rx types: `RxBool`, `RxString`, `RxList<T>`, `Rx<UserModel?>`. Use `.obs` suffix for reactive values (`final isLoading = false.obs`). Wrap UI in `Obx(() => ...)` for reactive updates. Use `debounce()` for search inputs, `ever()` for side effects. Dependency injection uses Bindings with `Get.lazyPut()` for controllers, `Get.put()` for services, `Get.putAsync()` for async services.

## Architecture Layers
**Bindings**: Dependency injection registration (`auth_binding.dart`, `listing_binding.dart`). **Controllers**: Business logic and state management organized by domain (`auth/`, `listing/`, `booking/`). **Data**: Models (POJOs with `@JsonSerializable`), Providers (Dio-based API clients), Repositories (data access abstraction), Services (external SDK integrations). **UI**: Views (page-level screens), Widgets (reusable components), Theme (styling). **Utils**: Constants, helpers, extensions, exceptions, logger.

## Error Handling
Use the exception hierarchy: `AppException` → `NetworkException` → `ApiException`, plus `AuthException` and `ValidationException`. Always wrap async operations in try/catch/finally blocks. Log errors with `AppLogger.error(message, error, stackTrace)`. Handle Dio errors with `_handleDioError()` that returns `ApiException`. Display errors via `Get.snackbar()` with user-friendly messages. Use reactive error observables in controllers (`final RxString emailError = ''.obs`).

## Testing Guidelines
Use `flutter_test` and `mockito` for unit tests, `integration_test` for flows. Mirror source directories when adding tests (e.g., `test/unit/controllers/listing/listing_controller_test.dart`). Target >80% code coverage. Mock external dependencies with `@GenerateMocks([])` and build_runner. Widget tests use `GetMaterialApp` and `Get.testMode = true`. Integration tests use `IntegrationTestWidgetsFlutterBinding.ensureInitialized()`.

## Commit & Pull Request Guidelines
Write Conventional Commits: `feat(auth): add social login`, `fix(booking): resolve date selection bug`. PRs must include description, linked issues, testing instructions, screenshots for UI changes, and pass `flutter analyze`, `dart format .`, and `flutter test`. Branch naming: `feature/user-auth`, `fix/payment-validation`, `hotfix/crash-on-launch`.

## Security & Configuration
Never commit secrets; use `.env.dev`, `.env.staging`, `.env.prod` with `API_BASE_URL`, `SUPABASE_URL`, `SUPABASE_ANON_KEY`. The `AppConfig` loader selects environment per entrypoint. Add new environment keys consistently across all `.env` files.

## Code Generation
After modifying annotated classes (e.g., `@JsonSerializable`), run: `dart run build_runner build --delete-conflicting-outputs`. Regenerate mocks after interface changes: `dart run build_runner build`.

## Key Files Reference
- Exception classes: `lib/app/utils/exceptions/`
- Logger: `lib/app/utils/logger/app_logger.dart`
- Route definitions: `lib/app/routes/app_routes.dart`, `app_pages.dart`
- Bindings example: `lib/app/bindings/auth_binding.dart`
- Controller patterns: `lib/app/controllers/auth/auth_controller.dart`
