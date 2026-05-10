You are running the Maestro Quickstart adventure. Teaching skill: drive the
real migration on the buyer's machine, narrate what's happening.

Goal: end with the 28 GTM-starter tables in the buyer's Supabase project.
Verifier: `verifiers/schema_migrate.sh` (counts public-schema tables, checks
for the canonical names: contacts, companies, signals, replies, sequences,
posts, lead_magnets, funnel_leads, journal, brain_chunks, plus 18 more).
Schema source: `~/.claude/skills/quickstart/templates/gtm-starter-schema.sql`

─── READ STATE ───────────────────────────────────────────────────────────────

  cat ~/.claude/skills/quickstart/state.json

If `schema_migrate` is in `completed_steps`: print "Schema already migrated.
Type `continue`." Wait. On `continue`, advance.

If `supabase_setup` is NOT in `completed_steps` and not in `skipped_steps`:
print "Schema migration needs a live Supabase project — run
`/quickstart goto supabase_setup` first" and wait.

─── PRE-FLIGHT: ALREADY APPLIED? ─────────────────────────────────────────────

Run the verifier first. If it exits 0, the 28 tables are already there.
**Don't just say "already done" and skip** — that's a missed teaching
moment. Print the table names in groups so the buyer sees what they have:

  ── 28 tables already in your project ────────────────────────────────────────

  Core (we'll use today):
    contacts, companies

  Outreach (Modules 3-4 in the Bootcamp):
    sequences, send_attempts, suppression_list, agentmail_inboxes,
    agentmail_webhook_events

  Replies (covered when the agent classifies inbound):
    replies, reply_classifications, reply_drafts

  Inbound + content:
    lead_magnets, funnel_leads, posts, content_calendar, post_engagements

  Signals + AI brain:
    signals, brain_chunks, journal, enrichment_cache

  LinkedIn channel:
    linkedin_campaigns, linkedin_connections, followup_linkedin_queue,
    followup_email_queue, followup_log

  Campaigns:
    outreach_campaigns, outreach_campaign_leads,
    outreach_cross_channel_state, meetings

  Each one is documented in the schema SQL — open
  `~/.claude/skills/quickstart/templates/gtm-starter-schema.sql` to read
  the column definitions. Ready to move on?

Then advance.

  bash ~/.claude/skills/quickstart/verifiers/schema_migrate.sh

─── LOAD CREDS ───────────────────────────────────────────────────────────────

Source SUPABASE_URL and SUPABASE_SERVICE_ROLE_KEY from any of:
`secrets/.env`, `.env`, `.env.local`, `~/.env`, `~/.env.maestro-quickstart`.
(supabase_setup writes to `secrets/.env`.) Also derive PROJECT_REF from the
URL (the 20-char slug between `https://` and `.supabase.co`).

If service_role key is missing, the buyer can either re-run supabase_setup or
paste it manually from
`https://supabase.com/dashboard/project/<PROJECT_REF>/settings/api`.

─── STEP INTRO ───────────────────────────────────────────────────────────────

Print:

  ── Schema Migration — give your database its shape ──────────────────────────

  We're about to apply 28 tables to your Supabase project. The two we'll
  actively use today: `contacts` (the people) and `companies` (where they
  work). The other 26 (sequences, replies, send_attempts, lead_magnets,
  signals, etc.) sit unused until you grow into them — free, applied once.

  The SQL file is at:
    ~/.claude/skills/quickstart/templates/gtm-starter-schema.sql

  We POST it to Supabase's Management API in one call (~1 second). It's
  idempotent — safe to re-run.

  Ask any of these — beginner questions welcome:
    • what's a "schema"? what's a "migration"? what's "idempotent"?
    • why does the SHAPE of data matter — can't I just put it in a Sheet?
    • what does each of the 28 tables actually store?
    • what's git? why do we commit migrations to it?

  Otherwise: ready when you are.

Wait for `continue`.

─── APPLY THE SCHEMA ─────────────────────────────────────────────────────────

You have two reliable paths. Pick one based on the buyer's tools.

**Path A — Supabase Management API (preferred, no extra tools).**
POST the SQL to `https://api.supabase.com/v1/projects/<PROJECT_REF>/database/query`
with `Authorization: Bearer <token>`. The token is either:
  - the buyer's SUPABASE_ACCESS_TOKEN env var, or
  - extracted from the macOS keychain:
    `security find-generic-password -s "Supabase CLI" -w | sed 's/go-keyring-base64://' | base64 -D`
  - or asked from the buyer (they get it from
    https://supabase.com/dashboard/account/tokens).

Send `{"query": "<entire SQL file content>"}`. Multi-statement is fine.

**Path B — psql piped from the schema file** (if the buyer has psql).
The DB URL is at the dashboard → Settings → Database. Pipe with:
  psql "$DB_URL" < ~/.claude/skills/quickstart/templates/gtm-starter-schema.sql

**Path C — paste-and-run via the SQL Editor** (last resort).
Open https://supabase.com/dashboard/project/<PROJECT_REF>/sql/new in the
browser, paste the schema file, click Run. Slower; use only if A and B fail.

Whichever path, the schema is idempotent (`CREATE TABLE IF NOT EXISTS`,
`CREATE UNIQUE INDEX IF NOT EXISTS`) — re-running is safe.

─── VERIFY ───────────────────────────────────────────────────────────────────

Run the verifier:

  bash ~/.claude/skills/quickstart/verifiers/schema_migrate.sh

If exit 0: continue to COMPLETE.

If exit 1: stderr names which tables are missing. Most common cause: ran the
SQL against the wrong project (different SUPABASE_URL than the one in
secrets/.env). Confirm the URL in secrets/.env matches the project you ran the
SQL against.

─── COMPLETE ─────────────────────────────────────────────────────────────────

Update state:

  jq --arg now "$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
     '.completed_steps += ["schema_migrate"] | .current_step = "wire_deepline" | .last_run_at = $now' \
     ~/.claude/skills/quickstart/state.json > /tmp/qs_schema.json \
     && mv /tmp/qs_schema.json ~/.claude/skills/quickstart/state.json

**Compose a narrative bridge per SKILL.md's "Narrative bridges" rule** —
what just happened (28 tables created in ~1 sec, schema is reproducible
+ idempotent) and what's next + why (wire Deepline because the database
needs DATA, and Deepline is the agentic alternative to clicking around
in Clay).

Then print:

  ── 28 tables confirmed. ────────────────────────────────────────────────────

  Tables verified: 28/28
  Browse at:       https://supabase.com/dashboard/project/<PROJECT_REF>/editor

  Type `continue` to wire Deepline.

─── RECOVERY MENU ────────────────────────────────────────────────────────────

If user types `help`, print the standard 5-option menu (LMS slug:
`schema-migrate`). Skip target:
`wire_deepline`.
