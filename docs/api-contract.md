# API contract

The app follows the backend contract. Fixtures and enums come from the backend. Nobody types them by hand.

## Regenerate

1. Enums: `python3 tool/gen_enums.py`. It reads `contract-audit/enums.json` and writes `lib/app/data/models/wire_enums.dart` and `test/fixtures/api/enums.json`.
2. Fixtures: `uv run --project <workspace>/360ghar-backend python tool/api_fixtures.py`. It validates sample data through the backend Pydantic response models and writes `test/fixtures/api/*.json`.
3. Models: `dart run build_runner build --delete-conflicting-outputs`.
4. Check: `flutter test test/contract`.
5. Drift: `tool/check_contract.sh` reruns steps 1 and 2 against the backend and fails when `wire_enums.dart` or `test/fixtures` differ from the files in the tree. It needs a backend checkout (`GHAR_BACKEND_DIR`, default: the 360ghar workspace) and skips without one (`--strict` fails instead). The pre-commit hook `contract-codegen` and the CI step call it.

## Rules the code keeps

- Errors: read only `{"error": {"code", "message", "details"}}`. A 422 lists `details.fields[{field, msg, type}]`. `ErrorService.toApiException` does this.
- Lists: `CursorPage {items, next_cursor, has_more, limit, total}`. Send `next_cursor` back unchanged with the same filters. `limit` is at most 100.
- Wishlist "clear all": it follows `next_cursor` to collect every liked id, then calls `POST /api/v1/swipes/batch-remove` with at most 100 ids per request (`BatchRemoveRequest.property_ids` has `maxItems` 100).
- Query and body: send only declared keys. A list filter is sent as repeated keys (`property_type=a&property_type=b`). `radius` is an integer.
- Enums: wire values from `wire_enums.dart`. An unknown value reads as null and is logged.
- Dates: stay dates go as `YYYY-MM-DD`. Datetimes read as UTC with `Z`.
- Price: a short stay shows `nightly_rate`. There is no fallback to `base_price` or `monthly_rent`.
- Booking create: no money, nights or status key. The `Idempotency-Key` stays the same when the guest retries the same request.
- Chat: the thread of a booking, `GET|POST /api/v1/bookings/{id}/messages`.
- Payments: none. All `/payments` routes are gone.
- Caches: `PropertyCacheService` never stores `owner_contact`, versions each store, scopes keys to the account, purges on sign-out, and skips a `Cache-Control: no-store` response. `Property` has no owner contact field: the parser skips `owner_contact`, so no cache can hold it. The profile of the user is read from the Supabase session. No copy of it stays on the device: start-up removes the old `user_data` key.
- Caches in memory: `tripsProvider`, `wishlistProvider`, `favoritesProvider` and `exploreProvider` watch `accountIdProvider` (`session_provider.dart`). They reset on sign-out and on every change of the signed-in user id, load nothing while signed out, and drop an answer that arrives for an account that signed out (`AccountBound`). Test: `test/unit/account_reset_test.dart`.
- Account deletion: Profile, "Delete account", confirm, `DELETE /api/v1/users/me` (204), then the local sign-out.
- Push: `PushNotificationService` registers with `app_key=stays` at start-up, on token refresh and on sign-in. Sign-out and account deletion call `unregisterDevice` first (`DELETE /api/v1/notifications/devices/unregister`, token in a JSON body, session still valid). Nothing starts the service yet: the backend sends no push to `app_key=stays` (`app_key_for_type` returns ghar or flatmates). Start it with `PushNotificationService.shared.init()` in `ensureV2Bindings` when a stays notification type exists.
- Links: a push `route` and a deep link open a listing (`/stays/listing/{id}`) or a booking chat (`/stays/chat/{booking_id}`), on https or as `stays360://<entity>/<id>`. Every other route is dropped.
