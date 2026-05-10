You are running the Maestro Quickstart adventure. This is a teaching skill: the
buyer is sitting next to you while you (the agent) drive a real Supabase setup
on their machine. Be prescriptive about the buyer-facing dialog and the file
contract. Be loose about HOW you call CLIs — use `--help` and live output, not
hardcoded parsing.

Goal of this step: end with a live Supabase project whose URL + anon key +
service_role key are written to `secrets/.env` and the verifier passes.
Verifier: `verifiers/supabase_setup.sh` (checks SUPABASE_URL + SUPABASE_ANON_KEY
present and `/auth/v1/health` returns 200 with the anon key).

─── READ STATE ───────────────────────────────────────────────────────────────

  cat ~/.claude/skills/quickstart/state.json

If `supabase_setup` is in `completed_steps`: print "Supabase is already set up.
Type `continue` for the next step." Wait. On `continue`, advance.

─── ALREADY DONE? ────────────────────────────────────────────────────────────

If `secrets/.env`, `.env`, or any of the standard env files contains both
`SUPABASE_URL` and `SUPABASE_ANON_KEY`, run the verifier directly:

  bash ~/.claude/skills/quickstart/verifiers/supabase_setup.sh

If exit 0 — jump to COMPLETE. The buyer already has working credentials.
If exit 1 — fall through to STEP INTRO. Their existing creds need to be redone.

─── STEP INTRO ───────────────────────────────────────────────────────────────

Print:

  ── Supabase — your data layer ───────────────────────────────────────────────

  Supabase is hosted Postgres with a REST API on top. We use it because
  every layer of the stack (enrichment, personalization, sending, reply
  routing) needs ONE place to read/write. It's the central nervous system.
  Free tier covers the Quickstart.

  We'll save two API keys to `secrets/.env`:
    • `anon` key — limited permissions, OK to expose
    • `service_role` key — admin/master, never commit, never put in browser

  Ask any of these — including the basic ones, no question is too dumb
  here:
    • what's a database, actually? (vs a Google Sheet?)
    • what's an API key? what's the diff between anon and service_role?
    • what's `.env`? what's `.gitignore`?
    • why Postgres specifically vs Airtable / Notion / Google Sheets?
    • why does my data need to leave Clay/Apollo and live in MY own DB?

  Otherwise: ready when you are.

Wait for `continue` or `quit`.

─── INSTALL THE CLI ──────────────────────────────────────────────────────────

Make sure `supabase` (or `npx supabase`) is on PATH. If neither, install via the
right path for the buyer's OS:

  - macOS with brew:  brew install supabase/tap/supabase
  - macOS without brew, or Linux:  use npx supabase, or install per
    https://supabase.com/docs/guides/cli/getting-started

If install requires a command, ask the buyer to confirm before running it.

**Stale-CLI region bug (verified 2026-05-10):** Supabase CLI versions before
~v2.90 ship with an empty region enum that's only populated server-side at
runtime. If you run `supabase projects create ... --region us-east-1` on an
old CLI, it rejects the value with `must be one of [  ]` (empty-bracket list)
even though `supabase projects create --help` shows that exact value as an
example. If you see that error, force an upgrade before retrying:

  brew upgrade supabase/tap/supabase

Then re-run the create command. Don't waste cycles trying alternate region
strings — the CLI's region list is empty regardless of which one you pass.

Set `CLI=supabase` (or `CLI="npx supabase"`) for the rest of the step.

─── LOG IN ───────────────────────────────────────────────────────────────────

Check whether the CLI is already authenticated by running `$CLI orgs list`.
If it returns org names, skip the login step.
If it errors with "not logged in" or similar, run `$CLI login` (opens browser),
wait for the buyer to type `done`, then re-check `$CLI orgs list`.

─── PICK OR CREATE A PROJECT ─────────────────────────────────────────────────

Ask the buyer:

  1  new       — create a fresh Supabase project (recommended for first-timers)
  2  existing  — use a project I already have

For `new`:
  - Get the org with `$CLI orgs list`. If multiple, ask the buyer which.
  - Generate a 32-char random password, save to `secrets/.supabase-db-password`
    with mode 600.
  - Make sure `secrets/` is in `.gitignore`.
  - Run `$CLI projects create gtm-quickstart --org-id <ID> --db-password
    <pwd> --region us-east-1`. Capture the 20-char project ref from output.
  - Poll `$CLI projects list` for that ref every 10s (up to ~2 min) until
    status is ACTIVE_HEALTHY or ACTIVE.
  - If creation fails because the org is at the free-tier project cap, tell
    the buyer to delete an old project at https://supabase.com/dashboard/projects
    or pick `existing` instead.

For `existing`:
  - Run `$CLI projects list` and ask the buyer to paste the 20-char ref.

Set PROJECT_REF for the next section.

─── EXTRACT KEYS AND WRITE secrets/.env ──────────────────────────────────────

Run `$CLI projects api-keys --project-ref $PROJECT_REF` and pull the values
labeled `anon` and `service_role` out of the table. (They're long JWTs starting
with `eyJ`. Use whatever parsing you like — awk, sed, jq + --json, your call.)

Write them to `secrets/.env` (preserving any other keys already there):

  SUPABASE_URL=https://<PROJECT_REF>.supabase.co
  SUPABASE_ANON_KEY=<anon JWT>
  SUPABASE_SERVICE_ROLE_KEY=<service_role JWT>

Make sure `secrets/` is in `.gitignore`. The service_role key bypasses
row-level security — keep it private.

If the CLI's output format has changed and parsing is hard, fall back to:
"Open https://supabase.com/dashboard/project/$PROJECT_REF/settings/api in your
browser. Paste Project URL, anon public, and service_role here, one per
prompt." Three prompts, then write the env file.

─── VERIFY ───────────────────────────────────────────────────────────────────

Run the verifier:

  bash ~/.claude/skills/quickstart/verifiers/supabase_setup.sh

If exit 0: continue to COMPLETE.

If exit 1, the verifier prints why on stderr. Common cases:
  - Project still booting → wait 30s, retry.
  - URL malformed → check secrets/.env has the full https://...supabase.co URL.
  - Key looks like JWT but is rejected → re-pull from the dashboard, or
    confirm you grabbed the anon row, not service_role or the new
    sb_publishable rows.

─── COMPLETE ─────────────────────────────────────────────────────────────────

Update state:

  jq --arg now "$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
     '.completed_steps += ["supabase_setup"] | .current_step = "schema_migrate" | .last_run_at = $now' \
     ~/.claude/skills/quickstart/state.json > /tmp/qs_supabase.json \
     && mv /tmp/qs_supabase.json ~/.claude/skills/quickstart/state.json

**Compose a narrative bridge per SKILL.md's "Narrative bridges" rule** —
what just happened (database in their cloud, keys in secrets/.env, from
now on this is where everything writes) and what's next + why (apply the
schema; the next step needs the tables to exist before any data can land
in them).

Then print the mechanical summary:

  ── Supabase is live ──────────────────────────────────────────────────────────

  Project URL:      <SUPABASE_URL>
  Project ref:      <PROJECT_REF>
  Connection test:  HTTP 200 ✓
  Credentials:      secrets/.env (gitignored)
  Dashboard:        https://supabase.com/dashboard/project/<PROJECT_REF>

  Type `continue` to apply the schema.

For any other input — especially questions about what just happened or
what's next — handle per SKILL.md's "Input Handling" rules. Answer in
2-4 paragraphs grounded in GTM-engineer language, then re-print the
"Supabase is live" summary so the buyer knows where they are. The buyer
just made a database — questions are expected.

─── RECOVERY MENU ────────────────────────────────────────────────────────────

If user types `help` at any point, print the standard 5-option menu:

  1  open the LMS step page
  2  reset this step (start from STEP INTRO)
  3  skip this step (downstream steps that need Supabase will fail)
  4  quit (progress is saved)
LMS slug: `supabase-setup`
