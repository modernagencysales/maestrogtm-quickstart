# Fundamentals glossary — for "what's a/an X?" questions

This file is for the agent. When the buyer asks a beginner-level "what is X"
question (database, API, CLI, git, .env, schema, idempotent, REST, JWT,
endpoint, payload, JSON, etc.), read this file FIRST and adapt the
explanation. Don't improvise from training — these explanations are
deliberately written in GTM-engineer language with the right analogies.

The buyer is a GTM person who knows Apollo, Clay, Smartlead, Sales Nav,
HubSpot, Gmail, LinkedIn — but NOT Postgres, REST, terminal, git. Every
explanation uses tools they know as analogies.

---

## Database

A database is a place to store data with **rules** about its shape. The
closest thing you've used: a Google Sheet. The differences:

- A Sheet is one tab; a database is dozens of linked tables (contacts,
  companies, replies, sequences) that "know" how to join.
- A Sheet's rules are loose ("this column is text"); a database enforces
  strict rules ("this column is text, max 255 chars, can't be null,
  must be unique").
- A Sheet is read by humans clicking around; a database is read by code
  and AI agents — they ask precise questions like "every contact at
  companies under 50 employees who replied in the last 30 days" in one
  query.

For GTM work specifically: Clay tables, Apollo lists, HubSpot — those are
all databases under the hood. We're moving your data from inside someone
else's tool into your own database (Supabase) so YOU control it.

## Postgres

The most common open-source database engine. ~30 years old, free,
boring/reliable. Wikipedia, Apple, Stripe, most startups run on Postgres.
We're using it because it's the ONE choice almost no one regrets.

## Supabase

Hosted Postgres + automatic REST API + dashboard. You don't manage a
server; Supabase does. Free tier covers ~500 MB and 50k rows. Think:
Postgres rented from a company that handles ops, with a clicky table
viewer for humans and an HTTP API for code.

## API (Application Programming Interface)

A way for one program to ask another program for data, in a strict format.
Every modern tool has an API behind its UI. When you click "search" in
Apollo, the Apollo UI is calling Apollo's API behind the scenes; the API
returns data; the UI shows it to you.

We use APIs directly so we can automate. Instead of a human clicking
"export" 100 times, code calls the API 100 times in a few seconds.

## REST API

A specific style of API where you make HTTP requests to URLs to get/create/
update/delete data. Same protocol your browser uses. A REST request looks
like:

  GET https://api.acme.com/contacts?email=tim@example.com

Response is JSON (a structured text format). Most APIs you've heard of —
Apollo's, Hunter's, HeyReach's, Supabase's — are REST APIs.

## CLI (Command Line Interface)

A program you run from the **terminal** (the black-screen-with-text app on
your Mac, called Terminal.app or iTerm). Instead of clicking buttons in a
GUI, you type commands. Examples:

  ls          → list files (like double-clicking a folder)
  supabase    → talk to Supabase via commands instead of the dashboard
  deepline    → talk to Deepline via commands

CLIs are powerful because they're scriptable — you can chain commands,
loop them, run them on a schedule. The dashboard can't do that.

If you've never opened the terminal: it's `Terminal.app` on macOS, and
typing into it works just like typing in a text box, except instead of
adding to a document, each line you submit is a command.

## .env file (and `secrets/.env`)

A plain text file where you store secret keys. Format:

  SUPABASE_URL=https://xyz.supabase.co
  SUPABASE_ANON_KEY=eyJhbG...

Code reads this file to get the keys it needs to talk to APIs. The same
shape Zapier and Vercel use for storing your credentials.

We put it in a folder called `secrets/` and add `secrets/` to a file
called `.gitignore` so the keys never get accidentally shared.

## git

A tool for tracking changes to files. Like Track Changes in Google Docs,
but for code. Every state of every file is recorded; you can roll back,
share, branch off. You don't NEED git to run the Quickstart, but it's
mentioned a lot because it's how serious teams keep their stack
reproducible. `brew install git` on Mac if you want to learn — 15
minutes of YouTube gets you 80% there.

## .gitignore

A list of file paths that git should ignore. Anything listed there is
NOT tracked, so secrets (API keys) can't accidentally get committed and
shared. Standard practice: `secrets/`, `.env`, `node_modules/` are all
gitignored.

## Schema

The "shape" of your database. What tables exist, what columns each has,
how they relate. The schema is what makes "every contact at companies
under 50 employees" a valid query — those columns and that relationship
have to be defined upfront.

## Migration

A SQL file that creates / changes the schema. We commit migrations to git
so anyone can rebuild the database from scratch. The opposite of "I built
a Clay table and now nobody can reproduce it."

## Idempotent

Safe to run twice. If you accidentally run the migration two times, the
second run does nothing harmful — it sees the tables already exist and
moves on. Idempotent operations are nice because you don't have to
remember whether you've already run them.

## JSON

A way to write structured data as text. Looks like:

  {"first_name": "Marina", "company": "Stripe", "size": 200}

Every modern API speaks JSON. We use jq (a CLI tool) to read/write it.

## Endpoint

A specific URL on an API. Apollo's "search organizations" endpoint is
`POST https://api.apollo.io/v1/mixed_companies/search`. Each endpoint does
one thing.

## Payload

The body of an API request — the data you SEND. For Apollo's search
endpoint, the payload might be `{"q_organization_keyword_tags": ["B2B SaaS"]}`.

## API key / token / JWT

A long string that proves who you are when calling an API. Like a
password, but for code. You DON'T type it every call — code reads it from
your .env file. Different APIs call it different things (key, token,
secret, JWT). Same idea.

## Anon vs service_role (Supabase)

Supabase gives you two API keys:
- `anon` — limited permissions. OK to expose in a browser.
- `service_role` — admin/master. Bypasses all security rules. NEVER put
  this in a browser, NEVER commit to git.

The Quickstart writes both to `secrets/.env` because background jobs need
the admin key for some operations.

## webhook

The reverse of a regular API call. Instead of YOU asking the API for
data, the API tells YOU when something happens. Example: AgentMail sends
a webhook when a reply comes in — your code receives it and updates
your database.

The way to think about it: API calls are pull, webhooks are push.

---

## How to use this glossary in conversation

When the buyer asks "what's a database?":
1. Read this file (you should have already loaded it once at session start).
2. Find the entry, summarize the relevant 2-3 paragraphs in your own
   conversational voice.
3. Re-print the step's prompt.
4. Don't dump the whole entry. Pick what's relevant to where they are.

If the buyer asks something not in this glossary, fall back to your
training data, but stay in GTM-engineer voice. Use Apollo / Clay / Gmail
/ Sheets as analogies first.
