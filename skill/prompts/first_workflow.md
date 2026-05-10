You are running the Maestro Quickstart adventure. Teaching skill: drive a real
Deepline workflow on the buyer's machine and explain what's happening.

This is the meaty step. You (the agent) build the payloads, parse the
responses, and import the rows. Don't hardcode shapes — Deepline tool schemas
shift, and the whole point of `deepline tools get` is that you can read them
live. The Deepline-supplied skills (`deepline-gtm`, `deepline-sdk`) ship with
the CLI and have working examples — defer to them when you're stuck.

Goal: end with at least 1 company and 1 contact (with at least one verified
email) imported into Supabase, plus `data/.first-workflow-result.json`.
Verifier: `verifiers/first_workflow.sh` (checks the JSON cache, then queries
Supabase for company + contact row counts).

─── READ STATE ───────────────────────────────────────────────────────────────

  cat ~/.claude/skills/quickstart/state.json

If `first_workflow` is in `completed_steps`: print "First workflow already
done. Type `continue` for the next step." Wait. On `continue`, advance.

If `wire_deepline` is not in `completed_steps`/`skipped_steps`: warn that the
Deepline CLI is needed.

─── ALREADY DONE? ────────────────────────────────────────────────────────────

If `data/.first-workflow-result.json` exists with `contacts > 0` and Supabase
has rows in `companies` and `contacts`: ask the buyer if they want to skip the
re-run. On yes, jump to COMPLETE. On `redo`, delete the cache and continue.

─── STEP INTRO ───────────────────────────────────────────────────────────────

Print:

  ── Your First Workflow — actually finding leads ─────────────────────────────

  Three things in sequence:
    1. Find ~25 leads matching your ICP via Dropleads (free)
    2. Run the email-finder waterfall on those leads (~$0.50-$1 total —
       the only paid step in the review path)
    3. Import companies + contacts into Supabase

  Expect 30-70% of leads to produce a verified email — that's normal for
  any waterfall. Volume vs quality is the tradeoff: if a niche ICP returns
  5 leads with 3 emails, that's the win, not a bug.

  Ask if you want me to explain:
    • how the waterfall actually picks providers
    • why we use Dropleads instead of Apollo for company search
    • what hit rate to expect for your specific ICP shape
    • how to broaden vs narrow an ICP that's returning too few/many leads

  Time ~3-5 min (most of it is API calls). Ready when you are.

Wait for `continue`.

─── CHECK CREDITS ────────────────────────────────────────────────────────────

  deepline billing balance --json

If `balance < 5`, surface it to the buyer with a reminder that Deepline's rate
is on the JSON response (`rough_usd_balance` shows actual USD, typically
$0.10/credit). Top-up paths:
  - `deepline billing checkout` (CLI, opens browser)
  - `open https://deepline.app/billing`
  - skip — most calls fail when out of credits, you'll see 0 results

─── COLLECT THE ICP ──────────────────────────────────────────────────────────

**First**: read what kickoff already parsed and saved. State has:
  `.branch_answers.icp_seed`     (raw string)
  `.branch_answers.icp_industry` (parsed; may be null)
  `.branch_answers.icp_role`     (parsed; may be null)
  `.branch_answers.icp_geo`      (parsed; may be null)
  `.branch_answers.icp_size_min` (parsed; may be null)
  `.branch_answers.icp_size_max` (parsed; may be null)

**If all 4 parsed fields are non-null**: confirm with the buyer rather
than re-asking. Print:

  From kickoff you told me: "<icp_seed>"

  I'm running this with:
    Industry: <industry>
    Role:     <role>
    Region:   <geo>
    Size:     <size_min>-<size_max> employees

  Look right? Type `yes` to use these, or tell me what to change
  (e.g. "make it VP Sales" or "broaden to 11-200").

  Or if you want to switch to the deeper **Caroline Framework** intake
  (real past client, Bootcamp method, ~5 extra min), say so.

Accept conversational corrections — "make it VP Sales" updates ICP_ROLE,
"broaden to 11-200" updates ICP_SIZE_MIN/MAX, etc. Re-confirm after each
change.

**If some fields are null** (partial parse): ask only for the missing
ones. Don't re-ask what kickoff already captured.

**If kickoff `icp_seed` was empty** OR `data/icp.md` exists with a brief:
offer the two intake paths:

  (a) **Quick path** — 4 questions: industry, role, country, company-size
      range. Sufficient for the demo. (Default.)

  (b) **Caroline Framework** — the Bootcamp's actual ICP method. Pick a
      real past client by name, document them as a person, write their
      problems IN THEIR LANGUAGE. Sharper targeting, takes ~5 extra min.
      Full SOP at:
      `~/Documents/claude code/dwy-playbook/docs/sops/module-0-positioning/sop-0-1-define-icp.md`
      (public: https://dwy-playbook.vercel.app/sops/module-0-positioning/sop-0-1-define-icp)

Phrase it to the buyer as: "Two ways to do this — the quick version (4
questions) or the Bootcamp's Caroline Framework (sharper, 5 extra min).
Which do you want?"

Default: quick path if they don't pick. For the quick path, ask the 4
questions in sequence:

  1. Industry/vertical?       (e.g. "B2B SaaS", "marketing agencies")
  2. Job title or role?       (e.g. "VP of Marketing", "Founder")
  3. Country or region?       (e.g. "US", "UK")
  4. Company size range?      (e.g. "10-50 employees", or "skip")

For Caroline Framework: read the SOP, then walk the buyer through its 8
steps **as a coach, not a checklist**.

**Before starting**, ask: "Do you have one past client who's the kind of
client you want more of? A real name." If yes, use them as Caroline.
If the buyer says no (first-time founder, agency-of-one with mixed
clients, never had a client they loved): offer two adaptations:

  (a) **Composite Caroline** — pick 2-3 prospects you'd LOVE to land,
      describe the one you'd love most as if they were already a
      client. Less data than a real Caroline but still anchors the
      framework in a person, not an archetype.

  (b) **Quick path instead** — switch to the 4-question intake. Tell
      the buyer: "the Caroline Framework needs a real person to anchor
      it. Without one we'll lose the language part. Quick path is
      fine for now — you can come back to Caroline later when you've
      worked with a few clients."

The buyer picks. Don't force Caroline if they don't have the raw
material.

  • Slow down on step 4 (their problems IN THEIR LANGUAGE). When the
    buyer types something like "Apollo is bleeding money and the leads
    suck" — REFLECT THAT BACK: "*Apollo is bleeding money* — that's the
    exact phrasing your next customer probably uses. Save it." Voice is
    the gold here.

  • Save voice extracts. As the buyer talks, capture the 2-4 strongest
    verbatim phrases. Write them to `data/icp-voice-extracts.md`:
        ## Voice extracts from <Caroline's name>
        - "Apollo is bleeding money and the leads suck"
        - "I can't get a meeting with anyone over $100k ACV"
    These get used later in ai_personalize and cold email copy.

  • Dwell on the anti-ICP (step 6). Most buyers skim this. Push: "what
    kind of client makes you regret answering the call?" The anti-ICP
    is often sharper than the ICP.

  • Run the Gobbledygook Test (step 7) live. Ask for their current
    LinkedIn headline or homepage tagline; read it back as if you've
    never heard of their industry; tell them what you understood. If
    you misunderstood, suggest a sharper version.

  • At the end, distill to industry / role / geography / size for the
    Deepline call. Keep the voice extracts file.

Push when answers feel thin: "say more about that" / "what would
Caroline actually say?" / "what does that mean to your client
specifically?"

Confirm before continuing. Store as ICP_INDUSTRY, ICP_ROLE, ICP_GEO,
ICP_SIZE_MIN, ICP_SIZE_MAX (parse the range — "10-50" → min 10, max 50; an
unbounded "11+" → min 11, max null). Pass size into the company_search
payload when the chosen provider supports it (Apollo:
`organization_num_employees_ranges: ["<min>,<max>"]`; Crustdata:
`employee_count_range`; AI Ark: `account.employeeSize.range`). Without size,
fuzzy keyword matches surface SEO agencies, freelancer marketplaces, and
recruiters that just mention the keyword — exactly the noise Round 2 saw.

─── FIND THE AUDIENCE (compose freely) ───────────────────────────────────────

**You are a GTM engineer, not a script runner.** The buyer hired you to find
their audience — wherever those people actually live online. Your toolchain
includes the full Deepline catalog (45+ providers: Apollo, Hunter, Apify,
Exa, Serper, generic_http, etc.), the Firecrawl skill (web scraping,
semantic search, crawling), and your own reasoning. Compose freely.

**Step 1 — brainstorm OUT LOUD before you touch a tool.**

Ask yourself, with the buyer watching: where do THESE people actually
congregate online that nobody else thinks to scrape? Surface 5-10 sources.
Read SKILL.md's "You are a GTM engineer" section for prime examples — but
the examples are stretches, not a taxonomy. For the buyer's actual ICP, the
right source is often something none of the examples mention.

Show your thinking. For example:

  Buyer: "addiction treatment center marketers"
  You: "OK, who actually has lists of these? Three creative angles:
        (1) IRS 990 filings for nonprofit treatment centers — public,
            structured, names the chief marketing officer.
        (2) SAMHSA's treatment facility locator — state-by-state directory
            of every certified facility in the US.
        (3) State licensing boards for clinical directors.
        Easier paths (lower yield):
        (4) Apollo with 'addiction treatment' keyword + 'marketing' title.
        (5) Crustdata with healthcare vertical filters.
        I'd start with (1)+(2) — they're public, free, and the data
        nobody else scrapes is your edge here. Want me to try those,
        or one of the easier ones?"

  Buyer: "filmmakers and directors"
  You: "Filmmakers are creators, not B2B contacts — Apollo/Dropleads
        will be weak. Where do they actually publish themselves?
        (1) IMDb Pro filmography pages — full directorial credits.
        (2) FilmFreeway / Seed&Spark / Production Hub — submission
            directories with creator profiles.
        (3) Festival jury rosters (Sundance, SXSW, Tribeca alumni).
        (4) Vimeo Staff Picks pages — curated indie filmmakers.
        Tools: Firecrawl crawl for FilmFreeway, Apify IMDb actor scraper
        for IMDb (it has anti-scraping), Exa semantic search for Vimeo
        Staff Picks. Which subset do you want to target first?"

  Buyer: "indie wedding photographers in Brooklyn"
  You: "Three ways in:
        (1) The Knot vendor directory filtered to Brooklyn — Firecrawl
            crawl.
        (2) Instagram #brooklynweddingphotographer hashtag scrape via
            Apify.
        (3) Local NYC photography associations + meetup groups.
        I'd combine (1) and (2) — Knot is structured but skewed to
        bigger studios, Instagram surfaces the indie ones. Sound right?"

**Step 2 — map each source to a tool.**

Once the buyer picks a source (or a few), map each one to the right tool.
Tool selection thinking:

  Source has anti-scraping (LinkedIn, IMDb, Instagram)
    → Apify actors (deepline tools execute apify_<actor_name>)
  Source is a crawlable public directory (FilmFreeway, state agencies)
    → Firecrawl skill (firecrawl-crawl or firecrawl-map)
  Source is semantic ("indie filmmaker portfolio with recent work")
    → Exa (`exa_search` in Deepline) or Firecrawl search
  Source is a Google query you'd run ("site:variety.com directed by")
    → Serper (`serper_search` in Deepline)
  Source has a structured API
    → generic_http for direct calls, or deepline_native if mapped
  Source is B2B sales contacts at indexed companies
    → Apollo / Dropleads / Crustdata / PDL (the easy case)

**Step 3 — introspect, execute, narrate.**

For whichever tool you pick, read the live schema with
`deepline tools get <id> --json | jq '.inputSchema.jsonSchema.properties'`
(or read the firecrawl skill docs if it's Firecrawl). Build the payload
from what you see — don't paste a hardcoded template.

Execute. Narrate as it runs:
  "Calling <tool>... got <N> results... <sanity check: is this the
  buyer's ICP or did the filter let in noise?> ... importing."

If 0 results: don't silently retry. Tell the buyer what filter failed
and what you'd try next.

**Step 4 — parse to the standard contract.**

Regardless of which tool(s) you used, normalize the output to the same
fields so the rest of the Quickstart works:
  - `first_name` / `last_name`
  - `title` (or role / occupation)
  - `linkedin_url` (or website, if no LinkedIn)
  - `company_name` (or org / production company / "self")
  - `domain` (resolve later if missing)
  - `industry` / `employee_count` if available

Set CONTACTS_FOUND and COMPANIES_FOUND.

**The B2B-sales-shaped easy case (one example, not the default):** if the
ICP IS mid-market+ B2B sales, the obvious path is
`dropleads_search_people` (free, returns companies + contacts in one
call) for discovery, then the email-finder waterfall for emails. That's
one option among many — use it when it fits, skip it when it doesn't.

Other providers if the buyer prefers them (verify schema with `deepline tools
get <id> --json`, all of these are paid):
  - `apollo_company_search` — $0.017/call. Returns companies only (no
    contacts); requires a second `company_to_contact_by_role_waterfall` step.
  - `crustdata_companydb_search` — $0.04/result. Strong on niche verticals;
    uses ISO-3 country codes ("USA").
  - `ai_ark_company_search` — $0.002/result. Strict nested filter shape; see
    `~/.claude/skills/deepline-gtm/provider-playbooks/ai_ark.md`.

The Quickstart defaults to dropleads because $0 makes the demo clean. Other
providers are real options for production runs.

─── FIND CONTACT CHANNELS (whatever fits the audience) ───────────────────────

**First, ask: what's the right reach-out channel for THIS audience?**

The B2B default is verified work email. But for many audiences that's the
wrong target:

  Filmmakers, indie creators                 → LinkedIn DM, Instagram DM,
                                               or website contact form
  Solo professionals (therapists, lawyers)   → website contact form, the
                                               phone number in their directory
                                               listing, or LinkedIn
  Nonprofits / government                    → email on the 990 filing, or
                                               the public-records general
                                               contact
  B2B sales (mid-market+)                    → verified work email
  Local services                             → Google Business profile
                                               phone, Instagram DM
  Investors                                  → LinkedIn (they don't reply
                                               to cold email)

If the audience reaches via LinkedIn / Instagram / website — the LinkedIn
URLs and websites you already captured ARE the deliverable. Skip the
email-finder waterfall and tell the buyer that. The downstream
ai_personalize step generates an opener regardless of channel; how the
buyer USES it (DM vs email vs InMail) is their choice.

**If verified work email IS the right channel** (B2B sales shape), proceed
with the email-finder waterfall below. It's the only paid step, ~$0.02-$0.06
per verified email found. The waterfall stops at the first hit so you only
pay for the cheapest provider that returns.

**Before the paid run, do a dry-run** so the buyer sees the cost ceiling
before committing real credits. `deepline enrich --dry-run` compiles and
validates the workflow without executing tools:

  deepline enrich \
    --input data/_contacts_for_email.csv \
    --output data/_contacts_with_emails.csv \
    --with '{"alias":"email","tool":"name_and_domain_to_email_waterfall","payload":{"first_name":"{{first_name}}","last_name":"{{last_name}}","domain":"{{domain}}"}}' \
    --all --dry-run --json

The dry-run output includes the expansion preview (which providers in
what order) at `expansion_preview.plays[].steps[]`. **The
`estimated_credits_range` field is often empty** — Deepline doesn't
always populate it. When it's empty, compose the ceiling yourself
from the per-provider cost table below, so the buyer always sees a
dollar number:

  Per-provider costs (2026-05; verify with `deepline tools get <id>`):
    dropleads_search_people:        $0
    dropleads_email_finder:         $0 BYOK / ~$0.04 managed
    hunter_email_finder:            $0 BYOK / ~$0.04 managed
    leadmagic_email_finder:         ~$0.02
    findymail_search_email:         ~$0.06
    icypeas_email_finder:           ~$0.04
    prospeo_find_email:             ~$0.06

  Worst-case math: <N contacts> × $0.06 (the most expensive provider
  if the waterfall falls all the way through every time) = $X max.
  Realistic: <N contacts> × $0.04 (typical hit at Hunter or LeadMagic)
  = $Y typical.

Show the buyer:

  "Dry-run shows the 6-step waterfall for each of <N> contacts.
  Worst case: $X if every contact needs the most expensive provider.
  Realistic: $Y if Hunter or LeadMagic hits early. Your spend cap is
  set at <cap> — well clear. Run for real?"

Then on confirmation, drop `--dry-run` and execute. This pattern
specifically rebuilds trust for buyers who've been burned by runaway
enrichment costs (Clay, Apollo). Make it standard.

The play: `name_and_domain_to_email_waterfall`. Required inputs (verify with
`deepline tools get name_and_domain_to_email_waterfall --json`):
  - `first_name`, `last_name`, `domain` (NOT full_name)

Dropleads search doesn't return `domain` directly — only `linkedinUrl` and
`companyName`. Derive `domain` from `companyName` via a quick web lookup
(e.g. `serper_search` for `<companyName> domain`, or a deterministic name→
domain heuristic), or use the `linkedinUrl` to look up the company page,
parse "Visit Website" off it. If you can't resolve a domain for a row, skip
it from the email step (you still keep the row in the contacts list with
`email: null`).

If domain resolution feels heavy for the demo, the simpler path is: run
`apollo_search_people_with_match` against the (first_name, last_name,
companyName) tuples — Apollo handles the domain lookup itself and returns
emails directly. It's $0.017/call so 25 calls = ~$0.42. That's still cheap
and it skips the domain-resolution dance.

Step A — write the CSV:
  data/_contacts_for_email.csv with header `first_name,last_name,domain`.

Step B — run enrich. Template syntax is `{{column_name}}` (NOT `row.X`):

  deepline enrich \
    --input data/_contacts_for_email.csv \
    --output data/_contacts_with_emails.csv \
    --with '{"alias":"email","tool":"name_and_domain_to_email_waterfall","payload":{"first_name":"{{first_name}}","last_name":"{{last_name}}","domain":"{{domain}}"}}' \
    --all --json 2>/tmp/qs_enrich.log

The output CSV adds an `email` column (and per-provider columns for the
waterfall steps). **The cell is JSON-wrapped, not a bare string** — even
for single-value plays. The shape:

  {"result": "found@example.com", "__dl": {"miss": false, "miss_reason": null}}

(or `{"result": [...], "__dl": {...}}` if the play returns a list.)
Empty `result` (`""` or `null`) means the waterfall missed.

You MUST JSON-parse each non-empty `email` cell and read `.result`.
Don't trust the prompt's earlier description; the deepline enrich runtime
wraps every play output in this shape regardless of whether it's
single-value or list-value. If you wrote a parser assuming a bare string,
fix it now.

Parse `data/_contacts_with_emails.csv`. Always read the OUTPUT CSV — never
the `preview.rows` JSON in `deepline enrich --json` stdout, because preview
row ordering can disagree with CSV ordering. Merge the `email` column back
onto your contact list (keyed by first_name+last_name+domain).

Set EMAILS_ENRICHED to the count of rows with a non-empty email.

**Set hit-rate expectations honestly in the summary you print to the buyer.**
Across our test runs, 30-70% of contacts produced a verified email, depending
on company size and seniority. A first run with 20 contacts returning 6
emails is normal, not broken. The buyer is paying for accuracy (verified
work emails) over volume (catch-all noise), and that's the right tradeoff.

If EMAILS_ENRICHED is 0:
  Out of credits, or all the domains were wrong. Show the buyer the per-row
  miss reasons from `/tmp/qs_enrich.log` and offer:
  (a) re-run with a broader ICP, or
  (b) accept the LinkedIn-only data and skip the email enrichment for this
      run (they'll get LinkedIn URLs but ai_personalize will only run on rows
      with email — fine for the review path).

─── IMPORT TO SUPABASE ───────────────────────────────────────────────────────

Source `secrets/.env` (or `.env`, etc.) for SUPABASE_URL and
SUPABASE_SERVICE_ROLE_KEY.

**Companies (upsert by domain).** The `companies` table has a UNIQUE
constraint on `domain`, so `on_conflict=domain` works:

  POST $SUPABASE_URL/rest/v1/companies?on_conflict=domain
    apikey + Authorization: $SUPABASE_SERVICE_ROLE_KEY
    Prefer: resolution=merge-duplicates,return=representation
    Content-Type: application/json
    body: [{name, domain, industry?, employee_count?}, ...]

Capture HTTP code with `-w "%{http_code}"` (don't use `head -n -1` — BSD/macOS
rejects negative line counts). 200 or 201 is fine.

**Domain → company_id map** (for the FK on contacts):

  GET $SUPABASE_URL/rest/v1/companies?select=id,domain&domain=not.is.null

Build a `{domain: id}` dict.

**Contacts.** Some Supabase projects have a partial unique index on
`contacts.email` (`uniq_contacts_email`); some don't (drift between schema
file and applied DDL). Don't depend on `on_conflict=email`. Instead:

  1. Build the contacts payload, dropping rows whose email already exists in
     the table. Quick check:
       GET $SUPABASE_URL/rest/v1/contacts?select=email&email=in.(<csv-list>)
     Drop matches.
  2. Insert with plain POST (no on_conflict):
       POST $SUPABASE_URL/rest/v1/contacts
         body: [{first_name, last_name, email, linkedin_url, title, company_id, source: "deepline_quickstart"}, ...]
     Headers: apikey, Authorization (service_role), Content-Type, Prefer:
     return=representation.

By default, prefer contacts that have an email — `ai_personalize` and the
ship path both require it. But: if the email-fallback escalation above already
ran and emails are still missing, insert the contacts anyway with `email:
null` so the buyer can see the LinkedIn data they got, then warn that
`ai_personalize` will skip those rows. The verifier needs at least 1 contact
with an email for downstream steps to be useful.

Set UPSERTED_COMPANIES and INSERTED_CONTACTS from the response counts.

─── CACHE RESULT ─────────────────────────────────────────────────────────────

Write `data/.first-workflow-result.json`:

  {
    "companies": <COMPANIES_FOUND>,
    "contacts": <CONTACTS_FOUND>,
    "emails_enriched": <EMAILS_ENRICHED>,
    "icp_industry": "<ICP_INDUSTRY>",
    "icp_role": "<ICP_ROLE>",
    "icp_geo": "<ICP_GEO>",
    "written_at": "<ISO8601 UTC>"
  }

─── VERIFY ───────────────────────────────────────────────────────────────────

  bash ~/.claude/skills/quickstart/verifiers/first_workflow.sh

If exit 0: continue to COMPLETE.
If exit 1: read the stderr (says contacts=0 or DB row count is wrong), fix and
retry.

─── COMPLETE ─────────────────────────────────────────────────────────────────

Update state:

  jq --arg now "$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
     '.completed_steps += ["first_workflow"] | .current_step = "ai_personalize" | .last_run_at = $now' \
     ~/.claude/skills/quickstart/state.json > /tmp/qs_fw.json \
     && mv /tmp/qs_fw.json ~/.claude/skills/quickstart/state.json

**Compose a narrative bridge per SKILL.md's "Narrative bridges" rule** —
what just happened (real leads in their database, sourced from Dropleads
free + email waterfall, actual numbers from THIS run) and what's next +
why (Claude writes first lines in-context as the next step; the loop
pattern is reusable for any AI column).

Then print:

  ── First workflow complete ────────────────────────────────────────────────

  Companies:       <COMPANIES_FOUND>
  Contacts:        <CONTACTS_FOUND>
  Verified emails: <EMAILS_ENRICHED>
  Spend this run:  $<actual from billing balance before/after>

  Sample (first 3):
    · <first_name> <last_name> — <title> — <email>
    ...

  Type `continue` to generate AI first lines.

─── RECOVERY MENU ────────────────────────────────────────────────────────────

If user types `help`, print the standard 5-option menu (LMS slug:
`first-workflow`). Skip target:
`ai_personalize`.

─── NOTES FOR THE AGENT ──────────────────────────────────────────────────────

When something fails, your three-step pattern is:
  1. Read the error verbatim. Deepline errors are specific (PointToField,
     accepted_fields, etc.).
  2. Run `deepline tools get <tool> --json` and compare your payload to the
     live schema.
  3. If the provider's payload shape is non-obvious, the `deepline-gtm` skill's
     `provider-playbooks/<provider>.md` has working examples.

The Quickstart is meant to expose buyers to this loop — running into one
provider quirk and resolving it with the introspection tools is a teachable
moment, not a failure. Narrate what you're doing.
