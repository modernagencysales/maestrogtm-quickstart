-- ╔═══════════════════════════════════════════════════════════════╗
-- ║  GTM Starter Schema                                           ║
-- ║  30 Days To Agentic GTM — every skill in the cohort           ║
-- ║  assumes these tables exist. Run on a fresh Supabase project. ║
-- ╚═══════════════════════════════════════════════════════════════╝
--
-- How to use:
--   1. Open your Supabase project's SQL editor.
--   2. Paste this entire file. Run.
--   3. Verify in Table editor: 28 tables created.
--
-- Idempotent — safe to re-run. Uses `IF NOT EXISTS` everywhere.
--
-- Conventions:
--   - All tables have a UUID primary key, created_at, updated_at.
--   - All foreign keys are explicit and indexed.
--   - All identifiers use snake_case.
--   - All emails stored lowercase + trimmed (enforced by trigger below).
--   - Soft delete via `deleted_at` (not all tables — only where we keep history).

-- ───────────────────────────────────────────────────────────────
-- Extensions
-- ───────────────────────────────────────────────────────────────

-- pgcrypto provides gen_random_uuid() — universally available on fresh Supabase projects.
-- (We do NOT require uuid-ossp; fresh Supabase projects don't enable it by default.)
CREATE EXTENSION IF NOT EXISTS "pgcrypto";


-- ───────────────────────────────────────────────────────────────
-- Companies — organizations in your TAM
-- ───────────────────────────────────────────────────────────────

CREATE TABLE IF NOT EXISTS companies (
  id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  domain        TEXT NOT NULL UNIQUE,
  name          TEXT NOT NULL,
  industry      TEXT,
  employee_count INT,
  revenue_band  TEXT,           -- e.g., "1-10M", "10-50M"
  geography     TEXT,           -- "US", "EU", "global"
  tech_stack    JSONB DEFAULT '[]'::jsonb,
  source        TEXT,           -- which provider found it: "apollo", "crustdata", "manual"
  source_data   JSONB,          -- raw provider response for traceability
  icp_score     INT,            -- 0-100, set by qualify_companies
  notes         TEXT,
  created_at    TIMESTAMPTZ DEFAULT NOW(),
  updated_at    TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_companies_domain ON companies(domain);
CREATE INDEX IF NOT EXISTS idx_companies_icp_score ON companies(icp_score) WHERE icp_score IS NOT NULL;


-- ───────────────────────────────────────────────────────────────
-- Contacts — people at companies
-- ───────────────────────────────────────────────────────────────

CREATE TABLE IF NOT EXISTS contacts (
  id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id    UUID REFERENCES companies(id) ON DELETE SET NULL,
  email         TEXT,
  email_status  TEXT,           -- "valid" | "invalid" | "risky" | "unknown" | NULL (unverified)
  first_name    TEXT,
  last_name     TEXT,
  full_name     TEXT GENERATED ALWAYS AS (TRIM(COALESCE(first_name,'') || ' ' || COALESCE(last_name,''))) STORED,
  title         TEXT,
  seniority     TEXT,           -- "ic", "manager", "director", "vp", "c-level", "founder"
  function      TEXT,           -- "sales", "marketing", "engineering", "ops", etc.
  linkedin_url  TEXT,
  linkedin_recent_post_text TEXT,  -- pulled in D9, used for personalization in D18
  source        TEXT,
  source_data   JSONB,
  icp_score     INT,
  -- Enrichment provenance (populated by D17 enrich_email)
  enrichment_source    TEXT,           -- which provider returned the email: "leadmagic", "prospeo", "findymail", etc.
  enrichment_cost_usd  NUMERIC(8,4),   -- credits spent finding this contact's email
  enriched_at          TIMESTAMPTZ,    -- when the enrichment landed (for staleness checks)
  -- Personalization columns (populated by D18 / D18.5)
  first_line    TEXT,
  cold_email_subject TEXT,
  -- Campaign tracking (populated by D19 / D19.5)
  campaign_id   TEXT,           -- ID in PlusVibe / Smartlead / etc.
  campaign_platform TEXT,       -- "plusvibe" | "smartlead" | "instantly" | "heyreach"
  -- Free-form per-contact metadata
  metadata      JSONB DEFAULT '{}'::jsonb,
  notes         TEXT,
  created_at    TIMESTAMPTZ DEFAULT NOW(),
  updated_at    TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_contacts_company ON contacts(company_id);
CREATE INDEX IF NOT EXISTS idx_contacts_email ON contacts(email) WHERE email IS NOT NULL;
-- Unique partial index on email — enables PostgREST `on_conflict=email` upserts.
-- Partial (WHERE email IS NOT NULL) so contacts without an email don't conflict with each other.
CREATE UNIQUE INDEX IF NOT EXISTS uniq_contacts_email
  ON contacts(email) WHERE email IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_contacts_enriched_at ON contacts(enriched_at) WHERE enriched_at IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_contacts_email_status ON contacts(email_status);
CREATE INDEX IF NOT EXISTS idx_contacts_campaign ON contacts(campaign_id) WHERE campaign_id IS NOT NULL;

-- Lower-case + trim emails on write (defense against provider variations)
CREATE OR REPLACE FUNCTION normalize_contact_email() RETURNS trigger AS $$
BEGIN
  IF NEW.email IS NOT NULL THEN
    NEW.email := LOWER(TRIM(NEW.email));
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_normalize_contact_email ON contacts;
CREATE TRIGGER trg_normalize_contact_email
BEFORE INSERT OR UPDATE OF email ON contacts
FOR EACH ROW EXECUTE FUNCTION normalize_contact_email();


-- ───────────────────────────────────────────────────────────────
-- Signals — intent, job-change, hiring (D22)
-- ───────────────────────────────────────────────────────────────

CREATE TABLE IF NOT EXISTS signals (
  id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  contact_id    UUID REFERENCES contacts(id) ON DELETE CASCADE,
  company_id    UUID REFERENCES companies(id) ON DELETE CASCADE,
  signal_type   TEXT NOT NULL,  -- "job_change" | "funding" | "hiring" | "tech_adoption" | "intent"
  strength      TEXT,           -- "weak" | "medium" | "strong"
  recency_days  INT,            -- how many days ago the signal happened
  source        TEXT,           -- "theirstack", "pdl", "crustdata"
  source_data   JSONB,
  observed_at   TIMESTAMPTZ NOT NULL,  -- when the underlying event happened
  ingested_at   TIMESTAMPTZ DEFAULT NOW(),
  CONSTRAINT signals_target CHECK (contact_id IS NOT NULL OR company_id IS NOT NULL)
);

CREATE INDEX IF NOT EXISTS idx_signals_contact ON signals(contact_id) WHERE contact_id IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_signals_company ON signals(company_id) WHERE company_id IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_signals_type_recency ON signals(signal_type, observed_at DESC);


-- ───────────────────────────────────────────────────────────────
-- Replies — incoming responses (D23 classifies, D24 drafts)
-- ───────────────────────────────────────────────────────────────

CREATE TABLE IF NOT EXISTS replies (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  contact_id      UUID REFERENCES contacts(id) ON DELETE SET NULL,
  channel         TEXT NOT NULL,  -- "email" | "linkedin_dm" | "linkedin_post_comment"
  campaign_id     TEXT,           -- which campaign the reply is to
  source_post_id  UUID,           -- → posts(id), FK added after posts is created (see below)
  thread_id       TEXT,
  subject         TEXT,
  body            TEXT NOT NULL,
  received_at     TIMESTAMPTZ NOT NULL,
  -- Classification (populated by D23)
  category      TEXT,           -- "booking_intent" | "soft_positive" | "objection" | "not_now" | "spam" | "unsubscribe"
  confidence    NUMERIC(3,2),   -- 0.00 to 1.00
  reasoning     TEXT,           -- model's reasoning, for audit
  classified_at TIMESTAMPTZ,
  classifier_version TEXT,
  -- Response (populated by D24)
  draft_a       TEXT,
  draft_b       TEXT,
  draft_c       TEXT,
  selected_draft TEXT,          -- "a" | "b" | "c" | "manual"
  responded_at  TIMESTAMPTZ,
  -- Auto-actions taken
  auto_unsubscribed BOOLEAN DEFAULT false,
  auto_filed_spam BOOLEAN DEFAULT false,
  created_at    TIMESTAMPTZ DEFAULT NOW(),
  updated_at    TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_replies_contact ON replies(contact_id);
CREATE INDEX IF NOT EXISTS idx_replies_received ON replies(received_at DESC);
CREATE INDEX IF NOT EXISTS idx_replies_category ON replies(category) WHERE category IS NOT NULL;


-- ───────────────────────────────────────────────────────────────
-- Sequences — outbound sequence state per contact (D25 manages)
-- ───────────────────────────────────────────────────────────────

CREATE TABLE IF NOT EXISTS sequences (
  id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  contact_id    UUID NOT NULL REFERENCES contacts(id) ON DELETE CASCADE,
  channel       TEXT NOT NULL,  -- "email" | "linkedin"
  campaign_id   TEXT NOT NULL,
  current_touch INT DEFAULT 0,  -- 0 = not started, 1-N = active touch number
  total_touches INT NOT NULL,
  status        TEXT DEFAULT 'pending',  -- "pending" | "running" | "paused" | "stopped" | "completed"
  paused_reason TEXT,           -- "replied" | "engaged_other_channel" | "manual"
  last_touch_at TIMESTAMPTZ,
  next_touch_at TIMESTAMPTZ,
  created_at    TIMESTAMPTZ DEFAULT NOW(),
  updated_at    TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_sequences_contact_channel ON sequences(contact_id, channel);
CREATE INDEX IF NOT EXISTS idx_sequences_next_touch ON sequences(next_touch_at) WHERE status = 'running';


-- ───────────────────────────────────────────────────────────────
-- Posts — LinkedIn posts (D8 generates, D27 schedules)
-- ───────────────────────────────────────────────────────────────

CREATE TABLE IF NOT EXISTS posts (
  id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  body          TEXT NOT NULL,
  hook_pattern  TEXT,           -- which of the 30 hook patterns
  status        TEXT DEFAULT 'draft',  -- "draft" | "scheduled" | "posted" | "archived"
  scheduled_for TIMESTAMPTZ,
  posted_at     TIMESTAMPTZ,
  external_id   TEXT,           -- LinkedIn post ID after publish
  -- Engagement (populated post-publish, D28 reads deltas)
  reactions     INT DEFAULT 0,
  comments_count INT DEFAULT 0,
  reposts       INT DEFAULT 0,
  impressions   INT DEFAULT 0,
  last_engagement_check TIMESTAMPTZ,
  -- Source — what topic + voice profile generated this
  topic         TEXT,
  voice_profile_version TEXT,
  source_skill  TEXT,           -- "generate_li_post" | "draft_newsletter" | "manual"
  notes         TEXT,
  created_at    TIMESTAMPTZ DEFAULT NOW(),
  updated_at    TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_posts_status_scheduled ON posts(status, scheduled_for);

-- Now that posts exists, wire the deferred replies.source_post_id FK.
-- Idempotent: drop-then-add so re-runs don't accumulate constraints.
ALTER TABLE replies DROP CONSTRAINT IF EXISTS replies_source_post_id_fkey;
ALTER TABLE replies ADD CONSTRAINT replies_source_post_id_fkey
  FOREIGN KEY (source_post_id) REFERENCES posts(id) ON DELETE SET NULL;
CREATE INDEX IF NOT EXISTS idx_replies_source_post ON replies(source_post_id) WHERE source_post_id IS NOT NULL;


-- ───────────────────────────────────────────────────────────────
-- Lead magnets + funnel leads (D10, D11)
-- ───────────────────────────────────────────────────────────────

CREATE TABLE IF NOT EXISTS lead_magnets (
  id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name          TEXT NOT NULL,
  slug          TEXT UNIQUE NOT NULL,
  status        TEXT DEFAULT 'draft',  -- "draft" | "live" | "archived"
  hook          TEXT,
  outcome       TEXT,
  format        TEXT,           -- "pdf" | "calculator" | "checklist" | "swipe_file"
  delivery_method TEXT,         -- "email_attachment" | "link" | "embed"
  brief         JSONB,          -- the full design brief from D10
  landing_url   TEXT,
  conversions   INT DEFAULT 0,  -- denormalized counter, kept fresh by trigger
  created_at    TIMESTAMPTZ DEFAULT NOW(),
  updated_at    TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS funnel_leads (
  id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  lead_magnet_id UUID NOT NULL REFERENCES lead_magnets(id) ON DELETE CASCADE,
  email         TEXT NOT NULL,
  first_name    TEXT,
  last_name     TEXT,
  source_url    TEXT,           -- referrer
  utm_source    TEXT,
  utm_medium    TEXT,
  utm_campaign  TEXT,
  ip_address    INET,
  user_agent    TEXT,
  delivered     BOOLEAN DEFAULT false,
  delivered_at  TIMESTAMPTZ,
  opt_in_confirmed BOOLEAN DEFAULT true,  -- single opt-in default; set false for double opt-in
  created_at    TIMESTAMPTZ DEFAULT NOW(),
  updated_at    TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_funnel_leads_lm ON funnel_leads(lead_magnet_id);
CREATE INDEX IF NOT EXISTS idx_funnel_leads_email ON funnel_leads(email);
CREATE UNIQUE INDEX IF NOT EXISTS uniq_funnel_leads_email_per_lm ON funnel_leads(lead_magnet_id, email);


-- ───────────────────────────────────────────────────────────────
-- Journal — every skill run logs here (used by D28 gtm_report)
-- ───────────────────────────────────────────────────────────────

CREATE TABLE IF NOT EXISTS journal (
  id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  ran_at        TIMESTAMPTZ DEFAULT NOW(),
  skill         TEXT NOT NULL,  -- "kickoff" | "build_tam" | etc.
  status        TEXT NOT NULL,  -- "success" | "partial" | "failed" | "skipped"
  duration_ms   INT,
  cost_usd      NUMERIC(10,4),  -- estimated AI/API cost for this run
  metadata      JSONB DEFAULT '{}'::jsonb,
  notes         TEXT
);

CREATE INDEX IF NOT EXISTS idx_journal_skill_ran ON journal(skill, ran_at DESC);


-- ───────────────────────────────────────────────────────────────
-- Brain — RAG corpus chunks (D12 query_brain)
-- ───────────────────────────────────────────────────────────────
-- Optional — only enable if pgvector extension is available.
-- Comment this section out if you're not using D12 yet.

CREATE EXTENSION IF NOT EXISTS vector;

CREATE TABLE IF NOT EXISTS brain_chunks (
  id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  source_type   TEXT NOT NULL,  -- "notion" | "transcript" | "post" | "doc"
  source_id     TEXT NOT NULL,  -- external ID for dedup
  source_url    TEXT,
  content       TEXT NOT NULL,
  content_hash  TEXT NOT NULL,  -- SHA256 — drives idempotency
  embedding     vector(1536),   -- OpenAI text-embedding-3-small dim
  metadata      JSONB DEFAULT '{}'::jsonb,
  ingested_at   TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_brain_chunks_source ON brain_chunks(source_type, source_id);
CREATE UNIQUE INDEX IF NOT EXISTS uniq_brain_chunks_hash ON brain_chunks(content_hash);
CREATE INDEX IF NOT EXISTS idx_brain_chunks_embedding ON brain_chunks
  USING ivfflat (embedding vector_cosine_ops) WITH (lists = 100);


-- ───────────────────────────────────────────────────────────────
-- Outreach campaigns — cold email campaign metadata (D18–D19)
-- Written by push_to_inbox; read by classify_reply, manage_followup,
-- gtm_report, and draft_reply for campaign context.
-- ───────────────────────────────────────────────────────────────

CREATE TABLE IF NOT EXISTS outreach_campaigns (
  id                  UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name                TEXT NOT NULL,
  platform            TEXT,           -- "plusvibe" | "smartlead" | "instantly" | "heyreach"
  campaign_external_id TEXT,          -- ID in the sending platform
  status              TEXT DEFAULT 'draft', -- "draft" | "active" | "paused" | "completed"
  icp_description     TEXT,           -- passed to classify_reply for context
  offer_description   TEXT,
  tone                TEXT,
  team_id             UUID,
  created_at          TIMESTAMPTZ DEFAULT NOW(),
  updated_at          TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_outreach_campaigns_status ON outreach_campaigns(status);
CREATE INDEX IF NOT EXISTS idx_outreach_campaigns_team   ON outreach_campaigns(team_id) WHERE team_id IS NOT NULL;


-- ───────────────────────────────────────────────────────────────
-- Outreach campaign leads — per-contact sequence enrollment (D19)
-- Written by push_to_inbox; read by classify_reply (unsubscribe
-- handling), triage_dms, draft_reply, and manage_followup.
-- ───────────────────────────────────────────────────────────────

CREATE TABLE IF NOT EXISTS outreach_campaign_leads (
  id                  UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  campaign_id         UUID REFERENCES outreach_campaigns(id) ON DELETE CASCADE,
  contact_id          UUID REFERENCES contacts(id) ON DELETE SET NULL,
  first_name          TEXT,
  last_name           TEXT,
  company_name        TEXT,
  domain              TEXT,
  linkedin_url        TEXT,
  email               TEXT,
  status              TEXT DEFAULT 'active',
    -- "active" | "paused" | "completed" | "unsubscribed" | "bounced" | "replied"
  enrolled_at         TIMESTAMPTZ DEFAULT NOW(),
  last_touched_at     TIMESTAMPTZ,
  team_id             UUID,
  created_at          TIMESTAMPTZ DEFAULT NOW(),
  updated_at          TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_ocl_campaign   ON outreach_campaign_leads(campaign_id);
CREATE INDEX IF NOT EXISTS idx_ocl_contact    ON outreach_campaign_leads(contact_id) WHERE contact_id IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_ocl_linkedin   ON outreach_campaign_leads(linkedin_url) WHERE linkedin_url IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_ocl_status     ON outreach_campaign_leads(status);


-- ───────────────────────────────────────────────────────────────
-- AgentMail inboxes — provisioned mailboxes for cold outreach
-- Written by send_outreach (D19). Read by gtm_report.
-- inbox_id is a soft reference target for send_attempts.inbox_id.
-- ───────────────────────────────────────────────────────────────

CREATE TABLE IF NOT EXISTS agentmail_inboxes (
  id                    UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  inbox_id              TEXT UNIQUE NOT NULL,    -- AgentMail's inbox ID
  email_address         TEXT NOT NULL UNIQUE,
  domain_id             TEXT,
  domain                TEXT,
  display_name          TEXT,
  -- Health
  status                TEXT DEFAULT 'warming',  -- 'warming' | 'ready' | 'paused' | 'flagged'
  warmup_started_at     TIMESTAMPTZ DEFAULT NOW(),
  warmup_ready_at       TIMESTAMPTZ,
  daily_send_cap        INT DEFAULT 50,
  -- DNS verification
  spf_status            TEXT,
  dkim_status           TEXT,
  dmarc_status          TEXT,
  -- Cost
  cost_per_month_usd    NUMERIC(10,2),
  created_at            TIMESTAMPTZ DEFAULT NOW(),
  updated_at            TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_agentmail_inboxes_status ON agentmail_inboxes(status);


-- ───────────────────────────────────────────────────────────────
-- Send attempts — one row per email/linkedin send to a contact
-- Written by push_to_inbox (D19) and linkedin_outreach (D20).
-- Read by classify_reply, manage_followup, gtm_report.
-- This is the canonical "what happened to this contact?" table —
-- every outbound touch traces back to contact_id from here.
-- ───────────────────────────────────────────────────────────────

CREATE TABLE IF NOT EXISTS send_attempts (
  id                  UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  contact_id          UUID NOT NULL REFERENCES contacts(id) ON DELETE CASCADE,
  campaign_id         UUID REFERENCES outreach_campaigns(id) ON DELETE SET NULL,
  sequence_id         UUID REFERENCES sequences(id) ON DELETE SET NULL,
  touch_number        INT,                    -- 1-N within sequence
  channel             TEXT NOT NULL,          -- 'email' | 'linkedin_dm' | 'linkedin_connect'
  -- Provider tracking
  provider            TEXT NOT NULL,          -- 'agentmail' | 'plusvibe' | 'smartlead' | 'instantly' | 'heyreach'
  provider_message_id TEXT,                   -- external ID for trace
  inbox_id            TEXT,                   -- agentmail inbox ID (soft ref — matches agentmail_inboxes.inbox_id)
  -- Idempotency
  attempt_key         TEXT NOT NULL,          -- hash(contact_id + campaign_id + touch_number) — prevents double-send
  -- Content snapshot at send time
  subject             TEXT,
  body                TEXT,
  variables_used      JSONB,                  -- {first_name, first_line, etc} for traceability
  -- Outcome
  status              TEXT NOT NULL DEFAULT 'queued',
    -- 'queued' | 'sent' | 'delivered' | 'bounced' | 'complained' | 'failed'
  status_at           TIMESTAMPTZ DEFAULT NOW(),
  error_message       TEXT,
  -- Cost
  cost_usd            NUMERIC(10,6),
  -- Timestamps
  queued_at           TIMESTAMPTZ DEFAULT NOW(),
  sent_at             TIMESTAMPTZ,
  delivered_at        TIMESTAMPTZ,
  bounced_at          TIMESTAMPTZ,
  complained_at       TIMESTAMPTZ,
  created_at          TIMESTAMPTZ DEFAULT NOW()
);

CREATE UNIQUE INDEX IF NOT EXISTS uniq_send_attempts_attempt_key ON send_attempts(attempt_key);
CREATE INDEX IF NOT EXISTS idx_send_attempts_contact  ON send_attempts(contact_id, sent_at DESC);
CREATE INDEX IF NOT EXISTS idx_send_attempts_campaign ON send_attempts(campaign_id, status);
CREATE INDEX IF NOT EXISTS idx_send_attempts_queued   ON send_attempts(status, queued_at) WHERE status = 'queued';


-- ───────────────────────────────────────────────────────────────
-- Post engagements — LinkedIn engagement by known/unknown contacts
-- Written by engage_comments (D9) + any post-publish enrichment.
-- Read by gtm_report (D28) for ICP engagement attribution.
-- contact_id links engagement back to a known contact. campaign_id
-- captures which campaign the contact was in when they engaged.
-- ───────────────────────────────────────────────────────────────

CREATE TABLE IF NOT EXISTS post_engagements (
  id                    UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  post_id               UUID NOT NULL REFERENCES posts(id) ON DELETE CASCADE,
  contact_id            UUID REFERENCES contacts(id) ON DELETE SET NULL,
  -- For unknown engagements (no contact match yet)
  engager_linkedin_url  TEXT,
  engager_name          TEXT,
  -- What kind
  engagement_type       TEXT NOT NULL,    -- 'reaction' | 'comment' | 'repost' | 'view'
  reaction_type         TEXT,             -- 'like' | 'celebrate' | 'support' | 'love' | 'insightful' | 'curious'
  comment_text          TEXT,
  -- Attribution: which campaign was this contact enrolled in when they engaged?
  campaign_id           UUID REFERENCES outreach_campaigns(id) ON DELETE SET NULL,
  -- Metadata
  observed_at           TIMESTAMPTZ NOT NULL,
  ingested_at           TIMESTAMPTZ DEFAULT NOW(),
  source                TEXT,             -- 'unipile' | 'manual'
  CONSTRAINT post_engagements_has_engager CHECK (
    contact_id IS NOT NULL OR engager_linkedin_url IS NOT NULL
  )
);

CREATE INDEX IF NOT EXISTS idx_post_engagements_post        ON post_engagements(post_id, observed_at DESC);
CREATE INDEX IF NOT EXISTS idx_post_engagements_contact     ON post_engagements(contact_id) WHERE contact_id IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_post_engagements_unknown_url ON post_engagements(engager_linkedin_url) WHERE contact_id IS NULL;


-- ───────────────────────────────────────────────────────────────
-- Reply classifications — structured inbox triage output (D23, D26)
-- Written by classify_reply (email) and triage_dms (LinkedIn DMs).
-- Read by draft_reply, manage_followup, and gtm_report.
-- ───────────────────────────────────────────────────────────────

CREATE TABLE IF NOT EXISTS reply_classifications (
  id                  UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  reply_id            UUID NOT NULL REFERENCES replies(id) ON DELETE CASCADE,
  team_id             UUID,
  category            TEXT NOT NULL,
    -- "booking_intent" | "soft_positive" | "objection" | "not_now"
    -- | "spam_auto_reply" | "unsubscribe"
  confidence          NUMERIC(3,2) NOT NULL,  -- 0.00–1.00
  reasoning           TEXT,
  auto_routed         BOOLEAN DEFAULT false,
  needs_review        BOOLEAN DEFAULT false,
  channel             TEXT DEFAULT 'email',   -- "email" | "linkedin"
  source              TEXT,                   -- "classify_reply" | "triage_dms" | "connection_acceptance"
  classifier_version  TEXT,
  -- Draft-reply lifecycle (populated by D24 draft_reply)
  draft_status        TEXT,  -- "drafted" | "sent" | "skipped" | "send_failed" | "draft_failed"
  status              TEXT,  -- "queued_for_reply" | "archived" | "unsubscribed" | "replied"
  classified_at       TIMESTAMPTZ DEFAULT NOW(),
  reviewed_at         TIMESTAMPTZ,
  created_at          TIMESTAMPTZ DEFAULT NOW(),
  updated_at          TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE (reply_id)
);

CREATE INDEX IF NOT EXISTS idx_reply_cls_reply    ON reply_classifications(reply_id);
CREATE INDEX IF NOT EXISTS idx_reply_cls_category ON reply_classifications(category);
CREATE INDEX IF NOT EXISTS idx_reply_cls_review   ON reply_classifications(needs_review) WHERE needs_review = true;
CREATE INDEX IF NOT EXISTS idx_reply_cls_channel  ON reply_classifications(channel);
CREATE INDEX IF NOT EXISTS idx_reply_cls_status   ON reply_classifications(status) WHERE status IS NOT NULL;


-- ───────────────────────────────────────────────────────────────
-- Suppression list — contacts opted out of all outreach (D23, D26)
-- Written by classify_reply (email unsubscribes) and triage_dms
-- (LinkedIn unsubscribes). Read by manage_followup for stop checks.
-- ───────────────────────────────────────────────────────────────

CREATE TABLE IF NOT EXISTS suppression_list (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  email           TEXT,                        -- suppressed email address
  linkedin_url    TEXT,                        -- suppressed LinkedIn profile URL
  identifier      TEXT,                        -- generic identifier (email or linkedin_url)
  identifier_type TEXT,                        -- "email" | "linkedin_url"
  reason          TEXT,  -- "unsubscribe" | "bounce" | "spam" | "manual"
  source          TEXT,  -- "classify_reply" | "triage_dms" | "manual"
  team_id         UUID,
  suppressed_at   TIMESTAMPTZ DEFAULT NOW(),
  created_at      TIMESTAMPTZ DEFAULT NOW(),
  CONSTRAINT suppression_has_identifier CHECK (
    email IS NOT NULL OR linkedin_url IS NOT NULL OR identifier IS NOT NULL
  )
);

CREATE UNIQUE INDEX IF NOT EXISTS uniq_suppression_email       ON suppression_list(email) WHERE email IS NOT NULL;
CREATE UNIQUE INDEX IF NOT EXISTS uniq_suppression_linkedin    ON suppression_list(linkedin_url) WHERE linkedin_url IS NOT NULL;
CREATE UNIQUE INDEX IF NOT EXISTS uniq_suppression_identifier  ON suppression_list(identifier, identifier_type) WHERE identifier IS NOT NULL;


-- ───────────────────────────────────────────────────────────────
-- AgentMail webhook events — raw inbound webhook archive
-- Written by the AgentMail webhook handler on every inbound event.
-- Read by classify_reply for delivered/bounced/complained resolution.
-- Kept for audit + debugging. Rows are never deleted.
-- ───────────────────────────────────────────────────────────────

CREATE TABLE IF NOT EXISTS agentmail_webhook_events (
  id                UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  event_type        TEXT NOT NULL,    -- 'message.received' | 'message.delivered' | 'message.bounced' | 'message.complained'
  event_id          TEXT UNIQUE,      -- AgentMail's event ID for dedup
  inbox_id          TEXT,
  message_id        TEXT,
  thread_id         TEXT,
  -- Resolved entity references (best-effort at ingest time)
  contact_id        UUID REFERENCES contacts(id) ON DELETE SET NULL,
  send_attempt_id   UUID REFERENCES send_attempts(id) ON DELETE SET NULL,
  reply_id          UUID REFERENCES replies(id) ON DELETE SET NULL,
  -- Raw payload
  payload           JSONB NOT NULL,
  -- Processing
  processed         BOOLEAN DEFAULT false,
  processed_at      TIMESTAMPTZ,
  process_error     TEXT,
  received_at       TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_agentmail_events_unprocessed ON agentmail_webhook_events(received_at) WHERE NOT processed;
CREATE INDEX IF NOT EXISTS idx_agentmail_events_contact     ON agentmail_webhook_events(contact_id) WHERE contact_id IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_agentmail_events_message_id  ON agentmail_webhook_events(message_id) WHERE message_id IS NOT NULL;


-- ───────────────────────────────────────────────────────────────
-- Outreach cross-channel state — per-contact channel coordination (D20, D25)
-- Written by linkedin_outreach; read by manage_followup to prevent
-- double-touching email-active contacts on LinkedIn in the same week.
-- ───────────────────────────────────────────────────────────────

CREATE TABLE IF NOT EXISTS outreach_cross_channel_state (
  id                      UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  contact_id              UUID NOT NULL REFERENCES contacts(id) ON DELETE CASCADE,
  team_id                 UUID,
  -- Email channel state (populated by D19 push_to_inbox)
  email_touched_at        TIMESTAMPTZ,
  email_campaign_id       TEXT,
  -- LinkedIn channel state (populated by D20 linkedin_outreach)
  linkedin_campaign_id    TEXT,          -- HeyReach campaign ID
  linkedin_touched_at     TIMESTAMPTZ,
  linkedin_sequence_step  TEXT,          -- "connection_request" | "dm_1" | "dm_2"
  created_at              TIMESTAMPTZ DEFAULT NOW(),
  updated_at              TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE (contact_id)
);

CREATE INDEX IF NOT EXISTS idx_cross_channel_contact       ON outreach_cross_channel_state(contact_id);
CREATE INDEX IF NOT EXISTS idx_cross_channel_email_touched ON outreach_cross_channel_state(email_touched_at) WHERE email_touched_at IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_cross_channel_li_campaign   ON outreach_cross_channel_state(linkedin_campaign_id) WHERE linkedin_campaign_id IS NOT NULL;


-- ───────────────────────────────────────────────────────────────
-- LinkedIn campaigns — HeyReach campaign tracking (D20, D28)
-- Written by linkedin_outreach; read by gtm_report for connection
-- acceptance + message delivery deltas.
-- ───────────────────────────────────────────────────────────────

CREATE TABLE IF NOT EXISTS linkedin_campaigns (
  id                    UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  campaign_external_id  TEXT NOT NULL,   -- HeyReach campaign ID
  platform              TEXT DEFAULT 'heyreach',
  name                  TEXT NOT NULL,
  status                TEXT DEFAULT 'active',  -- "active" | "paused" | "completed"
  connections_accepted  INT DEFAULT 0,
  messages_delivered    INT DEFAULT 0,
  team_id               UUID,
  created_at            TIMESTAMPTZ DEFAULT NOW(),
  updated_at            TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_li_campaigns_status  ON linkedin_campaigns(status);
CREATE INDEX IF NOT EXISTS idx_li_campaigns_team    ON linkedin_campaigns(team_id) WHERE team_id IS NOT NULL;


-- ───────────────────────────────────────────────────────────────
-- Reply drafts — AI-generated reply variants (D24 draft_reply)
-- Written by draft_reply; read by gtm_report for sent-variant stats.
-- ───────────────────────────────────────────────────────────────

CREATE TABLE IF NOT EXISTS reply_drafts (
  id                        UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  reply_id                  UUID NOT NULL REFERENCES replies(id) ON DELETE CASCADE,
  classification_id         UUID REFERENCES reply_classifications(id) ON DELETE SET NULL,
  team_id                   UUID,
  variant_a                 TEXT,
  variant_b                 TEXT,
  variant_c                 TEXT,
  recommended_variant       TEXT,                  -- "a" | "b" | "c"
  draft_status              TEXT DEFAULT 'pending_review',
    -- "pending_review" | "sent" | "skipped" | "send_failed" | "draft_failed"
  sent_variant              TEXT,                  -- "a" | "b" | "c"
  sent_at                   TIMESTAMPTZ,
  edited_before_send        BOOLEAN DEFAULT false,
  voice_profile_version     TEXT,
  brain_query_used          TEXT,
  context_snapshot_age_days INT,
  drafted_at                TIMESTAMPTZ DEFAULT NOW(),
  created_at                TIMESTAMPTZ DEFAULT NOW(),
  updated_at                TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_reply_drafts_reply          ON reply_drafts(reply_id);
CREATE INDEX IF NOT EXISTS idx_reply_drafts_classification  ON reply_drafts(classification_id) WHERE classification_id IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_reply_drafts_status         ON reply_drafts(draft_status);


-- ───────────────────────────────────────────────────────────────
-- Follow-up log — per-contact decision audit trail (D25)
-- Written by manage_followup with one row per contact per run.
-- Read by gtm_report for advance rate, stop reasons, hold warnings.
-- ───────────────────────────────────────────────────────────────

CREATE TABLE IF NOT EXISTS followup_log (
  id                UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  contact_id        UUID REFERENCES contacts(id) ON DELETE SET NULL,
  sequence_id       UUID REFERENCES sequences(id) ON DELETE SET NULL,
  team_id           UUID,
  channel           TEXT,                    -- "email" | "linkedin"
  touch_number      INT,
  decision          TEXT NOT NULL,
    -- "advance" | "accelerate" | "switch_channel" | "pause" | "stop"
    -- | "held_pending_classification"
  stop_reason       TEXT,
  hold_reason       TEXT,
  hold_warning      BOOLEAN DEFAULT false,   -- true if held > 4 hours
  signals_snapshot  JSONB,                   -- full signal bundle at decision time
  draft             JSONB,                   -- generated draft object (if applicable)
  draft_rationale   TEXT,
  status            TEXT,
    -- "queued" | "paused" | "stopped" | "held" | "skipped_no_ai" | "queued_locally"
  logged_at         TIMESTAMPTZ DEFAULT NOW(),
  created_at        TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_followup_log_contact   ON followup_log(contact_id) WHERE contact_id IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_followup_log_decision  ON followup_log(decision);
CREATE INDEX IF NOT EXISTS idx_followup_log_logged_at ON followup_log(logged_at DESC);


-- ───────────────────────────────────────────────────────────────
-- Enrichment cache — prospect context snapshots (D18 draft_reply)
-- Written by enrich_contact / draft_reply context refresh.
-- Read by draft_reply to check snapshot freshness before generating.
-- ───────────────────────────────────────────────────────────────

CREATE TABLE IF NOT EXISTS enrichment_cache (
  id                UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  contact_id        UUID REFERENCES contacts(id) ON DELETE CASCADE,
  domain            TEXT,
  linkedin_headline TEXT,
  recent_activity   TEXT,
  company_context   TEXT,
  snapshot          JSONB,          -- full raw enrichment snapshot
  team_id           UUID,
  enriched_at       TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  created_at        TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_enrichment_cache_contact    ON enrichment_cache(contact_id, enriched_at DESC) WHERE contact_id IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_enrichment_cache_domain     ON enrichment_cache(domain, enriched_at DESC) WHERE domain IS NOT NULL;


-- ───────────────────────────────────────────────────────────────
-- Content calendar — scheduled post slots (D27 manage_content_calendar)
-- Created and managed solely by manage_content_calendar.
-- Lives in starter schema for consistency (students run schema once).
-- ───────────────────────────────────────────────────────────────

CREATE TABLE IF NOT EXISTS content_calendar (
  id             UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  post_id        UUID REFERENCES posts(id),
  scheduled_at   TIMESTAMPTZ,
  status         TEXT NOT NULL DEFAULT 'planned',
    -- "planned" | "scheduled" | "queued" | "skipped" | "draft_failed"
  theme_tags     TEXT[],
  source_skill   TEXT,
  source_detail  JSONB,
  run_id         UUID,
  run_at         TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  team_id        UUID,
  UNIQUE (scheduled_at, team_id)
);

CREATE INDEX IF NOT EXISTS idx_cc_team_id  ON content_calendar(team_id);
CREATE INDEX IF NOT EXISTS idx_cc_run_id   ON content_calendar(run_id);
CREATE INDEX IF NOT EXISTS idx_cc_status   ON content_calendar(status);
CREATE INDEX IF NOT EXISTS idx_cc_sched_at ON content_calendar(scheduled_at DESC);


-- ───────────────────────────────────────────────────────────────
-- Follow-up queues — D25 → D19/D20 pickup tables
-- Written by manage_followup; consumed by push_to_inbox (email)
-- and linkedin_outreach (LinkedIn) on their next run.
-- ───────────────────────────────────────────────────────────────

CREATE TABLE IF NOT EXISTS followup_email_queue (
  id               UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  followup_log_id  UUID REFERENCES followup_log(id) ON DELETE CASCADE,
  contact_id       UUID REFERENCES contacts(id) ON DELETE SET NULL,
  campaign_id      TEXT,
  subject          TEXT,
  body             TEXT,
  scheduled_for    TIMESTAMPTZ,
  status           TEXT DEFAULT 'queued',   -- "queued" | "sent" | "failed" | "skipped"
  team_id          UUID,
  created_at       TIMESTAMPTZ DEFAULT NOW(),
  updated_at       TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_feq_status        ON followup_email_queue(status);
CREATE INDEX IF NOT EXISTS idx_feq_scheduled_for ON followup_email_queue(scheduled_for) WHERE status = 'queued';

CREATE TABLE IF NOT EXISTS followup_linkedin_queue (
  id               UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  followup_log_id  UUID REFERENCES followup_log(id) ON DELETE CASCADE,
  contact_id       UUID REFERENCES contacts(id) ON DELETE SET NULL,
  campaign_id      TEXT,
  linkedin_url     TEXT,
  body             TEXT,
  scheduled_for    TIMESTAMPTZ,
  status           TEXT DEFAULT 'queued',   -- "queued" | "sent" | "failed" | "skipped"
  team_id          UUID,
  created_at       TIMESTAMPTZ DEFAULT NOW(),
  updated_at       TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_flq_status        ON followup_linkedin_queue(status);
CREATE INDEX IF NOT EXISTS idx_flq_scheduled_for ON followup_linkedin_queue(scheduled_for) WHERE status = 'queued';


-- ───────────────────────────────────────────────────────────────
-- Meetings — booked + completed calls (D25 manage_followup, D28)
-- Written when a booking_intent reply is actioned and a meeting is
-- booked. Read by gtm_report for meeting delta metrics.
-- ───────────────────────────────────────────────────────────────

CREATE TABLE IF NOT EXISTS meetings (
  id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  contact_id    UUID REFERENCES contacts(id) ON DELETE SET NULL,
  reply_id      UUID REFERENCES replies(id) ON DELETE SET NULL,
  status        TEXT DEFAULT 'booked',  -- "booked" | "completed" | "cancelled" | "no_show"
  booked_at     TIMESTAMPTZ,
  scheduled_for TIMESTAMPTZ,
  completed_at  TIMESTAMPTZ,
  duration_min  INT,
  notes         TEXT,
  team_id       UUID,
  created_at    TIMESTAMPTZ DEFAULT NOW(),
  updated_at    TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_meetings_contact    ON meetings(contact_id) WHERE contact_id IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_meetings_status     ON meetings(status);
CREATE INDEX IF NOT EXISTS idx_meetings_created_at ON meetings(created_at DESC);


-- ───────────────────────────────────────────────────────────────
-- Schema extensions — additive ALTERs on existing tables
-- These columns are added here (not inline above) so re-runs are
-- safe on schemas that were created before these columns existed.
-- ───────────────────────────────────────────────────────────────

-- Gap 4: suppression_list — link to known contacts for cross-channel tracing
ALTER TABLE suppression_list
  ADD COLUMN IF NOT EXISTS contact_id UUID REFERENCES contacts(id) ON DELETE SET NULL;

CREATE INDEX IF NOT EXISTS idx_suppression_contact
  ON suppression_list(contact_id) WHERE contact_id IS NOT NULL;

-- Gap 5: funnel_leads — link inbound leads to the contact record they became
ALTER TABLE funnel_leads
  ADD COLUMN IF NOT EXISTS promoted_to_contact_id UUID REFERENCES contacts(id) ON DELETE SET NULL;

CREATE INDEX IF NOT EXISTS idx_funnel_leads_contact
  ON funnel_leads(promoted_to_contact_id) WHERE promoted_to_contact_id IS NOT NULL;


-- ───────────────────────────────────────────────────────────────
-- updated_at triggers (Postgres doesn't auto-update timestamps)
-- ───────────────────────────────────────────────────────────────

CREATE OR REPLACE FUNCTION touch_updated_at() RETURNS trigger AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DO $$
DECLARE
  t TEXT;
BEGIN
  FOR t IN SELECT unnest(ARRAY[
    'companies','contacts','replies','sequences','posts','lead_magnets','funnel_leads',
    'outreach_campaigns','outreach_campaign_leads','reply_classifications','reply_drafts',
    'outreach_cross_channel_state','linkedin_campaigns','followup_email_queue',
    'followup_linkedin_queue','meetings','agentmail_inboxes'
  ])
  LOOP
    EXECUTE format('DROP TRIGGER IF EXISTS trg_touch_%I ON %I;', t, t);
    EXECUTE format('CREATE TRIGGER trg_touch_%I BEFORE UPDATE ON %I FOR EACH ROW EXECUTE FUNCTION touch_updated_at();', t, t);
  END LOOP;
END $$;


-- ───────────────────────────────────────────────────────────────
-- LinkedIn connection lifecycle (added 2026-05-09)
-- Tracks per-touch HeyReach connection requests. Skills that write here:
-- send_connections, push_to_inbox cohort skill, manage_followup.
-- Kept separate from outreach_cross_channel_state (high-level state) to
-- preserve full request history and to avoid bloating contacts.
-- ───────────────────────────────────────────────────────────────

CREATE TABLE IF NOT EXISTS linkedin_connections (
  id                          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  contact_id                  UUID NOT NULL REFERENCES contacts(id) ON DELETE CASCADE,
  campaign_id                 UUID REFERENCES outreach_campaigns(id) ON DELETE SET NULL,
  -- Provider tracking
  provider                    TEXT NOT NULL DEFAULT 'heyreach',  -- 'heyreach' | 'unipile' | 'manual'
  heyreach_request_id         TEXT,                              -- external HeyReach ID for trace
  heyreach_campaign_id        TEXT,                              -- HeyReach campaign that handled the request
  -- Lifecycle
  status                      TEXT NOT NULL DEFAULT 'queued',
    -- 'queued' | 'sent' | 'accepted' | 'rejected' | 'withdrawn' | 'expired' | 'failed'
  status_at                   TIMESTAMPTZ DEFAULT NOW(),
  sent_at                     TIMESTAMPTZ,
  accepted_at                 TIMESTAMPTZ,
  withdrawn_at                TIMESTAMPTZ,
  -- Note content snapshot
  note_template_id            TEXT,
  note_text                   TEXT,
  -- Idempotency: hash(contact_id + campaign_id + send_attempt_n) prevents double-sends.
  attempt_key                 TEXT NOT NULL,
  created_at                  TIMESTAMPTZ DEFAULT NOW(),
  updated_at                  TIMESTAMPTZ DEFAULT NOW(),
  CONSTRAINT linkedin_connections_attempt_key_unique UNIQUE (attempt_key)
);

CREATE INDEX IF NOT EXISTS idx_lkc_contact ON linkedin_connections(contact_id);
CREATE INDEX IF NOT EXISTS idx_lkc_campaign ON linkedin_connections(campaign_id) WHERE campaign_id IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_lkc_status ON linkedin_connections(status);
CREATE INDEX IF NOT EXISTS idx_lkc_heyreach_id ON linkedin_connections(heyreach_request_id) WHERE heyreach_request_id IS NOT NULL;

DROP TRIGGER IF EXISTS trg_touch_linkedin_connections ON linkedin_connections;
CREATE TRIGGER trg_touch_linkedin_connections
BEFORE UPDATE ON linkedin_connections
FOR EACH ROW EXECUTE FUNCTION touch_updated_at();


-- ───────────────────────────────────────────────────────────────
-- Done.
-- ───────────────────────────────────────────────────────────────
--
-- To verify:
--   SELECT table_name FROM information_schema.tables
--   WHERE table_schema = 'public'
--     AND table_name IN (
--       'companies','contacts','signals','replies','sequences',
--       'posts','post_engagements','lead_magnets','funnel_leads','journal','brain_chunks',
--       'outreach_campaigns','outreach_campaign_leads','reply_classifications',
--       'suppression_list','outreach_cross_channel_state','linkedin_campaigns',
--       'reply_drafts','followup_log','enrichment_cache','content_calendar',
--       'followup_email_queue','followup_linkedin_queue','meetings',
--       'send_attempts','agentmail_inboxes','agentmail_webhook_events',
--       'linkedin_connections'
--     )
--   ORDER BY table_name;
--
-- Should return 28 rows.
