#!/usr/bin/env bash
# verifiers/finale.sh
# Verifies the adventure reached its final state.
#
# Checks:
#   1. state.json exists and is valid JSON
#   2. status field equals "complete"
#   3. Sets coupon_shown = true if not already set (idempotent side effect)
#
# Exit 0 = always passes once status is "complete".
# Exit 1 = adventure not yet complete.

set -e

STATE="$HOME/.claude/skills/quickstart/state.json"

# ── Check 1: file exists and is valid JSON ────────────────────────────────────

if [ ! -f "$STATE" ]; then
  echo "state.json not found at $STATE" >&2
  exit 1
fi

if ! jq empty "$STATE" 2>/dev/null; then
  echo "state.json is not valid JSON" >&2
  exit 1
fi

# ── Check 2: status is "complete" ────────────────────────────────────────────

STATUS=$(jq -r '.status // empty' "$STATE")

if [ "$STATUS" != "complete" ]; then
  CURRENT=$(jq -r '.current_step // "unknown"' "$STATE")
  PATH_VAL=$(jq -r '.path // "not yet set"' "$STATE")
  DONE=$(jq -r '.completed_steps | length' "$STATE")
  # Single linear path: 11 steps if ship, 9 if review (skip send_outreach + ship_test).
  TOTAL_HINT=$(jq -r 'if .path == "review" then 9 elif .path == "ship" then 11 else 11 end' "$STATE")

  echo "Adventure not yet complete (status=$STATUS)" >&2
  echo "  Path:            $PATH_VAL" >&2
  echo "  Current step:    $CURRENT" >&2
  echo "  Steps completed: $DONE of $TOTAL_HINT" >&2
  echo "" >&2
  echo "Run /quickstart continue to pick up where you left off." >&2
  exit 1
fi

# ── Side effect: ensure coupon_shown is true ─────────────────────────────────

COUPON_SHOWN=$(jq -r '.coupon_shown // false' "$STATE")

if [ "$COUPON_SHOWN" != "true" ]; then
  jq '.coupon_shown = true' "$STATE" > /tmp/qs_finale_verify.json \
    && mv /tmp/qs_finale_verify.json "$STATE"
fi

# ── Report ────────────────────────────────────────────────────────────────────

PATH_VAL=$(jq -r '.path // "unknown"' "$STATE")
DONE=$(jq -r '.completed_steps | length' "$STATE")
SKIPPED=$(jq -r '(.skipped_steps // []) | length' "$STATE")
FINISHED=$(jq -r '.finished_at // .last_run_at // "unknown"' "$STATE")

echo "finale verified: status=complete path=$PATH_VAL completed=$DONE skipped=$SKIPPED finished_at=$FINISHED"
exit 0
