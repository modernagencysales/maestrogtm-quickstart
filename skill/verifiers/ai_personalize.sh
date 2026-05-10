#!/usr/bin/env bash
# verifiers/ai_personalize.sh
# Verifies that the ai_personalize quickstart step ran successfully.
#
# Offer-first contract:
#   • data/offer.md MUST exist with non-trivial content (the offer is the email body)
#   • data/.personalize-result.json MUST exist with a `path` field
#   • Per-path success criteria:
#       path=skip       → no first_line coverage required
#       path=templated  → ≥80% of email-bearing contacts have first_line
#       path=real       → personalized + skipped_empty_signal == needs_count (empty
#                          signal → empty first_line is INTENDED, not failure)
#
# Exit 0 = pass. Exit 1 = fail (reason on stderr).

set -euo pipefail

# ── Load env from secrets/.env or fallback .env files ────────────────────────

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
SUPABASE_ANON_KEY="${SUPABASE_ANON_KEY:-}"

[ -z "$SUPABASE_URL"      ] && SUPABASE_URL=$(_load_from_env_files      "SUPABASE_URL"      2>/dev/null || true)
[ -z "$SUPABASE_ANON_KEY" ] && SUPABASE_ANON_KEY=$(_load_from_env_files "SUPABASE_ANON_KEY" 2>/dev/null || true)

# ── Check 0: campaign artifacts exist and are non-trivial ───────────────────

OFFER_FILE="data/campaign/offer.md"
SEQUENCE_FILE="data/campaign/sequence.md"
STRATEGY_FILE="data/campaign/strategy.md"

# Accept legacy data/offer.md location if present (pre-campaign-architect runs)
[ ! -f "$OFFER_FILE" ] && [ -f "data/offer.md" ] && OFFER_FILE="data/offer.md"

if [ ! -f "$OFFER_FILE" ]; then
  echo "FAIL: $OFFER_FILE not found — the offer artifact is mandatory." >&2
  echo "      Re-run ai_personalize and complete the offer-building phase." >&2
  exit 1
fi

OFFER_CHARS=$(wc -c < "$OFFER_FILE" | tr -d ' ')
if [ "$OFFER_CHARS" -lt 80 ]; then
  echo "FAIL: $OFFER_FILE is only ${OFFER_CHARS} chars — looks like a placeholder." >&2
  echo "      A real offer is 2-4 paragraphs covering what's free, who it's for, why now, what to expect." >&2
  exit 1
fi

if [ ! -f "$SEQUENCE_FILE" ]; then
  echo "WARN: $SEQUENCE_FILE not found — no email sequence was drafted." >&2
  echo "      send_outreach will fall back to using offer.md as the entire body." >&2
fi

# ── Check 1: cache file exists with required fields ──────────────────────────

if [ ! -f "data/.personalize-result.json" ]; then
  echo "FAIL: data/.personalize-result.json not found — personalization has not run yet." >&2
  exit 1
fi

PATH_CHOSEN=$(python3 -c "
import json
try:
  with open('data/.personalize-result.json') as f:
    d = json.load(f)
  print(d.get('path', ''))
except Exception:
  print('')
" 2>/dev/null || echo "")

if [ -z "$PATH_CHOSEN" ]; then
  echo "FAIL: data/.personalize-result.json is missing the 'path' field (skip|templated|real)." >&2
  echo "      Re-run ai_personalize — the cache writer must record which approach was used." >&2
  exit 1
fi

if [ "$PATH_CHOSEN" != "skip" ] && [ "$PATH_CHOSEN" != "templated" ] && [ "$PATH_CHOSEN" != "real" ]; then
  echo "FAIL: data/.personalize-result.json has unexpected path='${PATH_CHOSEN}' — must be skip|templated|real." >&2
  exit 1
fi

PERSONALIZED=$(python3 -c "
import json
try:
  with open('data/.personalize-result.json') as f:
    d = json.load(f)
  print(int(d.get('personalized', 0)))
except Exception:
  print(0)
" 2>/dev/null || echo "0")

SKIPPED_EMPTY=$(python3 -c "
import json
try:
  with open('data/.personalize-result.json') as f:
    d = json.load(f)
  print(int(d.get('skipped_empty_signal', 0)))
except Exception:
  print(0)
" 2>/dev/null || echo "0")

NEEDS_COUNT=$(python3 -c "
import json
try:
  with open('data/.personalize-result.json') as f:
    d = json.load(f)
  print(int(d.get('needs_count', 0)))
except Exception:
  print(0)
" 2>/dev/null || echo "0")

# ── Check 2: Supabase credentials present ────────────────────────────────────

if [ -z "$SUPABASE_URL" ] || [ -z "$SUPABASE_ANON_KEY" ]; then
  echo "FAIL: SUPABASE_URL or SUPABASE_ANON_KEY is not set." >&2
  echo "      Complete the supabase_setup step first." >&2
  exit 1
fi

# Helper: fetch count from PostgREST
_count_query() {
  local filter="$1"
  local resp
  resp=$(curl -s -w "\n%{http_code}" \
    -H "apikey: $SUPABASE_ANON_KEY" \
    -H "Authorization: Bearer $SUPABASE_ANON_KEY" \
    -H "Prefer: count=exact" \
    "${SUPABASE_URL}/rest/v1/contacts?select=count&${filter}" \
    --max-time 15 \
    2>/dev/null || echo -e "\n000")
  local code body
  code=$(echo "$resp" | tail -1)
  body=$(echo "$resp" | sed '$d')
  if [ "$code" != "200" ] && [ "$code" != "206" ]; then
    echo "ERR:$code:$body"
    return 1
  fi
  echo "$body" | python3 -c "
import sys, json
try:
  d = json.load(sys.stdin)
  print(d[0]['count'] if d else 0)
except Exception:
  print(0)
"
}

EMAIL_COUNT=$(_count_query "email=not.is.null" || true)
if [[ "$EMAIL_COUNT" == ERR:* ]]; then
  echo "FAIL: Supabase query for email count failed — ${EMAIL_COUNT}" >&2
  exit 1
fi

if [ "$EMAIL_COUNT" -lt 1 ] 2>/dev/null; then
  echo "FAIL: No contacts with a non-null email found in Supabase." >&2
  echo "      Run first_workflow to import enriched contacts before personalizing." >&2
  exit 1
fi

# ── Path-specific success criteria ───────────────────────────────────────────

case "$PATH_CHOSEN" in
  skip)
    # No first_line coverage required. Just sanity-check that offer.md exists
    # (already done above) and that the cache file recorded the skip decision.
    echo "OK: ai_personalize verified — path=skip, offer-only outreach (${OFFER_CHARS} chars in offer.md, ${EMAIL_COUNT} email-bearing contacts)."
    exit 0
    ;;

  templated)
    DONE_COUNT=$(_count_query "email=not.is.null&first_line=not.is.null" || true)
    if [[ "$DONE_COUNT" == ERR:* ]]; then
      echo "FAIL: Supabase query for first_line count failed — ${DONE_COUNT}" >&2
      exit 1
    fi
    COVERAGE_PCT=$(python3 -c "
total=int('$EMAIL_COUNT'); done=int('$DONE_COUNT')
print(0 if total==0 else int(done/total*100))
")
    if [ "$COVERAGE_PCT" -lt 80 ] 2>/dev/null; then
      echo "FAIL: path=templated requires ≥80% first_line coverage. Got ${DONE_COUNT}/${EMAIL_COUNT} (${COVERAGE_PCT}%)." >&2
      echo "      Templated personalization always writes a line — re-run for the remaining rows." >&2
      exit 1
    fi
    echo "OK: ai_personalize verified — path=templated, first_line=${DONE_COUNT}/${EMAIL_COUNT} (${COVERAGE_PCT}%), offer.md present."
    exit 0
    ;;

  real)
    # path=real: empty signal → empty first_line is intended behavior.
    # Require: personalized + skipped_empty_signal accounts for ≥90% of needs_count.
    # Also require personalized ≥ 1 (otherwise the buyer didn't actually try).
    if [ "$PERSONALIZED" -lt 1 ] 2>/dev/null; then
      echo "FAIL: path=real but personalized=0 — no first_lines were composed." >&2
      echo "      If signals were genuinely empty for everyone, switch to path=skip and re-run." >&2
      exit 1
    fi
    ACCOUNTED=$(( PERSONALIZED + SKIPPED_EMPTY ))
    if [ "$NEEDS_COUNT" -gt 0 ] 2>/dev/null; then
      RATIO_PCT=$(python3 -c "
n=int('$NEEDS_COUNT'); a=int('$ACCOUNTED')
print(0 if n==0 else int(a/n*100))
")
      if [ "$RATIO_PCT" -lt 90 ] 2>/dev/null; then
        echo "FAIL: path=real but only ${ACCOUNTED}/${NEEDS_COUNT} contacts were processed (${RATIO_PCT}%, need ≥90%)." >&2
        echo "      Re-run ai_personalize for the remaining rows." >&2
        exit 1
      fi
    fi
    echo "OK: ai_personalize verified — path=real, personalized=${PERSONALIZED}, skipped_empty_signal=${SKIPPED_EMPTY}, offer.md present."
    exit 0
    ;;
esac
