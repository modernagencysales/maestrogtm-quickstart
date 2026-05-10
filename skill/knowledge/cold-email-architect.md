# Cold Email Campaign Architect — condensed methodology

> **Use this** as background when running the `ai_personalize` (a.k.a. campaign-build) step.
> Source: Growth Engine X methodology, distilled from 800k-1.5M emails/month across hundreds of campaigns.
> Read top-to-bottom once on first invocation, then pull individual sections as needed.

---

## The frame: cold email is a private ads network

Stop thinking "SDR I can push harder." Think advertising. You optimize:

- **Impressions** = opens (deliverability, subject lines)
- **Targeting** = list quality and segmentation
- **Creative** = messaging, angle, offer

You cannot force meetings. You find the right message for the right person at the right time, or you don't.

**Response-rate benchmarks (positive replies per leads contacted):**

| Tier | Ratio | Notes |
|---|---|---|
| Exceptional | 1 / 10–30 | Killer offer + tiny ICP + perfect timing |
| Great | 1 / 30–100 | Strong offer + good list |
| Average | 1 / 250–400 | Decent everything |
| Poor | 1 / 500–2000 | Weak offer or wrong list |
| Failed | 1 / 2000+ or zero | Commoditized + no differentiation |

**The biggest driver: how much they need your offer right now.** Mediocre copy on a killer offer beats brilliant copy on a weak offer every time.

---

## The Three Pillars

If any pillar fails, the campaign fails.

### 1. Infrastructure
- 50 emails/day/inbox max
- 2 inboxes per domain
- Warm up before sending (14-21 days)
- Open rate as deliverability proxy: 50-80% healthy, <30% serious problem, <15% mostly spam folder
- **Cure for bad deliverability is always: more inboxes on fresh domains.** Not spam tests, not blacklist checkers.

### 2. Segmented ICP list
**Two-step segmentation:**

1. **Minimum qualification** — who should NEVER be contacted. (Industry exclusions, size exclusions, geo, persona, etc.)
2. **Best-customer waterfall** — flip it: "if I had 10 min per prospect, what would I check, and how would that change my message?" Build tiers (T1: all signals true, T2: most signals true, T3: minimum qualification).

**Goal:** a list of *experiments*, not a list of leads. Sometimes the experiment changes messaging; sometimes it changes the list.

### 3. Messaging
This is one-third of the equation. Brilliant copy on a bad list with poor deliverability = zero results.

---

## The 10 Angles (strategic frameworks)

Pick 1-2 per campaign. Great campaigns blend.

### 1. Problem Sniffing
Detect a SPECIFIC problem via scraping/data, surface it with proof.
- *When:* you can programmatically detect a problem your solution fixes (DMARC misconfig, bad reviews, missing tech, etc.)
- *Example:* parking-lot repair scraping restaurant reviews for "pothole" mentions, sending screenshot of the review.
- *Key:* SHOW the problem (screenshot, link, specific data). Never just claim.

### 2. Truly Funny, Relevant
Humor that directly supports the message, undeniably relevant.
- *Example:* "bed bugs" subject + image of toy Volkswagen Beetles on a bed, to a hotel during an outbreak.
- *Not:* random memes, jokes that need explanation, anything mocking the prospect.

### 3. AI Vision Casting
Use AI on their site/business to show what using your product looks like FOR THEM.
- *When:* your service has variable applications; creative/consulting/platforms.
- *Not:* commoditized identical-delivery services (bookkeeping, basic hosting).
- *Key:* AI writes PIECES (custom variables, ideas, first lines), never the whole email.

### 4. Stars Aligning
Only reach out when N specific factors are simultaneously true. Extreme qualification → extreme relevance.
- *When:* TAM is huge (80k+), specific buying window detectable.
- *Math:* 200k broad list, 1/400 → 500 responses; 15k stars-aligned, 1/50 → 300 responses. Fewer emails, similar results, much higher quality.

### 5. Extremely Relevant Case Studies
Lookalike lists + case study that matches them tightly.
- *Generic:* "we helped Acme improve response rate 63%."
- *Strong:* "you're a Series B fintech in mortgage automation. LendTech (same stage, same focus) booked 47 demos in 90 days with this playbook."

### 6. Influencer Audience Targeting
Followers of influencers who share your philosophy.
- *Never:* sell what the influencer sells; never reference seeing them like/comment a post.
- *Do:* speak to the shared belief, let them connect dots.

### 7. Great Lead Magnet
Something FREE that the market knows is otherwise paid.
- *Strong:* "5,000 verified leads free" (Apollo charges); "free tech-stack audit on your BuiltWith report"; "I built you a list of 50 prospects, here are 3 names + emails."
- *Weak:* free webinar, PDF guide, "free consultation," anything obviously marketing.

### 8. Being Genuinely Useful (no ask)
Tell them something they'd want to know, no CTA.
- *Example:* "scanned your area, found 2 units in your building listed on AirBnB — those allowed?"
- The ask comes in the reply, or follow-up. First email is pure value.

### 9. Two-Sentence Straight to Point
Brevity cuts noise when offer + relevance are both strong.
- *Example:* "saw on BuiltWith that {{company}} has {{N}} technologies — open to a free audit of which you actually use vs. should cancel?"
- *When:* binary offers, large TAMs, simple value props.

### 10. Flash Roll (Oren Klaff)
Demonstrate technical depth via specificity. Go deep but stay understandable.
- *Generic:* "we improve outbound response rates."
- *Flash Roll:* "we combine 40+ data sources into one waterfall, then use GPT-4 to write custom first lines from the prospect's last 3 LinkedIn posts, their company news, and their tech stack. Avg open 62%. Avg positive 1/180."

---

## The 4-email sequence

Maximum 4 emails. Email 5+ generates more spam reports than positives. By email 7 your data is stale anyway.

**You WILL reach these people again** — you'll cycle through the list and start back at the top with fresh data. Don't burn them in one sequence.

```
Email 1: NEW (introduction + why-you-why-now)
  ↓ 3-4 days
Email 2: THREADED (add context, more depth)
  ↓ 3-4 days
Email 3: NEW thread, NEW subject (different angle, lower-friction CTA)
  ↓ 4-5 days
Email 4: THREADED to E3 (graceful exit, "should I reach Sarah instead?")
```

### Email 1 — Introduction
- {{name}} — {{why-you-why-now sentence with research evidence}}
- Poke-the-bear question OR research-to-help segue
- Social proof, quantitative
- Clear CTA

### Email 2 — Add context (threaded)
- Personal AI-generated line (analogy, "the more I learn about {{company}} the more I think...", "is any of this interesting so you can spend more time with {{their customers}}?")
- Depth on the case study OR additional value
- Similar CTA

### Email 3 — Change the angle (NEW subject, NEW thread)
- Different "why now" hook
- Different pain point (rotate save-time / make-money / save-money)
- LOWER-FRICTION CTA ("would you watch a 5-min video I made for you?")

### Email 4 — Graceful exit (threaded to E3)
- "{{name}} — I know there's about {{employee_count}} at {{company}}, perhaps {{job-to-be-done}} isn't your responsibility. Should I reach out to {{other_person_full_name}} instead given their role?"
- Uses the other person's FULL name (extra-research signal)

---

## Copywriting rules (unbreakable)

1. Under 100 words.
2. 5th-grade reading level. No jargon except Flash Roll.
3. About THEM. Your company is the supporting character.
4. Show, don't tell. Screenshots, links, data.
5. Handle objections preemptively.
6. No spam triggers ("free," "guarantee," "act now," "limited time," "exclusive," "discount").
7. Social proof is quantitative. Not "we helped companies grow" — "Acme: 7% → 62% open rate."
8. If a competitor could find-and-replace your name in, it's not differentiated.

### Subject lines
- 2-3 words, lowercase, plausibly from a colleague.
- Good: `pizza orders`, `competitor insights`, `outbound edge`, `saw your post`, `your team`.
- Bad: `Don't Hire Until You Do This`, `Quick Question About Your Marketing Strategy`, `Touching Base`.

### Preview text
First sentence visible in the inbox. Put research evidence FIRST. Not "Hi John, I hope this email finds you well."

### CTAs (friction ladder)
1. Lowest: "Thoughts?" / "Curious if this resonates?"
2. Low: "Want details?"
3. Medium: "Would you watch a 5-min video I made for you?"
4. Higher: "Worth a 15-min call?"
5. Highest: "Demo this week?"

Start higher in E1, lower in E3.

### Poke the Bear (Josh Braun)
Questions that surface real problems they may not consciously recognize.
- Weak: "Do you need help with taxes?"
- Strong: "How do you know your current accountant is using every legal loophole to get you the most money back?"
- Weak: "Are you happy with your outbound?"
- Strong: "When's the last time your SDRs booked a meeting where the prospect actually showed up?"

### Reframing the offer
Same offer, different frame → different campaign:
- Failed: "Looking for help with your 2024 taxes?" → near-zero responses
- Won: "How do you know your accountant is using every legal loophole?" → 2-3 leads/day
Same list. Same infrastructure. Different frame.

---

## Demand capture vs. demand generation

|  | Demand CAPTURE | Demand GENERATION |
|---|---|---|
| | SOC2, web dev, M&A, taxes | Outbound, growth, new tech |
| Strategy | High volume, wait for timing, short sequences | Compelling offer, personalization, creative angles |
| Response rate | Lower but qualified | Higher but needs qualification |

|  | Low Awareness | High Awareness |
|---|---|---|
| | Don't know your category exists | Commoditized, many alternatives |
| Strategy | Heavy education, proof, Flash Roll | Differentiation, unique angle, volume |

---

## TAM math

1. Meetings needed/month
2. × response-to-meeting ratio
3. × leads-per-positive-response (use benchmark above based on offer strength)
4. = leads/month to contact
5. List size ÷ (4) = burn rate

**Reuse rule:** don't contact same person more than every 2-3 months.

---

## What kills campaigns (avoid)
1. Commoditized offer, no differentiation
2. Selling to people who hate cold email (technical ICs, engineers)
3. "Nice to have" products (wellness, engagement, culture)
4. Enterprise sales to F5000 with cold email alone
5. No clear buying trigger
6. Wrong persona (no budget authority)
7. Saturated market + undifferentiated wedge

## What makes campaigns explode
1. Killer offer + right audience (offer dominates)
2. Perfect timing (event week, recent funding, recent hire)
3. Lead magnets with real, recognizable value
4. AI personalization done right (variables, not whole emails)
5. Problem sniffing with proof
6. Flash Roll specificity
7. Deep ICP understanding (copy almost writes itself)

---

## Decision framework: pick angles

### Step 1 — Offer strength
**Strong indicators:** quantifiable outcome, unique differentiation, quantitative proof, real lead magnet, urgent problem.
**Weak indicators:** commoditized, vague outcome, no proof, "nice to have."

If WEAK: improve the offer first, OR compensate with extreme personalization, OR set volume expectations.

### Step 2 — TAM size
- Large (50k+): test multiple angles, shorter sequences, volume viable, Stars Aligning fits.
- Small (<10k): heavy personalization, full 4-email sequence, space sending, consider expanding ICP.

### Step 3 — Data availability

| Data they can access | Angles unlocked |
|---|---|
| Website content | AI Vision Casting, Problem Sniffing |
| Tech stack (BuiltWith) | Problem Sniffing, Two-Sentence |
| LinkedIn activity | Problem Sniffing, Being Useful |
| Recent news/funding | Stars Aligning |
| Job postings | Stars Aligning, Problem Sniffing |
| Reviews/social mentions | Problem Sniffing, Being Useful |
| Competitor customer lists | Problem Sniffing, Case Study |
| None (basic firmographics only) | Focus on messaging, not personalization |

### Step 4 — Combinations

|  | High differentiation | Low differentiation |
|---|---|---|
| **Large TAM** | AI Vision Casting + Flash Roll, 4 emails | Two-Sentence + Lead Magnet, 2 emails |
| **Small TAM** | Relevant Case Studies + Flash Roll, 4 emails high-personalization | Problem Sniffing + Case Studies, 4 emails — but improve offer first |
| **Unknown solution** | Being Useful + Flash Roll, 4 emails, expect lower response initially | (same — fix offer) |

---

## Discovery questions (when brainstorming with a buyer)

Don't run as a checklist. Pull what you need to assess offer strength + TAM + data availability + angle fit.

**Business:** what do you sell · who do you sell to · what problem · what outcome · price/deal size · sales cycle.

**Differentiation:** what makes you different · why did you start this · what do customers say when they pick you · what's your secret sauce.

**Customer:** best customer (specific example) · what triggered them · what were they doing before · common objections.

**Proof:** quantitative results · case studies · notable logos.

**List:** target titles/criteria · TAM size · existing lists · data accessible/scrapeable.

**Current situation:** prior cold email experience and what happened · monthly meeting goal · infra · tools.

**Angle-specific probes:**
- *Problem Sniffing:* "is there any way to detect someone has the problem you solve before reaching out?"
- *AI Vision Casting:* "does your service apply differently to different customers? Could you customize pitch from their website?"
- *Stars Aligning:* "what 5 things would all be true about your ideal prospect?"
- *Case Studies:* "do you have different case studies for different industries/company types?"
- *Lead Magnet:* "what do customers normally pay for that you could give away?"
- *Flash Roll:* "how does your solution actually work — walk me through the mechanics."

---

## Common objections + reconciliations

**"Hormozi says it should be a Grand Slam Offer."**
Both true, different layers. Grand Slam Offer = the *value proposition* —
outcome × likelihood × speed × effort. That's what the lead magnet is built
AROUND. Under-100-words = the *email envelope* delivering it. You can have
a $50k-perceived-value Grand Slam Offer and the email pitching it should
still be 80 words. The email's job is to make them click into the offer,
not absorb it.

**"I want 7 emails not 4."**
By E5+ you generate more spam reports than positives, kneecapping
deliverability for your *next* cycle. Data goes stale by E7 anyway. The
play isn't more touches in one sequence — it's a 4-touch sequence, then
re-cycle the same list 60-90 days later with fresh data and a new angle.
8-12 touches over 6 months, no spam tax.

**"The offer IS the demo."**
Pre-product founders say this constantly. "Come see my demo" is a pitch
disguised as an offer — it asks the prospect to spend 30 min on your
unfinished thing with nothing in it for them. Three honest paths to a
real offer in 20 min: (a) audit-shaped — scrape something specific about
them and send back a one-pager ("AI tooling audit of your 5 portfolio
companies"); (b) template-shaped — ship a useful template that stands
alone even if they never buy ("month-end-close AI workflow pack, 10
prompts, ChatGPT-ready"); (c) scarcity-shaped — "first 10 in this
category get the beta free for 6 months." A demo is none of those.

**"My list is 50 people I already kinda know."**
Sub-100 TAM with any warm element = different game entirely. The
playbook benchmarks (1/30 great, 1/250 average) don't apply — you're
going to hear back from most of them or none of them, depending on the
relationship, not the angle. Default angle is #8 Being Genuinely Useful
(no CTA, value-first). Skip the sequence framework; write one note per
person, the whole email IS the personalization. The Quickstart's data
layer still earns its $47 by helping them find the NEXT 50 they don't
know yet.

**"The playbook feels like 2022 advice."**
Fundamentals (offer > opener, infrastructure, segmented list, friction-
laddered CTAs) aren't 2022 — they're physics. What HAS shifted: AI
personalization is now table stakes (not a differentiator), Google's spam
classifier is more aggressive (under-100-words matters MORE, not less),
"free custom build" lead magnets have edged out PDF-style ones. The
specifics evolve; the structure doesn't.

## High-demand, low-fit angles (verify precondition before agreeing)

Three angles buyers ask for most often and fit least often. Don't just
accommodate; check the precondition.

- **Influencer Audience Targeting** — only works when ONE influencer's
  specific belief maps cleanly to your offer, and you can speak to that
  belief without name-dropping. "I follow some big names" is not enough —
  most ICPs follow 50 voices in their space; "follower of X" is a weak
  signal. Real signals (hiring, stack, recent scale) almost always beat it.
- **AI Vision Casting** — needs a service with VARIABLE applications per
  customer. If you deliver the same thing to everyone (bookkeeping, basic
  hosting, commoditized SEO), this angle is theater. Use it for
  consulting, platforms, creative services where the use case actually
  differs by customer.
- **Truly Funny, Relevant** — humor that doesn't directly reinforce the
  pain point dilutes the message. If the buyer can't show you the
  specific image/joke + the specific pain it captures, this is "we should
  be funnier" energy, not an angle. Decline.

When the buyer demands one of these, ask for the precondition specifically.
If they can't produce it, name the real signals available to them and
route to the angle those signals actually unlock.

## Lead magnet starters (for services without strong proof)

When the buyer has a service business but no quantitative case studies, a
lead magnet is the fastest path to a real offer. The pattern: give away
the smallest version of what you charge for.

- **Free smallest-deliverable** — colorist: "60-second free regrade on
  your festival cut." Designer: "one-page mockup of a section of your
  site." Copywriter: "free rewrite of your hero section."
- **Free diagnostic** — agency: "I'll audit your intake page + send 3
  positioning gaps." Tax advisor: "I'll review your last filing for
  missed loopholes." Recruiter: "I'll grade your job description against
  the top 10 ranking listings."
- **Free dataset / list** — outbound agency: "list of 5,000 verified
  emails matching your ICP." Researcher: "list of 50 companies that just
  hired your buyer persona." SEO: "list of 47 keywords your competitor
  ranks for that you don't."
- **Free tool / template** — consultant: "the spreadsheet I use to model
  X for clients." Operator: "the SOP we use to do Y."

The recipe each time: smallest version, real cost to you (otherwise
perceived value is zero), naturally leads to the paid offering. NOT a
webinar, NOT a PDF, NOT "free consultation."

## Validation checklist (before declaring offer + sequence ready)

For the OFFER:
- [ ] Specific, quantifiable outcome (not "grow your business")
- [ ] Differentiation a competitor couldn't paste their name into
- [ ] Quantitative proof OR honest acknowledgment of no proof yet
- [ ] Lead magnet identified (or explicit decision to use offer-as-pitch)
- [ ] Solves an urgent problem (not nice-to-have)

For each EMAIL in the sequence:
- [ ] Under 100 words
- [ ] "Why you, why now" clear in E1
- [ ] Poke-the-bear question OR equivalent surface-the-pain
- [ ] Quantitative social proof
- [ ] CTA answers "why is this worth their time"
- [ ] Subject 2-3 words, lowercase, could be from a colleague
- [ ] E3 different value-prop than E1
- [ ] E4 references another team member by full name

If 3+ checkboxes fail: don't ship. Iterate.
