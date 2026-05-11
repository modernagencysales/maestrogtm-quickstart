-- Maestro Quickstart — LMS course seed
--
-- Inserts a new cohort (course) into the gtm-os LMS schema with 5 modules,
-- 10 lessons, and placeholder content items ready for video upload.
--
-- Idempotent — safe to run multiple times. Re-running won't duplicate rows
-- but will update titles/descriptions/sort_order to match this file.
--
-- Run this in the Supabase SQL Editor for project qvawbxpijxlwdkolmjrs
-- (the shared mas-platform project), or via:
--   POST /v1/projects/qvawbxpijxlwdkolmjrs/database/query
--
-- After inserting: replace the `REPLACE_WITH_VIDEO_URL_*` placeholders with
-- the actual YouTube unlisted (or other) URLs once videos are recorded.

BEGIN;

-- ============================================
-- 1. Cohort = the course itself
-- ============================================

INSERT INTO lms_cohorts (
  workspace_id,
  name,
  description,
  status,
  sidebar_label,
  icon,
  sort_order,
  product_type,
  thrivecart_product_id,
  onboarding_config
)
VALUES (
  '00000000-0000-0000-0000-000000000002',  -- shared LMS workspace
  'Maestro Quickstart',
  'An AI coach walks you through building a real cold-email machine on your computer — Supabase database, Deepline data layer, AgentMail sending, a campaign drafted around your offer. ~60-90 minutes end-to-end.',
  'Active',
  'Quickstart',
  '⚡',
  5,  -- before GTM Engineer (10) and Foundations (20)
  'course',
  NULL,  -- TODO: set the ThriveCart product ID after Stripe/ThriveCart setup
  jsonb_build_object(
    'install_command', 'npx @maestrogtm/quickstart',
    'requires', jsonb_build_array('Claude Code', 'Node.js 16+'),
    'time_to_complete_minutes', 90,
    'cli_run_command', '/quickstart'
  )
)
ON CONFLICT (name) DO UPDATE SET
  description = EXCLUDED.description,
  sidebar_label = EXCLUDED.sidebar_label,
  icon = EXCLUDED.icon,
  sort_order = EXCLUDED.sort_order,
  onboarding_config = EXCLUDED.onboarding_config,
  updated_at = NOW();

-- Capture the cohort id for use below
DO $$
DECLARE
  v_cohort_id UUID;
  v_week_id UUID;
  v_lesson_id UUID;
BEGIN
  SELECT id INTO v_cohort_id FROM lms_cohorts WHERE name = 'Maestro Quickstart';

  -- ============================================
  -- 2. Weeks (modules)
  -- ============================================

  -- Module 1 — Setup
  INSERT INTO lms_weeks (workspace_id, cohort_id, title, description, sort_order)
  VALUES ('00000000-0000-0000-0000-000000000002', v_cohort_id, 'Module 1 — Setup', 'Install Claude Code, install the Quickstart skill, sign up for Supabase.', 1)
  ON CONFLICT (cohort_id, title) DO UPDATE SET description = EXCLUDED.description, sort_order = EXCLUDED.sort_order
  RETURNING id INTO v_week_id;

  -- Lesson 1.1 — What you bought + install
  INSERT INTO lms_lessons (workspace_id, week_id, title, description, sort_order)
  VALUES ('00000000-0000-0000-0000-000000000002', v_week_id, 'What you bought + install', 'What this product is, how Claude Code fits in, and how to drop the skill onto your machine.', 1)
  ON CONFLICT DO NOTHING;
  SELECT id INTO v_lesson_id FROM lms_lessons WHERE week_id = v_week_id AND title = 'What you bought + install';
  INSERT INTO lms_content_items (workspace_id, lesson_id, title, content_type, embed_url, description, sort_order)
  VALUES ('00000000-0000-0000-0000-000000000002', v_lesson_id, 'Video 1 — Install', 'video', 'REPLACE_WITH_VIDEO_URL_1', 'Install Claude Code, run npx @maestrogtm/quickstart, open the agent.', 1)
  ON CONFLICT DO NOTHING;
  INSERT INTO lms_content_items (workspace_id, lesson_id, title, content_type, content_text, sort_order)
  VALUES ('00000000-0000-0000-0000-000000000002', v_lesson_id, 'Install command', 'text',
    E'```bash\nnpx @maestrogtm/quickstart\n```\n\nThen open Claude Code (`claude`) and type `/quickstart`.', 2)
  ON CONFLICT DO NOTHING;

  -- Lesson 1.2 — Supabase signup + PAT
  INSERT INTO lms_lessons (workspace_id, week_id, title, description, sort_order)
  VALUES ('00000000-0000-0000-0000-000000000002', v_week_id, 'Supabase signup + PAT', 'What a database is, why you own your own, and how to give the agent access via a Personal Access Token.', 2)
  ON CONFLICT DO NOTHING;
  SELECT id INTO v_lesson_id FROM lms_lessons WHERE week_id = v_week_id AND title = 'Supabase signup + PAT';
  INSERT INTO lms_content_items (workspace_id, lesson_id, title, content_type, embed_url, description, sort_order)
  VALUES ('00000000-0000-0000-0000-000000000002', v_lesson_id, 'Video 2 — Supabase signup + PAT', 'video', 'REPLACE_WITH_VIDEO_URL_2', 'Sign up at supabase.com, generate a Personal Access Token, paste it into the agent.', 1)
  ON CONFLICT DO NOTHING;
  INSERT INTO lms_content_items (workspace_id, lesson_id, title, content_type, embed_url, description, sort_order)
  VALUES ('00000000-0000-0000-0000-000000000002', v_lesson_id, 'Supabase signup', 'external_link', 'https://supabase.com', 'Sign up here (free tier covers everything in this course).', 2)
  ON CONFLICT DO NOTHING;
  INSERT INTO lms_content_items (workspace_id, lesson_id, title, content_type, embed_url, description, sort_order)
  VALUES ('00000000-0000-0000-0000-000000000002', v_lesson_id, 'Generate your PAT', 'external_link', 'https://supabase.com/dashboard/account/tokens', 'Direct link to the token page.', 3)
  ON CONFLICT DO NOTHING;

  -- Module 2 — Data Layer
  INSERT INTO lms_weeks (workspace_id, cohort_id, title, description, sort_order)
  VALUES ('00000000-0000-0000-0000-000000000002', v_cohort_id, 'Module 2 — Data Layer', 'Apply the GTM schema, wire up Deepline for 1,000+ data tools.', 2)
  ON CONFLICT (cohort_id, title) DO UPDATE SET description = EXCLUDED.description, sort_order = EXCLUDED.sort_order
  RETURNING id INTO v_week_id;

  -- Lesson 2.1 — The 28 tables
  INSERT INTO lms_lessons (workspace_id, week_id, title, description, sort_order)
  VALUES ('00000000-0000-0000-0000-000000000002', v_week_id, 'The 28 tables and what they''re for', 'What a GTM data model looks like and why it''s shaped this way. Walk-through of the table groups.', 1)
  ON CONFLICT DO NOTHING;
  SELECT id INTO v_lesson_id FROM lms_lessons WHERE week_id = v_week_id AND title = 'The 28 tables and what they''re for';
  INSERT INTO lms_content_items (workspace_id, lesson_id, title, content_type, embed_url, description, sort_order)
  VALUES ('00000000-0000-0000-0000-000000000002', v_lesson_id, 'Video 3 — Schema migrate', 'video', 'REPLACE_WITH_VIDEO_URL_3', 'Agent applies the 28-table schema via Management API. Tour the core tables.', 1)
  ON CONFLICT DO NOTHING;

  -- Lesson 2.2 — Deepline
  INSERT INTO lms_lessons (workspace_id, week_id, title, description, sort_order)
  VALUES ('00000000-0000-0000-0000-000000000002', v_week_id, 'Deepline — one key, 1000+ tools', 'What data providers are, why people use 10 of them, what BYOK means, why we set a spend cap.', 2)
  ON CONFLICT DO NOTHING;
  SELECT id INTO v_lesson_id FROM lms_lessons WHERE week_id = v_week_id AND title = 'Deepline — one key, 1000+ tools';
  INSERT INTO lms_content_items (workspace_id, lesson_id, title, content_type, embed_url, description, sort_order)
  VALUES ('00000000-0000-0000-0000-000000000002', v_lesson_id, 'Video 4 — Wire Deepline', 'video', 'REPLACE_WITH_VIDEO_URL_4', 'Sign up at deepline.app, paste your key, agent sets a $50 monthly cap.', 1)
  ON CONFLICT DO NOTHING;
  INSERT INTO lms_content_items (workspace_id, lesson_id, title, content_type, embed_url, description, sort_order)
  VALUES ('00000000-0000-0000-0000-000000000002', v_lesson_id, 'Deepline signup', 'external_link', 'https://deepline.app', 'Sign up here. Google OAuth, one click.', 2)
  ON CONFLICT DO NOTHING;

  -- Module 3 — Build a List
  INSERT INTO lms_weeks (workspace_id, cohort_id, title, description, sort_order)
  VALUES ('00000000-0000-0000-0000-000000000002', v_cohort_id, 'Module 3 — Build a List', 'Enrich your first list of contacts. Clean the data without spreadsheets.', 3)
  ON CONFLICT (cohort_id, title) DO UPDATE SET description = EXCLUDED.description, sort_order = EXCLUDED.sort_order
  RETURNING id INTO v_week_id;

  -- Lesson 3.1 — First workflow
  INSERT INTO lms_lessons (workspace_id, week_id, title, description, sort_order)
  VALUES ('00000000-0000-0000-0000-000000000002', v_week_id, 'Your first list (the agent thinks out loud)', 'How to think about ICPs, what enrichment waterfalls are, why list-building is half the work.', 1)
  ON CONFLICT DO NOTHING;
  SELECT id INTO v_lesson_id FROM lms_lessons WHERE week_id = v_week_id AND title = 'Your first list (the agent thinks out loud)';
  INSERT INTO lms_content_items (workspace_id, lesson_id, title, content_type, embed_url, description, sort_order)
  VALUES ('00000000-0000-0000-0000-000000000002', v_lesson_id, 'Video 5 — First workflow', 'video', 'REPLACE_WITH_VIDEO_URL_5', 'Watch the agent brainstorm sources, run a real enrichment waterfall, land contacts in Supabase.', 1)
  ON CONFLICT DO NOTHING;

  -- Lesson 3.2 — Apply formula
  INSERT INTO lms_lessons (workspace_id, week_id, title, description, sort_order)
  VALUES ('00000000-0000-0000-0000-000000000002', v_week_id, 'Cleaning data without spreadsheets', 'The SELECT → transform → UPDATE pattern. The single most reusable thing in this course.', 2)
  ON CONFLICT DO NOTHING;
  SELECT id INTO v_lesson_id FROM lms_lessons WHERE week_id = v_week_id AND title = 'Cleaning data without spreadsheets';
  INSERT INTO lms_content_items (workspace_id, lesson_id, title, content_type, embed_url, description, sort_order)
  VALUES ('00000000-0000-0000-0000-000000000002', v_lesson_id, 'Video 6 — Apply formula', 'video', 'REPLACE_WITH_VIDEO_URL_6', 'Demo title normalization, show the before/after pattern that works for any column.', 1)
  ON CONFLICT DO NOTHING;

  -- Module 4 — Build the Campaign
  INSERT INTO lms_weeks (workspace_id, cohort_id, title, description, sort_order)
  VALUES ('00000000-0000-0000-0000-000000000002', v_cohort_id, 'Module 4 — Build the Campaign', 'The piece that justifies the price. Offer, angle, sequence — with the cold-email playbook in the agent''s head.', 4)
  ON CONFLICT (cohort_id, title) DO UPDATE SET description = EXCLUDED.description, sort_order = EXCLUDED.sort_order
  RETURNING id INTO v_week_id;

  -- Lesson 4.1 — Offer, angle, sequence
  INSERT INTO lms_lessons (workspace_id, week_id, title, description, sort_order)
  VALUES ('00000000-0000-0000-0000-000000000002', v_week_id, 'Offer, angle, and sequence', 'Why the offer drives 5-10x more than the opener. The 10 angles. The 4-email structure. The coach-style consultation.', 1)
  ON CONFLICT DO NOTHING;
  SELECT id INTO v_lesson_id FROM lms_lessons WHERE week_id = v_week_id AND title = 'Offer, angle, and sequence';
  INSERT INTO lms_content_items (workspace_id, lesson_id, title, content_type, embed_url, description, sort_order)
  VALUES ('00000000-0000-0000-0000-000000000002', v_lesson_id, 'Video 7 — Build campaign', 'video', 'REPLACE_WITH_VIDEO_URL_7', 'The big one. Watch the agent run a real cold-email strategist consultation.', 1)
  ON CONFLICT DO NOTHING;

  -- Module 5 — Send & Ship
  INSERT INTO lms_weeks (workspace_id, cohort_id, title, description, sort_order)
  VALUES ('00000000-0000-0000-0000-000000000002', v_cohort_id, 'Module 5 — Send & Ship', 'Why you don''t use Gmail. Wire AgentMail end-to-end. Confirm the loop.', 5)
  ON CONFLICT (cohort_id, title) DO UPDATE SET description = EXCLUDED.description, sort_order = EXCLUDED.sort_order
  RETURNING id INTO v_week_id;

  -- Lesson 5.1 — Why not Gmail
  INSERT INTO lms_lessons (workspace_id, week_id, title, description, sort_order)
  VALUES ('00000000-0000-0000-0000-000000000002', v_week_id, 'Why you don''t use Gmail (and what to use)', 'Deliverability fundamentals, why cold email needs its own infra, and the four options.', 1)
  ON CONFLICT DO NOTHING;
  SELECT id INTO v_lesson_id FROM lms_lessons WHERE week_id = v_week_id AND title = 'Why you don''t use Gmail (and what to use)';
  INSERT INTO lms_content_items (workspace_id, lesson_id, title, content_type, embed_url, description, sort_order)
  VALUES ('00000000-0000-0000-0000-000000000002', v_lesson_id, 'Video 8 — Why not Gmail', 'video', 'REPLACE_WITH_VIDEO_URL_8', 'Cold-emailing from your real Gmail tanks your domain in a week. Here''s what to do instead.', 1)
  ON CONFLICT DO NOTHING;

  -- Lesson 5.2 — Wire AgentMail
  INSERT INTO lms_lessons (workspace_id, week_id, title, description, sort_order)
  VALUES ('00000000-0000-0000-0000-000000000002', v_week_id, 'Wire AgentMail end-to-end', 'Sending domains, DNS records, warmup, what''s happening behind each step.', 2)
  ON CONFLICT DO NOTHING;
  SELECT id INTO v_lesson_id FROM lms_lessons WHERE week_id = v_week_id AND title = 'Wire AgentMail end-to-end';
  INSERT INTO lms_content_items (workspace_id, lesson_id, title, content_type, embed_url, description, sort_order)
  VALUES ('00000000-0000-0000-0000-000000000002', v_lesson_id, 'Video 9 — Wire AgentMail', 'video', 'REPLACE_WITH_VIDEO_URL_9', 'Sign up, add DNS records, provision 2 mailboxes, watch warmup start.', 1)
  ON CONFLICT DO NOTHING;
  INSERT INTO lms_content_items (workspace_id, lesson_id, title, content_type, embed_url, description, sort_order)
  VALUES ('00000000-0000-0000-0000-000000000002', v_lesson_id, 'AgentMail signup', 'external_link', 'https://agentmail.to', 'Free tier covers 3 inboxes.', 2)
  ON CONFLICT DO NOTHING;

  -- Lesson 5.3 — Test send + replies + what's next
  INSERT INTO lms_lessons (workspace_id, week_id, title, description, sort_order)
  VALUES ('00000000-0000-0000-0000-000000000002', v_week_id, 'Test send, reply capture, and what''s next', 'Confirm the end-to-end loop. What to do during the warmup period. Where this course ends and the Bootcamp begins.', 3)
  ON CONFLICT DO NOTHING;
  SELECT id INTO v_lesson_id FROM lms_lessons WHERE week_id = v_week_id AND title = 'Test send, reply capture, and what''s next';
  INSERT INTO lms_content_items (workspace_id, lesson_id, title, content_type, embed_url, description, sort_order)
  VALUES ('00000000-0000-0000-0000-000000000002', v_lesson_id, 'Video 10 — Test send + finale', 'video', 'REPLACE_WITH_VIDEO_URL_10', 'Email yourself, reply, watch the webhook fire. Then the Bootcamp / Coaching / Setup upsell.', 1)
  ON CONFLICT DO NOTHING;
  INSERT INTO lms_content_items (workspace_id, lesson_id, title, content_type, embed_url, description, sort_order)
  VALUES ('00000000-0000-0000-0000-000000000002', v_lesson_id, 'Bootcamp — next step', 'external_link', 'https://modernagencysales.com/bootcamp', 'For LinkedIn outreach, scaling past 1k/mo, multi-client setup, and the reply-classification pipeline.', 2)
  ON CONFLICT DO NOTHING;

END $$;

COMMIT;

-- ============================================
-- Verification queries (run separately after the seed)
-- ============================================
-- SELECT id, name, sidebar_label, icon FROM lms_cohorts WHERE name = 'Maestro Quickstart';
-- SELECT w.sort_order, w.title FROM lms_weeks w JOIN lms_cohorts c ON c.id = w.cohort_id WHERE c.name = 'Maestro Quickstart' ORDER BY w.sort_order;
-- SELECT w.title AS module, l.sort_order, l.title AS lesson FROM lms_lessons l JOIN lms_weeks w ON w.id = l.week_id JOIN lms_cohorts c ON c.id = w.cohort_id WHERE c.name = 'Maestro Quickstart' ORDER BY w.sort_order, l.sort_order;
-- SELECT lesson_id, title, content_type, embed_url FROM lms_content_items WHERE lesson_id IN (SELECT l.id FROM lms_lessons l JOIN lms_weeks w ON w.id = l.week_id JOIN lms_cohorts c ON c.id = w.cohort_id WHERE c.name = 'Maestro Quickstart') ORDER BY lesson_id, sort_order;
