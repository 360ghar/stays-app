# Repository Guidelines

## Project Structure & Module Organization
Flutter source lives in `lib/app/`, split by bindings, controllers (e.g. `controllers/auth/`), data providers, domain repositories, routes, UI views/widgets, and utilities. Configuration resides in `lib/config/` with environment-specific settings under `environments/`. Localization strings are in `l10n/` (`en.json`, `es.json`, `fr.json`) with helper services. Entrypoints select flavors via `lib/main_dev.dart`, `lib/main_staging.dart`, and `lib/main_prod.dart`. Tests mirror the structure in `test/unit`, `test/widget`, and `test/integration`, keeping `_test.dart` suffixes aligned with source paths.

## Build, Test, and Development Commands
- `flutter pub get`: install or refresh package dependencies.
- `flutter analyze`: lint the project using `flutter_lints`.
- `dart format .`: apply repository formatting rules (2-space indentation).
- `dart run build_runner build --delete-conflicting-outputs`: regenerate codegen outputs cleanly.
- `flutter run -t lib/main_dev.dart`: launch the dev flavor locally.
- `flutter test --coverage`: execute the full test suite with coverage metrics.
- `flutter build apk --flavor prod -t lib/main_prod.dart`: produce a production Android build.

## Coding Style & Naming Conventions
Follow the defaults enforced by `analysis_options.yaml` and `flutter_lints`. Keep Dart files in `lower_snake_case.dart`, types and widgets in `PascalCase`, members in `camelCase`, and constants in `SCREAMING_SNAKE_CASE`. Avoid `print`; rely on the shared logger utilities under `lib/app/utils/logger/`. Format frequently with `dart format .` and resolve analyzer warnings before committing.

## Testing Guidelines
Use `flutter_test` and `mockito` as primary frameworks, adding `integration_test` when simulating flows. Mirror source directories when adding tests (e.g. `test/unit/controllers/listing/listing_controller_test.dart`). Target meaningful coverage for controllers, providers, and navigation guards; run `flutter test --coverage` before reviews and upload artifacts when required.

## Commit & Pull Request Guidelines
Write Conventional Commits such as `feat: listing create flow` or `fix: token refresh`. Each PR should explain the change, link relevant issues, include screenshots or GIFs for UI updates, and confirm `flutter analyze`, `dart format .`, and `flutter test` have passed. Summarize testing evidence directly in the PR description.

## Security & Configuration Tips
Never commit secrets; rely on `.env.dev`, `.env.staging`, and `.env.prod` containing `API_BASE_URL`, `SUPABASE_URL`, and `SUPABASE_ANON_KEY`. The `AppConfig` loader selects the correct environment per entrypoint or `--flavor`. Add new environment keys consistently across all `.env` files and document usage in the configuration module.
