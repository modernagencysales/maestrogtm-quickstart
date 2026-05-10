#!/usr/bin/env bash
# verifiers/first_workflow.sh
# Verifies that the first_workflow step completed successfully.
#
# Checks:
#   1. data/.first-workflow-result.json exists
#   2. JSON is well-formed and contacts > 0
#   3. (Optional, if Supabase creds present) companies and contacts tables have rows
#
# Exit 0 = pass. Exit 1 = fail (reason on stderr).

set -e

RESULT_CACHE="data/.first-workflow-result.json"

# ── Check 1: result file exists ───────────────────────────────────────────────

if [ ! -f "$RESULT_CACHE" ]; then
  echo "data/.first-workflow-result.json not found" >&2
  echo "Run first_workflow to execute the Deepline workflow and cache the results." >&2
  echo "Expected at: $(pwd)/$RESULT_CACHE" >&2
  exit 1
fi

# ── Check 2: file is valid JSON ───────────────────────────────────────────────

if ! jq empty "$RESULT_CACHE" 2>/dev/null; then
  echo "data/.first-workflow-result.json is not valid JSON" >&2
  echo "Delete the file and re-run first_workflow:" >&2
  echo "  rm $RESULT_CACHE && /quickstart goto first_workflow" >&2
  exit 1
fi

# ── Check 3: contacts count is a number greater than 0 ───────────────────────

CONTACTS=$(jq -r '.contacts // 0' "$RESULT_CACHE" 2>/dev/null || echo "0")

if ! echo "$CONTACTS" | grep -qE '^[0-9]+$'; then
  echo "contacts is not a valid number in $RESULT_CACHE (got: $CONTACTS)" >&2
  echo "Delete the file and re-run first_workflow:" >&2
  echo "  rm $RESULT_CACHE && /quickstart goto first_workflow" >&2
  exit 1
fi

if [ "$CONTACTS" -lt 1 ]; then
  echo "contacts is 0 in $RESULT_CACHE — the workflow returned no results" >&2
  echo "Re-run first_workflow to try again with different ICP criteria." >&2
  exit 1
fi

# ── Check 4: written_at is present and recent ─────────────────────────────────

WRITTEN_AT=$(jq -r '.written_at // empty' "$RESULT_CACHE" 2>/dev/null)
if [ -z "$WRITTEN_AT" ]; then
  echo "written_at missing from $RESULT_CACHE — file may be from an older format" >&2
  echo "Delete the file and re-run first_workflow." >&2
  exit 1
fi

# Reject caches older than 24 hours — they likely belong to a previous run
# whose DB rows are still present, which can mask a 0-result current run.
AGE_HOURS=$(python3 -c "
import datetime, sys
try:
    written = datetime.datetime.fromisoformat('$WRITTEN_AT'.replace('Z','+00:00'))
    now = datetime.datetime.now(datetime.timezone.utc)
    print(int((now - written).total_seconds() // 3600))
except Exception:
    print(0)
" 2>/dev/null || echo "0")
if [ "$AGE_HOURS" -gt 24 ] 2>/dev/null; then
  echo "Cache is ${AGE_HOURS}h old — likely from a previous run." >&2
  echo "Delete data/.first-workflow-result.json and re-run first_workflow to refresh." >&2
  exit 1
fi

# ── Check 5: optional Supabase row counts ────────────────────────────────────

# Load env from secrets/.env first (where supabase_setup writes), then fall back
for f in secrets/.env .env .env.local "$HOME/.env" "$HOME/.env.maestro-quickstart"; do
  [ -f "$f" ] && set -a && source "$f" && set +a && break
done

SUPABASE_URL="${SUPABASE_URL:-}"
SUPABASE_SERVICE_ROLE_KEY="${SUPABASE_SERVICE_ROLE_KEY:-}"

if [ -z "$SUPABASE_URL" ] || [ -z "$SUPABASE_SERVICE_ROLE_KEY" ]; then
  echo "WARN: Supabase credentials not found — skipping database row count checks" >&2
  echo "Set SUPABASE_URL and SUPABASE_SERVICE_ROLE_KEY in secrets/.env to enable full verification." >&2
  COMPANIES=$(jq -r '.companies // 0' "$RESULT_CACHE" 2>/dev/null || echo "0")
  echo "first_workflow verified (DB checks skipped): companies=$COMPANIES contacts=$CONTACTS written_at=$WRITTEN_AT"
  exit 0
fi

_count_table() {
  local table="$1"
  local extra_filter="${2:-}"
  local resp count
  resp=$(curl -s \
    "${SUPABASE_URL}/rest/v1/${table}?select=id${extra_filter}" \
    -H "apikey: ${SUPABASE_SERVICE_ROLE_KEY}" \
    -H "Authorization: Bearer ${SUPABASE_SERVICE_ROLE_KEY}" \
    -H "Prefer: count=exact" \
    -I \
    --max-time 15 2>/dev/null || echo "")
  count=$(echo "$resp" | grep -i "content-range:" | sed 's/.*\///' | tr -d '[:space:][:cntrl:]')
  if ! echo "$count" | grep -qE '^[0-9]+$'; then
    # Fallback: JSON length
    local json
    json=$(curl -s \
      "${SUPABASE_URL}/rest/v1/${table}?select=id&limit=100${extra_filter}" \
      -H "apikey: ${SUPABASE_SERVICE_ROLE_KEY}" \
      -H "Authorization: Bearer ${SUPABASE_SERVICE_ROLE_KEY}" \
      --max-time 15 2>/dev/null || echo "[]")
    count=$(echo "$json" | jq 'length' 2>/dev/null || echo "0")
  fi
  echo "${count:-0}"
}

# Scope DB row counts to "this run" — `written_at` minus a 1h buffer to allow
# clock drift and slow imports. Without this, stale rows from prior runs let
# the verifier pass even when the current run imported nothing.
SINCE_TS=$(python3 -c "import datetime,sys; t=datetime.datetime.fromisoformat('$WRITTEN_AT'.replace('Z','+00:00')); print((t - datetime.timedelta(hours=1)).strftime('%Y-%m-%dT%H:%M:%SZ'))" 2>/dev/null || echo "$WRITTEN_AT")
RECENT_FILTER="&created_at=gte.${SINCE_TS}"

COMPANY_COUNT=$(_count_table companies "$RECENT_FILTER")
CONTACT_COUNT=$(_count_table contacts "$RECENT_FILTER")

if [ "$COMPANY_COUNT" -lt 1 ] 2>/dev/null; then
  echo "Supabase companies table has $COMPANY_COUNT rows — expected at least 1." >&2
  echo "The import step may not have run. Re-run first_workflow to retry." >&2
  exit 1
fi

if [ "$CONTACT_COUNT" -lt 1 ] 2>/dev/null; then
  echo "Supabase contacts table has $CONTACT_COUNT rows — expected at least 1." >&2
  echo "The import step may not have run or returned too few contacts." >&2
  exit 1
fi

# ── All checks passed ─────────────────────────────────────────────────────────

CACHED_COMPANIES=$(jq -r '.companies // 0' "$RESULT_CACHE" 2>/dev/null || echo "0")
echo "first_workflow verified: companies=$COMPANY_COUNT contacts=$CONTACT_COUNT (cache: companies=$CACHED_COMPANIES contacts=$CONTACTS) written_at=$WRITTEN_AT"
exit 0
