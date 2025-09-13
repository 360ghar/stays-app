# Repository Guidelines

## Project Structure & Module Organization
- Source lives under `lib/app/`: `bindings/`, domain `controllers/` (`auth/`, `listing/`, `booking/`, etc.), `data/` (`models/`, `providers/`, `repositories/`, `services/`), `routes/`, `ui/` (`views/`, `widgets/`, `theme/`), and `utils/` (`constants/`, `helpers/`, `extensions/`, `exceptions/`, `logger/`).
- Configuration in `lib/config/` (`app_config.dart`, `environments/*.dart`).
- Localization in `l10n/` (`en.json`, `es.json`, `fr.json`, `localization_service.dart`).
- Entrypoints: `lib/main_dev.dart`, `lib/main_staging.dart`, `lib/main_prod.dart`.
- Tests mirror source under `test/{unit,widget,integration}` with `*_test.dart` names.

## Build, Test, and Development Commands
```sh
flutter pub get                     # Install dependencies
flutter analyze                     # Static analysis
dart format .                       # Format code
dart run build_runner build --delete-conflicting-outputs  # Codegen
flutter run -t lib/main_dev.dart    # Run dev (or --flavor dev)
flutter test --coverage             # Run tests with coverage
flutter build apk --flavor prod -t lib/main_prod.dart     # Android release
```

## Coding Style & Naming Conventions
- Lints: `flutter_lints` (see `analysis_options.yaml`). Use 2‑space indentation.
- Avoid `print`; use the project `logger` utilities.
- Naming: files `lower_snake_case.dart`; types `PascalCase`; members `camelCase`; constants `SCREAMING_SNAKE_CASE`.
- Keep business logic in `controllers/` + `repositories/`; UI in `views/` + `widgets/`.

## Testing Guidelines
- Frameworks: `flutter_test`, `mockito` (add `integration_test` as needed).
- Place tests in `test/unit`, `test/widget`, `test/integration`; mirror source and suffix with `_test.dart`.
- Cover controllers, providers, route guards, and critical navigation.
- Run: `flutter test` (add `--coverage` for reports).

## Commit & Pull Request Guidelines
- Use Conventional Commits (e.g., `feat: listing create flow`, `fix: token refresh`).
- PRs should include: clear description, linked issues, relevant screenshots, and passing `flutter analyze`, `dart format .`, and `flutter test`.

## Security & Configuration
- Do not commit secrets. Use `.env.dev`, `.env.staging`, `.env.prod` with `API_BASE_URL`, `SUPABASE_URL`, `SUPABASE_ANON_KEY`.
- Envs load via `flutter_dotenv` and `AppConfig`; select by entrypoint or `--flavor`.
