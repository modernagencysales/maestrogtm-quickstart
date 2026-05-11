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

set -euo pipefail

# ── Colors ─────────────────────────────────────────────────────────────────
if [ -t 1 ] && command -v tput >/dev/null 2>&1; then
  BOLD=$(tput bold); DIM=$(tput dim); GREEN=$(tput setaf 2); YELLOW=$(tput setaf 3); RED=$(tput setaf 1); CYAN=$(tput setaf 6); RESET=$(tput sgr0)
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
    echo "${DIM}(non-interactive: assuming no)${RESET}"
    return 1
  fi
  local reply
  printf "%s [y/N] " "$1"
  read -r reply </dev/tty || return 1
  case "$reply" in [yY]|[yY][eE][sS]) return 0;; *) return 1;; esac
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

ensure_node() {
  hdr "1. Node.js"
  local ver; ver="$(node_version_int)"
  if [ -n "$ver" ] && [ "$ver" -ge 18 ] 2>/dev/null; then
    ok "Node.js v$(node --version | sed 's/^v//') already installed"
    return 0
  fi

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
