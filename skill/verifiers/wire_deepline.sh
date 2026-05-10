#!/usr/bin/env bash
# verifiers/wire_deepline.sh
# Verifies that the Deepline CLI is installed and authenticated.
#
# In the new flow we install Deepline via its official installer:
#   curl -s "https://code.deepline.com/api/v2/cli/install" | bash
# The installer handles auth automatically and adds `deepline` to PATH.
#
# Checks:
#   1. `deepline` binary is on PATH
#   2. `deepline --version` returns a version string (proves binary works)
#   3. data/.deepline-wired.json exists with status=ok
#
# Exit 0 = pass. Exit 1 = fail (reason on stderr).

set -euo pipefail

_fail() {
  echo "$1" >&2
  exit 1
}

# ── Check 1: deepline binary is available ────────────────────────────────────

if ! command -v deepline >/dev/null 2>&1; then
  _fail "The 'deepline' binary is not on your PATH.
Install it with:
  curl -s \"https://code.deepline.com/api/v2/cli/install\" | bash
Then re-run /quickstart goto wire_deepline."
fi

# ── Check 2: deepline --version returns something ────────────────────────────

DEEPLINE_VERSION=$(deepline --version 2>/dev/null || echo "")

if [ -z "$DEEPLINE_VERSION" ]; then
  _fail "'deepline --version' returned no output. The CLI may be broken.
Re-install with:
  curl -s \"https://code.deepline.com/api/v2/cli/install\" | bash"
fi

# ── Check 3: cached wired file exists with status=ok ─────────────────────────

if [ ! -f "data/.deepline-wired.json" ]; then
  _fail "data/.deepline-wired.json not found — the wire_deepline step hasn't completed.
Run /quickstart goto wire_deepline to complete the step."
fi

if ! jq empty data/.deepline-wired.json 2>/dev/null; then
  _fail "data/.deepline-wired.json is not valid JSON. Delete it and re-run wire_deepline."
fi

CACHED_STATUS=$(jq -r '.status // "missing"' data/.deepline-wired.json 2>/dev/null || echo "parse_error")

if [ "$CACHED_STATUS" != "ok" ]; then
  _fail "data/.deepline-wired.json exists but status is \"$CACHED_STATUS\" (expected \"ok\").
Re-run: /quickstart goto wire_deepline"
fi

# ── All checks passed ─────────────────────────────────────────────────────────

CACHED_VERSION=$(jq -r '.cli_version // "unknown"' data/.deepline-wired.json 2>/dev/null || echo "unknown")
echo "wire_deepline verified: deepline=${DEEPLINE_VERSION} cached_version=${CACHED_VERSION} status=ok"
exit 0
