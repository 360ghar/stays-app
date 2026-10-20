#!/usr/bin/env bash
# Runs both contract generators, then fails when the generated files in the
# tree differ from what the backend produces now:
#   lib/app/data/models/wire_enums.dart
#   test/fixtures/
#
# Needs a backend checkout. It looks in the 360ghar workspace; set
# GHAR_BACKEND_DIR for another path. Without a checkout the check is skipped,
# unless --strict is given (then it fails).
#
# The generators overwrite the files. After a failure, review the diff and
# commit the new files.
set -euo pipefail

cd "$(dirname "$0")/.."

strict=0
[ "${1:-}" = "--strict" ] && strict=1

backend="${GHAR_BACKEND_DIR:-$(cd ../../.. && pwd)/github/360ghar/360ghar-backend}"
if [ ! -f "$backend/docs/openapi.json" ]; then
  echo "check_contract: no backend checkout at $backend (set GHAR_BACKEND_DIR)." >&2
  [ "$strict" -eq 1 ] && exit 1
  echo "check_contract: skipped." >&2
  exit 0
fi
export GHAR_BACKEND_DIR="$backend"

# A snapshot, not `git diff`: a new file is not in git yet, and git diff then
# reports nothing.
before="$(mktemp -d)"
trap 'rm -rf "$before"' EXIT
cp lib/app/data/models/wire_enums.dart "$before/wire_enums.dart"
cp -R test/fixtures "$before/fixtures"

python3 tool/gen_enums.py --source "$backend/docs/openapi.json"
uv run --project "$backend" python tool/api_fixtures.py

status=0
diff -u "$before/wire_enums.dart" lib/app/data/models/wire_enums.dart || status=1
diff -ru "$before/fixtures" test/fixtures || status=1
if [ "$status" -ne 0 ]; then
  echo "check_contract: the generated contract files are out of date. They are regenerated now: review and commit them." >&2
  exit 1
fi
echo "check_contract: wire enums and fixtures match the backend."
