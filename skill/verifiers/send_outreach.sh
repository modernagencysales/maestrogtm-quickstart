#!/usr/bin/env bash
# verifiers/send_outreach.sh
# Verifies that outreach channels are wired end-to-end for the send_outreach step.
#
# Checks (in order):
#   1. path is "ship" in state.json
#   2. ai_personalize is in completed_steps
#   3. AGENTMAIL_API_KEY is set (env or secrets/.env)
#   4. data/.outreach-wired.json exists and is valid JSON
#   5. domain field is non-empty
#   6. inbox_ids array has at least 1 entry
#   7. test_send_message_id is set (proves test send succeeded)
#   8. webhook_id is set (proves reply intake is wired)
#   9. linkedin_channel field is set (one of: heyreach / skipped / deferred)
#
# Exit 0 = all checks pass. Exit 1 = failure (reason on stderr).

set -euo pipefail

# ── Helpers ───────────────────────────────────────────────────────────────────

_fail() {
  echo "$1" >&2
  exit 1
}

_load_key_from_files() {
  local key="$1"
  local value=""
  for f in secrets/.env .env "$HOME/.env" "$HOME/.env.maestro-quickstart"; do
    if [ -f "$f" ]; then
      value=$(grep -E "^${key}=" "$f" 2>/dev/null | head -1 | cut -d'=' -f2- | tr -d '\r\n ')
      if [ -n "$value" ]; then
        echo "$value"
        return 0
      fi
    fi
  done
  return 1
}

STATE="$HOME/.claude/skills/quickstart/state.json"
WIRED_FILE="data/.outreach-wired.json"

# ── Check 1: state.json exists and path is ship ───────────────────────────────

if [ ! -f "$STATE" ]; then
  _fail "state.json not found at $STATE
Run /quickstart to initialize state."
fi

if ! jq empty "$STATE" 2>/dev/null; then
  _fail "state.json is not valid JSON. Run /quickstart reset to start fresh."
fi

PATH_VALUE=$(jq -r '.path // empty' "$STATE")

if [ "$PATH_VALUE" != "ship" ]; then
  _fail "send_outreach is only valid for path=ship, got: '${PATH_VALUE:-unset}'
If you're on the ship path, check state.json .path field."
fi

# ── Check 2: ai_personalize in completed_steps ────────────────────────────────

PERSONALIZE_DONE=$(jq -r '[.completed_steps[] | select(. == "ai_personalize")] | length' "$STATE")

if [ "$PERSONALIZE_DONE" -eq 0 ]; then
  _fail "ai_personalize is not in completed_steps — send_outreach depends on it.
Run /quickstart goto ai_personalize to complete that step first."
fi

# ── Check 3: AGENTMAIL_API_KEY is set ────────────────────────────────────────

AGENTMAIL_API_KEY="${AGENTMAIL_API_KEY:-}"

if [ -z "$AGENTMAIL_API_KEY" ]; then
  AGENTMAIL_API_KEY=$(_load_key_from_files "AGENTMAIL_API_KEY" 2>/dev/null || true)
fi

if [ -z "$AGENTMAIL_API_KEY" ]; then
  _fail "AGENTMAIL_API_KEY is not set in the environment or any .env file.
Run /quickstart goto send_outreach to add your key."
fi

if [ ${#AGENTMAIL_API_KEY} -lt 10 ]; then
  _fail "AGENTMAIL_API_KEY looks truncated (${#AGENTMAIL_API_KEY} chars — expected > 10).
Re-copy the full key from agentmail.to → Settings → API Keys."
fi

# ── Check 4: data/.outreach-wired.json exists and is valid JSON ───────────────

if [ ! -f "$WIRED_FILE" ]; then
  _fail "data/.outreach-wired.json not found.
Run /quickstart goto send_outreach to wire outreach channels end-to-end."
fi

if ! jq empty "$WIRED_FILE" 2>/dev/null; then
  _fail "data/.outreach-wired.json exists but contains invalid JSON.
Delete it and re-run: /quickstart goto send_outreach"
fi

# ── Check 5: domain field is non-empty ───────────────────────────────────────

DOMAIN=$(jq -r '.domain // empty' "$WIRED_FILE")

if [ -z "$DOMAIN" ]; then
  _fail "data/.outreach-wired.json is missing the domain field.
Delete data/.outreach-wired.json and re-run: /quickstart goto send_outreach"
fi

# ── Check 6: inbox_ids array has at least 1 entry ────────────────────────────

INBOX_COUNT=$(jq -r '(.inbox_ids // []) | length' "$WIRED_FILE")

if [ "$INBOX_COUNT" -eq 0 ]; then
  _fail "data/.outreach-wired.json has an empty inbox_ids array — no mailboxes were provisioned.
Delete data/.outreach-wired.json and re-run: /quickstart goto send_outreach"
fi

# ── Check 7: test_send_message_id is set ─────────────────────────────────────

TEST_SEND_ID=$(jq -r '.test_send_message_id // empty' "$WIRED_FILE")

if [ -z "$TEST_SEND_ID" ]; then
  _fail "data/.outreach-wired.json is missing test_send_message_id — the test send did not complete.
Re-run the step to send the test email: /quickstart goto send_outreach"
fi

# ── Check 8: webhook is wired (webhook_id set) OR explicitly pending ─────────
# `webhook_status` was added so the user-chosen `skip` branch in the prompt
# (which leaves webhook_id null and sets webhook_status="pending") can be a
# soft pass — registration is documented as a manual follow-up. Without this,
# the skip branch was a trap that always failed verification.

WEBHOOK_ID=$(jq -r '.webhook_id // empty' "$WIRED_FILE")
WEBHOOK_STATUS=$(jq -r '.webhook_status // "active"' "$WIRED_FILE")

if [ -z "$WEBHOOK_ID" ] && [ "$WEBHOOK_STATUS" != "pending" ]; then
  _fail "data/.outreach-wired.json is missing webhook_id and webhook_status is not 'pending' — reply webhook was not registered.
Re-run the step: /quickstart goto send_outreach
Or register the webhook manually at agentmail.to and add the ID to data/.outreach-wired.json."
fi

if [ -z "$WEBHOOK_ID" ] && [ "$WEBHOOK_STATUS" = "pending" ]; then
  echo "WARN: webhook is marked pending — reply intake will not work until you register it manually." >&2
fi

# ── Check 9: linkedin_channel field is set ───────────────────────────────────

LINKEDIN_CHANNEL=$(jq -r '.linkedin_channel // empty' "$WIRED_FILE")

if [ -z "$LINKEDIN_CHANNEL" ]; then
  _fail "data/.outreach-wired.json is missing linkedin_channel — Phase 2 did not complete.
Re-run the step: /quickstart goto send_outreach"
fi

case "$LINKEDIN_CHANNEL" in
  heyreach|skipped|deferred)
    # Valid values. `deferred` is the new default — Quickstart is email-only;
    # LinkedIn lives in cohort D20 (linkedin_outreach).
    ;;
  *)
    _fail "data/.outreach-wired.json has an unexpected linkedin_channel value: '$LINKEDIN_CHANNEL'
Expected one of: heyreach, skipped, deferred.
Delete data/.outreach-wired.json and re-run: /quickstart goto send_outreach"
    ;;
esac

# ── All checks passed ─────────────────────────────────────────────────────────

WIRED_AT=$(jq -r '.wired_at // "unknown"' "$WIRED_FILE")
PRIMARY_INBOX=$(jq -r '.primary_inbox_id // "unknown"' "$WIRED_FILE")
LI_REQ_ID=$(jq -r '.linkedin_connection_request_id // "n/a"' "$WIRED_FILE")

echo "send_outreach verified: domain=$DOMAIN inboxes=$INBOX_COUNT primary_inbox=$PRIMARY_INBOX message_id=$TEST_SEND_ID webhook_id=$WEBHOOK_ID linkedin_channel=$LINKEDIN_CHANNEL linkedin_request_id=$LI_REQ_ID wired_at=$WIRED_AT"
exit 0
