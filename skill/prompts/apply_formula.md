You are running the Maestro Quickstart adventure. Teaching skill: show the
buyer how a "Clay-style column formula" maps to a SQL UPDATE / row-by-row
PATCH on their data, using a small string transform demo.

Goal: write `data/.formula-applied.json` after running (or no-op'ing) a row
transformation. Verifier: `verifiers/apply_formula.sh` (checks the cache file
exists with `rows_changed` + `applied_at`; warns if Supabase still has
em-dashes after a >0 run).

The demo target: replace em-dashes (—) with hyphens (-) in `first_line` and
`notes`. The pattern generalizes — `REPLACE`, `INITCAP(TRIM(x))`,
`REGEXP_REPLACE`, etc.

─── READ STATE ───────────────────────────────────────────────────────────────

  cat ~/.claude/skills/quickstart/state.json

If `apply_formula` is in `completed_steps`: print "Done. Type `continue`."
Wait, advance.

If `ai_personalize` is not in `completed_steps`/`skipped_steps`: warn that
there may be no first_line to clean (formulas can target the `notes` column
either way; em-dashes have to come from somewhere).

─── ALREADY APPLIED? ─────────────────────────────────────────────────────────

If `data/.formula-applied.json` exists with `rows_changed > 0`: ask if they
want to skip or `redo`.

─── STEP INTRO ───────────────────────────────────────────────────────────────

Print:

  ── Apply Formula — bulk transformations ─────────────────────────────────────

  We'll demo this on the `title` column. Real-world titles are messy:
  "Co-Founder & Visionary", "VP, Marketing", "VP of Marketing & Growth",
  "Marketing Manager  " (trailing spaces). For email subject lines or
  segment filters, you want a CLEAN canonical title. We'll:

    1. SELECT contacts where title is non-null
    2. Normalize each title: trim whitespace, collapse multi-spaces, strip
       trailing "& <fluff>" patterns ("& Growth", "& Visionary", "&
       Co-Founder")
    3. PATCH the cleaned title back

  This always produces visible changes — your contacts go from messy to
  clean. Pattern: SELECT → transform in memory → PATCH back. Same as
  ai_personalize but with deterministic code instead of an AI call. Free,
  fast, predictable.

  Used in production for: title normalization (this), phone cleanup,
  URL parameter stripping, name capitalization (`MARINA BLACK` → `Marina
  Black`), domain extraction. Clay's "Formulas" tab, but yours.

  Cost: $0. Time: seconds.

  Ask if you want me to explain why title normalization matters
  specifically (it's a deliverability + segmentation thing) — otherwise,
  ready when you are.

─── FETCH TITLES ─────────────────────────────────────────────────────────────

Source `secrets/.env`. Hit:

  GET $SUPABASE_URL/rest/v1/contacts?select=id,title&title=not.is.null

Capture HTTP code with `-w "%{http_code}"`. Bail loudly on 000/401/403/non-200.

For each row, compute the normalized title in memory. The transform:
  1. trim leading/trailing whitespace
  2. collapse runs of whitespace into single spaces
  3. strip ONLY a small whitelist of known-fluff trailing suffixes:
     `& Visionary`, `& Growth`, `& Operations`, `& Strategy`,
     `& Innovation`, `& Transformation`, `& Culture`. Do NOT strip
     real role information like `& Engineering`, `& Creative
     Director`, `& Sales`, `& Product`, `& Marketing` — those are
     signal, not fluff.
  4. fix obvious typos like "Director of of Marketing" → "Director of
     Marketing" (double-of)

The whitelist is intentionally conservative. Better to leave a real
title alone than to silently strip information that matters for
personalization. If you're not sure, don't change it.

Build a list of {id, old_title, new_title} ONLY where new_title differs
from old_title. That's CHANGES_NEEDED. If 0, fine — write cache with
rows_changed=0 reason="no_changes_needed" and advance.

─── SHOW SAMPLES + CONFIRM ───────────────────────────────────────────────────

Print up to 5 before/after pairs:

  Marina Black:    "VP of Marketing & Growth"  →  "VP of Marketing"
  Todd Tauber:     "SVP Marketing"             →  "SVP Marketing"  (no change)
  Karen Burdette:  "VP of Marketing, RevOps & Growth" → "VP of Marketing, RevOps"
  ...

Ask:

  Apply this to <CHANGES_NEEDED> rows? y/n

On `n`: write the cache with `rows_changed: 0, reason: "user_skipped"` and
advance.

─── APPLY ────────────────────────────────────────────────────────────────────

For each row in CHANGES_NEEDED, PATCH:

  PATCH $SUPABASE_URL/rest/v1/contacts?id=eq.<id>
    Auth: prefer SUPABASE_SERVICE_ROLE_KEY; fall back to anon.
    Content-Type, Prefer: return=minimal.
    body: {"title": "<normalized>"}

Track rows_changed.

Use whatever language is most convenient (short Python with `re`, or
shell + sed). Don't burn time on style.

─── CACHE RESULT ─────────────────────────────────────────────────────────────

Write `data/.formula-applied.json`:

  {
    "applied_at": "<ISO8601 UTC>",
    "rows_changed": <count>,
    "columns_affected": ["title"],
    "mode": "python-patch",
    "status": "success"
  }

─── VERIFY ───────────────────────────────────────────────────────────────────

  bash ~/.claude/skills/quickstart/verifiers/apply_formula.sh

─── COMPLETE ─────────────────────────────────────────────────────────────────

Update state:

  jq --arg now "$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
     '.completed_steps += ["apply_formula"] | .current_step = "fork_pick" | .last_run_at = $now' \
     ~/.claude/skills/quickstart/state.json > /tmp/qs_af.json \
     && mv /tmp/qs_af.json ~/.claude/skills/quickstart/state.json

**Compose a narrative bridge per SKILL.md's "Narrative bridges" rule** —
what just happened (titles normalized via deterministic code, free, this
is Clay's Formulas tab pattern in their database) and what's next + why
(fork_pick — buyer chooses review-and-stop vs ship-and-send; explain
what each path commits them to).

Then print:

  ── Formula applied ────────────────────────────────────────────────────────

  Rows changed:  <ROWS_CHANGED>
  Columns:       title
  Cost:          $0

  Type `continue` to pick your path (review or ship).

─── RECOVERY MENU ────────────────────────────────────────────────────────────

If `help`, print the standard 5-option menu (LMS slug: `apply-formula`). Skip target: `fork_pick`.
