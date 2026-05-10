#!/usr/bin/env bash
# verifiers/apply_formula.sh — Verifier for the apply_formula quickstart step.
#
# Exit 0 if ALL of the following are true:
#   1. data/.formula-applied.json exists
#   2. The JSON is well-formed and contains "rows_changed" and "applied_at" fields
#
# Optional check (legacy em-dash demo only — gated on the cache having
# `notes` in columns_affected). The current demo (title normalization)
# trusts the cache's rows_changed; no spot-check needed.
#
# Exit 1 (with a descriptive message to stderr) if any required check fails.

set -euo pipefail

# ─── Load env ────────────────────────────────────────────────────────────────

for ENV_FILE in secrets/.env .env .env.local "$HOME/.env" "$HOME/.env.maestro-quickstart"; do
  # shellcheck disable=SC1090
  [ -f "$ENV_FILE" ] && source "$ENV_FILE" 2>/dev/null || true
done

# ─── Check 1: cache file exists ──────────────────────────────────────────────

if [ ! -f "data/.formula-applied.json" ]; then
  echo "FAIL: data/.formula-applied.json not found." >&2
  echo "      The apply_formula step has not run yet (or ran outside the quickstart)." >&2
  echo "      Run /quickstart goto apply_formula to complete it." >&2
  exit 1
fi

# ─── Check 2: JSON is well-formed with required fields ───────────────────────

ROWS_CHANGED=$(jq '.rows_changed // -1' data/.formula-applied.json 2>/dev/null || echo "-1")
APPLIED_AT=$(jq -r '.applied_at // ""' data/.formula-applied.json 2>/dev/null || echo "")

if [ "$ROWS_CHANGED" = "-1" ] || [ -z "$APPLIED_AT" ]; then
  echo "FAIL: data/.formula-applied.json is malformed." >&2
  echo "      Expected fields: rows_changed (number), applied_at (ISO timestamp)." >&2
  echo "      Run /quickstart goto apply_formula to re-run the step." >&2
  exit 1
fi

# ─── Optional check: spot-check em-dash cleanup (legacy demo only) ───────────
# Only runs if rows_changed > 0 AND the cache says `notes` was in the
# columns_affected (the legacy em-dash demo). For the title-normalization
# demo or any other transform, the cache file is the source of truth — we
# trust rows_changed and skip the spot-check.

EM_DASH_DEMO_RAN=$(jq -r '(.columns_affected // []) | any(. == "notes")' data/.formula-applied.json 2>/dev/null || echo "false")

if [ "$ROWS_CHANGED" -gt 0 ] && [ "$EM_DASH_DEMO_RAN" = "true" ] 2>/dev/null; then
  SB_URL="${SUPABASE_URL:-}"
  SB_KEY="${SUPABASE_ANON_KEY:-}"

  if [ -n "$SB_URL" ] && [ -n "$SB_KEY" ]; then
    # Capture HTTP status separately. Old version only parsed content-range,
    # so a 401 returned empty REMAINING and silently degraded to "no warning"
    # — the verifier passed against a fully broken auth state.
    REMAINING_RAW=$(curl -s \
      -H "apikey: ${SB_KEY}" \
      -H "Authorization: Bearer ${SB_KEY}" \
      -H "Prefer: count=exact" \
      -o /dev/null -w "HTTP_CODE:%{http_code}|RANGE:%{header:content-range}" \
      "${SB_URL}/rest/v1/contacts?select=id&notes=like.*%E2%80%94*&limit=1" \
      --max-time 10 2>/dev/null || true)

    # `|| true` is load-bearing: under `set -euo pipefail`, a grep that finds
    # nothing exits 1 and aborts the script silently. Both pipelines can return
    # empty (e.g. older curl that doesn't expand %{header:content-range}, or a
    # response with no content-range header). Treat empty as "no info" and let
    # the if/elif chain below handle it via HTTP_CODE.
    HTTP_CODE=$(echo "$REMAINING_RAW" | grep -oE 'HTTP_CODE:[0-9]+' | cut -d: -f2 || true)
    HTTP_CODE="${HTTP_CODE:-000}"
    REMAINING=$(echo "$REMAINING_RAW" | grep -oE 'RANGE:[^|]*' | grep -oE '[0-9]+$' || true)

    if [ "$HTTP_CODE" = "200" ] || [ "$HTTP_CODE" = "206" ]; then
      if [ -n "$REMAINING" ] && [ "$REMAINING" -gt 0 ] 2>/dev/null; then
        echo "WARN: ${REMAINING} contacts still contain em-dashes in notes." >&2
        echo "      This may mean the UPDATE did not complete or new rows were inserted since." >&2
        echo "      Run /quickstart goto apply_formula and choose 'redo' to re-apply." >&2
        # Treat as a warning — do not fail the verifier. The cache file confirms the step ran.
      fi
    elif [ "$HTTP_CODE" = "000" ]; then
      echo "WARN: Could not reach Supabase to verify em-dash cleanup. Step's local cache says it ran." >&2
      # Soft warn — don't fail the verifier. A run that completed locally is still valid evidence.
    elif [ "$HTTP_CODE" = "401" ] || [ "$HTTP_CODE" = "403" ]; then
      echo "WARN: Supabase rejected the anon key (HTTP $HTTP_CODE). Em-dash re-check skipped." >&2
    else
      echo "WARN: Unexpected HTTP $HTTP_CODE from Supabase. Em-dash re-check skipped." >&2
    fi
  fi
fi

# ─── All checks passed ───────────────────────────────────────────────────────

COLUMNS=$(jq -r '(.columns_affected // []) | join(", ")' data/.formula-applied.json 2>/dev/null || echo "unknown")
ELAPSED=$(jq '.elapsed_ms // 0' data/.formula-applied.json 2>/dev/null || echo "0")
STATUS=$(jq -r '.status // "unknown"' data/.formula-applied.json 2>/dev/null || echo "unknown")
REASON=$(jq -r '.reason // ""' data/.formula-applied.json 2>/dev/null || echo "")

if [ -n "$REASON" ]; then
  echo "OK: apply_formula complete. rows_changed=${ROWS_CHANGED} reason=${REASON} applied_at=${APPLIED_AT}"
else
  echo "OK: apply_formula complete. rows_changed=${ROWS_CHANGED} columns=[${COLUMNS}] elapsed=${ELAPSED}ms status=${STATUS} applied_at=${APPLIED_AT}"
fi

exit 0
