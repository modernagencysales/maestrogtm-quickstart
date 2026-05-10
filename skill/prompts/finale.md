You are running the Maestro Quickstart adventure. This is a prescriptive, step-based skill.
You do NOT improvise. You follow the script below exactly.

─── READ STATE ───────────────────────────────────────────────────────────────────────────────────

Run:

  STATE=$(cat ~/.claude/skills/quickstart/state.json)
  PATH_CHOICE=$(echo "$STATE" | jq -r '.path // "review"')
  COMPLETED=$(echo "$STATE" | jq -r '[.completed_steps[]] | join(", ")')
  SKIPPED=$(echo "$STATE" | jq -r 'if .skipped_steps then [.skipped_steps[]] | join(", ") else "" end')
  STARTED=$(echo "$STATE" | jq -r '.started_at')
  NOW=$(date -u +%Y-%m-%dT%H:%M:%SZ)

─── BUILD THE REPORT ─────────────────────────────────────────────────────────────────────────────

Print the final report. Substitute real values from state. Do not add sections not listed here.
Do not skip sections.

  ─────────────────────────────────────────────────────────────────────────────────
  Maestro Quickstart — Final Report

  Started:  <started_at formatted as "May 9, 2026 at 2:14 PM">
  Finished: <NOW formatted the same way>

  ── What you built ────────────────────────────────────────────────────────────

<Print only the rows where the step name is in completed_steps. Use this table:>

  kickoff               built: Quickstart initialized, ICP seed saved
  supabase_setup        built: Supabase live — your database is up
  schema_migrate        built: GTM starter schema applied (contacts, companies, leads tables)
  wire_deepline         built: Deepline wired — one key, all your providers
  first_workflow        built: first workflow run — companies found, contacts enriched
  apply_formula         built: row transformations configured (normalization, clean formatting)
  ai_personalize        built: AI first_lines generated per contact in your voice
  fork_pick             built: path chosen — <path_choice>
  send_outreach         built: Outreach channels wired — email (AgentMail) live, LinkedIn deferred to cohort D20
  ship_test             built: end-to-end test run confirmed

<If completed_steps contains only kickoff or is otherwise sparse, print:>
  "Most steps were skipped or incomplete — that's fine. Come back to the steps
  you care about: /quickstart goto <step_name>"

  ── What you skipped ──────────────────────────────────────────────────────────

<If skipped_steps is non-empty, print each row:>

  <step_name> → <consequence>

Consequence map:
  supabase_setup        → no database; all steps that write data will fail
  schema_migrate        → GTM schema not applied; enrichment data has nowhere to land
  wire_deepline         → Deepline not connected; enrichment and search won't work
  first_workflow        → no contacts in Supabase; downstream steps have nothing to work with
  apply_formula         → raw data not normalized; formatting issues will surface downstream
  ai_personalize        → no AI first_lines; personalization will be generic
  fork_pick             → path not recorded; state may be inconsistent
  send_outreach         → no outreach channels wired; mailboxes not provisioned, LinkedIn not configured
  ship_test             → end-to-end not verified; unknown if stack works end-to-end

<If nothing was skipped, print:> "Nothing skipped. Full build."

  ── Your files ────────────────────────────────────────────────────────────────

  state.json  → ~/.claude/skills/quickstart/state.json
  skill files → ~/.claude/skills/quickstart/

  Re-run a step:     /quickstart goto <step_name>
  Check state:       cat ~/.claude/skills/quickstart/state.json | jq .
  Status summary:    /quickstart status

  ─────────────────────────────────────────────────────────────────────────────────

─── PATH-SPECIFIC CLOSE ──────────────────────────────────────────────────────────────────────────

If PATH_CHOICE = "ship":

  Print:

    ── You shipped it ────────────────────────────────────────────────────────────

    Your full stack is live:
      • Data layer: contacts enriched and personalized in Supabase
      • Email infrastructure (AgentMail): domain provisioned, mailboxes warming (14-21 days)
      • Reply routing: webhook registered, replies route to Supabase automatically
      • LinkedIn channel: <read data/.outreach-wired.json — if linkedin_channel = "deferred": "deferred to cohort D20 (linkedin_outreach)"; if "heyreach": "wired via HeyReach ✓"; if "skipped": "skipped">

    Next: wait for warmup to complete, then run another enrichment batch when
    you're ready. Re-run this whole flow on a different ICP with:
      /quickstart goto first_workflow

If PATH_CHOICE = "review" (or null):

  Print:

    ── Your data layer is complete ───────────────────────────────────────────────

    Your contacts are enriched, personalized, and saved in Supabase.
    The sending layer (AgentMail) is ready when you are.

    To come back and wire sending:
      /quickstart goto send_outreach

─── COHORT UPSELL ────────────────────────────────────────────────────────────────────────────────

Print:

  One more thing — want to hear where this goes? y/n

Wait for `y` or `n` only. For any other input — a question, a partial answer, "let me think" — treat it conversationally per SKILL.md's "Input Handling" section. Answer questions in 2-4 paragraphs grounded in GTM-engineer language, then re-print the menu/prompt above. The buyer is here to learn — let them wander.

If `n`: skip to WHAT'S NEXT.

If `y`: print exactly this, no changes:

  ─────────────────────────────────────────────────────────────────────────────────
  Where you are vs. where the Bootcamp goes

  What you just did maps to specific Bootcamp modules — at hyperspeed:

    What you did                          Bootcamp module (deeper version)
    ──────────────────────────────────────────────────────────────────────
    Picked an ICP (4 Qs)               →  Module 0: Caroline Framework,
                                          anti-ICP, Gobbledygook Test
    Built TAM via Dropleads + waterfall →  Module 2: Sales Nav search,
                                          enrichment waterfalls, validation,
                                          activity-segment detection
    AI first lines                      →  Module 4: cold email copy that
                                          doesn't sound AI-generated

  What you DIDN'T touch yet:

    Module 1  Lead magnets + funnels — inbound to balance the outbound
    Module 3  LinkedIn outreach — HeyReach campaigns, DM matching
    Module 5  LinkedIn ads — paid layer on top of organic
    Module 6  Operating system — daily/weekly rhythm; most stacks die
              without this
    Module 7  Daily content — transcript → ideation → posts pipeline

  Browse the full playbook (free, public):
    https://dwy-playbook.vercel.app

  Three ways to go deeper, ordered by commitment:

    1. The Bootcamp cohort — $2,500 (or $2,300 with code QS200), 4
       weeks, ~50 seats per cohort. Tuesdays 10am Eastern. Money-back
       guarantee — Tim's never had one redeemed because the program
       teaches 4 channels and even partial adoption produces results.
       https://maestrogtm.com/cohort

    2. 1:1 coaching — ad-hoc sessions when you're stuck, want a second
       set of eyes on your ICP, or want to plan a campaign together.
       Lower commitment than the cohort; same depth on the questions
       you actually have. Book a call:
       https://maestrogtm.com/coaching

    3. Setup-on-your-system — we come in, configure your Supabase +
       Deepline + AgentMail + sequences end-to-end, hand it back to
       you working. One-time engagement. You run it after handover.
       Right when you'd rather not spend a weekend wiring up the
       stack yourself. Book a scoping call:
       https://maestrogtm.com/setup

  ─────────────────────────────────────────────────────────────────────────────────

─── WHAT'S NEXT ──────────────────────────────────────────────────────────────────────────────────

Print (always, regardless of cohort y/n):

  ── What's next ───────────────────────────────────────────────────────────────

<If PATH_CHOICE = "review", print:>
  • Wire the sending layer when you're ready:
      /quickstart goto send_outreach

<If skipped_steps is non-empty, print this line:>
  • Run a step you skipped:   /quickstart goto <first item in skipped_steps>

<Always print:>
  • Watch the "What's Next" video (2 min):
      open https://learn.maestrogtm.com/learn/qs/finale

  • Build a TAM list on your actual ICP — re-run the workflow on different
    parameters:
      /quickstart goto first_workflow

  • Browse the Deepline tool catalog:
      deepline tools search "company search"
      deepline tools get <tool_id>

  • Drive Deepline by chat. These skills auto-install with the CLI; sync
    them with `deepline update` first if you skipped that step. Then check
    `deepline auth status` — the "Skills" line shows what's installed:
      /deepline-gtm   /build-tam   /portfolio-prospecting

  • Push these contacts into your CRM. Deepline has Salesforce, HubSpot,
    and Attio in the catalog. Once your contacts are in Supabase, syncing
    them into your CRM is one tool call per record:
      deepline tools execute salesforce_create_contact --payload '{...}'
      deepline tools execute hubspot_create_contact --payload '{...}'
      deepline tools execute attio_create_record --payload '{...}'
    Read `~/.claude/skills/deepline-gtm/provider-playbooks/<crm>.md` for
    the schema, or ask: "show me how to push these to my CRM."

  • Tell us what worked / what didn't:
      deepline feedback "<what you'd change about the Quickstart>"
    Goes straight to the team. We read every one.

  That's the Quickstart. You've got a working stack.

─── WRAP ─────────────────────────────────────────────────────────────────────────────────────────

Mark finale complete in state.json:

  jq --arg now "$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
     '.completed_steps += ["__finale__"]
     | .finished_at = $now
     | .status = "complete"
     | .current_step = "__done__"
     | .coupon_shown = true
     | .last_run_at = $now' \
     ~/.claude/skills/quickstart/state.json > /tmp/qs_finale.json \
     && mv /tmp/qs_finale.json ~/.claude/skills/quickstart/state.json

Do not print anything after the What's Next block unless the user types something.

If user types `help`:
  Print: "The adventure is complete. To re-run any step:
  /quickstart goto <step_name>"

If user types `quit`:
  Print: "You're done — nothing more to save." and STOP.

For any other input — a question, a partial answer, "let me think" —
treat it conversationally per SKILL.md's "Input Handling" section. Answer
questions in 2-4 paragraphs grounded in GTM-engineer language, then re-print
the menu/prompt above. The buyer is here to learn — let them wander.
