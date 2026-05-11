-- Action items (checkbox to-dos) for each module of Maestro Quickstart.
-- Students tick them off as they go via lms_student_action_item_progress.
-- Idempotent: DELETEs existing items for the course's weeks before re-inserting.

BEGIN;

DO $$
DECLARE
  v_cohort_id UUID;
  v_week_id UUID;
  v_workspace UUID := '00000000-0000-0000-0000-000000000002';
BEGIN
  SELECT id INTO v_cohort_id FROM lms_cohorts WHERE name = 'Maestro Quickstart';

  -- Wipe existing action items for this course (idempotency)
  DELETE FROM lms_action_items
  WHERE week_id IN (SELECT id FROM lms_weeks WHERE cohort_id = v_cohort_id);

  -- ============================================================
  -- Module 1 — Setup
  -- ============================================================
  SELECT id INTO v_week_id FROM lms_weeks WHERE cohort_id = v_cohort_id AND title = 'Module 1 — Setup';

  INSERT INTO lms_action_items (workspace_id, week_id, text, description, sort_order) VALUES
  (v_workspace, v_week_id, 'Install Node.js 18+', 'The bootstrap script does this for you if it''s missing. Verify with `node --version`.', 1),
  (v_workspace, v_week_id, 'Install Claude Code (CLI or desktop)', 'From claude.ai/code. Either surface works — they share the same skill system.', 2),
  (v_workspace, v_week_id, 'Run `npx @maestrogtm/quickstart` (or the curl|bash bootstrap)', 'Drops the skill into ~/.claude/skills/quickstart/ on your computer.', 3),
  (v_workspace, v_week_id, 'Sign up at supabase.com (free tier)', 'Email + password. Verify your inbox link before continuing.', 4),
  (v_workspace, v_week_id, 'Generate a Supabase Personal Access Token', 'Dashboard → Account → Access Tokens → "Generate new token". Copy it; you only see it once.', 5),
  (v_workspace, v_week_id, 'Type `/quickstart` in Claude Code and complete kickoff', 'Tell the agent your ICP. data/icp.md gets written — that''s your captured ICP for the rest of the flow.', 6);

  -- ============================================================
  -- Module 2 — Data Layer
  -- ============================================================
  SELECT id INTO v_week_id FROM lms_weeks WHERE cohort_id = v_cohort_id AND title = 'Module 2 — Data Layer';

  INSERT INTO lms_action_items (workspace_id, week_id, text, description, sort_order) VALUES
  (v_workspace, v_week_id, 'Apply the GTM schema (28 tables)', 'Agent runs the migration via Supabase Management API. Refresh the Table Editor to see them.', 1),
  (v_workspace, v_week_id, 'Sign up at deepline.app (Google OAuth)', 'One-click signup. Free search tier on most tools.', 2),
  (v_workspace, v_week_id, 'Generate a Deepline API key', 'Dashboard → API Keys → Generate. Paste it into the agent when prompted.', 3),
  (v_workspace, v_week_id, 'Confirm the $50/mo spend cap is set', 'Agent runs `deepline billing --set-monthly-limit 50` automatically. Verify in deepline.app billing settings.', 4);

  -- ============================================================
  -- Module 3 — Build a List
  -- ============================================================
  SELECT id INTO v_week_id FROM lms_weeks WHERE cohort_id = v_cohort_id AND title = 'Module 3 — Build a List';

  INSERT INTO lms_action_items (workspace_id, week_id, text, description, sort_order) VALUES
  (v_workspace, v_week_id, 'Run the first_workflow with your ICP', 'Agent translates ICP to provider filters, shows you cost, then runs the enrichment waterfall.', 1),
  (v_workspace, v_week_id, 'Confirm contacts landed in Supabase', 'Refresh the `contacts` table — you should see real rows with emails, titles, LinkedIn URLs.', 2),
  (v_workspace, v_week_id, 'Run apply_formula to clean titles (or another column)', 'Demonstrates the SELECT→transform→UPDATE pattern. Free, fast.', 3);

  -- ============================================================
  -- Module 4 — Build the Campaign
  -- ============================================================
  SELECT id INTO v_week_id FROM lms_weeks WHERE cohort_id = v_cohort_id AND title = 'Module 4 — Build the Campaign';

  INSERT INTO lms_action_items (workspace_id, week_id, text, description, sort_order) VALUES
  (v_workspace, v_week_id, 'Complete the discovery (4-6 questions with the agent)', 'Agent asks about your business, customer, proof, lead magnet. The consultation IS the value.', 1),
  (v_workspace, v_week_id, 'Get an honest offer assessment from the agent', 'Strong, OK, or weak — and what to fix if weak. Don''t skip this step.', 2),
  (v_workspace, v_week_id, 'Confirm `data/campaign/offer.md` exists', '2-4 paragraphs describing your offer: what''s free, who it''s for, why now, what to expect.', 3),
  (v_workspace, v_week_id, 'Confirm `data/campaign/sequence.md` exists', '2- or 4-email sequence drafted by the agent. Open it, read it, edit anything that doesn''t sound like you.', 4),
  (v_workspace, v_week_id, 'Pick your per-row personalization path', 'Skip openers / templated / real signal-grounded. The agent recommends based on your angle.', 5);

  -- ============================================================
  -- Module 5 — Send & Ship
  -- ============================================================
  SELECT id INTO v_week_id FROM lms_weeks WHERE cohort_id = v_cohort_id AND title = 'Module 5 — Send & Ship';

  INSERT INTO lms_action_items (workspace_id, week_id, text, description, sort_order) VALUES
  (v_workspace, v_week_id, 'Pick a sending option (AgentMail / Instantly / Smartlead / Gmail manual)', 'Most buyers should pick AgentMail (option 1) — free tier, fully wired here. Bootcamp covers Instantly/Smartlead.', 1),
  (v_workspace, v_week_id, 'Sign up at agentmail.to and paste API key', 'Free tier covers 3 inboxes. Agent creates a scoped key for you.', 2),
  (v_workspace, v_week_id, 'Pick a sending domain', 'Your subdomain (mail.youragency.com), a sister domain, or let AgentMail buy one for you.', 3),
  (v_workspace, v_week_id, 'Add DNS records at your registrar (MX + SPF + DKIM + DMARC)', 'Agent generates them; paste at your registrar. Propagation is 5-60 minutes.', 4),
  (v_workspace, v_week_id, '2 mailboxes provisioned, warmup started', 'Your mailboxes are now warming for 14-21 days. Do NOT cold-send before warmup completes.', 5),
  (v_workspace, v_week_id, 'Run the test send to your personal email', 'Agent sends Email 1 of your sequence to you. Confirm it lands in inbox (not spam).', 6),
  (v_workspace, v_week_id, 'Reply to the test email and verify the webhook fired', 'Reply with anything. Within ~30 seconds the row should appear in your Supabase `replies` table.', 7),
  (v_workspace, v_week_id, 'Set a launch date (14-21 days from today)', 'Block 2 hours on your calendar. That''s when warmup ends and your real first cold send goes out.', 8);

END $$;

COMMIT;
