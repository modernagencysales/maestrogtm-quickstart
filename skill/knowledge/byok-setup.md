# BYOK setup — bring your own provider keys

For buyers who already pay for Apollo / Hunter / Crustdata / PeopleDataLabs /
Smartlead / etc. and want Deepline to USE those subscriptions instead of
charging managed credits.

**The economic case:**
- Apollo: $99/seat/month for unlimited search + enrichment
- Without BYOK: each enrichment call costs Deepline managed credits (~$0.17
  per Apollo people-match call at $0.10/credit)
- With BYOK: $0 per call. Deepline charges nothing for orchestration; you
  pay your provider directly per their usual contract.

For teams already paying for these tools, BYOK pays for itself the moment
you run any meaningful enrichment volume.

---

## How to wire BYOK keys (concrete walkthrough)

This happens at `https://deepline.app/integrations` (browser; one-time setup
per provider key). The agent should NOT do this for the buyer — they paste
their key into Deepline's web UI, not into the CLI.

Walk the buyer through it:

1. **Open the integrations page** (in the buyer's browser):
     `https://deepline.app/integrations`

2. **Pick the provider** they want to BYOK. Common ones:
   - Apollo (paid Apollo accounts; needs `master api key` from Apollo
     settings → API)
   - Hunter (Hunter dashboard → API → personal access token)
   - Crustdata (Crustdata dashboard → API key)
   - PeopleDataLabs (PDL console → API keys)
   - ZeroBounce (ZB dashboard → API keys; for email validation)
   - HeyReach (HeyReach → settings → API)
   - Smartlead, Lemlist, Instantly (per-platform; their API key page)

3. **Paste the key.** Deepline encrypts it and uses it ONLY when the buyer
   calls a tool that maps to that provider. Deepline does NOT store the
   key in plaintext or read its contents.

4. **Verify the wiring.** Run a tiny call from the CLI to confirm the
   provider answers via the BYOK route:
     ```
     deepline tools execute hunter_email_finder \
       --payload '{"first_name":"<known>","last_name":"<known>","domain":"<known-domain>"}' \
       --json --wait --wait-timeout 30
     ```
   Inspect the response. The `credential_source` field in the response
   should say `byok` (not `managed`). If it says `managed`, the key didn't
   wire — re-check on deepline.app.

5. **Verify your bill.** Run `deepline billing balance --json` BEFORE and
   AFTER the call. If BYOK is wired, your Deepline credit balance should
   NOT decrease (you're paying your provider, not Deepline).

---

## What providers stay paid even with BYOK?

Some Deepline tools are FREE through managed credits AND don't have a
BYOK alternative because there's no underlying paid API:
- `dropleads_search_people` — free either way
- `dropleads_get_lead_count` — free either way
- `dropleads_mobile_finder` — free either way

Some Deepline tools are deepline-native (no third-party provider underneath):
- `deepline_native_search_contact`
- `name_to_linkedin_url_waterfall` (waterfall across multiple providers)

For waterfalls: each STEP in the waterfall checks for BYOK on its
underlying provider. If you BYOK Hunter but not Findymail, the
`name_and_domain_to_email_waterfall` will use your Hunter key (free) but
charge managed credits when it falls through to Findymail.

---

## Common questions

**"Can I see which call used BYOK vs managed credits?"**

Yes. Every tool execute response includes `credential_source: "byok" |
"managed" | "none"`. Aggregate at `https://deepline.app/usage`.

**"What if I have Apollo for one teammate but not another?"**

Deepline's BYOK is per-org, not per-user. The org's Apollo key (whoever
plugged it in) is what gets used. If you need per-user routing, that's
not in scope for BYOK; you'd run separate Deepline orgs.

**"Does BYOK work with the Quickstart's `dropleads_search_people` default?"**

Dropleads search is free either way, so BYOK doesn't change anything
for the Quickstart's first_workflow step. BYOK starts mattering when the
buyer runs the email-finder waterfall (Hunter / LeadMagic / Findymail
all have paid APIs that benefit from BYOK).

**"Can I YOLO and just plug in Apollo, run everything?"**

Yes. Apollo's `apollo_search_people_with_match` covers most of what
`dropleads_search_people` does at zero cost when you BYOK Apollo. The
Quickstart defaults to Dropleads because most BUYERS don't BYOK; if you
do, Apollo is fine and arguably better for company size < 50 (where
Dropleads has weak coverage).

---

## When the buyer asks about BYOK during the Quickstart

The conversation should look like:

  Buyer: "I already pay for Apollo. Can I plug my key in?"
  Agent: "Yes. Deepline supports BYOK — you paste your Apollo key at
          deepline.app/integrations and Deepline routes Apollo calls
          through your account at zero markup. Want me to walk you
          through it now (~3 min, browser opens once), or run the
          Quickstart on managed credits and switch later?"
  Buyer: "Walk me through it now."
  Agent: <reads this doc, walks through steps 1-5 above, asks if the
          credential_source verification returned 'byok' on the test
          call>
