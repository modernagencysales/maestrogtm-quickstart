#!/usr/bin/env bash
# verifiers/schema_migrate.sh
# Verifies the GTM starter schema has been migrated into the user's Supabase project.
#
# Checks:
#   1. SUPABASE_URL is set (env or .env files)
#   2. SUPABASE_SERVICE_ROLE_KEY is set — required; anon key cannot query information_schema
#   3. All 28 required tables exist in the public schema
#
# The 28 tables (per course/SCHEMA_RELATIONSHIPS.md): contacts is the root entity.
# Every other table chains back to contacts in <= 1 join.
#
# Exit 0 = all tables present. Exit 1 = failure (reason on stderr).

set -e

# ── Required tables (28, source of truth: SCHEMA_RELATIONSHIPS.md) ────────────

REQUIRED_TABLES=(
  agentmail_inboxes
  agentmail_webhook_events
  brain_chunks
  companies
  contacts
  content_calendar
  enrichment_cache
  followup_email_queue
  followup_linkedin_queue
  followup_log
  funnel_leads
  journal
  lead_magnets
  linkedin_campaigns
  linkedin_connections
  meetings
  outreach_campaign_leads
  outreach_campaigns
  outreach_cross_channel_state
  post_engagements
  posts
  replies
  reply_classifications
  reply_drafts
  send_attempts
  sequences
  signals
  suppression_list
)

# ── Load credentials from env or .env files ───────────────────────────────────

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

SUPABASE_URL="${SUPABASE_URL:-}"
SUPABASE_SERVICE_ROLE_KEY="${SUPABASE_SERVICE_ROLE_KEY:-}"

if [ -z "$SUPABASE_URL" ]; then
  SUPABASE_URL=$(_load_from_env_files "SUPABASE_URL" 2>/dev/null || true)
fi

if [ -z "$SUPABASE_SERVICE_ROLE_KEY" ]; then
  SUPABASE_SERVICE_ROLE_KEY=$(_load_from_env_files "SUPABASE_SERVICE_ROLE_KEY" 2>/dev/null || true)
fi

# ── Check 1: SUPABASE_URL ─────────────────────────────────────────────────────

if [ -z "$SUPABASE_URL" ]; then
  echo "SUPABASE_URL is not set in the environment or any .env file" >&2
  echo "Set it with: export SUPABASE_URL=https://yourproject.supabase.co" >&2
  exit 1
fi

if ! echo "$SUPABASE_URL" | grep -qE '^https://[a-z0-9]+\.supabase\.co$'; then
  echo "SUPABASE_URL does not look valid: $SUPABASE_URL" >&2
  echo "Expected format: https://abcdefghijklmnop.supabase.co" >&2
  exit 1
fi

# ── Check 2: SUPABASE_SERVICE_ROLE_KEY ───────────────────────────────────────

if [ -z "$SUPABASE_SERVICE_ROLE_KEY" ]; then
  echo "SUPABASE_SERVICE_ROLE_KEY is required for schema verification." >&2
  echo "The anon key cannot read information_schema — service role can." >&2
  echo "" >&2
  echo "Get it from: Supabase Dashboard → Settings → API → service_role → Reveal" >&2
  echo "Add to your .env file as: SUPABASE_SERVICE_ROLE_KEY=<key>" >&2
  echo "Then re-run the verifier." >&2
  exit 1
fi

if ! echo "$SUPABASE_SERVICE_ROLE_KEY" | grep -qE '^eyJ'; then
  echo "SUPABASE_SERVICE_ROLE_KEY does not look like a valid JWT (should start with eyJ)" >&2
  exit 1
fi

# ── Check 3: Query Supabase for existing tables ───────────────────────────────
# Use the PostgREST schema-discovery endpoint: GET /rest/v1/ returns an OpenAPI
# spec whose "paths" keys are the table names prefixed with "/".

RESPONSE=$(curl -s \
  -H "apikey: $SUPABASE_SERVICE_ROLE_KEY" \
  -H "Authorization: Bearer $SUPABASE_SERVICE_ROLE_KEY" \
  --max-time 15 \
  "$SUPABASE_URL/rest/v1/" \
  2>/dev/null || true)

HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" \
  -H "apikey: $SUPABASE_SERVICE_ROLE_KEY" \
  -H "Authorization: Bearer $SUPABASE_SERVICE_ROLE_KEY" \
  --max-time 15 \
  "$SUPABASE_URL/rest/v1/" \
  2>/dev/null || true)
HTTP_CODE="${HTTP_CODE:-000}"

if [ "$HTTP_CODE" = "401" ]; then
  echo "Supabase returned HTTP 401 — service role key is invalid or has been rotated" >&2
  echo "Get a fresh key from: Supabase Dashboard → Settings → API → service_role" >&2
  exit 1
fi

if [ "$HTTP_CODE" = "000" ]; then
  echo "Could not reach $SUPABASE_URL (connection timeout or no internet)" >&2
  echo "Check your internet connection and try again." >&2
  exit 1
fi

if [ "$HTTP_CODE" != "200" ]; then
  echo "Supabase returned unexpected HTTP $HTTP_CODE from $SUPABASE_URL/rest/v1/" >&2
  exit 1
fi

# ── Parse paths out of the OpenAPI response ───────────────────────────────────
# The response is a JSON object. Keys under "paths" are "/<tablename>".
# We extract them and strip the leading slash.

if command -v jq >/dev/null 2>&1; then
  FOUND_TABLES=$(echo "$RESPONSE" | jq -r '.paths | keys[] | ltrimstr("/")' 2>/dev/null | sort)
else
  # Fallback: grep for quoted path names (less precise but no jq dependency)
  FOUND_TABLES=$(echo "$RESPONSE" | grep -oE '"\/[a-z_]+"' | tr -d '"/' | sort)
fi

# ── Check each required table ─────────────────────────────────────────────────

MISSING=()

for table in "${REQUIRED_TABLES[@]}"; do
  if ! echo "$FOUND_TABLES" | grep -qx "$table"; then
    MISSING+=("$table")
  fi
done

# ── Report results ────────────────────────────────────────────────────────────

if [ "${#MISSING[@]}" -gt 0 ]; then
  echo "Schema verification failed — missing tables:" >&2
  for t in "${MISSING[@]}"; do
    echo "  ✗ $t" >&2
  done
  echo "" >&2
  PRESENT_COUNT=$(( ${#REQUIRED_TABLES[@]} - ${#MISSING[@]} ))
  echo "Found $PRESENT_COUNT of ${#REQUIRED_TABLES[@]} required tables." >&2
  echo "" >&2
  echo "To fix (fastest): run  supabase db push  from your project directory." >&2
  echo "Make sure supabase/migrations/<timestamp>_gtm_starter.sql is present first." >&2
  echo "Schema SQL source: ~/.claude/skills/quickstart/templates/gtm-starter-schema.sql" >&2
  exit 1
fi

# ── All 28 tables confirmed ───────────────────────────────────────────────────

PROJECT=$(echo "$SUPABASE_URL" | sed -E 's|^https://([a-z0-9]+)\.supabase\.co.*|\1|')
[ -z "$PROJECT" ] && PROJECT="unknown"
echo "schema_migrate verified: project=$PROJECT tables=${#REQUIRED_TABLES[@]}/28 HTTP=200"
exit 0
