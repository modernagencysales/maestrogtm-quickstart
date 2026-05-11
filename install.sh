#!/usr/bin/env bash
# Maestro Quickstart — one-line bootstrap
#
# Usage:
#   curl -fsSL https://raw.githubusercontent.com/modernagencysales/maestrogtm-quickstart/main/install.sh | bash
#
# What this does:
#   1. Detects your OS (macOS / Linux / WSL)
#   2. Checks for Node.js 18+ — offers to install if missing
#   3. Checks for Claude Code — points you at the installer if missing
#   4. Runs `npx @maestrogtm/quickstart` to drop the skill onto your machine
#
# Safe to re-run. Asks before installing anything. Prints what it's doing.
#
# Debug: re-run with `bash -x` after curling to /tmp/install.sh, or set
#   MAESTRO_DEBUG=1 to enable trace output.

# Print immediately so the user sees something even if something later fails.
echo ""
echo "Maestro Quickstart — bootstrap starting..."

# Trap errors so silent failures are debuggable
trap 'rc=$?; echo "" >&2; echo "✗ Bootstrap failed at line $LINENO (exit $rc). Re-run with MAESTRO_DEBUG=1 to see what happened." >&2; exit $rc' ERR

if [ -n "${MAESTRO_DEBUG:-}" ]; then
  set -x
fi

# `set -e` only — we deliberately do NOT use `-u` (unset vars are common in
# shell helpers) or `-o pipefail` (some tput/grep pipelines return non-zero
# on no-match which would crash unrelated code paths).
set -e

# ── Colors (defang every tput call — TERM=dumb or missing terminfo would
# otherwise crash the whole script silently) ───────────────────────────────
if [ -t 1 ] && command -v tput >/dev/null 2>&1; then
  BOLD=$(tput bold 2>/dev/null || echo "")
  DIM=$(tput dim 2>/dev/null || echo "")
  GREEN=$(tput setaf 2 2>/dev/null || echo "")
  YELLOW=$(tput setaf 3 2>/dev/null || echo "")
  RED=$(tput setaf 1 2>/dev/null || echo "")
  CYAN=$(tput setaf 6 2>/dev/null || echo "")
  RESET=$(tput sgr0 2>/dev/null || echo "")
else
  BOLD=""; DIM=""; GREEN=""; YELLOW=""; RED=""; CYAN=""; RESET=""
fi

say()  { echo "${1:-}"; }
ok()   { echo "${GREEN}✓${RESET} $1"; }
warn() { echo "${YELLOW}!${RESET} $1"; }
err()  { echo "${RED}✗${RESET} $1" >&2; }
hdr()  { echo ""; echo "${BOLD}$1${RESET}"; }
ask()  {
  # ask "prompt" → returns 0 if yes, 1 if no. Default no.
  if [ -n "${MAESTRO_NONINTERACTIVE:-}" ]; then
    echo "${DIM}(non-interactive: assuming yes)${RESET}"
    return 0
  fi
  # When piped via curl|bash, stdin is the script content, so read from /dev/tty.
  # If /dev/tty isn't available (CI, automated install), default to yes.
  if [ ! -r /dev/tty ]; then
    echo "${DIM}(no controlling terminal: assuming yes)${RESET}"
    return 0
  fi
  local reply
  printf "%s [Y/n] " "$1"
  read -r reply </dev/tty || reply=""
  case "$reply" in [nN]|[nN][oO]) return 1;; *) return 0;; esac
}

# ── Detect OS ──────────────────────────────────────────────────────────────
detect_os() {
  local uname_out; uname_out="$(uname -s)"
  case "$uname_out" in
    Darwin) OS="macos" ;;
    Linux)
      if grep -qi microsoft /proc/version 2>/dev/null; then
        OS="wsl"
      else
        OS="linux"
      fi
      ;;
    MINGW*|MSYS*|CYGWIN*) OS="windows-bash" ;;
    *) OS="unknown" ;;
  esac

  # Detect Linux distro family for Node install
  if [ "$OS" = "linux" ] || [ "$OS" = "wsl" ]; then
    if command -v apt-get >/dev/null 2>&1; then
      LINUX_FAMILY="debian"
    elif command -v dnf >/dev/null 2>&1; then
      LINUX_FAMILY="fedora"
    elif command -v yum >/dev/null 2>&1; then
      LINUX_FAMILY="rhel"
    elif command -v pacman >/dev/null 2>&1; then
      LINUX_FAMILY="arch"
    else
      LINUX_FAMILY="unknown"
    fi
  fi
}

# ── Node.js check + install ────────────────────────────────────────────────
node_version_int() {
  # Echoes the major version of node (e.g. 18, 20). Empty string if not installed.
  if command -v node >/dev/null 2>&1; then
    node --version 2>/dev/null | sed -E 's/^v?([0-9]+)\..*/\1/' || true
  fi
}

# Look for Node installations that exist on disk but aren't on PATH.
# This happens constantly with nvm/fnm/volta installs that never wrote their
# shell hook into ~/.zshrc, or with Homebrew installed in a non-default location.
# Echoes the path to the newest qualifying node binary (v18+), or empty.
find_orphaned_node() {
  local candidates=()

  # nvm — most common offender
  if [ -d "$HOME/.nvm/versions/node" ]; then
    local nvm_latest
    nvm_latest=$(ls -d "$HOME"/.nvm/versions/node/v*/bin/node 2>/dev/null | sort -V | tail -1)
    [ -n "$nvm_latest" ] && candidates+=("$nvm_latest")
  fi

  # fnm
  if [ -d "$HOME/.fnm/node-versions" ]; then
    local fnm_latest
    fnm_latest=$(ls -d "$HOME"/.fnm/node-versions/v*/installation/bin/node 2>/dev/null | sort -V | tail -1)
    [ -n "$fnm_latest" ] && candidates+=("$fnm_latest")
  fi

  # volta
  [ -x "$HOME/.volta/bin/node" ] && candidates+=("$HOME/.volta/bin/node")

  # asdf
  if [ -d "$HOME/.asdf/installs/nodejs" ]; then
    local asdf_latest
    asdf_latest=$(ls -d "$HOME"/.asdf/installs/nodejs/*/bin/node 2>/dev/null | sort -V | tail -1)
    [ -n "$asdf_latest" ] && candidates+=("$asdf_latest")
  fi

  # Homebrew (Apple Silicon and Intel)
  [ -x "/opt/homebrew/bin/node" ] && candidates+=("/opt/homebrew/bin/node")
  [ -x "/usr/local/bin/node" ] && candidates+=("/usr/local/bin/node")

  # Pick the first one that's v18+
  local node_path v
  for node_path in "${candidates[@]}"; do
    v=$("$node_path" --version 2>/dev/null | sed -E 's/^v?([0-9]+)\..*/\1/')
    if [ -n "$v" ] && [ "$v" -ge 18 ] 2>/dev/null; then
      echo "$node_path"
      return 0
    fi
  done
  return 1
}

# Given a path to an orphaned node binary, figure out the right shell rc
# block to append, write it (idempotently), and source it for this session.
fix_node_path() {
  local node_path="$1"
  local rc_file
  case "${SHELL:-/bin/zsh}" in
    */zsh)  rc_file="$HOME/.zshrc" ;;
    */bash)
      # macOS uses .bash_profile for login shells; Linux uses .bashrc
      if [ "$OS" = "macos" ]; then rc_file="$HOME/.bash_profile"; else rc_file="$HOME/.bashrc"; fi
      ;;
    *) rc_file="$HOME/.profile" ;;
  esac
  touch "$rc_file"

  local marker="# Added by maestrogtm-quickstart bootstrap"

  case "$node_path" in
    *"/.nvm/versions/node/"*)
      if grep -q "NVM_DIR" "$rc_file" 2>/dev/null; then
        say "  ${DIM}nvm hook already in $(basename "$rc_file") — sourcing for this session${RESET}"
      else
        say "  ${DIM}Appending nvm hook to $(basename "$rc_file")${RESET}"
        {
          echo ""
          echo "$marker"
          echo 'export NVM_DIR="$HOME/.nvm"'
          echo '[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"'
          echo '[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"'
        } >> "$rc_file"
      fi
      export NVM_DIR="$HOME/.nvm"
      # shellcheck disable=SC1091
      [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh" 2>/dev/null || true
      ;;

    *"/.fnm/"*)
      if grep -q "fnm env" "$rc_file" 2>/dev/null; then
        say "  ${DIM}fnm hook already in $(basename "$rc_file") — sourcing for this session${RESET}"
      else
        say "  ${DIM}Appending fnm hook to $(basename "$rc_file")${RESET}"
        {
          echo ""
          echo "$marker"
          echo 'eval "$(fnm env --use-on-cd)"'
        } >> "$rc_file"
      fi
      command -v fnm >/dev/null 2>&1 && eval "$(fnm env --use-on-cd)" 2>/dev/null || true
      ;;

    *"/.volta/"*)
      if grep -q "VOLTA_HOME" "$rc_file" 2>/dev/null; then
        say "  ${DIM}volta hook already in $(basename "$rc_file") — sourcing for this session${RESET}"
      else
        say "  ${DIM}Appending volta hook to $(basename "$rc_file")${RESET}"
        {
          echo ""
          echo "$marker"
          echo 'export VOLTA_HOME="$HOME/.volta"'
          echo 'export PATH="$VOLTA_HOME/bin:$PATH"'
        } >> "$rc_file"
      fi
      export VOLTA_HOME="$HOME/.volta"
      export PATH="$VOLTA_HOME/bin:$PATH"
      ;;

    *"/.asdf/"*)
      if grep -q "asdf.sh" "$rc_file" 2>/dev/null; then
        say "  ${DIM}asdf hook already in $(basename "$rc_file") — sourcing for this session${RESET}"
      else
        say "  ${DIM}Appending asdf hook to $(basename "$rc_file")${RESET}"
        {
          echo ""
          echo "$marker"
          echo '. "$HOME/.asdf/asdf.sh"'
        } >> "$rc_file"
      fi
      # shellcheck disable=SC1091
      [ -s "$HOME/.asdf/asdf.sh" ] && \. "$HOME/.asdf/asdf.sh" 2>/dev/null || true
      ;;

    /opt/homebrew/*)
      if grep -q "/opt/homebrew/bin/brew shellenv" "$rc_file" 2>/dev/null; then
        say "  ${DIM}brew shellenv already in $(basename "$rc_file") — sourcing for this session${RESET}"
      else
        say "  ${DIM}Appending brew shellenv to $(basename "$rc_file")${RESET}"
        {
          echo ""
          echo "$marker"
          echo 'eval "$(/opt/homebrew/bin/brew shellenv)"'
        } >> "$rc_file"
      fi
      eval "$(/opt/homebrew/bin/brew shellenv)" 2>/dev/null || true
      ;;

    /usr/local/*)
      # Intel brew is usually already in /usr/local/bin which is on PATH by default,
      # but if we got here something stripped it — add it explicitly.
      if ! echo "$PATH" | tr ':' '\n' | grep -qx "/usr/local/bin"; then
        say "  ${DIM}/usr/local/bin not on PATH — fixing${RESET}"
        export PATH="/usr/local/bin:$PATH"
        if ! grep -q "/usr/local/bin" "$rc_file" 2>/dev/null; then
          {
            echo ""
            echo "$marker"
            echo 'export PATH="/usr/local/bin:$PATH"'
          } >> "$rc_file"
        fi
      fi
      ;;
  esac
}

ensure_node() {
  hdr "1. Node.js"

  # Path 1: node is already on PATH and modern enough — done.
  local ver; ver="$(node_version_int)"
  if [ -n "$ver" ] && [ "$ver" -ge 18 ] 2>/dev/null; then
    ok "Node.js v$(node --version | sed 's/^v//') already installed"
    return 0
  fi

  # Path 2: node EXISTS somewhere (nvm/fnm/volta/brew/asdf) but the shell
  # never picked it up. This is the single most common Mac failure mode.
  local orphan
  if orphan=$(find_orphaned_node); then
    say ""
    say "Found a working Node at ${CYAN}$orphan${RESET}"
    say "but your shell can't see it. Wiring it into PATH now."
    say ""
    fix_node_path "$orphan"
    # Re-check after fixing PATH for this session
    ver="$(node_version_int)"
    if [ -n "$ver" ] && [ "$ver" -ge 18 ] 2>/dev/null; then
      ok "Node.js v$(node --version | sed 's/^v//') is now usable"
      say "  ${DIM}New terminals will pick this up automatically. Existing terminals: run \`source ~/.zshrc\`.${RESET}"
      return 0
    fi
    warn "PATH fix didn't take effect in this session — falling through to install."
  fi

  # Path 3: nothing found anywhere — install fresh.
  if [ -n "$ver" ]; then
    warn "Node.js v$ver is installed but too old (need 18+)"
  else
    warn "Node.js not found"
  fi

  case "$OS" in
    macos) install_node_macos ;;
    linux|wsl) install_node_linux ;;
    windows-bash)
      err "Detected Git Bash / MSYS / Cygwin on Windows."
      say "  Install Node.js manually from ${CYAN}https://nodejs.org${RESET} (pick the LTS .msi)."
      say "  Or use winget in PowerShell: ${CYAN}winget install OpenJS.NodeJS.LTS${RESET}"
      say "  Then close this terminal, open a new one, and re-run this script."
      exit 1
      ;;
    *)
      err "Unsupported OS for auto-install. Install Node.js LTS from https://nodejs.org and re-run."
      exit 1
      ;;
  esac
}

install_node_macos() {
  say ""
  say "I can install Node.js for you via Homebrew."
  say "${DIM}(Homebrew is the standard Mac package manager. If you don't have it, this will install it too.)${RESET}"
  say ""
  if ! ask "Install Node.js via Homebrew now?"; then
    err "Skipping Node.js install. Re-run after installing Node.js manually from https://nodejs.org"
    exit 1
  fi

  if ! command -v brew >/dev/null 2>&1; then
    say ""
    say "${BOLD}Installing Homebrew first${RESET} (you'll be asked for your Mac password)..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    # Add brew to PATH for this session (Apple Silicon vs Intel)
    if [ -x /opt/homebrew/bin/brew ]; then
      eval "$(/opt/homebrew/bin/brew shellenv)"
    elif [ -x /usr/local/bin/brew ]; then
      eval "$(/usr/local/bin/brew shellenv)"
    fi
  fi

  say ""
  say "${BOLD}Installing Node.js via Homebrew${RESET}..."
  brew install node

  if ! command -v node >/dev/null 2>&1; then
    err "Node install reported success but \`node\` is not in PATH."
    say "  Try closing this terminal and opening a new one, then re-run the install."
    exit 1
  fi

  ok "Node.js v$(node --version | sed 's/^v//') installed"
}

install_node_linux() {
  case "${LINUX_FAMILY:-unknown}" in
    debian)
      say ""
      say "I can install Node.js LTS via NodeSource (requires sudo)."
      if ! ask "Install Node.js now?"; then
        err "Skipping. Install Node.js LTS from https://nodejs.org and re-run."
        exit 1
      fi
      curl -fsSL https://deb.nodesource.com/setup_lts.x | sudo -E bash -
      sudo apt-get install -y nodejs
      ;;
    fedora|rhel)
      say ""
      if ! ask "Install Node.js via dnf/yum (requires sudo)?"; then
        err "Skipping. Install Node.js LTS from https://nodejs.org and re-run."
        exit 1
      fi
      curl -fsSL https://rpm.nodesource.com/setup_lts.x | sudo bash -
      sudo dnf install -y nodejs || sudo yum install -y nodejs
      ;;
    arch)
      say ""
      if ! ask "Install Node.js via pacman (requires sudo)?"; then
        err "Skipping. Install Node.js LTS from https://nodejs.org and re-run."
        exit 1
      fi
      sudo pacman -Sy --noconfirm nodejs npm
      ;;
    *)
      err "Couldn't detect a supported Linux package manager."
      say "  Install Node.js LTS from ${CYAN}https://nodejs.org${RESET} (or your distro's package manager) and re-run."
      exit 1
      ;;
  esac

  ok "Node.js v$(node --version | sed 's/^v//') installed"
}

# ── Claude Code check ──────────────────────────────────────────────────────
ensure_claude_code() {
  hdr "2. Claude Code"
  if command -v claude >/dev/null 2>&1; then
    ok "Claude Code CLI detected (\`claude\` is in PATH)"
    return 0
  fi
  warn "Claude Code CLI not detected in PATH"
  say ""
  say "  You'll need Claude Code to run the Quickstart. Two options:"
  say "    ${BOLD}Terminal:${RESET}   install instructions at ${CYAN}https://claude.ai/code${RESET}"
  say "    ${BOLD}Desktop app:${RESET} download at ${CYAN}https://claude.ai/code${RESET} (pick 'Desktop')"
  say ""
  say "  Either works — they share the same skill system."
  say "  ${DIM}You can install Claude Code later; the skill files will still be in place when you do.${RESET}"
  say ""
  # Don't exit — continue with the skill install. They might be using the desktop app
  # already and just don't have the CLI binary, which is fine.
}

# ── Install the skill via npx ─────────────────────────────────────────────
install_skill() {
  hdr "3. Maestro Quickstart skill"
  say "Running: ${CYAN}npx -y @maestrogtm/quickstart@latest install${RESET}"
  say ""
  if [ -n "${MAESTRO_NONINTERACTIVE:-}" ]; then
    npx -y @maestrogtm/quickstart@latest install --force
  else
    npx -y @maestrogtm/quickstart@latest install
  fi
}

# ── Next steps message ────────────────────────────────────────────────────
final_message() {
  hdr "Done."
  say ""
  say "  ${BOLD}To start the adventure:${RESET}"
  say ""
  say "    ${CYAN}mkdir -p ~/maestro-quickstart && cd ~/maestro-quickstart${RESET}"
  say "    ${CYAN}claude${RESET}"
  say "    ${CYAN}/quickstart${RESET}"
  say ""
  say "  ${DIM}If \`claude\` isn't installed yet, install it from claude.ai/code first.${RESET}"
  say "  ${DIM}If you prefer the desktop app, open it instead of running \`claude\`, then type /quickstart.${RESET}"
  say ""
  say "  ${BOLD}Docs + video walkthroughs:${RESET} ${CYAN}https://modernagencysales.com/learn${RESET}"
  say ""
}

# ── Main ──────────────────────────────────────────────────────────────────
main() {
  echo ""
  echo "${BOLD}Maestro Quickstart — bootstrap${RESET}"
  echo "${DIM}https://modernagencysales.com/learn${RESET}"

  detect_os
  case "$OS" in
    macos)        say "${DIM}Detected: macOS${RESET}" ;;
    linux)        say "${DIM}Detected: Linux (${LINUX_FAMILY:-unknown})${RESET}" ;;
    wsl)          say "${DIM}Detected: Windows WSL (${LINUX_FAMILY:-unknown})${RESET}" ;;
    windows-bash) say "${DIM}Detected: Windows (Git Bash / MSYS)${RESET}" ;;
    *)            warn "Unknown OS — best-effort install" ;;
  esac

  ensure_node
  ensure_claude_code
  install_skill
  final_message
}

main "$@"
