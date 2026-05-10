# Multi-seat / team economics — what does this cost at scale?

For buyers asking "what's the realistic annual cost for my team running
this kind of recipe weekly / daily?" These are estimates grounded in
Deepline's posted pricing ($0.10/credit) and real call costs from the
catalog. Always show the math; never quote a single number.

---

## Per-run cost (the unit)

The Quickstart's review path runs ~$0-$1 per run, dominated by the email-
finder waterfall. Breakdown:

- Dropleads search (companies + contacts): **$0** (free)
- Email waterfall (per contact, when one provider hits):
  - Dropleads finder: $0 if BYOK Dropleads, ~$0.04 managed
  - Hunter: $0 if BYOK Hunter, ~$0.04 managed
  - LeadMagic: ~$0.02 managed
  - Findymail: ~$0.06 managed
  - The waterfall stops at the first hit, so a typical row costs
    $0.02–$0.06 (the cheapest provider that returned)

For 25 contacts where 60% produce emails: 15 emails × $0.04 average =
**$0.60 per run**.

For 100 contacts: ~$2.40 per run.

For 500 contacts: ~$12 per run.

These assume managed credits. With BYOK on Hunter or LeadMagic the same
runs cost ~30-60% less.

---

## Annual cost projections by team size and cadence

Math: per-run × runs-per-week × 52 weeks. Assume ~25 contacts per run on
average for the Quickstart-shape pipeline (small ICP probes); 100 if the
team builds bigger TAMs weekly.

### Solo / 1-seat (founder, agency-of-one)

- 1 run/week × ~25 contacts = $0.60/week × 52 = **~$30/year**
- 1 run/week × ~100 contacts = $2.40/week × 52 = **~$125/year**

Free signup credits typically cover the first ~2 months.

### Small team (3-5 seats), each running weekly

- 5 seats × 1 run/week × 25 contacts = $3/week × 52 = **~$155/year**
- 5 seats × 1 run/week × 100 contacts = $12/week × 52 = **~$625/year**

Multi-seat note: Deepline's monthly cap is **per-org, not per-seat**.
That means a 5-person team sharing one Deepline org also shares the cap;
no one teammate can blow the budget. Set the cap at 5x what one seat
needs.

### Medium team (10 seats), each running daily

- 10 seats × 5 runs/week × 25 contacts = $30/week × 52 = **~$1,560/year**
- 10 seats × 5 runs/week × 100 contacts = $120/week × 52 = **~$6,240/year**

This is the breakpoint where BYOK starts paying off hard. If your team
has Apollo or Hunter subscriptions ($99/mo Apollo seat × 10 = $11,880/yr
flat), routing email-finding through BYOK Apollo zeros out Deepline's
managed-credit bill for those calls. Net: $0 Deepline + your existing
Apollo bill.

### Comparison points the buyer might bring

**Clay**: typical agency uses $300-$2,000/month per seat at this kind of
volume. The pricing is opaque (credits + actions + AI columns), and runs
without spend caps default to "keep going." A burned Clay buyer often
has a bill 3-5x their estimate.

**Apollo direct (no Deepline)**: $99/seat/month, unlimited search +
enrichment with throttling. For teams already paying, BYOK in Deepline
gets you Apollo's coverage WITHOUT Deepline managed-credit charges, AND
you still get the waterfall fallback for non-Apollo providers.

**Hunter standalone**: $34-$149/month tiered, capped at lookups/month.
Cheap if email-finding is your only need. With Deepline BYOK Hunter,
your monthly Hunter quota is what governs cost.

---

## What buyers should set up to keep this safe

1. **Spend cap, day one.** `deepline billing --set-monthly-limit 50`
   ($5) is the right floor for most. Raise as volume grows. The cap is
   server-side and REJECTS calls that would exceed it — Deepline won't
   bill you past your cap.

2. **Dry-run before any non-trivial enrichment.** `deepline enrich
   --dry-run` shows the expansion + max credit estimate. Standard
   practice for runs over 50 rows.

3. **BYOK what you already pay for.** If your team has Apollo, Hunter,
   Crustdata, or PDL subscriptions, plug those keys into Deepline at
   `https://deepline.app/integrations`. Routes calls through your
   existing account at zero Deepline markup.

4. **Cache and idempotency.** The Quickstart's `data/.first-workflow-
   result.json` cache means re-running doesn't re-charge. Same pattern
   in production: cache enrichment results in your own DB, only call
   Deepline for net-new contacts.

---

## What the agent should say to a multi-seat buyer

When the buyer asks about team costs, walk through:

1. Their team size + run cadence (ask if not given).
2. The per-run math above.
3. Their volume × cadence × 52.
4. The BYOK lever if they already pay for providers.
5. The spend-cap recommendation.

Then offer to set up the cap and a BYOK walkthrough if applicable.

**Do NOT quote a single annual number without the math.** Buyers like
Sarah (previously burned by opaque Clay bills) anchor on the number AND
suspect anything that doesn't show its work. The math IS the trust
move.
