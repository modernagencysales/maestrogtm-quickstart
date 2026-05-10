# Team handoff — Day 2 onboarding for the rest of your team

For buyers who want to onboard 2-10 teammates onto the same agentic GTM
stack they just set up. Mark (a 5-seat team buyer) will literally use
this as the message he sends to his SDRs.

---

## What's shared vs what's per-user

| Resource | Shared or per-user? | Notes |
|---|---|---|
| Supabase project | Shared | Everyone on the team uses the same project (e.g. `ipbffmnildqbpcygnjih.supabase.co`). All contacts, companies, replies live in one place. |
| Supabase API keys | Shared | Distributed via your team's secrets manager (1Password, Doppler, just a private Slack channel for small teams). Each teammate puts them in their own `secrets/.env`. |
| Deepline org | Shared | Single org; everyone's calls bill against the same wallet. Cap is per-org, so the team shares the budget ceiling. |
| Deepline auth (per-user) | Per-user | Each teammate runs `deepline auth register` once on their own machine. They get an invite link from the org owner (you) at deepline.app → Settings → Team. |
| BYOK keys (Apollo, Hunter, etc.) | Shared at org | Plugged in once at deepline.app/integrations; all org members benefit. |
| Quickstart skill files | Per-machine | Each teammate installs the skill once: `~/.claude/skills/quickstart/`. They get the latest version when they pull from your team's skill repo (or you ship them updates). |
| Schema / migrations | Already-applied | The 28 tables are in Supabase already. New teammates skip `schema_migrate` (the verifier short-circuits). |

---

## The Day-2 onboarding script (for SDRs / teammates)

Tell your team to run these in order on their own machine:

```bash
# 1. Make sure they have Claude Code (claude.com/cli or `brew install claude-code`)
claude --version

# 2. Install the Quickstart skill
# (From your team's repo, or copy the directory across)
cp -r /path/to/skill ~/.claude/skills/quickstart/

# 3. Set up Deepline auth (one browser flow per user)
deepline auth register
# When prompted, accept the invite to your team org

# 4. Set up Supabase auth (or just paste the keys into secrets/.env)
mkdir -p ~/my-gtm-work && cd ~/my-gtm-work
mkdir -p secrets
cat > secrets/.env << EOF
SUPABASE_URL=<your shared URL>
SUPABASE_ANON_KEY=<your shared anon key>
SUPABASE_SERVICE_ROLE_KEY=<your shared service-role key>
EOF
chmod 600 secrets/.env

# 5. Run /quickstart and skip directly to first_workflow
claude
> /quickstart goto first_workflow
```

The verifiers will short-circuit through `kickoff`, `supabase_setup`,
`schema_migrate`, and `wire_deepline` because the upstream resources
are all already set up. Each teammate lands directly at the "find
companies + contacts for this ICP" step.

---

## Budget control across teammates

**Today's reality:** Deepline's monthly cap is **per-org, not per-user**.
You set ONE cap (`deepline billing --set-monthly-limit N`) and everyone
on the org shares it. If one teammate burns 80% of the cap, the others
hit it next.

**Workarounds for asymmetric access:**

1. **Separate orgs for contractors** — Move freelancers to their own
   Deepline org with a tiny cap (e.g. 10 credits/$1). They can't touch
   your team's wallet. Costs nothing extra — Deepline orgs are free to
   create. Downside: BYOK keys don't share across orgs; each org needs
   its own.

2. **BYOK isolation** — Give the contractor only a low-quota provider
   key (e.g. a Hunter starter plan capped at 25 lookups/month) instead
   of access to your team's Apollo key. Soft cap via the underlying
   provider's own quota.

3. **Procedural** — SDRs have CLI access; contractor submits CSV
   requests to a designated runner (you), who executes against the
   team org. Highest control, lowest velocity. Reasonable for new
   contractors during a trust-building period.

---

## Recipes the team will run

These are the common workflows your team will repeat (each = a re-run
of `/quickstart goto first_workflow` with different ICP inputs):

- **Daily ICP probe** — 10-25 contacts on a tight ICP, $0.30-$0.50.
  Run before the morning sales standup. Output goes to Supabase, gets
  AI-personalized lines, lands in your CRM via the post-Quickstart
  push (see `~/.claude/skills/deepline-gtm/provider-playbooks/{salesforce,
  hubspot,attio}.md`).
- **Weekly TAM build** — 100-500 contacts on a broader ICP, $1-$5.
  Run Monday morning. Same flow.
- **Niche prospecting** — 5-10 contacts on a very tight ICP (named
  accounts, specific job-change signals). Mostly free if Dropleads
  hits.

---

## What to tell your team about cost

Show them this conversation:

```
You: "Our team cap is $20/month. The Quickstart's daily probe runs
~$0.30-$0.50 per run. Two SDRs running daily × 5 days × 4 weeks =
roughly $24/month — we'll hit the cap. Set your cadence to 3x/week
or BYOK Hunter to bring it down."
```

Replace the numbers with your team's actuals. Math from
`multi-seat-economics.md`.

---

## Common Day-2 questions

**"What if I need to add a new column to the contacts table?"**
Edit `~/.claude/skills/quickstart/templates/gtm-starter-schema.sql`,
write a new migration file under `supabase/migrations/`, run
`supabase db push` (or POST to the Mgmt API). The schema is yours; you
own it.

**"Can I run this against a different Supabase project?"**
Yes. Each teammate can have their own `secrets/.env` pointing at a
different Supabase project. The schema applies the same way.

**"Where do I see what other teammates are running?"**
`deepline billing usage --json` shows recent calls across the org.
Pipe to jq for filtering.

**"How do I handle when the cap fires?"**
Either raise the cap (`deepline billing --set-monthly-limit <higher>`),
wait until next month's cycle, or BYOK to take that provider off
managed credits. The cap is a feature, not a bug — it's stopping you
from accidentally overspending.
