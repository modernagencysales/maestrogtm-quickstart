#!/usr/bin/env bash
# verifiers/ship_test.sh
# Verifies that the ship_test step is ready to run (single-path flow).
#
# In the new flow, ship_test only runs on path = "ship". The actual end-to-end
# verification re-uses the send_outreach.sh verifier (which checks
# data/.outreach-wired.json). This wrapper confirms the pre-conditions and that
# send_outreach already produced the expected artifacts.
#
# Checks:
#   1. state.json exists and is valid JSON
#   2. path is "ship"
#   3. send_outreach is in completed_steps (or skipped)
#   4. data/.outreach-wired.json exists and has the required fields
#
# Exit 0 = pre-conditions met. Exit 1 = pre-conditions not met (reason on stderr).

set -e

STATE="$HOME/.claude/skills/quickstart/state.json"
WIRED_FILE="data/.outreach-wired.json"

# ── Check 1: state.json exists and is valid JSON ──────────────────────────────

if [ ! -f "$STATE" ]; then
  echo "state.json not found at $STATE" >&2
  echo "Run /quickstart to initialize the adventure." >&2
  exit 1
fi

if ! jq empty "$STATE" 2>/dev/null; then
  echo "state.json is not valid JSON — run /quickstart reset to start fresh." >&2
  exit 1
fi

# ── Check 2: path is "ship" ───────────────────────────────────────────────────

PATH_VALUE=$(jq -r '.path // empty' "$STATE")

case "$PATH_VALUE" in
  ship)
    : # valid — proceed
    ;;
  review)
    echo "ship_test does not apply to path = review (review path skips straight to finale)." >&2
    echo "Run /quickstart goto __finale__ to continue." >&2
    exit 1
    ;;
  ""|null)
    echo "Path not set — fork_pick has not completed." >&2
    echo "Run /quickstart goto fork_pick to choose ship or review." >&2
    exit 1
    ;;
  *)
    echo "Path has unexpected value: '$PATH_VALUE' (expected 'ship' or 'review')." >&2
    echo "Run /quickstart reset to start fresh." >&2
    exit 1
    ;;
esac

# ── Check 3: send_outreach completed or skipped ──────────────────────────────

DONE_OR_SKIPPED=$(jq -r '
  ((.completed_steps // []) + (.skipped_steps // []))
  | map(select(. == "send_outreach"))
  | length
' "$STATE")

if [ "$DONE_OR_SKIPPED" -eq 0 ]; then
  echo "send_outreach is not in completed_steps or skipped_steps." >&2
  echo "Run /quickstart goto send_outreach to wire your outreach channels." >&2
  exit 1
fi

# ── Check 4: data/.outreach-wired.json exists with required fields ───────────

if [ ! -f "$WIRED_FILE" ]; then
  echo "data/.outreach-wired.json not found." >&2
  echo "Run /quickstart goto send_outreach to wire outreach end-to-end." >&2
  exit 1
fi

if ! jq empty "$WIRED_FILE" 2>/dev/null; then
  echo "data/.outreach-wired.json is not valid JSON. Delete it and re-run send_outreach." >&2
  exit 1
fi

REQUIRED_FIELDS=(domain inbox_ids test_send_message_id webhook_id linkedin_channel)
MISSING=""
for f in "${REQUIRED_FIELDS[@]}"; do
  HAS=$(jq -r --arg k "$f" 'has($k)' "$WIRED_FILE")
  [ "$HAS" = "true" ] || MISSING="$MISSING $f"
done

if [ -n "$MISSING" ]; then
  echo "data/.outreach-wired.json is missing required fields:$MISSING" >&2
  echo "Re-run /quickstart goto send_outreach to regenerate the wiring file." >&2
  exit 1
fi

# ── All pre-conditions met ────────────────────────────────────────────────────

DOMAIN=$(jq -r '.domain' "$WIRED_FILE")
INBOX_COUNT=$(jq -r '(.inbox_ids // []) | length' "$WIRED_FILE")
LI_CHANNEL=$(jq -r '.linkedin_channel' "$WIRED_FILE")
COMPLETED=$(jq -r '.completed_steps | length' "$STATE")
SKIPPED=$(jq -r '(.skipped_steps // []) | length' "$STATE")

echo "ship_test verified: path=ship domain=$DOMAIN inboxes=$INBOX_COUNT linkedin=$LI_CHANNEL completed=$COMPLETED skipped=$SKIPPED"
exit 0
