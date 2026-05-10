#!/usr/bin/env bash
# verifiers/supabase_setup.sh
# Verifies Supabase credentials are present and the project is reachable.
#
# Checks:
#   1. SUPABASE_URL is set in the environment OR found in a .env / secrets/.env file
#   2. SUPABASE_ANON_KEY is set in the environment OR found in a .env / secrets/.env file
#   3. Both values are non-empty and pass basic format validation
#   4. HTTP GET to $SUPABASE_URL/auth/v1/health returns 200
#      (auth health endpoint, anon-accessible — does NOT require an apikey
#       header. Avoids the false-401 trap on /rest/v1/ for newer projects
#       whose anon role lacks USAGE on the public schema by default.)
#
# Optional indicator (not required for pass):
#   5. secrets/.supabase-db-password exists → Path A (CLI) was taken
#
# Exit 0 = pass. Exit 1 = fail (reason on stderr).

set -e

# ── Resolve credentials from env or .env files ────────────────────────────────

_load_from_env_files() {
  local key="$1"
  local value=""

  for f in secrets/.env .env .env.local "$HOME/.env" "$HOME/.env.maestro-quickstart"; do
    if [ -f "$f" ]; then
      value=$(grep -E "^${key}=" "$f" 2>/dev/null | head -1 | cut -d'=' -f2- | tr -d '\r\n')
      if [ -n "$value" ]; then
        echo "$value"
        return 0
      fi
    fi
  done
  return 1
}

# Prefer shell environment, fall back to .env files
SUPABASE_URL="${SUPABASE_URL:-}"
SUPABASE_ANON_KEY="${SUPABASE_ANON_KEY:-}"

if [ -z "$SUPABASE_URL" ]; then
  SUPABASE_URL=$(_load_from_env_files "SUPABASE_URL" 2>/dev/null || true)
fi

if [ -z "$SUPABASE_ANON_KEY" ]; then
  SUPABASE_ANON_KEY=$(_load_from_env_files "SUPABASE_ANON_KEY" 2>/dev/null || true)
fi

# ── Check 1: SUPABASE_URL present and valid ───────────────────────────────────

if [ -z "$SUPABASE_URL" ]; then
  echo "SUPABASE_URL is not set in the environment or any .env file" >&2
  echo "Expected locations: secrets/.env, .env, .env.local, ~/.env, ~/.env.maestro-quickstart" >&2
  exit 1
fi

if ! echo "$SUPABASE_URL" | grep -qE '^https://[a-z0-9]+\.supabase\.co$'; then
  echo "SUPABASE_URL does not look valid: $SUPABASE_URL" >&2
  echo "Expected format: https://abcdefghijklmnop.supabase.co" >&2
  exit 1
fi

# ── Check 2: SUPABASE_ANON_KEY present and valid ──────────────────────────────

if [ -z "$SUPABASE_ANON_KEY" ]; then
  echo "SUPABASE_ANON_KEY is not set in the environment or any .env file" >&2
  echo "Get it from: Supabase Dashboard → Settings → API → anon public" >&2
  echo "Or re-run the CLI path: supabase projects api-keys --project-ref <ref>" >&2
  exit 1
fi

if ! echo "$SUPABASE_ANON_KEY" | grep -qE '^eyJ'; then
  echo "SUPABASE_ANON_KEY does not look like a valid JWT (should start with eyJ)" >&2
  exit 1
fi

# ── Check 3: Live connectivity test ───────────────────────────────────────────
# Hit /auth/v1/health WITH the anon apikey header. Newer Supabase projects
# (created after the API-keys revamp) reject unauthenticated requests to this
# endpoint with 401; older projects accepted them. Sending the apikey is
# correct on both. Avoids /rest/v1/ which requires service_role on new projects.

HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" \
  -H "apikey: $SUPABASE_ANON_KEY" \
  "$SUPABASE_URL/auth/v1/health" \
  --max-time 10 \
  2>/dev/null || true)
# curl prints "000" via %{http_code} on failure already; never concat another "000".
HTTP_CODE="${HTTP_CODE:-000}"

if [ "$HTTP_CODE" = "200" ]; then
  : # pass — project is live and reachable
elif [ "$HTTP_CODE" = "000" ]; then
  echo "Could not reach $SUPABASE_URL (connection timeout or no internet)" >&2
  echo "Check your internet connection. If the project is new, wait 30s and retry." >&2
  exit 1
else
  echo "Supabase auth health returned unexpected HTTP $HTTP_CODE from $SUPABASE_URL/auth/v1/health" >&2
  echo "The project may be paused or the URL may be wrong. Confirm at: Supabase Dashboard → your project" >&2
  exit 1
fi

# ── All checks passed ─────────────────────────────────────────────────────────

PROJECT=$(echo "$SUPABASE_URL" | sed -E 's|^https?://([a-z0-9]+)\.supabase\.co.*|\1|')

# Optional: note if Path A (CLI) was taken — presence of db password file is the indicator
PATH_TAKEN="manual-or-browser"
if [ -f "secrets/.supabase-db-password" ]; then
  PATH_TAKEN="cli"
fi

echo "supabase_setup verified: project=$PROJECT HTTP=200 path=$PATH_TAKEN"
exit 0
