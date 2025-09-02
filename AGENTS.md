# Repository Guidelines

## Project Structure & Architecture
- `lib/app/`: core layers.
  - `bindings/` (e.g., `initial_binding.dart`, `auth_binding.dart`, `listing_binding.dart`).
  - `controllers/` by domain: `auth/`, `listing/`, `booking/`, `payment/`, `messaging/`, `review/`, `notification/`.
  - `data/`: `models/` (POJOs), `providers/` (GetConnect), `repositories/` (abstraction), `services/` (supabase, storage, location, push, analytics).
  - `routes/`: `app_pages.dart`, `app_routes.dart`.
  - `ui/`: `views/` (auth, home, listing, booking, payment, messaging, profile, settings), `widgets/` (common, cards, forms, dialogs), `theme/`.
  - `utils/`: `constants/`, `helpers/`, `extensions/`, `exceptions/`, `logger/`.
- `lib/config/`: `app_config.dart`, `environments/{dev,staging,prod}_config.dart`.
- `l10n/`: `en.json`, `es.json`, `fr.json`, `localization_service.dart`.
- Entrypoints: `lib/main_dev.dart`, `lib/main_staging.dart`, `lib/main_prod.dart` (loads `.env.*`).
- Tests: `test/{unit,widget,integration}`; name files `*_test.dart`.

## File Responsibilities
- `main.dart|main_*.dart`: initializes env, DI, routes, theme; runs app.
- `app/bindings/initial_binding.dart`: registers core services/controllers.
- `config/app_config.dart`: environment selection and values.
- Controllers: manage feature flows and state (auth, listing, booking, payment, messaging, review, notification).
- Data layer: models (JSON), providers (API), repositories (domain access), services (external SDKs).

## Build, Test, and Development Commands
- Deps: `flutter pub get`.
- Analyze: `flutter analyze`; Format: `dart format .`.
- Codegen: `dart run build_runner build --delete-conflicting-outputs`.
- Run dev: `flutter run -t lib/main_dev.dart` (or `--flavor dev`).
- Tests: `flutter test` (coverage: `--coverage`).
- Release: `flutter build apk|ios --flavor prod -t lib/main_prod.dart`.

## Coding Style & Naming
- Lints: `flutter_lints` (see `analysis_options.yaml`); 2-space indent; avoid `print`, use `logger`.
- Names: files `lower_snake_case.dart`; types `PascalCase`; members `camelCase`; constants `SCREAMING_SNAKE_CASE`.
- Separation: business logic in `controllers/` + `repositories/`; UI in `views/` + `widgets/`.

## Testing Guidelines
- Frameworks: `flutter_test`, `mockito`; add `integration_test` as needed.
- Layout: `test/unit`, `test/widget`, `test/integration`; mirror source; suffix `_test.dart`.
- Scope: cover controllers, providers, middleware/route guards, and critical navigation.

## Commit & PR Guidelines
- Commits: prefer Conventional Commits (e.g., `feat: listing create flow`, `fix: token refresh`).
- PRs: clear description, linked issues, UI screenshots, and green `flutter analyze`, `dart format .`, `flutter test`.

## Security & Config
- Env: `.env.dev`, `.env.staging`, `.env.prod` (`API_BASE_URL`, `SUPABASE_URL`, `SUPABASE_ANON_KEY`). Do not commit secrets.
- Env loading via `flutter_dotenv` and `AppConfig`; select entrypoint/`--flavor` per environment.
