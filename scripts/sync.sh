#!/usr/bin/env bash
# scripts/sync.sh
# Mirror the live skill at ~/.claude/skills/quickstart/ into this package's
# skill/ directory. Run this before every `npm publish` so the package ships
# the latest version of the orchestrator + prompts + knowledge files.
#
# Usage:
#   ./scripts/sync.sh           # sync from default location
#   ./scripts/sync.sh /custom   # sync from a custom source

set -euo pipefail

SRC="${1:-$HOME/.claude/skills/quickstart}"
DST="$(cd "$(dirname "$0")/.." && pwd)/skill"

if [ ! -d "$SRC" ]; then
  echo "FAIL: source directory $SRC does not exist." >&2
  exit 1
fi

# Files / directories we ship in the package
ITEMS=(
  SKILL.md
  prompts
  verifiers
  knowledge
  lib
  templates
  state.example.json
)

# Files we explicitly do NOT ship (stateful or buyer-specific)
EXCLUDES=(
  state.json
  data
  secrets
  '*.backup.*'
)

echo "Syncing $SRC → $DST"
echo ""

# Ensure destination exists and is empty (clean slate so deletions propagate)
rm -rf "$DST"
mkdir -p "$DST"

for item in "${ITEMS[@]}"; do
  if [ -e "$SRC/$item" ]; then
    cp -R "$SRC/$item" "$DST/"
    echo "  ✓ $item"
  else
    echo "  ⚠ missing (skipped): $item"
  fi
done

# Strip out anything that snuck in from the excludes list
for pattern in "${EXCLUDES[@]}"; do
  find "$DST" -name "$pattern" -exec rm -rf {} + 2>/dev/null || true
done

# Make sure shell scripts keep executable bits
find "$DST" -type f -name "*.sh" -exec chmod +x {} \;

echo ""
echo "Synced. Diff vs last release:"
if command -v git >/dev/null 2>&1 && git -C "$(dirname "$DST")" rev-parse --git-dir >/dev/null 2>&1; then
  git -C "$(dirname "$DST")" --no-pager diff --stat skill/ || true
else
  echo "(not a git repo — skipping diff)"
fi
