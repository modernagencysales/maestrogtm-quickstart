#!/usr/bin/env bash
# verifiers/fork_pick.sh
#
# Defensive-only verifier. The orchestrator's Phase 5 advances state.path
# through the fork_pick prompt itself, so by the time anything calls this
# verifier, .path is already set. Kept on disk because SKILL.md's state
# machine references it, and to surface a clear error if state.path was
# ever cleared by hand.
#
# Verifies that the user has chosen a path (ship or review) at the fork.
#
# Checks:
#   1. state.json exists and is valid JSON
#   2. .path is set to "ship" or "review"
#   3. fork_pick is in completed_steps
#
# Exit 0 = pass. Exit 1 = fail (reason on stderr).

set -e

STATE="$HOME/.claude/skills/quickstart/state.json"

# ── Check 1: file exists and is valid JSON ────────────────────────────────────

if [ ! -f "$STATE" ]; then
  echo "state.json not found at $STATE" >&2
  exit 1
fi

if ! jq empty "$STATE" 2>/dev/null; then
  echo "state.json is not valid JSON — run /quickstart reset to start fresh." >&2
  exit 1
fi

# ── Check 2: path is set to a valid value ────────────────────────────────────

PATH_VALUE=$(jq -r '.path // empty' "$STATE")

case "$PATH_VALUE" in
  ship|review)
    : # valid
    ;;
  ""|null)
    echo "fork_pick has not completed — .path is null." >&2
    echo "Run /quickstart goto fork_pick to choose ship or review." >&2
    exit 1
    ;;
  *)
    echo "Path has invalid value: '$PATH_VALUE' (expected 'ship' or 'review')." >&2
    echo "Run /quickstart goto fork_pick to re-pick, or /quickstart reset to start fresh." >&2
    exit 1
    ;;
esac

# ── Check 3: fork_pick is in completed_steps ─────────────────────────────────

DONE=$(jq -r '[.completed_steps[] | select(. == "fork_pick")] | length' "$STATE")

if [ "$DONE" -eq 0 ]; then
  echo "fork_pick is not in completed_steps yet — but .path is set to '$PATH_VALUE'." >&2
  echo "This is an inconsistent state. Run /quickstart goto fork_pick to re-confirm." >&2
  exit 1
fi

# ── All checks passed ─────────────────────────────────────────────────────────

echo "fork_pick verified: path=$PATH_VALUE"
exit 0
