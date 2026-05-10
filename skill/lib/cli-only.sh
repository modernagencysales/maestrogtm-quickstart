#!/usr/bin/env bash
# lib/cli-only.sh — Maestro Quickstart shared helper
#
# Source this file in any skill prompt that contains a UI step.
# When MAESTRO_CLI_ONLY=1 is set, browser-required steps print a
# structured error and exit rather than prompting the user to open
# a URL. This lets automated runners and power users detect which
# steps need out-of-band handling before starting a skill.
#
# Usage:
#   source "$(dirname "$0")/../lib/cli-only.sh"
#   require_browser_or_fail \
#     "AgentMail account signup" \
#     "https://agentmail.to" \
#     "(no CLI alternative — account signup is foreign onboarding)"
#
# Arguments:
#   $1  description   — short human-readable name for the browser step
#   $2  url           — the URL the user would otherwise open
#   $3  cli_alt       — optional: a CLI command that replaces this step,
#                       or a note explaining why none exists
#
# Exit behaviour:
#   MAESTRO_CLI_ONLY=1  → prints structured error to stderr, exits 1
#   MAESTRO_CLI_ONLY=0  → no-op (continues normally)
#   unset               → no-op (continues normally)

require_browser_or_fail() {
  local description="${1:-browser action required}"
  local url="${2:-}"
  local cli_alt="${3:-}"

  if [ "${MAESTRO_CLI_ONLY:-0}" != "1" ]; then
    return 0
  fi

  echo "━━━ MAESTRO_CLI_ONLY=1 — browser step blocked ━━━━━━━━━━━━━━━━━━━" >&2
  echo "Step:  $description" >&2
  if [ -n "$url" ]; then
    echo "URL:   $url" >&2
  fi
  if [ -n "$cli_alt" ]; then
    echo "CLI:   $cli_alt" >&2
  else
    echo "CLI:   (no programmatic alternative for this step)" >&2
  fi
  echo "" >&2
  echo "To proceed: run without MAESTRO_CLI_ONLY=1 and complete this" >&2
  echo "step in the browser, then re-run with MAESTRO_CLI_ONLY=1." >&2
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" >&2
  exit 1
}

# Alias for skill prompts that describe their browser touches up-front
# before executing. Prints a list without exiting — useful for a
# pre-flight "here's what needs a browser" summary.
warn_browser_step() {
  local description="${1:-browser step}"
  local url="${2:-}"

  if [ "${MAESTRO_CLI_ONLY:-0}" = "1" ]; then
    echo "[BROWSER REQUIRED] $description${url:+ — $url}" >&2
  fi
}
