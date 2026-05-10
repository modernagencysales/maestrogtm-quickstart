You are running the Maestro Quickstart adventure. Teaching skill: install
Deepline (the data layer behind every later step) and explain the catalog.

Goal: `deepline` on PATH, authenticated, with `data/.deepline-wired.json`
written. Verifier: `verifiers/wire_deepline.sh`.

─── READ STATE ───────────────────────────────────────────────────────────────

  cat ~/.claude/skills/quickstart/state.json

If `wire_deepline` is in `completed_steps`: print "Deepline already wired.
Type `continue`." Wait, advance.

─── ALREADY INSTALLED? ───────────────────────────────────────────────────────

If `command -v deepline` succeeds AND `deepline auth status` shows an active
workspace: jump to WRITE CACHE.

If `deepline` exists but no auth: prompt the buyer to run
`deepline auth register` (browser opens) and confirm with `done`. Then re-check.

─── PRECHECK ─────────────────────────────────────────────────────────────────

Deepline needs Node 20+ and Python 3.10+ (per the installer). Quick check:

  node --version && python3 --version

If anything's too old or missing, point the buyer at https://nodejs.org and
https://www.python.org/downloads (or `brew install node@20 python@3.11` on
macOS), wait for `retry`.

─── STEP INTRO ───────────────────────────────────────────────────────────────

Print:

  ── Deepline — your enrichment layer ─────────────────────────────────────────

  Imagine all the lead-data tools you've heard of — Apollo, Hunter,
  Crustdata, ZeroBounce, LeadMagic — behind ONE login and ONE bill.
  That's Deepline.

  Instead of signing up for each, juggling three keys and three rate
  limits, you make one call and Deepline routes it to whichever provider
  has the data. For email-finding it tries the cheapest one first ($0),
  falls through to the next, stops at the first hit. You pay only for
  the provider that returned.

  Free signup credits cover the entire Quickstart for most ICPs. We
  also set a spend cap upfront — Deepline supports a server-side monthly
  credit limit (`deepline billing --set-monthly-limit`) that REJECTS
  paid calls when exceeded. Default we'll suggest: 50 credits ($5).
  Buyer can raise it any time; if they don't say otherwise, we set it
  before any paid call so the floor is "you cannot accidentally spend
  more than $5 today."

  This step (~2 min): install the CLI, verify auth, set the spend cap,
  cache state.

  Ask if you want me to explain:
    • what's a CLI? what's a "waterfall"? what's an API key?
    • when does Deepline pick Apollo vs Crustdata vs Dropleads?
    • can I plug in my OWN Apollo / Hunter / Crustdata keys (BYOK)? —
      yes, you can; ask if you have these subscriptions and I'll walk
      you through plugging them in
    • what each Deepline-bundled Claude Code skill does

  ── For the agent (not buyer-facing) ─────────────────────────────────────────

  If the buyer pushes on BYOK (e.g. "I already pay Apollo, walk me
  through plugging it in"), read
  `~/.claude/skills/quickstart/knowledge/byok-setup.md` and walk them
  through the 5-step setup. Don't hand-wave.

  Default for first_workflow: `dropleads_search_people` ($0) for
  company+contact search; email waterfall (~$0.50-$1) for emails.
  Mention these by name only if asked — beginners glaze on provider
  names without context.

  ── SET SPEND CAP (proactive, before any paid call) ──────────────────────────

  Show the buyer this command and run it WITH THEIR CONFIRMATION:

    deepline billing --set-monthly-limit 50

  Tell the buyer: "I'm setting a server-side cap of 50 credits ($5) for
  this month. Deepline will REJECT any call that would push you over.
  You can raise it later with the same command. Type a number (e.g.
  `100` for $10, `500` for $50) if you want a different cap, or
  `default` to take 50."

  After the buyer answers, run the command, then verify with
  `deepline billing limit --json` and show them the active cap. This is
  the single highest-trust move in the whole Quickstart for any
  previously-burned buyer — set it BY DEFAULT, not on request.

─── INSTALL ──────────────────────────────────────────────────────────────────

The installer is one command:

  curl -s "https://code.deepline.com/api/v2/cli/install" | bash

It puts `deepline` in `~/.deepline/bin`, adds it to PATH via your shell rc
file, runs the auth browser flow, and syncs the skills. Offer `inspect` (curl
to /tmp first, less the script) for paranoid buyers.

After install, source the buyer's shell rc so PATH picks it up:

  for rc in ~/.zshrc ~/.bashrc ~/.profile; do [ -f $rc ] && source $rc; done

Confirm:

  command -v deepline && deepline --version
  deepline auth status

If `deepline` isn't on PATH yet, ask the buyer to open a new terminal and
re-run `/quickstart continue`.

─── PROVIDERS WORTH KNOWING ──────────────────────────────────────────────────

Print this catalog teaching beat — it's the buyer's mental model of what
Deepline is:

  ── What's in the catalog ─────────────────────────────────────────────────────

  ~25 providers, all behind `deepline tools execute <id> --payload '{...}'`.
  Discover and inspect any of them:
    deepline tools                       — list all
    deepline tools search "email"        — find tools by query
    deepline tools get <id>              — inputs, outputs, cost

  Two we'd reach for first:

  AI Ark — strongest all-rounder. Company search + people search + email
  finding + phones + bulk export, with the broadest filters for ICP shaping.
  Default for TAM-style "B2B SaaS, 50-200 employees, US, raised in last 12mo".

  Discolike — niche / SMB / long-tail specialist. Apollo and ZoomInfo are weak
  on companies under 50 employees and on verticals outside their core indexes.
  Discolike covers the long tail (boutique law firms, indie agencies,
  vertical-SaaS niches).

  Other names you'll see in the catalog: Apollo, Crustdata, Hunter, LeadMagic,
  Findymail, Prospeo, Dropleads, ZeroBounce, PeopleDataLabs, TheirStack,
  RocketReach, Lusha, HeyReach, Unipile, Smartlead, Lemlist, Instantly, Slack,
  Hubspot, Salesforce, Attio, Bloomberry, Wiza.

  ── Plays (waterfalls) ───────────────────────────────────────────────────────

  Some calls are waterfalls — Deepline tries provider A, falls through to B
  if A misses, etc. You only pay for the provider that returned a valid hit.
  Examples: `name_and_domain_to_email_waterfall`,
  `person_linkedin_to_email_waterfall`,
  `company_to_contact_by_role_waterfall` (we use this one in the next step).

  Plays run via `deepline enrich --with`, NOT `deepline tools execute`.
  Template references to CSV columns use `{{column_name}}` — not `row.X`,
  not `${X}` — just plain `{{column}}`.

─── SYNC SKILLS ──────────────────────────────────────────────────────────────

Deepline ships Claude Code skills (`/deepline-gtm`, `/build-tam`,
`/portfolio-prospecting`, etc.). The installer syncs them once.

Skip the re-sync if it ran in the last 24 hours — it costs ~60s for a no-op
and the cache marker tells you whether it's needed:

  if [ -f data/.deepline-skills-synced ] && \
     [ "$(find data/.deepline-skills-synced -mtime -1 2>/dev/null)" ]; then
    echo "Skills already synced in the last 24h; skipping deepline update."
  else
    # macOS doesn't ship GNU `timeout` — use a portable wrapper.
    ( deepline update 2>&1 & PID=$!
      ( sleep 60; kill $PID 2>/dev/null ) & WATCH=$!
      wait $PID; EXIT=$?
      kill $WATCH 2>/dev/null
      exit $EXIT ) | tail -10
    mkdir -p data && touch data/.deepline-skills-synced
  fi

If the wrapper times out, the skills already-installed during the initial
install still work. Point the buyer at `deepline auth status` to confirm; the
"Skills:" line lists what's installed.

─── WRITE CACHE ──────────────────────────────────────────────────────────────

  mkdir -p data
  jq -n --arg version "$(deepline --version 2>/dev/null)" \
        --arg ts "$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
        '{status: "ok", cli_version: $version, cached_at: $ts}' \
        > data/.deepline-wired.json

─── VERIFY ───────────────────────────────────────────────────────────────────

  bash ~/.claude/skills/quickstart/verifiers/wire_deepline.sh

─── COMPLETE ─────────────────────────────────────────────────────────────────

  jq --arg now "$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
     '.completed_steps += ["wire_deepline"] | .current_step = "first_workflow" | .last_run_at = $now' \
     ~/.claude/skills/quickstart/state.json > /tmp/qs_wd.json \
     && mv /tmp/qs_wd.json ~/.claude/skills/quickstart/state.json

**Compose a narrative bridge per SKILL.md's "Narrative bridges" rule** —
what just happened (Deepline on PATH, authed, spend cap set so they
can't accidentally overspend) and what's next + why (the next step is
where the buyer SEES Deepline earn its keep — abstract setup becomes
real leads on the screen, via the free Dropleads search + waterfall
email-finder).

Then print:

  ── Deepline is wired. ──────────────────────────────────────────────────────

  CLI build:    <first 10 chars of build hash>
  Workspace:    <from `deepline auth status`>
  Spend cap:    <verified from `deepline billing limit --json`>

  Type `continue` to run your first workflow.

─── RECOVERY MENU ────────────────────────────────────────────────────────────

If `help`, print the standard 5-option menu (LMS slug: `wire-deepline`). Skip target: `first_workflow`.
