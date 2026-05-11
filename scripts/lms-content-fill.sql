-- Fill in real text content for every lesson in Maestro Quickstart course.
-- Idempotent: DELETEs items by title before re-inserting so re-running updates.

BEGIN;

DO $$
DECLARE
  v_cohort_id UUID;
  v_lesson_id UUID;
  v_workspace UUID := '00000000-0000-0000-0000-000000000002';
BEGIN
  SELECT id INTO v_cohort_id FROM lms_cohorts WHERE name = 'Maestro Quickstart';

  -- Helper to fetch lesson IDs by (module title, lesson title)
  -- ============================================================
  -- Module 1, Lesson 1.1 — What you bought + install
  -- ============================================================
  SELECT l.id INTO v_lesson_id
  FROM lms_lessons l JOIN lms_weeks w ON w.id = l.week_id
  WHERE w.cohort_id = v_cohort_id
    AND w.title = 'Module 1 — Setup'
    AND l.title = 'What you bought + install';

  -- Replace any existing "Read along" and "If install fails" items
  DELETE FROM lms_content_items WHERE lesson_id = v_lesson_id AND title IN ('Read along — what you just bought', 'If the install fails');

  INSERT INTO lms_content_items (workspace_id, lesson_id, title, content_type, content_text, sort_order)
  VALUES (v_workspace, v_lesson_id, 'Read along — what you just bought', 'text',
E'## What the $47 actually buys

Four things, in order of importance:

1. **The agent** — a Claude Code skill at `~/.claude/skills/quickstart/`. Type `/quickstart` in Claude Code and it walks you through 11 steps: builds your database, finds + enriches contacts, drafts your campaign, wires email sending — all on your own machine.

2. **This LMS** — these videos and written notes. The agent does the work; this teaches you the *why* so you can run it again for new ICPs, new offers, new campaigns.

3. **The npm package** — `@maestrogtm/quickstart`, public on the npm registry. The mechanism that drops the skill files onto your computer.

4. **Tim''s reviews** — after you complete a run, you can book a call (link in the finale lesson) and Tim will review your pipeline.

## How the pieces fit

- **Claude Code** is Anthropic''s agentic coding tool — CLI, desktop app, or IDE extension. Different from the Claude chat app at claude.ai.
- **Skills** live at `~/.claude/skills/` on your computer. They extend what Claude Code can do.
- **Our skill** is in `~/.claude/skills/quickstart/` — the orchestrator (`SKILL.md`), step prompts, shell verifiers, and reference knowledge files.
- **`/quickstart`** is the slash command that triggers the agent.

## What you''ll have at the end

- Your own Supabase Postgres database (yours, not rented)
- A working enrichment pipeline using Deepline''s 1,000+ tool catalog
- A real cold-email campaign — offer, angle, sequence — drafted with the Growth Engine X playbook
- AgentMail wired end-to-end with mailboxes warming for the next 14-21 days
- A reply webhook that drops responses into your database automatically

Everything is on your machine. Nothing renews unless you opt into AgentMail''s paid tier later.', 5)
  ON CONFLICT DO NOTHING;

  INSERT INTO lms_content_items (workspace_id, lesson_id, title, content_type, content_text, sort_order)
  VALUES (v_workspace, v_lesson_id, 'If the install fails', 'text',
E'## When something goes wrong

The bootstrap script handles 95% of install failures automatically (missing Node, missing Homebrew, orphaned nvm installs, wrong PATH, etc). If yours is in the other 5%, you have two choices:

### Option 1 — Just ask Claude Code to fix it

Open Claude Code (terminal or desktop app), paste this exact prompt:

```
I''m trying to install Node.js 18+ on this machine so I can run
`npx @maestrogtm/quickstart` but the install is failing. Diagnose
and fix it. Don''t ask me unnecessary questions — investigate first,
then propose the fix.

1. Investigate:
   - uname -a, sw_vers, arch, echo $SHELL, echo $PATH
   - which node, which npm, which npx, node --version
   - which brew, xcode-select -p
   - ls -la ~/.nvm/versions/node ~/.fnm ~/.volta ~/.asdf/installs/nodejs /opt/homebrew/bin/node /usr/local/bin/node 2>&1
   - grep -E "node|nvm|brew|fnm|volta|asdf" ~/.zshrc ~/.bash_profile ~/.bashrc ~/.profile 2>/dev/null

2. Try install paths in order:
   - Path A: Homebrew clean install (brew install node)
   - Path B: Official Node .pkg installer from nodejs.org
   - Path C: nvm fallback (curl https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.1/install.sh | bash, then nvm install --lts)

3. Common gotchas to handle automatically:
   - Xcode CLT missing: xcode-select --install (GUI dialog — alert me)
   - Apple Silicon Mac but Intel brew: uninstall + install ARM brew
   - PATH not picking up node: fix the shell rc and source it
   - nvm installed but never wired to .zshrc: append the standard nvm block

4. Once Node works:
   - Run: npx -y @maestrogtm/quickstart@latest install
   - Verify: ls ~/.claude/skills/quickstart/SKILL.md

5. Report: state before, which path worked, final node --version, anything weird.

Pause only for password/GUI prompts. Otherwise just run things.
```

This prompt is the same diagnostic flow the bootstrap script tries to do — but with Claude''s reasoning on top, so it can adapt to anything weird about your specific machine.

### Option 2 — Email support@modernagencysales.com

Include:
- The output of: `uname -a && which node && which brew`
- A screenshot of the error
- What you''ve already tried

We''ll get back to you within a business day.', 6)
  ON CONFLICT DO NOTHING;

  -- ============================================================
  -- Module 1, Lesson 1.2 — Supabase signup + PAT
  -- ============================================================
  SELECT l.id INTO v_lesson_id FROM lms_lessons l JOIN lms_weeks w ON w.id = l.week_id
  WHERE w.cohort_id = v_cohort_id AND w.title = 'Module 1 — Setup' AND l.title = 'Supabase signup + PAT';
  DELETE FROM lms_content_items WHERE lesson_id = v_lesson_id AND title = 'Read along — Supabase';

  INSERT INTO lms_content_items (workspace_id, lesson_id, title, content_type, content_text, sort_order)
  VALUES (v_workspace, v_lesson_id, 'Read along — Supabase', 'text',
E'## What a database actually is

A database is a structured place to keep data — rows and columns that other software can query. Spreadsheets are databases (just not very good ones). Apollo, Clay, Smartlead all have databases inside them. The difference: when you use theirs, your data is locked inside their product. When you stop paying, the data is gone or held hostage.

Postgres is the most-used open-source database in the world. Supabase is hosted Postgres — they run the server, give you a web UI, handle backups. The free tier covers up to 500MB of data, which is roughly 50,000 enriched contacts.

You own this. The same data could move to AWS, Render, your laptop, or any other Postgres host with one export.

## What you''ll do in this lesson

1. **Sign up at supabase.com** — email + password. 90 seconds.
2. **Verify your email** — click the link they send you. 30 seconds (sometimes the email takes a minute).
3. **Generate a Personal Access Token** — Supabase dashboard → Account → Access Tokens → "Generate new token". Name it `maestro-quickstart`. Copy it. 30 seconds.
4. **Paste the PAT into the agent** — the agent is waiting in your terminal. Paste, hit enter.
5. **Watch the agent take over** — it creates a Supabase organization, creates a project, waits for it to provision, then fetches the anon + service-role keys and writes them to `secrets/.env`. About 30 seconds.

## What''s a Personal Access Token (PAT)?

A long random string that lets software act on your behalf. Supabase has two interfaces:
- **Dashboard** — for humans, clicks and forms
- **Management API** — for programs

The PAT is what makes the agent able to call the Management API *as you* without needing your password. You generate it once; you can revoke it anytime in the same Supabase Account settings page.

## Why this is the only browser step

Supabase signup requires a real email and a real click on a verification link. No API can do that for you — that''s by design, prevents abuse. After you have the PAT, everything else is automated.

## Common questions

- **Do I need a credit card?** No. The free tier doesn''t ask for one.
- **What if I already have a Supabase account?** Skip the signup, just generate a new PAT.
- **What gets saved to my computer?** The PAT, your project''s anon key, and service-role key — all in `secrets/.env`, which is `.gitignore`d so you won''t accidentally commit it.', 5)
  ON CONFLICT DO NOTHING;

  -- ============================================================
  -- Module 2, Lesson 2.1 — The 28 tables
  -- ============================================================
  SELECT l.id INTO v_lesson_id FROM lms_lessons l JOIN lms_weeks w ON w.id = l.week_id
  WHERE w.cohort_id = v_cohort_id AND w.title = 'Module 2 — Data Layer' AND l.title = 'The 28 tables and what they''re for';
  DELETE FROM lms_content_items WHERE lesson_id = v_lesson_id AND title = 'Read along — the schema';

  INSERT INTO lms_content_items (workspace_id, lesson_id, title, content_type, content_text, sort_order)
  VALUES (v_workspace, v_lesson_id, 'Read along — the schema', 'text',
E'## Why 28 tables

Every cold-email tool has a hidden data model. Apollo has one. Smartlead has one. Clay has one. The reason your data feels stuck inside those tools is that *they* designed the model. We''re applying a GTM-shaped schema *you* control and can extend.

## The four table groups

**1. People & companies** — who exists in your world
- `contacts` — individuals (name, email, title, LinkedIn URL, etc.)
- `companies` — organizations (name, domain, size, industry)
- `relationships` — how contacts connect to companies

**2. Campaigns & sends** — what you sent and what happened
- `campaigns` — a campaign (name, ICP, offer, sequence)
- `messages` — every individual email send
- `message_events` — opens, clicks, bounces, replies (one row per event)

**3. Replies & routing** — what came back
- `replies` — the raw inbound emails
- `reply_classifications` — categorized (positive, objection, bounce, unsubscribe, OOO)

**4. Context layer** — things you''ve learned that don''t fit elsewhere
- `notes` — freeform observations about contacts
- `signals` — buying triggers (recent hires, recent funding, tech changes)
- `enrichments` — third-party data attached to contacts (Crustdata firmographics, etc.)

The other 16 tables handle: list management, segments, ICP definitions, AI personalization caches, sequence state, suppression lists, team members (for when you scale past one person), and a handful of auth/audit tables.

## You won''t use most of them on day one

That''s fine. They''re shaped so that every additional thing you do later (LinkedIn outreach, ads, content, reply automation) plugs in cleanly without re-architecting. You couldn''t add LinkedIn outreach to Apollo''s database — you''d have to bolt on a separate tool. Here, you just write rows.

## Migrations — what the agent is actually doing

A "migration" is a SQL file that creates or alters tables. The agent runs the migration through Supabase''s Management API. If you ever need to add a column later, you write another migration — you don''t edit live data, you add a new version.

## What you''ll do in this lesson

1. The agent shows you the migration list (one big migration for the initial setup)
2. You hit `y` to apply
3. The Management API runs the SQL in ~20 seconds
4. You refresh the Supabase Table Editor and see all 28 tables appear

## Common questions

- **Can I edit the schema?** Yes — but write a new migration, don''t hand-edit tables in the dashboard. The agent will pick up your migrations automatically.
- **What if I already have a Supabase project for something else?** Don''t use that one. Make a fresh project for this. Supabase free tier covers two projects.
- **Does this cost anything?** No. Schema migrations don''t consume resources beyond the storage they create.', 2)
  ON CONFLICT DO NOTHING;

  -- ============================================================
  -- Module 2, Lesson 2.2 — Deepline
  -- ============================================================
  SELECT l.id INTO v_lesson_id FROM lms_lessons l JOIN lms_weeks w ON w.id = l.week_id
  WHERE w.cohort_id = v_cohort_id AND w.title = 'Module 2 — Data Layer' AND l.title = 'Deepline — one key, 1000+ tools';
  DELETE FROM lms_content_items WHERE lesson_id = v_lesson_id AND title = 'Read along — Deepline';

  INSERT INTO lms_content_items (workspace_id, lesson_id, title, content_type, content_text, sort_order)
  VALUES (v_workspace, v_lesson_id, 'Read along — Deepline', 'text',
E'## The problem Deepline solves

When agencies build a cold-email setup, they end up paying for:
- Apollo (~$99/mo) — firmographic data
- Hunter (~$49/mo) — email enrichment
- Clearbit (~$99/mo) — company enrichment
- Crustdata (~$300/mo) — hiring + funding signals
- Apify usage (~$30/mo) — LinkedIn scraping
- A few more depending on the stack

Five different bills, five different APIs, five different rate limits. The integration glue between them is its own full-time job.

## What Deepline is

Deepline aggregates 1,007 data tools behind one API and one auth. You call `deepline tools call dropleads_search_people` — you get people. `apollo_search_people` — different people, same auth. `firecrawl_scrape` — scraping. `crustdata_company_search` — firmographics.

Same key, same billing, same logs.

## Two ways to pay through Deepline

1. **Managed credits** — load $20, run searches, Deepline marks them up slightly (~10-20%). Frictionless for getting started.
2. **BYOK (Bring Your Own Keys)** — if you already pay Apollo or Hunter, you paste your existing keys into Deepline. Your calls go through Deepline''s API but Apollo/Hunter bills you directly. Zero markup. Covered in a later video (BYOK setup).

For this Quickstart we start with managed credits. You can switch to BYOK later in minutes.

## The spend cap (important)

Before any paid call, the agent runs `deepline billing --set-monthly-limit 50`. That''s a hard $50/month ceiling. If a search would push you over, Deepline rejects the call. You can''t accidentally spend $400 in the middle of the night because a script went haywire.

Raise or lower the cap anytime: `deepline billing --set-monthly-limit 100` (etc.).

## What you''ll do in this lesson

1. **Sign up at deepline.app** — Google OAuth, one click.
2. **Generate an API key** — Dashboard → API Keys → Generate.
3. **Paste it into the agent** — the agent verifies the key with a free search call before saving.
4. **Watch the spend cap get set automatically** — the agent runs the billing limit command first thing.

## Common questions

- **Do I need a credit card?** Only if you want to use managed credits past the free tier search calls. The Quickstart doesn''t spend more than ~$2-5 in real runs.
- **What happens at the $50 cap?** Deepline rejects further paid calls until next month. Free searches still work.
- **BYOK is free — why use managed credits?** Setup speed. BYOK requires you to already have accounts at Apollo/Hunter/etc. Managed credits = zero prior setup, you pay slightly more per call.', 3)
  ON CONFLICT DO NOTHING;

  -- ============================================================
  -- Module 3, Lesson 3.1 — First workflow
  -- ============================================================
  SELECT l.id INTO v_lesson_id FROM lms_lessons l JOIN lms_weeks w ON w.id = l.week_id
  WHERE w.cohort_id = v_cohort_id AND w.title = 'Module 3 — Build a List' AND l.title = 'Your first list (the agent thinks out loud)';
  DELETE FROM lms_content_items WHERE lesson_id = v_lesson_id AND title = 'Read along — building a list';

  INSERT INTO lms_content_items (workspace_id, lesson_id, title, content_type, content_text, sort_order)
  VALUES (v_workspace, v_lesson_id, 'Read along — building a list', 'text',
E'## Why this is the most important lesson

The single biggest lever in cold email is **who you send to**. Not what you send, not when, not how. Who. A great email to the wrong list does nothing. A mediocre email to the right list books meetings.

Most cold-email courses spend 80% of their time on copy. We spend 20% on copy and 80% on list. This is on purpose.

## What an ICP actually is

Ideal Customer Profile — the specific person you want in front of, narrow enough that two people in your team would describe them the same way.

Strong ICP: *"VPs of Marketing at B2B SaaS companies, US, 50-200 employees, post-Series-A."*

Weak ICP: *"Marketing people."* (Two people would interpret this differently.)

The strongest ICPs are usually narrower than the buyer initially thinks. Better to send 200 emails to a tight ICP than 2,000 to a loose one.

## The enrichment waterfall

Finding someone''s name is easy. Finding their *work email* is harder — providers have different hit rates and different costs. A waterfall tries them in order, cheapest first:

1. **Dropleads search** — free. Returns names + LinkedIn URLs + maybe emails.
2. **Bettercontact verify** — ~$0.02-0.06/email. Validates that an email is real and deliverable.
3. **(Optional) Apollo / Hunter fallback** — if the first two miss, retry with a paid provider for the remaining contacts.

End result: emails at ~$0.04 average instead of ~$0.25. For a list of 200, that''s $8 instead of $50.

## What you''ll do in this lesson

1. **Type your ICP** in plain English: *"VPs of Marketing at B2B SaaS, US, 50-200 employees"*
2. **The agent reflects back** what filters it''s about to apply: `dropleads_search_people` with title filter, size 50-200, geo US, limit 25 (or whatever number you ask for). It also tells you the expected cost BEFORE running.
3. **You approve** and watch contacts stream in
4. **The agent saves them to Supabase** — refresh the Table Editor and see real rows

## Why the agent thinks out loud

You''re going to do this again. The agent shows you its reasoning (where it''s looking, why it picked this provider, what the cost is) so that next time you can guide it: *"don''t use Dropleads for this ICP, the data''s thin — use Apollo with these filters."*

The thinking-out-loud IS the lesson.

## Common questions

- **What if my ICP isn''t in Dropleads?** The agent will tell you the result count is low and propose alternatives (Apollo, Crustdata, Apify for LinkedIn scraping).
- **What if I want a bigger list?** Just say so. The agent will raise the limit and the cost. It''ll always tell you the cost before running.
- **What if my ICP is B2C, not B2B?** Tell it. Tools like Dropleads/Apollo are B2B-focused; for B2C the agent will brainstorm community sites, forums, niche directories instead.', 2)
  ON CONFLICT DO NOTHING;

  -- ============================================================
  -- Module 3, Lesson 3.2 — Apply formula
  -- ============================================================
  SELECT l.id INTO v_lesson_id FROM lms_lessons l JOIN lms_weeks w ON w.id = l.week_id
  WHERE w.cohort_id = v_cohort_id AND w.title = 'Module 3 — Build a List' AND l.title = 'Cleaning data without spreadsheets';
  DELETE FROM lms_content_items WHERE lesson_id = v_lesson_id AND title = 'Read along — clean data';

  INSERT INTO lms_content_items (workspace_id, lesson_id, title, content_type, content_text, sort_order)
  VALUES (v_workspace, v_lesson_id, 'Read along — clean data', 'text',
E'## Why this matters

Real prospect data is messy:
- "VP, Marketing"
- "VP of Marketing"
- "Vice President of Marketing & Growth"
- "  VP of Marketing  " (trailing spaces)

These are the same person, three different ways. Before you send, you want them canonical. Tools like Clay sell you a "Formulas" tab for this. You''re going to do the same thing in your own database in 90 seconds.

## The pattern: SELECT → transform → UPDATE

Every database transformation is the same three moves:

1. **SELECT** the rows you want to change
2. **Transform** each one in memory (in code or in the agent''s head)
3. **UPDATE** them back into the database

The agent does this for you and shows you the before/after **before** committing. You always get a chance to say "no, don''t change those."

## What you''ll do in this lesson

1. The agent shows you 5 messy titles (or whatever column we''re cleaning today — phone, name capitalization, URL stripping, etc.)
2. It proposes the normalized version of each
3. You hit `y` to apply
4. The UPDATE runs in your Supabase — instant, free
5. You refresh and see the clean column

## Why this pattern is reusable

The same SELECT-transform-UPDATE works for *any* column:
- **Phone numbers** — strip parens, normalize country code
- **Names** — `MARINA BLACK` → `Marina Black`
- **URLs** — strip tracking parameters
- **Domains** — extract from email addresses
- **Titles** — normalize (today''s lesson)
- **Companies** — dedupe `Acme Inc` and `Acme, Inc.` and `acme`

You''re not just cleaning titles. You''re learning a pattern you''ll use for the rest of your cold-email career.

## What''s under the hood

The agent doesn''t use a UI tool — it writes SQL. Specifically:

```sql
UPDATE contacts
SET title = ''VP of Marketing''
WHERE id IN (''uuid1'', ''uuid2'', ''uuid3'');
```

You can do this yourself anytime in the Supabase SQL Editor. The agent is just faster and shows you the diff first.

## Common questions

- **What if I want to keep one of the "messy" versions because it''s meaningful?** Tell the agent. It will skip that row. The discipline is the value — don''t blindly normalize everything.
- **Can I write my own transformation?** Yes. Tell the agent the rule you want (e.g. "uppercase the first letter of every word in the company name"). It will run that against the rows.
- **What if I mess up?** Supabase has point-in-time recovery on the free tier. You can also just re-import the original data — your enrichment was logged.', 2)
  ON CONFLICT DO NOTHING;

  -- ============================================================
  -- Module 4, Lesson 4.1 — Build campaign
  -- ============================================================
  SELECT l.id INTO v_lesson_id FROM lms_lessons l JOIN lms_weeks w ON w.id = l.week_id
  WHERE w.cohort_id = v_cohort_id AND w.title = 'Module 4 — Build the Campaign' AND l.title = 'Offer, angle, and sequence';
  DELETE FROM lms_content_items WHERE lesson_id = v_lesson_id AND title = 'Read along — offer angle sequence';

  INSERT INTO lms_content_items (workspace_id, lesson_id, title, content_type, content_text, sort_order)
  VALUES (v_workspace, v_lesson_id, 'Read along — offer angle sequence', 'text',
E'## The hard truth most courses won''t tell you

Cold email is not "AI writes a personalized email per contact." That''s field-swap with a model bolted on top — it''s a third of the equation. Two-thirds is offer + angle + list.

Reply rate benchmarks from real campaign data (1.5M+ emails/month, agency-level):
- Exceptional: 1 reply / 10-30 leads (killer offer + tiny ICP + perfect timing)
- Great: 1 reply / 30-100 (strong offer + good list)
- Average: 1 reply / 250-400 (decent everything)
- Poor: 1 reply / 500-2,000 (weak offer or wrong list)
- Failed: 0 (commoditized offer, no differentiation)

The biggest driver of which bucket you''re in: **the offer**. Not the copy.

## The three pillars

Every cold-email campaign needs three things. If one breaks, the campaign breaks.

1. **Infrastructure** — sending mechanics (covered in Module 5)
2. **Segmented list** — who you send to (Module 3, which you just did)
3. **Messaging** — what you say (this lesson)

## What the agent does in this lesson

The agent becomes a senior cold-email strategist. It has the Growth Engine X playbook in its head — 10 strategic angles, the 4-email sequence structure, the copywriting rules, the validation checklist. It runs you through a structured brainstorm:

1. **Discovery** — 5-6 questions about your business, customer, proof, lead magnet
2. **Offer assessment** — honest read: is your offer strong, OK, or weak? If weak, the agent will tell you what to fix.
3. **Angle selection** — picks 1-2 angles from the 10 (Problem Sniffing, Lead Magnet, Stars Aligning, Flash Roll, Two-Sentence, Being Useful, etc.). It explains why for your specific situation.
4. **Sequence draft** — 2-email or 4-email sequence (never 7), with subjects, bodies, variables, timing
5. **Per-row decision** — should you fetch a per-row signal (LinkedIn post, About page), or skip openers entirely?

## The 10 angles in brief

1. **Problem Sniffing** — detect a specific problem in their data, surface it with proof
2. **Truly Funny, Relevant** — humor that supports the message
3. **AI Vision Casting** — use AI to show what your product looks like FOR THEM
4. **Stars Aligning** — only reach out when N signals are all true (extreme qualification)
5. **Extremely Relevant Case Studies** — lookalike list + matching case study
6. **Influencer Audience Targeting** — followers of an influencer who shares your philosophy
7. **Great Lead Magnet** — something free that the market normally pays for
8. **Being Genuinely Useful** — tell them something they''d want to know, no CTA
9. **Two-Sentence Straight to Point** — when offer + relevance are both strong
10. **Flash Roll** — demonstrate technical depth via specificity

You don''t need to memorize them. The agent picks the right ones for your situation.

## What you''ll have at the end

Three files on your computer:
- `data/campaign/offer.md` — the offer (what you give away, who it''s for, what to expect)
- `data/campaign/sequence.md` — the drafted 2- or 4-email sequence with variables
- `data/campaign/strategy.md` — the decision log: what angles, why, expected response rate

You can edit these yourself. The agent will pick up your edits.

## Common gotchas

- **"Just write me 4 emails"** — the agent will resist skipping the consultation. The consultation IS the value; the emails without it are slop.
- **"I want 7 emails not 4"** — the agent will push back. Past email 4 you generate more spam reports than positive replies. Bad math.
- **"The offer is just my demo"** — pre-product founders fall into this trap. A demo of an unfinished thing is a pitch, not an offer. The agent will help you find a real offer (audit, template, free build) instead.', 2)
  ON CONFLICT DO NOTHING;

  -- ============================================================
  -- Module 5, Lesson 5.1 — Why not Gmail
  -- ============================================================
  SELECT l.id INTO v_lesson_id FROM lms_lessons l JOIN lms_weeks w ON w.id = l.week_id
  WHERE w.cohort_id = v_cohort_id AND w.title = 'Module 5 — Send & Ship' AND l.title = 'Why you don''t use Gmail (and what to use)';
  DELETE FROM lms_content_items WHERE lesson_id = v_lesson_id AND title = 'Read along — sending infra';

  INSERT INTO lms_content_items (workspace_id, lesson_id, title, content_type, content_text, sort_order)
  VALUES (v_workspace, v_lesson_id, 'Read along — sending infra', 'text',
E'## If you remember one thing from this whole course

**Do not cold-email from your regular Gmail or Google Workspace.**

Twenty cold sends a day from your normal Gmail account will tank the domain''s reputation inside a week. Your real personal/work email starts going to spam. The damage isn''t reversible without rotating to a new domain.

This is the most common rookie mistake. It''s also the most expensive — you lose your real inbox until you switch domains and re-warm.

## Why Gmail kills your domain

Google''s spam classifier learns from your domain''s behavior. Normal accounts:
- Send 5-30 outbound a day
- To known contacts
- With high engagement (replies, forwards, archives)

Cold senders:
- Blast 50+ per day
- To strangers
- With low engagement (no replies, lots of "mark as spam")

The classifier sees the pattern, downgrades the domain, and from then on every email from that domain — even to your mom — gets filtered to spam.

## What proper cold-email infrastructure does

A real sending platform owns three things you can''t replicate in Gmail:

1. **Warmup** — slowly builds your sending reputation by exchanging emails with other warmed inboxes. Takes 14-21 days before you can actually cold-send.
2. **DKIM/SPF/DMARC** — cryptographic records that prove you''re authorized to send from your domain. Modern receivers (Gmail, Outlook) require these.
3. **Reply webhooks** — when someone replies, the platform fires a webhook that lands the reply in your database automatically. No polling, no missed replies.

## The four options in this course

| Option | Best for | Cost |
|---|---|---|
| **AgentMail (recommended)** | Most buyers, especially first cold-email setup | Free tier (3 inboxes) |
| **Instantly** | Already running it, scaling past 1k/mo | $37/mo starter — covered in Bootcamp |
| **Smartlead** | Same as Instantly | $39/mo starter — covered in Bootcamp |
| **Hand-write from existing Gmail** | TAM < 50 + warm contacts you already know | $0 — not cold outreach |

We wire AgentMail in the next lesson because it''s free, agentic-first (native MCP + first-class webhooks), and covers everything you need for the first 90 days of real campaigns.

## When option 4 (Gmail manual) is right

If your TAM is genuinely small (< 50 people) AND they''re warm (you''ve worked with them, met them at conferences, share a community), don''t set up cold-email infra. Write each note by hand from your existing Gmail. The data layer (Supabase + Deepline) is still worth it to help you find the *next* 50 contacts you don''t already know — but for the warm 50, just send notes.

This is what photographers, niche service providers, and small B2B agencies often need.

## Why we don''t teach Instantly/Smartlead in the Quickstart

They''re great tools. The Bootcamp covers them in depth because each one needs its own auth flow, campaign setup, warmup configuration, and integration with the data layer. Doing those properly takes 20-30 minutes per tool. AgentMail wires end-to-end in 12 minutes — better fit for the Quickstart''s time budget.', 2)
  ON CONFLICT DO NOTHING;

  -- ============================================================
  -- Module 5, Lesson 5.2 — Wire AgentMail
  -- ============================================================
  SELECT l.id INTO v_lesson_id FROM lms_lessons l JOIN lms_weeks w ON w.id = l.week_id
  WHERE w.cohort_id = v_cohort_id AND w.title = 'Module 5 — Send & Ship' AND l.title = 'Wire AgentMail end-to-end';
  DELETE FROM lms_content_items WHERE lesson_id = v_lesson_id AND title = 'Read along — wire AgentMail';

  INSERT INTO lms_content_items (workspace_id, lesson_id, title, content_type, content_text, sort_order)
  VALUES (v_workspace, v_lesson_id, 'Read along — wire AgentMail', 'text',
E'## The three things you''re about to set up

1. **A sending domain** — a subdomain like `mail.youragency.com` or a separate domain like `try-youragency.com`. You do NOT use your real domain for cold outreach (same reason you don''t send from your real Gmail).
2. **2 mailboxes on that domain** — `outreach1@mail.youragency.com` and `outreach2@mail.youragency.com`. AgentMail starts warming both immediately.
3. **A reply webhook** — fires when prospects reply. Lands replies in your Supabase `replies` table.

## Why a separate sending domain

If a campaign goes wrong (you send to a bad list, hit too many spam traps), the sending domain takes the hit. Your real `youragency.com` stays clean. Subdomains and sister domains cost ~$10/year each and isolate the damage.

Three patterns work:
- **Subdomain of your real domain**: `mail.youragency.com`, `outreach.youragency.com` (uses your existing DNS — easiest)
- **Sister domain**: `tryyouragency.com`, `getyouragency.com` (separate DNS, slight extra setup)
- **AgentMail provisions one for you**: pick a name, AgentMail buys it ($10-15/year, handled inside the product)

## DNS records — what they are and what they do

You''ll add three or four records at your registrar (Namecheap, Cloudflare, GoDaddy, etc.):

| Type | Purpose |
|---|---|
| **MX** | Tells receivers "mail FOR this domain comes to AgentMail" — needed for replies |
| **TXT (SPF)** | Says "AgentMail is authorized to send mail AS this domain" |
| **TXT (DKIM)** | Cryptographic signature on every outgoing email |
| **TXT (DMARC)** | Tells receivers what to do if SPF or DKIM fails |

You don''t need to understand these in detail. AgentMail generates them; you paste them at your registrar once. Propagation is 5-60 minutes worldwide (Cloudflare is near-instant).

## Warmup — what''s happening for 14-21 days

After provisioning, your mailboxes go into warmup. AgentMail sends small volumes (5-10/day at first, scaling up) to its network of other warmed inboxes. Those inboxes open and reply. To Gmail/Outlook''s classifiers, this looks like a normal new inbox building a reputation.

By day 15-21, you can cold-send for real. Trying to shortcut this is how people get blacklisted.

**What you CAN do during warmup**:
- Iterate your offer based on feedback
- Build out more lists for future campaigns
- Draft sequence variations
- Test send to yourself

**What you CANNOT do during warmup**:
- Send to your real prospect list
- Send more than ~20 emails/day from each inbox
- Sign up for additional services from the new mailbox (some platforms flag fresh accounts)

## What you''ll do in this lesson

1. Sign up at agentmail.to (Google OAuth, free tier)
2. The agent collects the API key, creates a scoped key, saves to `secrets/.env`
3. Pick your sending domain (your own, AgentMail-provisioned, or shared test subdomain)
4. The agent generates DNS records — copy them, paste at your registrar
5. Wait for DNS verification (typically <10 min on Cloudflare, up to 60 min elsewhere)
6. The agent provisions 2 mailboxes
7. Mailboxes enter warmup

## Common questions

- **What does this cost?** Free tier covers 3 inboxes. Past 3 it''s ~$30/mo per additional inbox.
- **Can I use my existing domain?** Yes — use a subdomain. `mail.yourdomain.com`. Doesn''t affect your real email.
- **What if I don''t have a domain?** Buy one for $10-15 at Cloudflare/Namecheap, or let AgentMail buy one inside the product.
- **What about CAN-SPAM compliance?** AgentMail handles unsubscribe links + DMARC compliance automatically. You stay legal as long as you''re sending B2B with accurate sender info and a real unsubscribe.', 3)
  ON CONFLICT DO NOTHING;

  -- ============================================================
  -- Module 5, Lesson 5.3 — Test send + finale
  -- ============================================================
  SELECT l.id INTO v_lesson_id FROM lms_lessons l JOIN lms_weeks w ON w.id = l.week_id
  WHERE w.cohort_id = v_cohort_id AND w.title = 'Module 5 — Send & Ship' AND l.title = 'Test send, reply capture, and what''s next';
  DELETE FROM lms_content_items WHERE lesson_id = v_lesson_id AND title = 'Read along — test send + what''s next';

  INSERT INTO lms_content_items (workspace_id, lesson_id, title, content_type, content_text, sort_order)
  VALUES (v_workspace, v_lesson_id, 'Read along — test send + what''s next', 'text',
E'## What this lesson confirms

The full loop:
```
agent sends → your inbox receives → you reply → webhook fires → row lands in Supabase
```

Each arrow is something that can break. The test confirms all of them, end-to-end.

## What you''ll do

1. **Agent sends a test email** to your personal email address. Uses the actual offer + Email 1 from your drafted sequence. This is what your campaign would send for real.
2. **You check your inbox** — the email should arrive within 1-3 minutes. Check primary inbox, not spam.
3. **You reply** — type anything ("test reply" is fine), hit send.
4. **The agent waits ~30-60 seconds** then queries Supabase for new rows in the `replies` table.
5. **Row appears** — AgentMail caught the reply, fired the webhook, the webhook landed in your database.

## If the test send goes to spam

This happens occasionally during warmup. It''s NOT a sign your real campaign will go to spam — receivers'' spam filters give brand new domains stricter scrutiny for the first few days. Things to check:

- DNS records all show "Verified" in AgentMail dashboard
- Subject line isn''t obviously sales-y (e.g. "Quick Question About Your Marketing Strategy" → spam)
- Body doesn''t have spam trigger words ("free," "guarantee," "act now," "limited time")

If still in spam after 24 hours and DNS is verified, post in support and we''ll look at the headers.

## What''s next — the warmup period

For the next 14-21 days, your mailboxes are warming. You can''t cold-send for real. What you SHOULD do:

1. **Iterate your offer** — the drafts the agent wrote are starting points. Read them out loud. Show them to two trusted peers. Change anything that doesn''t sound like you.
2. **Expand your list** — re-run the first_workflow with different ICPs or filters. Build a backlog of 200-500 contacts.
3. **Draft A/B variations** — write a second subject line, a second opener, a second CTA. You''ll test these once warmup finishes.
4. **Set a launch date** — pick the day warmup ends. Block 2 hours on the calendar for the real first send.

## What''s NOT in the Quickstart (and where to find it)

The Quickstart is intentionally scoped — we ship the core cold-email loop, not the full GTM stack. Things that come next:

| Thing | Where it''s covered |
|---|---|
| LinkedIn outreach (HeyReach, Unipile) | Bootcamp Module 3 |
| Scaling past 1k/mo (Instantly, Smartlead, multi-domain) | Bootcamp Module 4 |
| Reply classification + auto-routing to your CRM | Bootcamp Module 5 |
| Multi-client / agency setup (per-client database isolation) | Setup-on-your-system (1:1) |
| Content + post automation | Bootcamp Module 7 |
| The offer iteration loop after first 50 replies | Bootcamp Module 6 |

## Upsell ladder (no pressure — for when you''re ready)

1. **Bootcamp** — cohort-based, $2,500. Modules 1-7 above. Live calls, peer review, Tim on Slack. Link in the next content item.
2. **1:1 Coaching** — book a call ([modernagencysales.com/coaching](https://modernagencysales.com/coaching)). Help on offer iteration, ICP refinement, debugging a campaign that isn''t working.
3. **Setup-on-your-system** — book a call ([modernagencysales.com/setup](https://modernagencysales.com/setup)). Tim does the whole stack setup on your machine in 90 minutes. For agencies that want it done right the first time.

## Congratulations

You built a real cold-email machine. The data layer is yours. The pipeline is yours. The campaign is drafted. The sending infrastructure is wired. Mailboxes are warming.

In 14-21 days, you ship.', 3)
  ON CONFLICT DO NOTHING;

END $$;

COMMIT;
