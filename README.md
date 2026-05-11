# @maestrogtm/quickstart

An AI coach that walks you through building a real cold-email machine on your computer — Supabase database, Deepline data layer, AgentMail sending, a campaign drafted around your offer.

## Install (the easy way)

One command — installs Node.js if missing (with your permission), drops the skill into `~/.claude/skills/quickstart/`, and points you at Claude Code.

**macOS / Linux / WSL:**
```bash
curl -fsSL https://raw.githubusercontent.com/modernagencysales/maestrogtm-quickstart/main/install.sh | bash
```

**Windows (PowerShell):**
```powershell
iwr -useb https://raw.githubusercontent.com/modernagencysales/maestrogtm-quickstart/main/install.ps1 | iex
```

The script:
1. Detects your OS
2. Checks for Node.js 18+. If missing, offers to install via Homebrew (Mac) / NodeSource (Linux) / winget (Windows)
3. Checks for Claude Code. If missing, points you at [claude.ai/code](https://claude.ai/code)
4. Drops the skill into `~/.claude/skills/quickstart/`

Then:
```bash
mkdir -p ~/maestro-quickstart && cd ~/maestro-quickstart
claude
/quickstart
```

## Install (manual, if you already have Node)

```bash
npx @maestrogtm/quickstart install
```

## Requirements

- **macOS, Linux, or Windows**
- **Node.js 18+** (the bootstrap installs this for you if needed)
- **Claude Code** (terminal CLI or desktop app — [claude.ai/code](https://claude.ai/code))

## What you get

The agent runs you through 11 steps:

1. **Kickoff** — captures your ICP, writes `data/icp.md` so the coach can reference it later
2. **Supabase setup** — creates your own Postgres database (free tier)
3. **Schema migrate** — applies the 28-table GTM data model
4. **Wire Deepline** — one key for 1,000+ data tools (Apollo, Hunter, Crustdata, Apify, Firecrawl, etc.)
5. **First workflow** — enriches a real list of contacts into Supabase
6. **Apply formula** — demonstrates the SELECT→transform→UPDATE loop
7. **Build campaign** — offer, angle, 4-email sequence drafted with the Growth Engine X playbook
8. **Fork pick** — review or ship
9. **Send outreach** — AgentMail wired end-to-end (free tier covers it)
10. **Test send** — end-to-end loop confirmed
11. **Finale** — recap and what's next

## Requirements

- macOS or Linux (Windows via WSL works but untested)
- [Claude Code](https://claude.ai/code) installed
- Node.js 16+

## Commands

```bash
npx @maestrogtm/quickstart           # install (default)
npx @maestrogtm/quickstart upgrade   # update to latest version
npx @maestrogtm/quickstart uninstall # remove the skill
npx @maestrogtm/quickstart help      # all options
```

## License

Bundled with paid access to the Maestro GTM Quickstart and Bootcamp programs at [modernagencysales.com/learn](https://modernagencysales.com/learn). The CLI installer itself is open; the structured walkthrough, per-step videos, cohort, and coaching live on the LMS.
