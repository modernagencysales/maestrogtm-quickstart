You are running the Maestro Quickstart adventure. This is a prescriptive, step-based skill.
You do NOT improvise. You follow the script below exactly.

─── READ STATE ───────────────────────────────────────────────────────────────────────────────────

Run:

  cat ~/.claude/skills/quickstart/state.json

Confirm `path` is `ship`. If it is not, print:
  "This step is only for the Ship path. Your path is <path>. Type `continue`
  to move to your correct next step."
Then advance to the correct next step for their path. Do not continue.

Check if `send_outreach` is already in `completed_steps`.
If yes: print "Outreach channels already wired. Type `continue` for the next step." and wait.
On `continue`, advance. Do not re-run this step.

─── PRE-FLIGHT: DEPENDENCY CHECK ────────────────────────────────────────────────────────────────

Confirm `ai_personalize` is in `completed_steps`.
If it is NOT:
  Print:
    "── Warning ────────────────────────────────────────────────────────────────────────────────
    ai_personalize has not completed yet. That step is where you defined your OFFER
    (the body of the cold email) and decided on a personalization approach. Without it,
    we have no email body to send.
    Type `continue` to proceed anyway (test email will use a placeholder body), or type
    `goto ai_personalize` to run that step first.
    ────────────────────────────────────────────────────────────────────────────────────────────"

  Wait for `continue` or `goto ai_personalize`.
  If `goto ai_personalize`: update current_step in state.json and STOP.

Also confirm the campaign offer artifact exists (new location, with legacy fallback):

  OFFER_FILE="data/campaign/offer.md"
  [ ! -f "$OFFER_FILE" ] && [ -f "data/offer.md" ] && OFFER_FILE="data/offer.md"

  if [ ! -f "$OFFER_FILE" ]; then
    Print:
      "$OFFER_FILE not found. The offer is the body of your email — without it,
      send_outreach can only send a placeholder test. Type `goto ai_personalize` to
      build the campaign, or `continue` to send the placeholder anyway."
    Wait for `continue` or `goto ai_personalize`.
    If `goto ai_personalize`: STOP.
  fi

Also note `data/campaign/sequence.md` if it exists — that's the full email
sequence, not just E1. The test send uses E1 only; the rest of the sequence
lives there for when you launch a real campaign.

─── PRE-FLIGHT: IDEMPOTENCY CHECK ───────────────────────────────────────────────────────────────

Before prompting for anything, check if outreach is already wired end-to-end:

  WIRED_FILE="data/.outreach-wired.json"

  if [ -f "$WIRED_FILE" ]; then
    if ! jq empty "$WIRED_FILE" 2>/dev/null; then
      echo "data/.outreach-wired.json exists but contains invalid JSON — re-running step."
    else
      MSG_ID=$(jq -r '.test_send_message_id // empty' "$WIRED_FILE")
      WEBHOOK_ID=$(jq -r '.webhook_id // empty' "$WIRED_FILE")
      LI_CHANNEL=$(jq -r '.linkedin_channel // empty' "$WIRED_FILE")

      if [ -n "$MSG_ID" ] && [ -n "$WEBHOOK_ID" ] && [ -n "$LI_CHANNEL" ]; then
        DOMAIN=$(jq -r '.domain // "unknown"' "$WIRED_FILE")
        INBOX_COUNT=$(jq -r '(.inbox_ids // []) | length' "$WIRED_FILE")
        Print:
          "Outreach already wired end-to-end.
            Domain:           $DOMAIN
            Inboxes:          $INBOX_COUNT
            Test message ID:  $MSG_ID
            Webhook ID:       $WEBHOOK_ID
            LinkedIn channel: $LI_CHANNEL

          Skipping straight to complete."
        Jump to COMPLETE.
      fi
    fi
  fi

─── STEP INTRO ───────────────────────────────────────────────────────────────────────────────────

Print:

  ── Wire Outreach Channels ────────────────────────────────────────────────────

  This step wires the sending layer (~10-12 min). One important truth
  before the menu:

  **Do NOT cold-email from your regular Gmail or Google Workspace.** Even
  20-30 cold sends a day from a normal Gmail address will tank your
  domain's reputation inside a week — your real personal/work email
  starts going to spam, the damage isn't reversible without rotating
  domains. If you've heard a podcast clip about someone "sending 5k/day
  from Gmail," they had a fleet of warmed inboxes you didn't see. Don't.

  Four paths:

    1  **AgentMail (recommended, fully wired here)** — free tier covers
       3 inboxes, enough for a real campaign. Native MCP, first-class
       reply webhooks. We wire it end-to-end in this step (~12 min).
       Default for anyone starting cold outreach today.

    2  **Instantly** — industry-standard cold-email platform, mature
       warmup analytics, $37/mo starter. Many serious operators use it.
       We don't teach Instantly inside the Quickstart — the Bootcamp's
       cohort covers it properly, or you can wire it yourself using
       Deepline's `instantly_*` connectors after this step. Pick this
       if you're already running it; we'll save your campaign artifacts
       and skip the AgentMail wiring.

    3  **Smartlead** — Instantly's main competitor, same shape. Also
       not taught inside the Quickstart; covered in the cohort. Same
       skip-pattern as option 2.

    4  **One-by-one personal notes from your existing Gmail** —
       NOT a cold-email campaign. This is the right answer when your
       TAM is small (under ~50) and the contacts are warm — you've
       worked with them, met them at conferences, share a community.
       At that scale you write each note by hand; the data layer
       helps you find the NEXT 50 you don't already know. We save
       `data/send-manually.md` with your offer + sequence as
       templates, and finish the step. No sending infra to wire.

  Quick selection guide:
    - Cold outreach to people you don't know (any TAM) → option 1
    - Already paying for Instantly/Smartlead → option 2 or 3 (we skip)
    - TAM < 50 and contacts are warm → option 4 (personal notes)
    - Anything else where you're tempted to "just use Gmail" → option 1.
      The free tier exists specifically for this.

  After option 1 your mailboxes warm up over 14-21 days; you can't
  cold-send tomorrow but everything is wired and ready.

  LinkedIn outreach is NOT in the Quickstart. HeyReach has no one-shot
  connection-request API and Unipile-direct needs its own auth. The
  cohort's D20 `linkedin_outreach` skill covers both. We record
  `linkedin_channel: deferred` in the wired file.

  Type 1, 2, 3, or 4:

Wait for the buyer's pick. Free questions welcome — answer in 2-3
paragraphs and re-print the menu. Don't push them to a number.

Branch on the pick:
  - 1 → AgentMail path (Phase 1 below — free tier by default)
  - 2 → Instantly skip path: write `data/.outreach-wired.json` with
        `provider: "instantly"`, `wiring: "deferred-to-cohort"`,
        `campaign_artifacts: ["data/campaign/offer.md",
        "data/campaign/sequence.md"]`, point them at the Bootcamp's
        Module 4 (cold-email launch SOP) for the Instantly wiring,
        mark the step complete. Be honest: "Instantly is a great tool
        — we don't wire it here because the cohort SOP is more
        thorough than we can do in 12 min. Your campaign artifacts
        are ready; you'll paste them into Instantly during cohort
        Module 4."
  - 3 → Smartlead skip path: same as option 2 with
        `provider: "smartlead"`.
  - 4 → Gmail personal-notes path: write `data/send-manually.md`
        with the offer + sequence as ready-to-paste templates, plus a
        one-paragraph header explaining this is hand-sent, not cold,
        and the data layer's real value is helping them find the
        next 50 contacts they don't already know. Mark step complete,
        no AgentMail wiring.

Then ask:

  Watch the 2-min overview of how the sending layer wires in? y/n

Wait for `y` or `n` only. For any other input — a question, a partial answer, "let me think" —
treat it conversationally per SKILL.md's "Input Handling" section. Answer
questions in 2-4 paragraphs grounded in GTM-engineer language, then re-print
the menu/prompt above. The buyer is here to learn — let them wander.
If `y`:
  Run: open https://learn.maestrogtm.com/learn/qs/send-outreach
  Print: "Video opened. Come back here and type `continue` when ready."
  Wait for `continue`.

If `n`: continue immediately.

═══════════════════════════════════════════════════════════════════════════════════════════════════
PHASE 1 — EMAIL VIA AGENTMAIL
═══════════════════════════════════════════════════════════════════════════════════════════════════

─── COST NOTE (AgentMail path) ────────────────────────────────────────────────────────────────────

Print:

  ── AgentMail pricing — quick honesty ────────────────────────────────────────

  Free tier: 3 inboxes free, enough for the Quickstart's test send AND for
  most solo operators to run real campaigns. Verify current terms at
  https://agentmail.to/pricing.

  Paid: starts around $30/mo per additional sending mailbox if you need more
  than 3. For most first-time buyers, you'll never hit the paywall on this
  step.

  We're going to provision 2 mailboxes on the free tier. Zero recurring
  cost unless you grow past 3.

  Type `continue` to sign up, or `back` to pick a different sending option
  (Instantly, Smartlead, or Gmail manual).

Wait for `continue` or `back`. On `back`: return to the option-pick menu in
the STEP INTRO above.

─── SIGNUP: AGENTMAIL ACCOUNT ────────────────────────────────────────────────────────────────────

# MAESTRO_CLI_ONLY gate — account signup is the only unavoidable browser step in this skill.
# All other steps (key creation, domain connect, DNS records, inbox provisioning, webhook) are API-driven.
# Note: $0 from inside an LLM-orchestrated prompt won't resolve to the prompt file. Use the
# absolute installed path so the helper actually loads.
source "$HOME/.claude/skills/quickstart/lib/cli-only.sh" 2>/dev/null || true
type require_browser_or_fail >/dev/null 2>&1 && require_browser_or_fail \
  "AgentMail account signup" \
  "https://agentmail.to" \
  "(no CLI alternative — foreign account signup requires browser)"

Print:

  ── Step 1 of 6 — Create an AgentMail account ────────────────────────────────

  AgentMail is the email-sending infrastructure for the rest of this Quickstart.
  Quick translation if it's new: when you "send a cold email at scale" you can't
  just use Gmail — Gmail will throttle you and ding your reputation. You need a
  proper sending platform that owns mailbox warming (slowly building reputation
  by sending small volumes first), DKIM/SPF/DMARC (cryptographic proofs to
  inbox providers that you're not a spammer), and reply webhooks (so we can
  catch responses and route them to your CRM).

  AgentMail does all of that in one tool, designed for AI-driven outreach
  (which we are). Alternatives include Smartlead, Instantly, and Maildoso —
  AgentMail is the one we use for the Quickstart because:
    • One API + one auth (most others need 3+ tools chained)
    • Native MCP + first-class reply webhooks (replies show up in Supabase
      automatically, no polling)
    • Auto-DKIM/SPF/DMARC (you don't touch DNS records by hand — they
      generate them, you paste them at your registrar once, done)

  What you'll do in the next 30 seconds:
    1. Open agentmail.to in your browser
    2. Click "Sign up" (top right)
    3. Use email or Google OAuth — no credit card up front
    4. Check your inbox for a welcome email — AgentMail sends your root API
       key there. Keep that email open in another tab; we'll grab the key next.

  Pricing — free tier covers 3 inboxes (enough for the Quickstart and most
  solo cold-email setups). Paid plans kick in past 3 mailboxes, ~$30/mo per
  additional. Verify at agentmail.to/pricing.

  Type `continue` when you have the welcome email open with your root key.

Wait for `continue` or `done` or `ready`.
For any other input — a question, a partial answer, "let me think" —
treat it conversationally per SKILL.md's "Input Handling" section. Answer
questions in 2-4 paragraphs grounded in GTM-engineer language, then re-print
the menu/prompt above. The buyer is here to learn — let them wander.
─── KEY COLLECTION ───────────────────────────────────────────────────────────────────────────────

Print:

  Step 2 of 6 — API key

  AgentMail gives you a root key when you sign up (check your welcome email or
  the dashboard under Settings → API Keys). Paste that root key here — we'll
  use it to automatically create a scoped "maestro-quickstart" key so your root
  key never touches secrets/.env.

  Paste your AgentMail root API key here:

Wait for user input.

Validate:
  ROOT_KEY=$(echo "$INPUT" | tr -d '[:space:]')
  [ ${#ROOT_KEY} -gt 10 ] || fail

If the pasted value is empty or <= 10 chars after stripping:
  Print: "That doesn't look like a full API key. Check your AgentMail welcome email
  or agentmail.to → Settings → API Keys. Try again:"
  Re-prompt.

If whitespace was stripped and the raw input differed from the stripped value:
  Print: "Stripped whitespace. Using: <first 8 chars>..."

Store as AGENTMAIL_ROOT_KEY.

─── CREATE SCOPED KEY ────────────────────────────────────────────────────────────────────────────

Print: "Creating a scoped 'maestro-quickstart' API key via AgentMail API..."

# AgentMail API: POST /v0/api-keys
# Auth: Bearer token. Response: { api_key, api_key_id, prefix, name, ... }
Run:
  KEY_RESP=$(curl -s -w "\n%{http_code}" -X POST \
    "https://api.agentmail.to/v0/api-keys" \
    -H "Authorization: Bearer $AGENTMAIL_ROOT_KEY" \
    -H "Content-Type: application/json" \
    -d "{\"name\":\"maestro-quickstart-$(date +%Y%m%d)\"}" \
    --max-time 15 2>/dev/null)

  KEY_HTTP=$(echo "$KEY_RESP" | tail -1)
  KEY_BODY=$(echo "$KEY_RESP" | sed '$d')

Evaluate:
  A) KEY_HTTP = 200 or 201:
     AGENTMAIL_API_KEY=$(echo "$KEY_BODY" | jq -r '.api_key // empty' 2>/dev/null || echo "")
     KEY_ID=$(echo "$KEY_BODY" | jq -r '.api_key_id // empty' 2>/dev/null || echo "")
     if [ -n "$AGENTMAIL_API_KEY" ]; then
       Print:
         "Scoped key created.
           Key ID:  $KEY_ID
           Prefix:  $(echo "$AGENTMAIL_API_KEY" | cut -c1-8)...
         Root key is NOT saved. Only the scoped key goes to secrets/.env."
     else
       Print: "AgentMail returned 200 but no api_key field in the response.
       Body: $(echo "$KEY_BODY" | head -c 300)

       Falling back — paste the root key directly (it will be used as AGENTMAIL_API_KEY):"
       AGENTMAIL_API_KEY="$AGENTMAIL_ROOT_KEY"
     fi

  B) KEY_HTTP = 401 or 403:
     Print: "Root key was rejected (HTTP $KEY_HTTP). Did you paste the root key correctly?
     Type `retry` to re-enter your root key, or `skip` to use the root key directly."
     Wait for `retry` or `skip`.
     If `retry`: re-run KEY COLLECTION, then re-run CREATE SCOPED KEY.
     If `skip`:
       AGENTMAIL_API_KEY="$AGENTMAIL_ROOT_KEY"
       Print: "Using root key as AGENTMAIL_API_KEY. Consider rotating it later from
       agentmail.to → Settings → API Keys."

  C) KEY_HTTP = 000 or connection failure:
     Print: "Could not reach api.agentmail.to. Check your connection, then type `retry`
     or type `skip` to use the root key directly."
     Wait for `retry` or `skip`.
     If `retry`: re-run the curl.
     If `skip`: AGENTMAIL_API_KEY="$AGENTMAIL_ROOT_KEY"

  D) Any other code:
     Print: "Unexpected HTTP $KEY_HTTP creating scoped key:
       $(echo "$KEY_BODY" | head -c 300)
     Type `skip` to use the root key directly or `retry` to try again."
     Wait for `skip` or `retry`.
     If `skip`: AGENTMAIL_API_KEY="$AGENTMAIL_ROOT_KEY"
     If `retry`: re-run the curl.

Store final value as AGENTMAIL_API_KEY.

─── WRITE KEY TO ENV ─────────────────────────────────────────────────────────────────────────────

Ensure directories exist:

  mkdir -p secrets data

Determine env file (prefer secrets/.env, fall back to .env):

  ENV_FILE=$(ls secrets/.env .env "$HOME/.env" "$HOME/.env.maestro-quickstart" 2>/dev/null | head -1)
  [ -z "$ENV_FILE" ] && ENV_FILE="secrets/.env"

Back up if the file already exists:

  [ -f "$ENV_FILE" ] && cp "$ENV_FILE" "$ENV_FILE.bak.$(date +%s)"

Write key — remove any existing AGENTMAIL_API_KEY line, then append:

  grep -v '^AGENTMAIL_API_KEY=' "$ENV_FILE" 2>/dev/null > "$ENV_FILE.tmp" || true
  echo "AGENTMAIL_API_KEY=$AGENTMAIL_API_KEY" >> "$ENV_FILE.tmp"
  mv "$ENV_FILE.tmp" "$ENV_FILE"

Print: "Key written to $ENV_FILE."

# Auth: Authorization: Bearer $AGENTMAIL_API_KEY (confirmed from AgentMail docs)
# Base URL: https://api.agentmail.to/v0/ (confirmed from AgentMail docs)

─── DOMAIN STEP ──────────────────────────────────────────────────────────────────────────────────

Print:

  ── Step 3 of 6 — Pick a sending domain ──────────────────────────────────────

  Quick translation if "sending domain" is new: every email needs to come FROM
  somewhere — like jane@yourcompany.com or outreach@reply.youragency.com. That
  thing after the @ is your sending domain. For cold outreach, you do NOT use
  your main company domain (yourcompany.com) — if a campaign goes wrong and
  spam filters mark mail from that domain as spam, your real Gmail/Outlook
  starts going to spam too. Bad day.

  The standard practice: use a SEPARATE domain just for outreach. Common
  patterns: reply.yourcompany.com (subdomain), youragencyhq.com (typo of your
  real domain), getyourcompany.com (alt prefix). Each costs ~$10/year at any
  registrar. AgentMail can also buy one for you in-product.

  Three options:

    1  I have a domain I want to use  (recommended — best deliverability)
       You'll add a few DNS records at your registrar; AgentMail walks you
       through them. ~5 minute setup, then DNS propagation can take an hour.

    2  I want to buy one through AgentMail  (easiest — they handle it end-to-end)
       Pick a name, pay ~$10-15/year, AgentMail provisions everything.

    3  Skip — use AgentMail's shared test subdomain for now
       Lets you complete the test send today, but you can't actually run a
       real cold campaign from a shared subdomain. Fine for proving the wiring
       works; come back here later when you're ready to send for real.

  Type 1, 2, or 3:

Wait for 1, 2, or 3 only. For any other input — a question, a partial answer, "let me think" —
treat it conversationally per SKILL.md's "Input Handling" section. Answer
questions in 2-4 paragraphs grounded in GTM-engineer language, then re-print
the menu/prompt above. The buyer is here to learn — let them wander.
─── DOMAIN OPTION 1: CONNECT EXISTING ───────────────────────────────────────────────────────────

If option 1:

  Print: "What domain do you want to connect? (e.g. reply.youragency.com):"
  Wait for user input. Store as SENDING_DOMAIN.

  Print: "Connecting $SENDING_DOMAIN to AgentMail..."

  # POST /v0/domains — body: { domain, feedback_enabled }
  # Response includes records[].{type, name, value, priority, status}
  Run:
    DOMAIN_RESP=$(curl -s -w "\n%{http_code}" -X POST \
      "https://api.agentmail.to/v0/domains" \
      -H "Authorization: Bearer $AGENTMAIL_API_KEY" \
      -H "Content-Type: application/json" \
      -d "{\"domain\": \"$SENDING_DOMAIN\", \"feedback_enabled\": true}" \
      --max-time 15 2>/dev/null)

    HTTP_CODE=$(echo "$DOMAIN_RESP" | tail -1)
    BODY=$(echo "$DOMAIN_RESP" | sed '$d')

  Evaluate:
    A) HTTP_CODE = 200 or 201:
       DOMAIN_ID=$(echo "$BODY" | jq -r '.domain_id // .id // empty' 2>/dev/null || echo "")

       # Extract DNS records directly from the POST /domains response — no dashboard visit needed.
       # AgentMail returns records[].{type, name, value, priority, status}
       DNS_RECORDS=$(echo "$BODY" | jq -r '
         (.records // [])
         | .[]
         | if .type == "MX"
           then "  \(.type)\t\(.name)\t\(.value)\t(priority: \(.priority // 10))"
           else "  \(.type)\t\(.name)\t\(.value)"
           end
       ' 2>/dev/null || echo "")

       if [ -n "$DNS_RECORDS" ]; then
         Print:
           "Domain $SENDING_DOMAIN connected.

           Add these DNS records at your registrar now — AgentMail cannot send or
           warm up until DNS is verified.

           Quick translation if 'DNS records' is new:
             Your domain has a control panel at whoever you bought it from
             (Namecheap, GoDaddy, Cloudflare, Google Domains, Squarespace...).
             That panel has a 'DNS' or 'Records' section. You add each row
             below as a new record. Type = MX/TXT/CNAME (we tell you which),
             Name = the host part, Value = the destination.

             What each one does:
               MX   = where email FOR your domain gets delivered (replies)
               TXT  = SPF, DKIM, DMARC — the cryptographic proofs that say
                      'AgentMail is authorized to send as this domain'
               CNAME = sometimes used for tracking links

             You don't need to understand them — just paste them at your
             registrar exactly as shown.

           Type  Name                        Value
           ────  ──────────────────────────  ─────────────────────────────────────
           $DNS_RECORDS

           Records typically take 5-60 minutes to propagate worldwide. Some
           registrars (Cloudflare) are near-instant.

           Tip: If your DNS is on Cloudflare, set CLOUDFLARE_API_TOKEN + CLOUDFLARE_ZONE_ID
           in secrets/.env and we can add these automatically on a future pass.

           When you've added the records at your registrar, type \`continue\`."
       else
         # Records not in the response — fall back to instructing the API GET call
         Print:
           "Domain $SENDING_DOMAIN connected (ID: $DOMAIN_ID).
           DNS records are provisioning — fetch them now:

             curl -s -H 'Authorization: Bearer \$AGENTMAIL_API_KEY' \\
               'https://api.agentmail.to/v0/domains/$DOMAIN_ID' | jq '.records'

           Add each record at your registrar, then type \`continue\`."
       fi

       Wait for `continue`.
       Jump to VERIFY DOMAIN.

    B) HTTP_CODE = 401 or 403:
       Print: "AgentMail rejected the key — it may have been copied incorrectly.
       Type `retry` to re-enter your key, or `help` for options."
       Wait for `retry` or `help`.
       If `retry`: re-run KEY COLLECTION, then come back to DOMAIN OPTION 1.
       If `help`: go to RECOVERY MENU.

    C) HTTP_CODE = 409 or body contains "already exists":
       Print: "That domain is already connected to your AgentMail account. Using it."
       DOMAIN_ID=$(echo "$BODY" | jq -r '.domain_id // .id // empty' 2>/dev/null || echo "existing")
       SENDING_DOMAIN stays as-is. Jump to MAILBOX PROVISIONING.

    D) Any other code:
       Print: "Unexpected response (HTTP $HTTP_CODE) connecting $SENDING_DOMAIN:
         $(echo "$BODY" | head -c 400)

       Type `retry` to try again or `help` for options."
       Wait for `retry` or `help`.
       If `retry`: re-run the POST.
       If `help`: go to RECOVERY MENU.

─── VERIFY DOMAIN ────────────────────────────────────────────────────────────────────────────────

Print: "Checking DNS verification status for $SENDING_DOMAIN..."

# GET /v0/domains/{id} — read the domain's current verification state
# (AgentMail re-checks DNS automatically; there's no separate trigger endpoint.)
# Response: domain object with status field — NOT_STARTED|PENDING|VERIFYING|VERIFIED|FAILED
Run:
  VERIFY_RESP=$(curl -s -w "\n%{http_code}" \
    "https://api.agentmail.to/v0/domains/${DOMAIN_ID}" \
    -H "Authorization: Bearer $AGENTMAIL_API_KEY" \
    --max-time 15 2>/dev/null)

  HTTP_CODE=$(echo "$VERIFY_RESP" | tail -1)
  BODY=$(echo "$VERIFY_RESP" | sed '$d')

  VERIFIED=$(echo "$BODY" | jq -r '.status // empty' 2>/dev/null || echo "")

If HTTP_CODE = 200 and VERIFIED = "VERIFIED":
  Print: "DNS verified. DKIM, SPF, and DMARC are confirmed by AgentMail. Moving on."
  Jump to MAILBOX PROVISIONING.

If HTTP_CODE = 200 and VERIFIED is one of "PENDING" / "VERIFYING" / "NOT_STARTED":
  Print:
    "DNS status: $VERIFIED — that's normal. Propagation takes 5-60 minutes.
    You can continue now; warmup won't start until DNS is verified but the rest
    of the wiring will work.
    Type `recheck` to GET the domain again now, or `continue` to proceed."
  Wait for `recheck` or `continue`. On `recheck`: re-run the GET, re-evaluate;
  if still PENDING, ask again (cap 5 rechecks before forcing continue). On
  `continue`: jump to MAILBOX PROVISIONING.

If HTTP_CODE = 200 and VERIFIED is "INVALID" or "FAILED":
  Print:
    "DNS status: $VERIFIED — your DNS records aren't matching what AgentMail
    expects. Common causes:
      • Wrong record values pasted at the registrar
      • Wrong record type (CNAME vs TXT confused)
      • Records not yet propagated (try again in 30 min)
      • A conflicting SPF or DMARC record from another sender

    Re-open the AgentMail dashboard at https://agentmail.to → Domains →
    $SENDING_DOMAIN to view the exact records you need to set, fix at your
    registrar, then type `recheck` to re-verify. Or `skip` to defer the
    verification and continue with mailbox provisioning (mailboxes will sit
    inactive until DNS is fixed)."
  Wait for `recheck` or `skip`. On `recheck`: re-run the GET. On `skip`:
  jump to MAILBOX PROVISIONING with a warning logged.

If HTTP_CODE != 200:
  Print: "Could not check verification status (HTTP $HTTP_CODE). Continuing — check
  agentmail.to → Domains later to confirm DNS is active.
  Type `continue` to proceed."
  Wait for `continue`. Jump to MAILBOX PROVISIONING.

─── DOMAIN OPTION 2: BUY VIA AGENTMAIL ──────────────────────────────────────────────────────────

If option 2:

  Print:
    "Go to agentmail.to → Domains → Buy a Domain.
    Pick something close to your real domain (e.g. tryagencyname.com, getagencyname.com).
    Avoid hyphens and keywords that trigger spam filters.

    Mailbox cost: check agentmail.to pricing — confirm before purchasing.

    Once you've purchased and AgentMail has provisioned the domain, come back
    and paste the domain name here (e.g. tryagencyname.com):"

  Wait for user input. Store as SENDING_DOMAIN.
  DOMAIN_ID="purchased"
  Print: "Using purchased domain: $SENDING_DOMAIN. DNS is handled by AgentMail."
  Jump to MAILBOX PROVISIONING.

─── DOMAIN OPTION 3: SHARED TEST SUBDOMAIN ──────────────────────────────────────────────────────

If option 3:

  Print:
    "Using AgentMail's shared sending infrastructure for this test. This is fine for
    proving the wiring — you'll want a dedicated domain before cold-sending for real.

    Note: the test email will come from an @agentmail.to address, not your domain."

  SENDING_DOMAIN="agentmail-shared"
  DOMAIN_ID="shared"
  Jump to MAILBOX PROVISIONING.

─── MAILBOX PROVISIONING ─────────────────────────────────────────────────────────────────────────

Print:

  Step 4 of 6 — Provision mailboxes

  Creating 2 mailboxes on $SENDING_DOMAIN. AgentMail starts warming them
  immediately after provisioning.

  Mailbox cost: check agentmail.to pricing — confirm per-inbox/month before launch.

Run a loop to create 2 mailboxes (index 1 and 2):

  INBOX_IDS=()

  For each LOCAL_PART in ("outreach1" "outreach2"):

    # POST /v0/inboxes — body: { username, domain, display_name }
    # username = local part of the email address (e.g. "outreach1")
    INBOX_RESP=$(curl -s -w "\n%{http_code}" -X POST \
      "https://api.agentmail.to/v0/inboxes" \
      -H "Authorization: Bearer $AGENTMAIL_API_KEY" \
      -H "Content-Type: application/json" \
      -d "$(jq -n \
          --arg username "$LOCAL_PART" \
          --arg domain "$SENDING_DOMAIN" \
          '{username: $username, domain: $domain}')" \
      --max-time 15 2>/dev/null)

    HTTP_CODE=$(echo "$INBOX_RESP" | tail -1)
    BODY=$(echo "$INBOX_RESP" | sed '$d')

    Evaluate:
      A) HTTP_CODE = 200 or 201:
         INBOX_ID=$(echo "$BODY" | jq -r '.inbox_id // .id // empty' 2>/dev/null || echo "")
         if [ -n "$INBOX_ID" ]; then
           INBOX_IDS+=("$INBOX_ID")
           Print: "  ✓ Created $LOCAL_PART@$SENDING_DOMAIN (id: $INBOX_ID)"
         else
           Print: "  ⚠ Created but couldn't parse inbox ID from response — continuing."
           INBOX_IDS+=("unknown-$LOCAL_PART")
         fi

      B) HTTP_CODE = 409 or body contains "already exists":
         Print: "  ✓ $LOCAL_PART@$SENDING_DOMAIN already exists — using it."
         INBOX_ID=$(echo "$BODY" | jq -r '.id // .inbox_id // empty' 2>/dev/null || echo "existing-$LOCAL_PART")
         INBOX_IDS+=("$INBOX_ID")

      C) Any other code:
         Print: "  ✗ Failed to create $LOCAL_PART@$SENDING_DOMAIN (HTTP $HTTP_CODE):
           $(echo "$BODY" | head -c 300)

         Type `retry` to try this mailbox again, `skip` to continue with fewer inboxes,
         or `help` for options."
         Wait for `retry`, `skip`, or `help`.
         If `retry`: retry this mailbox (loop back).
         If `skip`: continue with the inboxes created so far.
         If `help`: go to RECOVERY MENU.

  After the loop:

  if [ ${#INBOX_IDS[@]} -eq 0 ]; then
    Print: "No inboxes were created. Type `help` for recovery options."
    Go to RECOVERY MENU.
  fi

  PRIMARY_INBOX_ID="${INBOX_IDS[0]}"

  Print:
    "${#INBOX_IDS[@]} mailbox(es) provisioned. Warmup starts automatically.
    Expected sending readiness: 14-21 days from today."

─── WARMUP NOTICE ────────────────────────────────────────────────────────────────────────────────

Print:

  ── Warmup Period ─────────────────────────────────────────────────────────────

  AgentMail handles warmup automatically: it exchanges emails between warmed
  inboxes at a controlled rate, building reputation gradually. You do NOT need
  to do anything.

  Do NOT cold-send from these mailboxes until warmup is complete. Sending cold
  to strangers before warmup destroys deliverability.

  What you CAN do now:
    - Send the test email below (to your own inbox — not cold)
    - Wire the reply webhook
    - Prepare your contact list and first_line copy

  Type `continue` to send the test email.

Wait for `continue`. For any other input — a question, a partial answer, "let me think" —
treat it conversationally per SKILL.md's "Input Handling" section. Answer
questions in 2-4 paragraphs grounded in GTM-engineer language, then re-print
the menu/prompt above. The buyer is here to learn — let them wander.
─── TEST SEND ────────────────────────────────────────────────────────────────────────────────────

Print:

  Step 5 of 6 — Test send

  We'll send one email FROM your new inbox TO your own email address. This
  proves the mailbox is live without touching your prospect list.

  What's your personal email address? (We'll send the test there):

Wait for user input. Store as USER_EMAIL.
Validate: must contain `@` and `.`.
If invalid: print "That doesn't look like a valid email. Try again:" and re-prompt.

Build the test email body from the offer + an optional personalized opener:

  source secrets/.env 2>/dev/null || source .env 2>/dev/null || true

  # 1) Load the OFFER (the actual value prop — this is what gets the reply).
  #    Prefer the new campaign location; fall back to legacy.
  if [ -f data/campaign/offer.md ]; then
    OFFER_BODY=$(cat data/campaign/offer.md)
  elif [ -f data/offer.md ]; then
    OFFER_BODY=$(cat data/offer.md)
  else
    OFFER_BODY="(no offer file found — placeholder body for system test)"
  fi

  # 1b) If a full sequence was drafted, prefer Email 1's body for the test send
  #     so the buyer sees their actual campaign copy land in their inbox.
  if [ -f data/campaign/sequence.md ]; then
    # Extract just Email 1's body between "## Email 1" and "## Email 2"
    # (best-effort — falls back to OFFER_BODY if parse yields empty)
    E1_BODY=$(awk '/^## Email 1/{flag=1; next} /^## Email 2/{flag=0} flag && /^Body:/{getline; while ($0 !~ /^## /) { print; if (!getline) break }}' data/campaign/sequence.md 2>/dev/null | sed -e '/^$/N;/^\n$/D')
    if [ -n "$E1_BODY" ]; then
      OFFER_BODY="$E1_BODY"
    fi
  fi

  # 2) Pull one contact with a first_name (and first_line if it exists) for the
  #    opener. first_line is OPTIONAL — many contacts won't have one (path=skip,
  #    or path=real with empty signal). We do NOT fabricate filler.
  CONTACT_RESP=$(curl -s \
    -H "apikey: $SUPABASE_ANON_KEY" \
    -H "Authorization: Bearer $SUPABASE_ANON_KEY" \
    "${SUPABASE_URL}/rest/v1/contacts?select=first_name,first_line&first_name=not.is.null&limit=1" \
    --max-time 10 2>/dev/null || echo "[]")
  FIRST_LINE=$(echo "$CONTACT_RESP" | jq -r '.[0].first_line // empty' 2>/dev/null || echo "")
  FIRST_NAME=$(echo "$CONTACT_RESP" | jq -r '.[0].first_name // "there"' 2>/dev/null || echo "there")

  # 3) Compose the body. Opener line is conditional on first_line being non-empty.
  if [ -n "$FIRST_LINE" ]; then
    OPENER="Hi $FIRST_NAME,

$FIRST_LINE"
  else
    OPENER="Hi $FIRST_NAME,"
  fi

  EMAIL_BODY="$OPENER

$OFFER_BODY

---
This is a system test. Reply to this email to verify reply routing works.

– Maestro Quickstart"

Print: "Sending test email to $USER_EMAIL from inbox $PRIMARY_INBOX_ID..."

# POST /v0/inboxes/{inbox_id}/messages/send — send a new message
# (Plain `/messages` is the LIST endpoint; `/messages/send` is required to send.)
# Body fields per AgentMail docs: to (string), subject, text (plain text body)
Run:
  SEND_RESP=$(curl -s -w "\n%{http_code}" -X POST \
    "https://api.agentmail.to/v0/inboxes/${PRIMARY_INBOX_ID}/messages/send" \
    -H "Authorization: Bearer $AGENTMAIL_API_KEY" \
    -H "Content-Type: application/json" \
    -d "$(jq -n \
        --arg to "$USER_EMAIL" \
        --arg subject "Maestro Quickstart — test send" \
        --arg text "Hi $FIRST_NAME,

$FIRST_LINE

---
This is a system test. Reply to this email to verify reply routing works.

– Maestro Quickstart" \
        '{to: $to, subject: $subject, text: $text}')" \
    --max-time 15 2>/dev/null)

  HTTP_CODE=$(echo "$SEND_RESP" | tail -1)
  BODY=$(echo "$SEND_RESP" | sed '$d')

Evaluate:
  A) HTTP_CODE = 200 or 201 or 202:
     TEST_SEND_MESSAGE_ID=$(echo "$BODY" | jq -r '.message_id // .id // empty' 2>/dev/null || echo "")
     if [ -z "$TEST_SEND_MESSAGE_ID" ]; then
       Print: "AgentMail returned $HTTP_CODE but no message_id in the body:
         $(echo "$BODY" | head -c 400)
       Refusing to forge a fake ID. Type `retry` to re-send, or `help`."
       Wait for `retry` or `help`. Do NOT mark this step complete.
     fi
     Print:
       "Test email sent. Message ID: $TEST_SEND_MESSAGE_ID

       Go check your inbox at $USER_EMAIL now.
       It should arrive within 1-3 minutes.

       Type `continue` once it lands in your inbox (not spam — inbox)."
     Wait for `continue`. For any other input — a question, a partial answer, "let me think" —
treat it conversationally per SKILL.md's "Input Handling" section. Answer
questions in 2-4 paragraphs grounded in GTM-engineer language, then re-print
the menu/prompt above. The buyer is here to learn — let them wander.
  B) HTTP_CODE = 401 or 403:
     Print: "AgentMail rejected the send — API key issue.
     Type `retry` to re-enter your key, or `help` for options."
     Wait for `retry` or `help`.
     If `retry`: re-run KEY COLLECTION, then return to TEST SEND.
     If `help`: go to RECOVERY MENU.

  C) HTTP_CODE = 422 or 400:
     Print: "AgentMail returned a validation error (HTTP $HTTP_CODE):
       $(echo "$BODY" | head -c 400)

     This usually means the inbox ID or one of the fields in the request body
     is malformed. The expected body is { to: <email>, subject: <string>, text: <string> }.
     If the body looks right, try sending without the inbox_id path component
     and using the inbox-aware /v0/messages endpoint instead.
     Type `help` for recovery options."
     Go to RECOVERY MENU.

  D) HTTP_CODE = 000 or connection failure:
     Print: "Could not reach api.agentmail.to (timeout or no connection).
     Type `retry` to try again or `help` for options."
     Wait for `retry` or `help`.
     If `retry`: re-run the send curl.
     If `help`: go to RECOVERY MENU.

  E) Any other code:
     Print: "Unexpected HTTP $HTTP_CODE from AgentMail:
       $(echo "$BODY" | head -c 300)
     Type `help` for options."
     Go to RECOVERY MENU.

─── WIRE REPLY WEBHOOK ───────────────────────────────────────────────────────────────────────────

Print:

  Step 6 of 6 — Reply webhook

  When a prospect replies, AgentMail fires a webhook so the reply lands in
  your Supabase `replies` table and triggers downstream classification.

  Heads up — disclosure: by default this Quickstart points the webhook at
  https://api.maestrogtm.com/webhooks/agentmail/<hash>. That endpoint runs
  on Maestro's infrastructure and forwards each reply into YOUR Supabase
  project (the hash is derived from your AgentMail API key, so we know
  which project to route to). Your reply BODIES traverse Maestro's edge.

  If you'd rather webhooks go directly to your own server (no third-party
  hop), set MAESTRO_WEBHOOK_BASE in secrets/.env to your own URL — e.g.:
    MAESTRO_WEBHOOK_BASE=https://your-domain.example.com
  and re-run this step. We'll register the webhook against
  $MAESTRO_WEBHOOK_BASE/webhooks/agentmail/<hash> instead.

  WEBHOOK_BASE="${MAESTRO_WEBHOOK_BASE:-https://api.maestrogtm.com}"
  echo "Registering webhook at $WEBHOOK_BASE/webhooks/agentmail/..."

Compute the API key hash for the webhook URL. Use `shasum` (works on macOS
and Linux; `sha256sum` is GNU-only and missing on stock macOS):

  API_KEY_HASH=$(echo -n "$AGENTMAIL_API_KEY" | shasum -a 256 | cut -c1-16)

# POST /v0/webhooks — AgentMail webhook events (per docs.agentmail.to/events):
#   field name is `event_types` (not `events`); event values are dotted
#   (`message.received`, `message.bounced`, `message.complained`).
Run:
  WEBHOOK_RESP=$(curl -s -w "\n%{http_code}" -X POST \
    "https://api.agentmail.to/v0/webhooks" \
    -H "Authorization: Bearer $AGENTMAIL_API_KEY" \
    -H "Content-Type: application/json" \
    -d "$(jq -n \
        --arg url "$WEBHOOK_BASE/webhooks/agentmail/${API_KEY_HASH}" \
        --argjson event_types '["message.received", "message.bounced", "message.complained"]' \
        '{url: $url, event_types: $event_types}')" \
    --max-time 15 2>/dev/null)

  HTTP_CODE=$(echo "$WEBHOOK_RESP" | tail -1)
  BODY=$(echo "$WEBHOOK_RESP" | sed '$d')

Evaluate:
  A) HTTP_CODE = 200 or 201:
     WEBHOOK_ID=$(echo "$BODY" | jq -r '.webhook_id // .id // empty' 2>/dev/null || echo "")
     if [ -z "$WEBHOOK_ID" ]; then
       Print: "AgentMail returned $HTTP_CODE but no webhook_id in the body:
         $(echo "$BODY" | head -c 400)
       Refusing to forge a fake ID. Type `retry` or `help`."
       Wait for `retry` or `help`. Do NOT mark this step complete.
     else
       Print:
         "Reply webhook registered.
           Webhook ID:  $WEBHOOK_ID
           Events:      message.received, message.bounced, message.complained
           Target URL:  $WEBHOOK_BASE/webhooks/agentmail/$API_KEY_HASH"
     fi

  B) HTTP_CODE = 409 or body contains "already exists":
     WEBHOOK_ID=$(echo "$BODY" | jq -r '.id // .webhook_id // empty' 2>/dev/null || echo "existing-webhook")
     Print: "Webhook already registered — using existing one (ID: $WEBHOOK_ID)."

  C) HTTP_CODE = 401 or 403:
     Print: "AgentMail rejected the webhook registration — API key issue.
     Type `retry` to re-enter your key, or `help` for options."
     Wait for `retry` or `help`.
     If `retry`: re-run KEY COLLECTION, then re-run WIRE REPLY WEBHOOK.
     If `help`: go to RECOVERY MENU.

  D) Any other code:
     Print: "Unexpected HTTP $HTTP_CODE registering webhook:
       $(echo "$BODY" | head -c 300)
     Type `retry` to try again, or `skip` to save and note webhook registration as pending."
     Wait for `retry` or `skip`.
     If `retry`: re-run the webhook POST.
     If `skip`:
       WEBHOOK_ID=""
       WEBHOOK_STATUS="pending"
       Print: "Webhook marked as pending (webhook_id will be empty in
       data/.outreach-wired.json with webhook_status='pending'). Register it
       manually via API:
         curl -s -X POST 'https://api.agentmail.to/v0/webhooks' \\
           -H 'Authorization: Bearer \$AGENTMAIL_API_KEY' \\
           -H 'Content-Type: application/json' \\
           -d '{\"url\":\"$WEBHOOK_BASE/webhooks/agentmail/$API_KEY_HASH\",\"event_types\":[\"message.received\",\"message.bounced\",\"message.complained\"]}'
       Or check existing webhooks: curl -s -H 'Authorization: Bearer \$AGENTMAIL_API_KEY' 'https://api.agentmail.to/v0/webhooks'"

─── WEBHOOK TEST ─────────────────────────────────────────────────────────────────────────────────

Print:

  Webhook test — reply to the test email

  Open your email client and reply to the test email that landed in $USER_EMAIL.
  Any reply content is fine (e.g. "test reply").

  This fires the message.received event at AgentMail → Maestro receives it →
  it lands in your Supabase replies table.

  After you've replied, type `continue`. We'll verify the webhook fired.

Wait for `continue`. For any other input — a question, a partial answer, "let me think" —
treat it conversationally per SKILL.md's "Input Handling" section. Answer
questions in 2-4 paragraphs grounded in GTM-engineer language, then re-print
the menu/prompt above. The buyer is here to learn — let them wander.
Check for the webhook receipt (allow ~30 seconds):

  source secrets/.env 2>/dev/null || source .env 2>/dev/null || true

  # Query Supabase for the most recent reply row created after step started
  STEP_START=$(date -u +%Y-%m-%dT%H:%M:%SZ)

  REPLY_COUNT=$(curl -s \
    -H "apikey: $SUPABASE_ANON_KEY" \
    -H "Authorization: Bearer $SUPABASE_ANON_KEY" \
    -H "Prefer: count=exact" \
    "${SUPABASE_URL}/rest/v1/replies?select=count&created_at=gte.${STEP_START}" \
    2>/dev/null | jq '.[0].count // 0' 2>/dev/null || echo "0")

If REPLY_COUNT >= 1:
  WEBHOOK_TEST_TIMESTAMP=$(date -u +%Y-%m-%dT%H:%M:%SZ)
  Print:
    "Reply webhook confirmed — row landed in Supabase replies table.
    End-to-end confirmed: send → inbox → reply → Supabase."

If REPLY_COUNT = 0:
  Print:
    "No reply row found yet. It can take 30-60 seconds for the webhook to fire
    and the row to land.

    Options:
      1  Check again (wait 30 seconds)
      2  Skip this check and mark webhook test as assumed-pass
      3  Help — webhook isn't firing"

  Wait for 1, 2, or 3.
  If 1:
    Re-run the curl count check. If it still returns 0 after 3 retries, fall through to 2.
  If 2:
    WEBHOOK_TEST_TIMESTAMP="assumed-$(date -u +%Y-%m-%dT%H:%M:%SZ)"
    Print: "Webhook test skipped. If replies don't flow in production, check:
      1. agentmail.to → Webhooks — is the URL correct?
      2. api.maestrogtm.com/webhooks/agentmail/<hash> — is the route deployed?"
  If 3:
    Go to RECOVERY MENU.

Print:

  Phase 1 complete. Email infrastructure is live.

    Domain:        $SENDING_DOMAIN
    Inboxes:       ${#INBOX_IDS[@]} (warming now — 14-21 days)
    Test send:     landed in $USER_EMAIL ✓
    Reply webhook: registered (ID: $WEBHOOK_ID) ✓

  Moving to Phase 2 — LinkedIn outreach check.
  Type `continue`.

Wait for `continue`. For any other input — a question, a partial answer, "let me think" —
treat it conversationally per SKILL.md's "Input Handling" section. Answer
questions in 2-4 paragraphs grounded in GTM-engineer language, then re-print
the menu/prompt above. The buyer is here to learn — let them wander.
═══════════════════════════════════════════════════════════════════════════════════════════════════
PHASE 2 — LINKEDIN (DEFERRED TO COHORT)
═══════════════════════════════════════════════════════════════════════════════════════════════════

The Quickstart is email-only. LinkedIn outreach lives in the cohort because:

  • HeyReach has no one-shot "send connection request" API — it works by adding
    leads to an existing campaign that you've configured. That's a lot of setup
    to demonstrate as a single channel-proof step.
  • Unipile (the direct alternative) needs its own auth + per-platform setup.
  • The cohort's D20 `linkedin_outreach` skill covers both patterns properly.

For this step we record `linkedin_channel: deferred` in the wired file so the
verifier and finale know LinkedIn was intentionally not wired here.

  LINKEDIN_CHANNEL="deferred"
  LINKEDIN_CONNECTION_REQUEST_ID=""
  LINKEDIN_SKIP_REASON="quickstart-is-email-only-see-cohort-d20"

Print:
  "Skipping LinkedIn — covered in the cohort (D20 linkedin_outreach).
  Email-only is the right scope for the Quickstart."

─── SAVE WIRED FILE ──────────────────────────────────────────────────────────────────────────────

Write data/.outreach-wired.json with all connection details:

  mkdir -p data

  INBOX_IDS_JSON=$(printf '%s\n' "${INBOX_IDS[@]}" | jq -R . | jq -s .)

  jq -n \
    --arg domain "$SENDING_DOMAIN" \
    --arg domain_id "${DOMAIN_ID:-}" \
    --argjson inbox_ids "${INBOX_IDS_JSON}" \
    --arg primary_inbox_id "$PRIMARY_INBOX_ID" \
    --arg api_key_hash "$API_KEY_HASH" \
    --arg webhook_id "$WEBHOOK_ID" \
    --arg webhook_status "${WEBHOOK_STATUS:-active}" \
    --arg test_send_message_id "$TEST_SEND_MESSAGE_ID" \
    --arg test_webhook_received "$WEBHOOK_TEST_TIMESTAMP" \
    --arg linkedin_channel "$LINKEDIN_CHANNEL" \
    --arg linkedin_connection_request_id "${LINKEDIN_CONNECTION_REQUEST_ID:-}" \
    --arg linkedin_skip_reason "${LINKEDIN_SKIP_REASON:-}" \
    --arg wired_at "$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
    '{
      domain: $domain,
      domain_id: $domain_id,
      inbox_ids: $inbox_ids,
      primary_inbox_id: $primary_inbox_id,
      api_key_hash: $api_key_hash,
      webhook_id: (if $webhook_id == "" then null else $webhook_id end),
      webhook_status: $webhook_status,
      test_send_message_id: $test_send_message_id,
      test_webhook_received: $test_webhook_received,
      linkedin_channel: $linkedin_channel,
      linkedin_connection_request_id: (if $linkedin_connection_request_id == "" then null else $linkedin_connection_request_id end),
      linkedin_skip_reason: (if $linkedin_skip_reason == "" then null else $linkedin_skip_reason end),
      wired_at: $wired_at
    }' > data/.outreach-wired.json

Print:
  "Saved data/.outreach-wired.json."

─── COMPLETE ─────────────────────────────────────────────────────────────────────────────────────

Update state.json:

  jq --arg now "$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
     'if (.completed_steps | contains(["send_outreach"])) then . else
       .completed_steps += ["send_outreach"]
     end | .last_run_at = $now' \
     ~/.claude/skills/quickstart/state.json > /tmp/qs_outreach.json \
     && mv /tmp/qs_outreach.json ~/.claude/skills/quickstart/state.json

  jq --arg next "ship_test" \
     '.current_step = $next' \
     ~/.claude/skills/quickstart/state.json > /tmp/qs_outreach_next.json \
     && mv /tmp/qs_outreach_next.json ~/.claude/skills/quickstart/state.json

Print:

  Outreach channels wired.

    Email infrastructure (AgentMail):
      Domain:        $SENDING_DOMAIN
      Inboxes:       ${#INBOX_IDS[@]} (warming now — 14-21 days)
      Test send:     landed in $USER_EMAIL ✓
      Reply webhook: registered (ID: $WEBHOOK_ID) ✓

    LinkedIn channel: deferred — covered in cohort D20 (linkedin_outreach)

    State saved:   data/.outreach-wired.json

  Your mailboxes are warming. AgentMail handles this automatically — no action
  needed. After ~14 days the inboxes are ready for cold outreach.

  When you're ready to send, come back and run:
    /quickstart goto ship_test

  Or type `continue` now to move to ship_test.

For any other input — a question, a partial answer, "let me think" —
treat it conversationally per SKILL.md's "Input Handling" section. Answer
questions in 2-4 paragraphs grounded in GTM-engineer language, then re-print
the menu/prompt above. The buyer is here to learn — let them wander.
─── RECOVERY MENU ────────────────────────────────────────────────────────────────────────────────

If user types `help` at any point, print:

  help — recovery options for step `send_outreach`:

    1  open the LMS step page (full SOP, transcript, troubleshooting)
    2  reset this step (start from the top)
    3  skip this step (mark incomplete — ship_test will still run but no outreach
       channels will be wired)
    4  quit the adventure (your progress is saved)
  Type 1, 2, 3, or 4:

Handle each:
  1 → run: open https://learn.maestrogtm.com/learn/qs/send-outreach
      Print: "LMS page opened. Come back here and type `continue` when ready."

  2 → remove send_outreach from completed_steps in state.json, re-run from STEP INTRO:
        jq '.completed_steps = [.completed_steps[] | select(. != "send_outreach")]' \
           ~/.claude/skills/quickstart/state.json > /tmp/qs_reset.json \
           && mv /tmp/qs_reset.json ~/.claude/skills/quickstart/state.json
      Print: "Step reset. Starting from the top."

  3 → jq --arg now "$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
           '.skipped_steps += ["send_outreach"] | .current_step = "ship_test" | .last_run_at = $now' \
           ~/.claude/skills/quickstart/state.json > /tmp/qs_skip.json \
           && mv /tmp/qs_skip.json ~/.claude/skills/quickstart/state.json
       Print: "Skipped outreach wiring. You can return with /quickstart goto send_outreach.
       ship_test will run but you won't have live sending or LinkedIn channels yet."
       Advance to ship_test.

  4 → jq --arg now "$(date -u +%Y-%m-%dT%H:%M:%SZ)" '.last_run_at = $now' \
           ~/.claude/skills/quickstart/state.json > /tmp/qs_quit.json \
           && mv /tmp/qs_quit.json ~/.claude/skills/quickstart/state.json
       Print: "Progress saved. Resume with: claude → /quickstart continue"
       STOP.
       Wait for `continue` or `quit`.

For any other input — a question, a partial answer, "let me think" —
treat it conversationally per SKILL.md's "Input Handling" section. Answer
questions in 2-4 paragraphs grounded in GTM-engineer language, then re-print
the menu/prompt above. The buyer is here to learn — let them wander.
