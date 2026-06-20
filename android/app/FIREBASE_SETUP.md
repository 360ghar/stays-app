# 360 Stays — Environments & Firebase Setup

Single source of truth for the Stays Android environment structure. The app ships
in three flavors, each fully isolated: **production data is never shared with dev
or staging.**

## 1. Flavor → package → Firebase mapping

| Flavor | `applicationId` | Firebase project | Config file (Gradle reads this) | Status |
|--------|-----------------|------------------|----------------------------------|--------|
| `prod` | `com.the360ghar.stays_app` | `stays-360` (prod, isolated) | `android/app/src/prod/google-services.json` | ⛔ template only — add real config locally (do not commit) |
| `dev` | `com.the360ghar.stays_app.dev` | `stays-360-nonprod` (shared non-prod) | `android/app/src/dev/google-services.json` | ⛔ template only — add real config locally (do not commit) |
| `staging` | `com.the360ghar.stays_app.staging` | `stays-360-nonprod` (shared non-prod) | `android/app/src/staging/google-services.json` | ⛔ template only — add real config locally (do not commit) |

- The package ids come from `android/app/build.gradle.kts` (`prod` uses the base
  `applicationId`; `staging` appends `.staging`; `dev` sets its own).
- **Isolation model:** production lives in its **own** Firebase project
  (`stays-360`). Dev and staging live in a **separate** non-prod project
  (`stays-360-nonprod`) so their Firestore/Auth/Analytics/Crashlytics/FCM data
  can never mix with production. (Dev and staging may share the non-prod project;
  if you want them fully separated too, create `stays-360-staging` as well and
  point the staging config at it.)

## 2. How Gradle picks the file

The `com.google.gms.google-services` plugin resolves, per active flavor, the
**first** match of:
`src/<flavor><BuildType>/` → `src/<flavor>/` → `src/<buildType>/` → `app/`.

Because each flavor has its own `src/<flavor>/google-services.json`, there is **no
base `app/google-services.json`** — this is intentional. It guarantees a build
fails loudly ("File google-services.json is missing") if a flavor's config is
absent, instead of silently falling back to the wrong (e.g. prod) project.

> `*.example` files are documentation only; Gradle ignores them. The real file
> must be named exactly `google-services.json`.

## 3. One-time setup (per Firebase project)

### Production — `stays-360` (already done)
- App `com.the360ghar.stays_app` registered; config committed at
  `src/prod/google-services.json`. ✅

### Non-prod — create `stays-360-nonprod`
1. Firebase Console → **Add project** → name it `stays-360-nonprod`
   (keep it entirely separate from `stays-360`).
2. **Add app → Android** twice, registering:
   - `com.the360ghar.stays_app.dev`
   - `com.the360ghar.stays_app.staging`
3. For each app, add the **debug + release SHA-1 and SHA-256** signing certs
   (required for Google Sign-In and App Links). Get them with:
   ```bash
   # debug
   keytool -list -v -keystore ~/.android/debug.keystore -alias androiddebugkey -storepass android -keypass android
   # release (the upload key referenced by android/key.properties)
   keytool -list -v -keystore <release-keystore.jks> -alias <alias>
   ```
4. Download each app's `google-services.json` and save (replacing the templates):
   - dev → `android/app/src/dev/google-services.json`
   - staging → `android/app/src/staging/google-services.json`
5. **Do NOT commit the real files with API keys.** The template placeholders
   (`REPLACE_FROM_FIREBASE_CONSOLE`) are committed as documentation. Add the
   real `google-services.json` files locally only. Consider adding them to
   `.gitignore` if not already excluded.

## 4. Build / verify each flavor

```bash
flutter build apk --release --flavor prod    -t lib/main_prod.dart       # uses stays-360
flutter build apk --release --flavor dev     -t lib/main_dev.dart        # uses stays-360-nonprod
flutter build apk --release --flavor staging -t lib/main_staging.dart    # uses stays-360-nonprod
```
Confirm the built artifact's package matches the table in §1 (e.g. via
`aapt dump badging <apk> | grep package`).

## 5. Files in this folder

| Path | Purpose |
|------|---------|
| `src/prod/google-services.json` | template — replace with the real prod config (do not commit) |
| `src/prod/google-services.json.example` | template documenting the prod shape |
| `src/dev/google-services.json` | template — replace with the real dev config (do not commit) |
| `src/dev/google-services.json.example` | template — replace with the real dev config |
| `src/staging/google-services.json` | template — replace with the real staging config (do not commit) |
| `src/staging/google-services.json.example` | template — replace with the real staging config |

## 6. History (why this exists)

The package drifted over time (`com.example.stays_app` → `com.a360ghar.stays`)
and never matched the Play Console id. It is now standardized to the canonical
`com.the360ghar.stays_app` (and `.dev` / `.staging` per flavor). The old Firebase
project (`866676409773`) and obsolete packages are fully retired.
