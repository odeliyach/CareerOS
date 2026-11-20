# Architecture

## Overview

CareerOS is built around a single design principle: **GitHub as the database**. Every piece of data, job applications, email logs, the dashboard, tailored CVs, lives as a Markdown file in a private GitHub repository. This gives version history, human-readable diffs, zero cost, and native Obsidian compatibility for free.

The workflow engine (n8n, self-hosted on Docker) orchestrates everything. It has no persistent state of its own, it reads from GitHub, calls Groq, and writes back to GitHub.

---

## Data Flow

```
                        ┌─────────────────┐
                        │   CareerOS      │
                        │  GitHub Repo    │  ← public (code, workflows, demo)
                        └────────┬────────┘
                                 │ git push triggers
                                 ▼
                        ┌─────────────────┐
                        │  GitHub Pages   │  ← odeliyach.github.io/CareerOS
                        │  (index.html)   │
                        └────────┬────────┘
                                 │ visitor pastes JD
                                 │ POST /webhook/job-search-demo
                                 ▼
┌────────────────────────────────────────────────────────────────┐
│                    n8n  (Docker · localhost:5679)               │
│                                                                 │
│  ┌──────────────┐    ┌─────────────┐    ┌──────────────────┐   │
│  │ Form Trigger │    │   Webhook   │    │  Schedule Trigger│   │
│  │  (manual)    │    │  (demo)     │    │  (4x daily, 30m) │   │
│  └──────┬───────┘    └──────┬──────┘    └────────┬─────────┘   │
│         └─────────────┬─────┘                    │             │
│                       ▼                          ▼             │
│               ┌───────────────┐      ┌───────────────────┐     │
│               │  Job Input    │      │  Follow-Up /      │     │
│               │  (Set node)   │      │  Email workflows  │     │
│               └───────┬───────┘      └───────────────────┘     │
│                       │                                        │
│              Groq API calls (gpt-oss-120b)                   │
│              14 calls · ~8-10 min total                        │
│                       │                                        │
│               ┌───────▼───────┐                                │
│               │  GitHub Commit│                                │
│               │  (HTTP PUT)   │                                │
│               └───────┬───────┘                                │
└───────────────────────┼────────────────────────────────────────┘
                        │
                        ▼
              ┌──────────────────┐
              │  job-search-data │  ← private GitHub repo
              │  (private)       │
              │                  │
              │  Job_Applications│◄── Obsidian Git (pull every 10 min)
              │  Dashboard/      │
              │  My_Materials/   │
              │  Obsidian_Vault/ │
              └──────────────────┘
```

---

## Component Breakdown

### Main Workflow, All Tiers

The core pipeline. Accepts input from two sources:

| Trigger | Use case |
|---|---|
| Form Trigger (n8n form) | Manual job submission from browser |
| Webhook (`/webhook/job-search-demo`) | Fired by the portfolio demo |

Both connect into a `Job Input` Set node that normalizes field names, so all downstream nodes read from `$('Job Input')` regardless of which trigger fired.

**Sequential chain with wait nodes (WHY: Groq 6000 TPM limit)**

```
Extract Job Fields → Parse Job Fields
        ↓
T1: Resume Analysis → [wait 15s] → Cover Letter → [wait 15s] → Job Fit Score
        ↓ [wait 15s after T1]
T2: Intro Email → [wait 15s] → Follow-Up → [wait 15s] → Company Research → [wait 15s] → LinkedIn
        ↓ [wait 15s after T2]
T3: Skills Gap → [wait 15s] → Interview Qs → [wait 15s] → Talking Points → [wait 15s] → Salary
        ↓ [wait 20s after T3]
T4: GitHub Repos fetch → [wait 15s] → Portfolio Analysis
        ↓
T5: Tracking (no LLM, pure JS date calculations)
        ↓ [wait 25s after T5]
T6: Tailored Resume (largest prompt, 4096 max_tokens)
        ↓
Merge Results → Prepare Git Content → Get File SHA → Commit → Dashboard → Email
```

Total runtime: ~8–10 minutes per job submission.

### Follow-Up Scheduler

Runs 4 times daily. Each run handles exactly one follow-up type:

| Time | Type | Why split |
|---|---|---|
| 09:00 | day_3 | Groq 6000 TPM, 20 items at once would exhaust it |
| 09:30 | day_7 | Each run stays under ~5 items |
| 10:00 | day_30 | Natural spacing between batches |
| 10:30 | day_90 | Least frequent, safest to run last |

Type filtering uses the current hour/minute, no data passing between trigger and downstream nodes needed.

### Gmail Auto-Labeler

5-node pipeline running every 30 minutes:

```
Fetch Emails (message, not thread)
      ↓
Fix Logic (Run Once for All Items, dedup by threadId, classify)
      ↓
Clear All (remove all existing job labels from thread)
      ↓
Apply Label (apply the single correct label)
```

WHY message not thread: switching to thread resource changes the ID format, breaking the downstream Gmail nodes which expect message IDs.

WHY Clear+Apply not just Apply: without clearing first, a thread can accumulate multiple job labels as its status changes.

### Email Listener

Gmail Trigger fires on incoming emails matching job-search keywords. Branches into 3 paths:

```
Classify Email
      ↓
Route by Type ──► rejection ──► detect stage (phone/technical/final)
              │                       ↓
              │               generate stage-appropriate response template
              │                       ↓
              │               GitHub commit (Email_Log/)
              │                       ↓
              │               email notification with draft
              │
              ├──► interview_invite ──► log + notify (action required)
              │
              └──► offer ──► log + notify (review offer)
```

---

## Storage Schema

All data lives in `odeliyach/job-search-data` (private). Structure:

```
job-search-data/
├── Job_Applications/
│   └── Active/
│       └── CompanyName_YYYYMMDD.md      ← one file per application
│           frontmatter: company, role, applied_date, stage,
│                        fit_score, ats_score, follow-up dates
│           body: resume analysis, cover letter, cold emails,
│                 company research, interview prep, portfolio match
│
├── Dashboard/
│   └── Main_Dashboard.md               ← auto-updated on every submission
│       uses Dataview to query Job_Applications/ frontmatter live
│
├── My_Materials/
│   └── Resume_Versions/
│       └── CompanyName_tailored_cv.md  ← per-company tailored CV
│
└── Obsidian_Vault/
    └── Email_Log/
        └── YYYY-MM-DD-rejection.md     ← email events from Email Listener
```

**WHY GitHub as a database:**
- Version history on every field change (git diff shows exactly what the LLM changed)
- Human-readable without any tooling
- Obsidian reads the same files locally, no sync layer needed
- Zero cost, zero infrastructure
- The tradeoff: no joins, no aggregations across files without reading them all

---

## Key Design Decisions

### SHA pattern for GitHub file updates

GitHub's API returns `422` if you `PUT` a file that already exists without providing its current `sha`. Every commit operation does:

```
GET /contents/path  →  extract sha  →  PUT with sha || undefined
```

`sha || undefined` means: first run creates the file (no sha needed), subsequent runs update it (sha required). This pattern appears in 6 places across the workflows.

### Fire-and-forget webhook

The demo fires the webhook and immediately shows a simulated result. Blocking the UI for 8–10 minutes would make the demo unusable. The `fetch()` call uses `.catch(()=>{})`, intentionally ignored. The terminal animation always completes at 5.1 seconds regardless of webhook status.

### n8n node-name reads vs positional indexing

`$input.all()[0]` breaks when a node has multiple upstream inputs, the order isn't guaranteed. Every node that needs data from a specific upstream step reads it by name:

```js
const jobData = $('Parse Job Fields').first().json;
```

This is non-obvious n8n behavior. The bug only manifests in the Merge node path, not in linear chains.

### Rate limit architecture

Groq free tier: 6000 TPM. With 14 calls per submission averaging ~400 tokens each, firing them consecutively would exhaust the limit. Solution: 30-second wait nodes between every consecutive pair of calls. For the follow-up scheduler: split by type across 4 daily triggers instead of one large batch.

### Human-in-the-loop for follow-ups

Follow-up emails are generated but never auto-sent. The scheduler emails a digest with drafts for manual review. This is a deliberate safety decision, anything going to a real recruiter requires human approval. The system is optimistic about AI generation quality but conservative about automated sending.
