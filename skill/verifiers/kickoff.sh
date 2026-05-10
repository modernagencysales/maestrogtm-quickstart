#!/usr/bin/env bash
# verifiers/kickoff.sh
# Verifies the kickoff step completed successfully (single-path flow).
#
# Checks:
#   1. state.json exists at the canonical path
#   2. version field is present
#   3. branch_answers.icp_seed key exists (value may be empty — kickoff allows skipping)
#   4. kickoff has been marked complete OR current_step has advanced past kickoff
#
# Exit 0 = pass. Exit 1 = fail (reason on stderr).

set -e

STATE="$HOME/.claude/skills/quickstart/state.json"

# ── Check 1: file exists ──────────────────────────────────────────────────────

if [ ! -f "$STATE" ]; then
  echo "state.json not found at $STATE" >&2
  exit 1
fi

# ── Check 2: valid JSON + version ─────────────────────────────────────────────

if ! jq empty "$STATE" 2>/dev/null; then
  echo "state.json is not valid JSON — run /quickstart reset to reinitialize" >&2
  exit 1
fi

VERSION=$(jq -r '.version // empty' "$STATE")
if [ -z "$VERSION" ]; then
  echo "state.json missing 'version' field" >&2
  exit 1
fi

# ── Check 3: branch_answers.icp_seed key exists (value may be empty) ─────────

# Use `// {}` to handle the case where branch_answers is null/missing
# (otherwise jq throws "null cannot be checked for keys" and set -e exits)
HAS_ICP_KEY=$(jq -r '(.branch_answers // {}) | has("icp_seed")' "$STATE" 2>/dev/null)
if [ "$HAS_ICP_KEY" != "true" ]; then
  echo "branch_answers.icp_seed key not set — kickoff did not complete" >&2
  echo "Run /quickstart goto kickoff to re-run the welcome." >&2
  exit 1
fi

# ── Check 4: kickoff complete OR current_step advanced ───────────────────────

KICKOFF_DONE=$(jq -r '[.completed_steps[] | select(. == "kickoff")] | length' "$STATE")
CURRENT_STEP=$(jq -r '.current_step // empty' "$STATE")

if [ "$KICKOFF_DONE" -eq 0 ] && [ "$CURRENT_STEP" = "kickoff" ]; then
  echo "kickoff is not in completed_steps and current_step is still 'kickoff'" >&2
  echo "Type 'continue' in the kickoff prompt to advance." >&2
  exit 1
fi

# ── All checks passed ─────────────────────────────────────────────────────────

ICP_SEED=$(jq -r '.branch_answers.icp_seed // ""' "$STATE")
ICP_DISPLAY="${ICP_SEED:-(empty — set later in first_workflow)}"
echo "kickoff verified: icp_seed=\"$ICP_DISPLAY\" current_step=$CURRENT_STEP"
exit 0
