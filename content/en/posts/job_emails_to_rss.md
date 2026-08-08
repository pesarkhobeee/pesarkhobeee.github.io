+++
title = 'Turn Job Alert Emails Into an RSS Feed with Cloudflare Workers'
date = 2026-08-09T00:00:00+02:00
categories = ['ideas']
tags = ['cloudflare', 'workers', 'rss', 'ai', 'd1']
+++

Job-alert emails pile up quickly and are hard to skim. Each message bundles many listings, and there is no good way to filter or search across them. This is a blueprint for a small pipeline that ingests those emails, extracts the individual listings with an LLM, and serves them as a clean RSS feed and a searchable web dashboard — entirely on Cloudflare's free tier. It is meant as an idea to replicate, not a ready-made repository.

## What

Four independent Workers backed by a single Cloudflare D1 (SQLite) database:

- **Email Worker** — receives incoming mail via Cloudflare Email Routing, parses it with `postal-mime`, extracts job listings using Workers AI (Llama 3.3 70B), and stores them in D1.
- **Enrichment Worker** — hourly cron that looks up unknown companies via the Brave Search API and caches a short description.
- **RSS Worker** — serves a paginated RSS feed on a custom domain.
- **Dashboard Worker** — a Tailwind + vanilla-JS SPA for browsing, searching, and deleting jobs and emails. Protected by Cloudflare Zero Trust (identity provider of choice).

## Why

Converting the email stream into RSS makes the listings consumable in any feed reader, deduplicated by URL, and independent of the original inbox. Running on Workers keeps the whole stack on a single free-tier platform with no servers to maintain, and Workers AI removes the need for a separate LLM API key.

## How

1. Configure a dedicated address in Cloudflare Email Routing to trigger the Email Worker on every inbound message.
2. In the Email Worker, parse the MIME body, send the text to Workers AI with a schema-constrained prompt, and store the extracted listings as a JSON blob in an `emails` table. Deduplicate at ingestion time on `job_url`.
3. Schedule the Enrichment Worker as an hourly cron. It finds companies without a description in a `companies` table, queries Brave Search, and writes the result back.
4. In the RSS Worker, read from D1 and generate a paginated feed.
5. In the Dashboard Worker, expose a small JSON API (`/api/jobs`, `/api/emails`, stats, delete) consumed by the SPA. Gate access with a Cloudflare Zero Trust Access policy — an AAAA record pointing `dashboard` to `100::` plus `workers_dev = false` in the Wrangler config is enough to block `*.workers.dev` bypass paths.

## Snippets

The whole design fits in a handful of small pieces.

**Schema** — two tables in D1:

```sql
CREATE TABLE emails (
  id             INTEGER PRIMARY KEY AUTOINCREMENT,
  subject        TEXT NOT NULL,
  received_at    TEXT NOT NULL,
  companies_json TEXT NOT NULL,  -- AI-extracted jobs as a JSON blob
  raw_body       TEXT
);

CREATE TABLE companies (
  company_name TEXT PRIMARY KEY,
  description  TEXT NOT NULL,
  enriched_at  TEXT NOT NULL
);
```

**Email Worker** — the entry point Cloudflare Email Routing calls on every inbound message:

```javascript
import PostalMime from "postal-mime";

export default {
  async email(message, env) {
    try {
      const parsed = await new PostalMime().parse(
        await new Response(message.raw).arrayBuffer()
      );
      const body = parsed.text || parsed.html || "";
      const result = await extractJobsWithAI(body, parsed.subject, env);

      await env.DB.prepare(
        `INSERT INTO emails (subject, received_at, companies_json, raw_body)
         VALUES (?, ?, ?, ?)`
      ).bind(parsed.subject, new Date().toISOString(),
             JSON.stringify(result), body).run();
    } catch (err) {
      // Never throw — Cloudflare returns 421 to the sender on unhandled errors
      console.error(err);
    }
  },
};
```

**AI extraction** — Workers AI with a schema-constrained prompt:

```javascript
async function extractJobsWithAI(body, subject, env) {
  const prompt = `Extract job listings from the email below.
Return ONLY JSON: { "jobs": [{ "company_name", "job_title",
"location", "salary", "job_url" }] }

Subject: ${subject}
Body: ${body}`;

  const res = await env.AI.run("@cf/meta/llama-3.3-70b-instruct-fp8-fast", {
    messages: [{ role: "user", content: prompt }],
    max_tokens: 4000,
  });
  return JSON.parse(res.response.match(/\{[\s\S]*\}/)[0]);
}
```

**Dedup on ingestion** — LinkedIn and similar senders reuse the same job URL across many alerts, so tracking params are stripped and compared against existing rows before insert:

```javascript
const stripTracking = (url) => new URL(url).origin + new URL(url).pathname;
```

**Enrichment cron** — a separate Worker on an hourly schedule fills in company descriptions via Brave Search and caches them in the `companies` table, so the RSS feed and dashboard can join against them without hitting the API again.

## Stack

Cloudflare Workers (ES modules), D1, Workers AI, Email Routing, Zero Trust, `postal-mime`. No build step required — Wrangler deploys plain JS directly. A short `Makefile` wrapping `wrangler deploy` and `wrangler tail` per worker keeps day-to-day operation simple.
