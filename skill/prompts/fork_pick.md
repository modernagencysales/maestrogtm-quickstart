You are running the Maestro Quickstart adventure. This is a prescriptive, step-based skill.
You do NOT improvise. You follow the script below exactly.

─── READ STATE ───────────────────────────────────────────────────────────────────────────────────

Run:

  STATE=$(cat ~/.claude/skills/quickstart/state.json)
  COMPLETED=$(echo "$STATE" | jq -r '[.completed_steps[]] | join(", ")')
  PATH_CHOICE=$(echo "$STATE" | jq -r '.path // empty')

Check if `fork_pick` is already in `completed_steps` AND `.path` is set to "review" or "ship".
If yes:
  Print: "Path already chosen: $PATH_CHOICE. Type `continue` to resume from your next step."
  Wait for `continue`. On `continue`, advance to the correct next step per path:
    ship   → send_outreach
    review → __finale__
  Do not re-run this step.

─── PRE-FLIGHT: DEPENDENCY CHECK ────────────────────────────────────────────────────────────────

Confirm `ai_personalize` is in `completed_steps`.
If it is NOT:
  Print:
    "── Warning ────────────────────────────────────────────────────────────────
    ai_personalize has not completed yet. That step generates the first_line
    personalization for each contact — the whole point of this build.

    Type `goto ai_personalize` to run it now, or type `continue` to fork
    anyway (your contacts will be in Supabase but without personalization).
    ────────────────────────────────────────────────────────────────────────────"

  Wait for `continue` or `goto ai_personalize`.
  If `goto ai_personalize`:
    jq --arg now "$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
       '.current_step = "ai_personalize" | .last_run_at = $now' \
       ~/.claude/skills/quickstart/state.json > /tmp/qs_fork_goto.json \
       && mv /tmp/qs_fork_goto.json ~/.claude/skills/quickstart/state.json
    Print: "Jumping to ai_personalize. Run /quickstart continue to pick up there."
    STOP.

─── CONTACT COUNT ────────────────────────────────────────────────────────────────────────────────

Pull the contact count from Supabase for the summary line:

  source secrets/.env 2>/dev/null || source .env 2>/dev/null || true

  CONTACT_COUNT=$(curl -s \
    -H "apikey: $SUPABASE_ANON_KEY" \
    -H "Authorization: Bearer $SUPABASE_ANON_KEY" \
    -H "Prefer: count=exact" \
    "${SUPABASE_URL}/rest/v1/contacts?select=count" \
    2>/dev/null | jq '.[0].count // 0' 2>/dev/null || echo "0")

  PERSONALIZED_COUNT=$(curl -s \
    -H "apikey: $SUPABASE_ANON_KEY" \
    -H "Authorization: Bearer $SUPABASE_ANON_KEY" \
    -H "Prefer: count=exact" \
    "${SUPABASE_URL}/rest/v1/contacts?select=count&first_line=not.is.null" \
    2>/dev/null | jq '.[0].count // 0' 2>/dev/null || echo "0")

If the curl fails or returns 0 for both, use "?" as the display value.

─── SHOW THE DATA THE BUYER JUST BUILT ──────────────────────────────────────

Before the fork prompt, take a victory lap. The buyer just enriched and
personalized real contacts and they haven't actually seen them yet — go
fetch a few rows and show them.

  source secrets/.env 2>/dev/null || source .env 2>/dev/null || true

  SAMPLE=$(curl -s \
    -H "apikey: $SUPABASE_ANON_KEY" \
    -H "Authorization: Bearer $SUPABASE_ANON_KEY" \
    "${SUPABASE_URL}/rest/v1/contacts?select=first_name,last_name,title,first_line,companies(name)&first_line=not.is.null&limit=3" \
    --max-time 10 2>/dev/null || echo "[]")

Print up to 3 sample rows in a tight format. Each row gets 2 lines:

  • <first> <last>, <title> at <company>
    "<first_line>"

Then print the dashboard URL so they can browse the rest themselves:

  Browse all your contacts:
    https://supabase.com/dashboard/project/<PROJECT_REF>/editor

(Derive PROJECT_REF from SUPABASE_URL — the slug between `https://` and
`.supabase.co`.)

This is the "I built this" moment that justifies the $47. Don't skip it.

─── FORK PROMPT ──────────────────────────────────────────────────────────────────────────────────

Print:

  ── What do you want to do next? ─────────────────────────────────────────────

  You've built the data layer.
  Contacts enriched:     $CONTACT_COUNT
  Personalized (first_line): $PERSONALIZED_COUNT

  Now choose your path:

    1  Ship it — provision mailboxes via AgentMail, send a test email, wire
       the reply webhook, and optionally send a LinkedIn connection request
       via HeyReach. Email is mandatory; LinkedIn is detected automatically.
       Your stack goes live today. (~12-15 min)

    2  Review only — stop here. Your data is built and saved. Come back for the
       sending layer when you're ready.

  Type 1 or 2:

Wait for `1`, `2`, `help`, or `quit`.
For any other input — a question, a partial answer, "let me think" —
treat it conversationally per SKILL.md's "Input Handling" section. Answer
questions in 2-4 paragraphs grounded in GTM-engineer language, then re-print
the menu/prompt above. The buyer is here to learn — let them wander.
─── PATH A: SHIP ─────────────────────────────────────────────────────────────────────────────────

If user types `1`:

  Write path = "ship" to state.json and advance to send_outreach:

    jq --arg now "$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
       '.path = "ship"
       | if (.completed_steps | contains(["fork_pick"])) then . else .completed_steps += ["fork_pick"] end
       | .current_step = "send_outreach"
       | .last_run_at = $now' \
       ~/.claude/skills/quickstart/state.json > /tmp/qs_fork_ship.json \
       && mv /tmp/qs_fork_ship.json ~/.claude/skills/quickstart/state.json

  Print:
    "Path: Ship it. Next up — outreach channel setup.

    You'll provision sending mailboxes via AgentMail (mandatory), send a test
    email to your own inbox, wire the reply webhook, and optionally send a
    LinkedIn connection request if HeyReach is in your Deepline. The whole
    outreach layer in one step.

    Type `continue` to start."

  Wait for `continue`. For any other input — a question, a partial answer, "let me think" —
treat it conversationally per SKILL.md's "Input Handling" section. Answer
questions in 2-4 paragraphs grounded in GTM-engineer language, then re-print
the menu/prompt above. The buyer is here to learn — let them wander.
  Then load and run prompts/send_outreach.md.

─── PATH B: REVIEW ONLY ──────────────────────────────────────────────────────────────────────────

If user types `2`:

  Write path = "review" to state.json and advance to __finale__:

    jq --arg now "$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
       '.path = "review"
       | if (.completed_steps | contains(["fork_pick"])) then . else .completed_steps += ["fork_pick"] end
       | .current_step = "__finale__"
       | .last_run_at = $now' \
       ~/.claude/skills/quickstart/state.json > /tmp/qs_fork_review.json \
       && mv /tmp/qs_fork_review.json ~/.claude/skills/quickstart/state.json

  Print:
    "Path: Review only. Your data layer is complete and saved.

    When you're ready to add the sending layer, run:
      /quickstart goto send_outreach

    Loading your final report..."

  Immediately load and run prompts/finale.md.

─── RECOVERY MENU ────────────────────────────────────────────────────────────────────────────────

If user types `help` at any point, print:

  help — recovery options for step `fork_pick`:

    1  open the LMS step page
    2  reset this step (re-run the choice)
    3  skip — not available for fork_pick (it's the routing step)
    4  quit the adventure (your progress is saved)
  Type 1, 2, 3, or 4:

Handle each:
  1 → run: open https://learn.maestrogtm.com/learn/qs/fork-pick
      Print: "LMS page opened. Come back and type `continue` when ready."
      Wait for `continue`.

  2 → Remove fork_pick from completed_steps and clear path:
        jq 'del(.path)
            | .completed_steps = [.completed_steps[] | select(. != "fork_pick")]' \
           ~/.claude/skills/quickstart/state.json > /tmp/qs_fork_reset.json \
           && mv /tmp/qs_fork_reset.json ~/.claude/skills/quickstart/state.json
      Print: "Step reset. Re-running the choice."
      Re-run from FORK PROMPT.

  3 → Print: "fork_pick can't be skipped — it's how we decide whether to ship or review.
      Type 1 or 2 to pick a path, or `quit` to exit."
      Then reprint the FORK PROMPT.

  4 → jq --arg now "$(date -u +%Y-%m-%dT%H:%M:%SZ)" '.last_run_at = $now' \
           ~/.claude/skills/quickstart/state.json > /tmp/qs_fork_quit.json \
           && mv /tmp/qs_fork_quit.json ~/.claude/skills/quickstart/state.json
       Print: "Progress saved. Resume with: claude → /quickstart continue"
       STOP.
       Wait for `continue` or `quit`.

For any other input — a question, a partial answer, "let me think" —
treat it conversationally per SKILL.md's "Input Handling" section. Answer
questions in 2-4 paragraphs grounded in GTM-engineer language, then re-print
the menu/prompt above. The buyer is here to learn — let them wander.
