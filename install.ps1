# Maestro Quickstart — one-line bootstrap (Windows / PowerShell)
#
# Usage (run in PowerShell):
#   iwr -useb https://raw.githubusercontent.com/modernagencysales/maestrogtm-quickstart/main/install.ps1 | iex
#
# What this does:
#   1. Checks for Node.js 18+ — installs via winget if missing
#   2. Checks for Claude Code — points you at the installer if missing
#   3. Runs `npx @maestrogtm/quickstart` to drop the skill onto your machine
#
# Safe to re-run. Asks before installing anything.

$ErrorActionPreference = "Stop"

function Write-Hdr  { param([string]$msg) Write-Host ""; Write-Host $msg -ForegroundColor White }
function Write-Ok   { param([string]$msg) Write-Host "✓ $msg" -ForegroundColor Green }
function Write-Warn { param([string]$msg) Write-Host "! $msg" -ForegroundColor Yellow }
function Write-Err  { param([string]$msg) Write-Host "✗ $msg" -ForegroundColor Red }
function Write-Dim  { param([string]$msg) Write-Host $msg -ForegroundColor DarkGray }

function Ask {
  param([string]$prompt)
  if ($env:MAESTRO_NONINTERACTIVE) { return $false }
  $reply = Read-Host "$prompt [y/N]"
  return $reply -match '^[Yy]'
}

function Get-NodeMajor {
  try {
    $v = (node --version) 2>$null
    if ($v -match '^v(\d+)\.') { return [int]$Matches[1] }
  } catch {}
  return 0
}

function Ensure-Node {
  Write-Hdr "1. Node.js"
  $major = Get-NodeMajor
  if ($major -ge 18) {
    $v = (node --version)
    Write-Ok "Node.js $v already installed"
    return
  }
  if ($major -gt 0) {
    Write-Warn "Node.js v$major is installed but too old (need 18+)"
  } else {
    Write-Warn "Node.js not found"
  }

  Write-Host ""
  Write-Host "I can install Node.js for you via winget (built into Windows 10/11)."
  Write-Host ""

  if (-not (Ask "Install Node.js LTS now?")) {
    Write-Err "Skipping Node.js install. Re-run after installing Node.js LTS from https://nodejs.org"
    exit 1
  }

  if (-not (Get-Command winget -ErrorAction SilentlyContinue)) {
    Write-Err "winget not found. Install Node.js manually from https://nodejs.org and re-run."
    exit 1
  }

  Write-Host ""
  Write-Host "Installing Node.js LTS via winget..." -ForegroundColor White
  winget install --id OpenJS.NodeJS.LTS --accept-source-agreements --accept-package-agreements

  # winget installs to a path that needs a fresh PATH lookup
  $env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")

  if (-not (Get-Command node -ErrorAction SilentlyContinue)) {
    Write-Err "Node install completed but \`node\` is not on PATH in this session."
    Write-Host "  Close this PowerShell window, open a new one, and re-run this install script."
    exit 1
  }

  $v = (node --version)
  Write-Ok "Node.js $v installed"
}

function Ensure-ClaudeCode {
  Write-Hdr "2. Claude Code"
  if (Get-Command claude -ErrorAction SilentlyContinue) {
    Write-Ok "Claude Code CLI detected"
    return
  }
  Write-Warn "Claude Code CLI not detected in PATH"
  Write-Host ""
  Write-Host "  You'll need Claude Code to run the Quickstart. Two options:"
  Write-Host "    Terminal:    install from https://claude.ai/code" -ForegroundColor Cyan
  Write-Host "    Desktop app: download from https://claude.ai/code (pick 'Desktop')" -ForegroundColor Cyan
  Write-Host ""
  Write-Host "  Either works — they share the same skill system."
  Write-Dim "  You can install Claude Code later; the skill files will still be in place when you do."
  Write-Host ""
}

function Install-Skill {
  Write-Hdr "3. Maestro Quickstart skill"
  Write-Host "Running: " -NoNewline; Write-Host "npx -y @maestrogtm/quickstart@latest install" -ForegroundColor Cyan
  Write-Host ""

  if ($env:MAESTRO_NONINTERACTIVE) {
    npx -y "@maestrogtm/quickstart@latest" install --force
  } else {
    npx -y "@maestrogtm/quickstart@latest" install
  }

  if ($LASTEXITCODE -ne 0) {
    Write-Err "Skill install failed (exit code $LASTEXITCODE). See output above for the error."
    exit 1
  }
}

function Final-Message {
  Write-Hdr "Done."
  Write-Host ""
  Write-Host "  To start the adventure:" -ForegroundColor White
  Write-Host ""
  Write-Host "    mkdir ~/maestro-quickstart -Force; cd ~/maestro-quickstart" -ForegroundColor Cyan
  Write-Host "    claude" -ForegroundColor Cyan
  Write-Host "    /quickstart" -ForegroundColor Cyan
  Write-Host ""
  Write-Dim "  If \`claude\` isn't installed yet, install it from claude.ai/code first."
  Write-Dim "  If you prefer the desktop app, open it instead, then type /quickstart."
  Write-Host ""
  Write-Host "  Docs + video walkthroughs: https://modernagencysales.com/learn" -ForegroundColor Cyan
  Write-Host ""
}

# ── Main ──────────────────────────────────────────────────────────────────
Write-Host ""
Write-Host "Maestro Quickstart — bootstrap" -ForegroundColor White
Write-Dim "https://modernagencysales.com/learn"
Write-Dim "Detected: Windows / PowerShell"

Ensure-Node
Ensure-ClaudeCode
Install-Skill
Final-Message
