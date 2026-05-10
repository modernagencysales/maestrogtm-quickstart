You are running the Maestro Quickstart adventure. This is a prescriptive, step-based skill.
You do NOT improvise. You follow the script below exactly.

─── READ STATE ───────────────────────────────────────────────────────────────────────────────────

Run:

  STATE=$(cat ~/.claude/skills/quickstart/state.json)
  PATH_VALUE=$(echo "$STATE" | jq -r '.path // empty')
  COMPLETED=$(echo "$STATE" | jq -r '[.completed_steps[]] | join(", ")')

Check if `ship_test` is already in `completed_steps`.
If yes: print "Ship test already passed. Type `continue` to move to the finale."
Wait for `continue`, then advance to __finale__. Do not re-run.

─── PRE-FLIGHT: PATH MUST BE SHIP ───────────────────────────────────────────────────────────────

Validate path:

  case "$PATH_VALUE" in
    ship)
      : # valid — proceed
      ;;
    review)
      Print: "ship_test does not apply to the review path. Type `continue` to load the finale."
      Wait for `continue`. Advance directly to __finale__ (skip ship_test).
      STOP.
      ;;
    ""|null)
      Print: "Path not yet set — fork_pick has not completed.
              Type `continue` to jump to fork_pick, or `quit` to exit."
      Wait for `continue` or `quit`.
      If `continue`: set current_step=fork_pick, STOP.
      If `quit`: STOP.
      ;;
    *)
      Print: "Path has unexpected value: $PATH_VALUE. Run /quickstart reset to start fresh."
      STOP.
      ;;
  esac

─── PRE-FLIGHT: SEND_OUTREACH MUST BE DONE ──────────────────────────────────────────────────────

Confirm `send_outreach` is in `completed_steps` or `skipped_steps`. If neither:

  Print: "send_outreach has not completed yet. ship_test verifies the outreach
  wiring it produced. Run /quickstart goto send_outreach first, or type `skip`
  to skip the end-to-end verification."

  Wait for `skip` or `continue`.
  If `skip`: write ship_test to skipped_steps, advance to __finale__.

─── STEP INTRO ───────────────────────────────────────────────────────────────────────────────────

Print:

  ── Ship Test ─────────────────────────────────────────────────────────────────

  Final end-to-end verification of the ship path. We re-run the send_outreach
  verifier against your wiring artifacts:

    • data/.outreach-wired.json
    • Supabase contacts and (if available) send_attempts table

  Takes under 30 seconds.

─── PRINT WHAT WAS BUILT ─────────────────────────────────────────────────────────────────────────

Read completed_steps from state.json. Print only the rows where the step name is in
completed_steps. Use this table:

  kickoff           →  ICP seed saved
  supabase_setup    →  Supabase live — your database is up
  schema_migrate    →  GTM starter schema applied (28 tables)
  wire_deepline     →  Deepline CLI installed and authenticated
  first_workflow    →  companies + contacts enriched and imported
  apply_formula     →  row transformations applied
  ai_personalize    →  AI first_lines generated per contact
  fork_pick         →  path = ship
  send_outreach     →  AgentMail wired (mailboxes warming, webhook live)

Print heading first, then the matching rows:

  ── What you've built ─────────────────────────────────────────────────────────

  <each matched row printed as "  ✓ <step_label>">

If no rows match (very early state):
  Print: "Most steps were skipped — the ship test will verify what it can."

─── RUN THE VERIFIER ─────────────────────────────────────────────────────────────────────────────

Run the send_outreach verifier (it covers everything ship_test cares about):

  VERIFIER=~/.claude/skills/quickstart/verifiers/send_outreach.sh

  if [ ! -f "$VERIFIER" ]; then
    echo "VERIFIER_MISSING"
  else
    bash "$VERIFIER" 2>/tmp/qs_ship_test_err.txt
    VERIFY_EXIT=$?
  fi

If VERIFIER_MISSING:
  Print: "send_outreach verifier missing on disk. Re-install the skill:
          rm -rf ~/.claude/skills/quickstart && /quickstart"
  STOP.

If VERIFY_EXIT is 0:
  Read the verifier's stdout for the summary line.
  Print:

    ✅ Ship test passed.

    The verifier confirmed:
      • AgentMail key is set
      • data/.outreach-wired.json has all required fields (domain, inboxes, test send
        message id, webhook id, linkedin channel)
      • ai_personalize is in completed_steps

    Your stack is wired end-to-end. Mailboxes are still warming (14-21 days from
    provisioning), so don't cold-send today — but the moment warmup completes,
    you can hit go.

  Advance to COMPLETE.

If VERIFY_EXIT is non-zero:
  Read the error output from /tmp/qs_ship_test_err.txt.
  Print:

    ✗ Ship test failed.

    Error from send_outreach verifier:
    <error output verbatim, indented 2 spaces>

  Advance to RECOVERY MENU.

─── COMPLETE ─────────────────────────────────────────────────────────────────────────────────────

Write completion to state.json:

  jq --arg now "$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
     '.completed_steps += ["ship_test"] | .last_run_at = $now' \
     ~/.claude/skills/quickstart/state.json > /tmp/qs_ship_test.json \
     && mv /tmp/qs_ship_test.json ~/.claude/skills/quickstart/state.json

  jq '.current_step = "__finale__"' \
     ~/.claude/skills/quickstart/state.json > /tmp/qs_ship_test_next.json \
     && mv /tmp/qs_ship_test_next.json ~/.claude/skills/quickstart/state.json

Print:

  Type `continue` for the finale.

For any other input — a question, a partial answer, "let me think" —
treat it conversationally per SKILL.md's "Input Handling" section. Answer
questions in 2-4 paragraphs grounded in GTM-engineer language, then re-print
the menu/prompt above. The buyer is here to learn — let them wander.
─── RECOVERY MENU ────────────────────────────────────────────────────────────────────────────────

If the verifier failed OR the user types `help`, print:

  help — recovery options for step `ship_test`:

    1  open the LMS step page (full SOP, transcript, troubleshooting)
    2  re-run the verification (retry send_outreach.sh)
    3  skip this step (mark incomplete and go to the finale anyway)
    4  quit the adventure (your progress is saved)
  Type 1, 2, 3, or 4:

Handle each:
  1 → run: open https://learn.maestrogtm.com/learn/qs/ship-test
      Print: "LMS page opened. Come back and type `continue` when ready."
      Wait for `continue`.
  2 → re-run the RUN THE VERIFIER section
  3 → jq '.skipped_steps += ["ship_test"] | .current_step = "__finale__"' and advance with warning:
        "Skipped ship test. The finale will still run — but your stack hasn't been
        end-to-end verified. Run `/quickstart goto ship_test` to come back."
  4 → print "Progress saved. Run `/quickstart continue` to pick up here." and STOP
