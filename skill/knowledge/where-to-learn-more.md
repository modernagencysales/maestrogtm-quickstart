# Where to learn more — agent's knowledge index

This file is for YOU (Claude, the orchestrator). It is NOT for the buyer.

The buyer is a GTM engineer who paid $47 for the Quickstart. They want to
get hands-on value without being overwhelmed. The Quickstart prompts are
deliberately lean. When the buyer asks something deep ("how do I really
pick an ICP?", "why this provider over that one?", "what does warmup
actually do?"), DO NOT improvise from your own training. Instead:

1. Identify which canonical doc covers it (use the table below).
2. Read that doc with `Read`.
3. Summarize the relevant 2-4 paragraphs IN THE BUYER'S TERMS — GTM-engineer
   language, no CS jargon, analogies they know (Clay, Apollo, Smartlead,
   Gmail, Zapier).
4. Offer the full source as a follow-up: "If you want the deeper version,
   it's in the Bootcamp at https://dwy-playbook.vercel.app/sops/..."
5. Re-print the step's prompt so they know where they were.

Goal: agent has access to the whole library. Buyer sees only the slice that
helps them right now. No walls of text.

---

## Question → source map

| Buyer asks about | Canonical source | Public URL (offer to buyer) |
|---|---|---|
| **Fundamentals** — "what's a database / API / CLI / git / .env / schema / idempotent / JSON / webhook?" | `~/.claude/skills/quickstart/knowledge/fundamentals-glossary.md` | (internal — load at session start, summarize on demand) |
| **Stack architecture** — what's a GTM stack, why these layers | `~/Documents/claude code/mas-platform/docs/onboarding/GTM-CHANNELS.md` | (internal — summarize, don't link) |
| **What is Maestro** — the platform overall | `~/Documents/claude code/mas-platform/docs/MAESTRO-OVERVIEW.md` | (internal) |
| **ICP definition / Caroline Framework** | `~/Documents/claude code/dwy-playbook/docs/sops/module-0-positioning/sop-0-1-define-icp.md` | https://dwy-playbook.vercel.app/sops/module-0-positioning/sop-0-1-define-icp |
| **Anti-ICP / who NOT to target** | sop-0-1 (same doc, step 6) | same |
| **Lead magnet ideation** | `dwy-playbook/docs/sops/module-1-lead-magnets/sop-1-1-ideate-lead-magnet.md` | https://dwy-playbook.vercel.app/sops/module-1-lead-magnets/sop-1-1-ideate-lead-magnet |
| **Funnel building** | `dwy-playbook/.../sop-1-3-build-funnel.md` | (Module 1) |
| **TAM building (LinkedIn export)** | `dwy-playbook/.../module-2-tam-building/sop-2-1-export-connections.md` | (Module 2) |
| **Sales Navigator search** | `dwy-playbook/.../sop-2-2-sales-navigator-search.md` | (Module 2) |
| **Email enrichment waterfall** — what providers, what order, what hit rate | `dwy-playbook/.../sop-2-4-email-enrichment-waterfall.md` | https://dwy-playbook.vercel.app/sops/module-2-tam-building/sop-2-4-email-enrichment-waterfall |
| **Validate emails** — bounce checks, catch-all detection | `dwy-playbook/.../sop-2-5-validate-emails.md` | (Module 2) |
| **Detect activity / segment** — who's actually active on LinkedIn | `dwy-playbook/.../sop-2-6-detect-activity-segment.md` | (Module 2) |
| **HeyReach / LinkedIn outreach setup** | `dwy-playbook/.../sop-3-1-heyreach-connection.md` | (Module 3) |
| **Message matching** — which opener for which prospect | `dwy-playbook/.../sop-3-2-message-matching.md` | (Module 3) |
| **DM campaigns to existing connections** | `dwy-playbook/.../sop-3-5-dm-campaign-existing-connections.md` | (Module 3) |
| **Cold email mailbox provisioning** | `dwy-playbook/.../module-4-cold-email/sop-4-1-provision-zapmail.md` | (Module 4) |
| **Mailbox warmup — why 14-21 days, what happens** | `dwy-playbook/.../sop-4-2-warmup-plusvibe.md` | https://dwy-playbook.vercel.app/sops/module-4-cold-email/sop-4-2-warmup-plusvibe |
| **Cold email campaign strategy** — Three Pillars, 10 Angles, 4-Email Sequence, response-rate benchmarks, decision framework | `~/.claude/skills/quickstart/knowledge/cold-email-architect.md` | (internal — the methodology playbook for ai_personalize) |
| **Cold email copy** | `dwy-playbook/.../sop-4-3-write-cold-email-copy.md` | (Module 4) |
| **Cold email launch** | `dwy-playbook/.../sop-4-4-launch-cold-email.md` | (Module 4) |
| **LinkedIn ads setup** | `dwy-playbook/.../module-5-linkedin-ads/sop-5-1-setup-linkedin-ads.md` | (Module 5) |
| **Daily operating rhythm** | `dwy-playbook/.../module-6-operating-system/sop-6-1-daily-operating-rhythm.md` | (Module 6) |
| **Weekly review** | `dwy-playbook/.../sop-6-2-weekly-review.md` | (Module 6) |
| **Full-funnel orchestration** | `dwy-playbook/.../sop-6-4-full-funnel-orchestration.md` | (Module 6) |
| **Daily content from transcripts** | `dwy-playbook/.../module-7-daily-content/sop-7-1-load-transcripts.md` | (Module 7) |
| **Bootcamp FAQ** — common buyer questions | `dwy-playbook/docs/reference/faq.md` | https://dwy-playbook.vercel.app/reference/faq |
| **What is each tool / product** | `dwy-playbook/docs/reference/tools-and-products.md` | https://dwy-playbook.vercel.app/reference/tools-and-products |
| **BYOK setup — wire your own Apollo/Hunter/etc keys** | `~/.claude/skills/quickstart/knowledge/byok-setup.md` | (internal — walk the buyer through) |
| **CRM sync — push contacts to Salesforce/HubSpot/Attio** | `~/.claude/skills/deepline-gtm/provider-playbooks/{salesforce,hubspot,attio}.md` | (internal — show the buyer the right tools) |
| **Multi-seat / team economics** — what does this cost at scale? | `~/.claude/skills/quickstart/knowledge/multi-seat-economics.md` | (internal — show the math, never a single number) |
| **Team handoff** — onboarding teammates / SDRs Day 2 | `~/.claude/skills/quickstart/knowledge/team-handoff.md` | (internal — give them the script + shared/per-user table) |
| **Spend caps + safeguards** — how to set a hard ceiling | covered in `multi-seat-economics.md` and `wire_deepline.md` (default offered upfront) | — |
| **Cost preview / dry-run** — see cost ceiling before paying | `deepline enrich --dry-run` (built into the CLI; first_workflow uses it) | — |

## Provider-specific questions (route to deepline-gtm)

When the buyer asks about a SPECIFIC provider — its tradeoffs, schema, gotchas,
when to use it — load `~/.claude/skills/deepline-gtm/provider-playbooks/<provider>.md`.

The full set: adyntel, ai_ark, apify, apollo, attio, bettercontact, bloomberry,
builtwith, cloudflare, contactout, crustdata, dataforseo, datagma,
deepline_native, deeplineagent, discolike, dropleads, exa, findymail,
firecrawl, forager, fullenrich, generic_http, heyreach, hubspot, hunter,
icypeas, instantly, ipqs, leadmagic, lemlist, linkedin_ads_audiences,
linkedin_scraper, lusha, openwebninja, parallel, peopledatalabs, prospeo,
rocketreach, salesforce, serper, slack, smartlead, snowflake, theirstack,
trestle, wiza, zerobounce.

For "which provider should I use" cross-cutting questions, load:
- `~/.claude/skills/deepline-gtm/finding-companies-and-contacts.md` (ROI order)
- `~/.claude/skills/deepline-gtm/enriching-and-researching.md`
- `~/.claude/skills/deepline-gtm/writing-outreach.md`

## How to use this index

**Don't dump the whole table at the buyer.** When they ask about X:

1. Match the question to one or two rows.
2. Read those source files.
3. Compose a 2-4 paragraph answer using ONLY the parts that answer their
   specific question. Cut everything else.
4. Offer the public URL for follow-up if they're a Bootcamp candidate, or
   "I can dig deeper if you want" if they're an internal-doc topic.
5. Re-print the step's prompt so they know where they were.

**Examples of how to phrase the depth offer:**
- "If you want to go deeper, the Bootcamp covers this in [Module 2, SOP
  2-4](https://dwy-playbook.vercel.app/...) — that's the cohort version with
  more provider-specific detail."
- "There's a longer breakdown if you want — say `more on this` and I'll
  pull it up. Otherwise, ready to keep going?"

**Don't link to the same doc twice in one session** — once you've offered
the SOP for, say, ICP, the buyer knows where it is. Just keep moving.

## What this index is NOT

- Not a script. Don't read these docs unless the buyer asks something
  they cover.
- Not exhaustive. If the buyer asks something esoteric, fall back to your
  own knowledge + the deepline-gtm playbooks.
- Not for the buyer to read. This file is internal orchestrator scaffolding.

## Strategic framing the buyer should walk away with

What they did in the Quickstart maps to specific Bootcamp modules:

| Quickstart step | Maps to Bootcamp |
|---|---|
| kickoff (define ICP, generic 4-question version) | Module 0 (ICP — Caroline Framework, anti-ICP, Gobbledygook Test) |
| supabase_setup + schema_migrate | (no direct Bootcamp equivalent — Bootcamp uses Clay; the Quickstart is the agentic alternative) |
| wire_deepline + first_workflow | Module 2 (TAM building — Sales Nav, enrichment waterfalls, validation) |
| ai_personalize | Module 4 (cold email copy) + Module 7 (daily content w/ AI) |
| apply_formula | Pattern only — Bootcamp doesn't have a 1:1 |
| send_outreach | Module 4 (cold email — provision, warmup, launch) + Module 3 (LinkedIn — for ship path's optional channel) |
| finale | Module 6 (operating system — what to do daily/weekly with this stack) |

Use this map at the FINALE to position the cohort upsell concretely:
"You just experienced Modules 0, 2, and 4 of the Bootcamp at hyperspeed.
The cohort slows down, goes deep on each, and adds Modules 1, 3, 5, 6, 7
that we didn't touch today."
