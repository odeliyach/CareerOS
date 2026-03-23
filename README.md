<div align="center">

<img src="https://img.shields.io/badge/CareerOS-v1.0-c87da0?style=for-the-badge&labelColor=252235" alt="CareerOS"/>

# CareerOS — Automated Job Intelligence System

**End-to-end job search automation: AI analysis · CV tailoring · follow-up scheduling · Gmail classification · inbox auto-labeling · live portfolio dashboard**

[![Demo](https://img.shields.io/badge/Live_Demo-odeliyach.github.io%2FCareerOS-78b898?style=flat-square&logo=github)](https://odeliyach.github.io/CareerOS)
[![n8n](https://img.shields.io/badge/n8n-Workflow_Automation-EF6C00?style=flat-square&logo=n8n)](https://n8n.io)
[![Groq](https://img.shields.io/badge/Groq-LLaMA_3.1-F55036?style=flat-square)](https://groq.com)
[![GitHub](https://img.shields.io/badge/Data_Store-GitHub_API-181717?style=flat-square&logo=github)](https://github.com)
[![License: MIT](https://img.shields.io/badge/License-MIT-green)](LICENSE)

---

> *"I didn't want another spreadsheet. I wanted a system that thinks."*

</div>

---

## What is CareerOS?

CareerOS is a fully automated job search operating system. Paste a job description — within minutes it produces a tailored CV, cover letter, cold outreach emails, interview prep, ATS keyword analysis, and a follow-up schedule. Everything commits automatically to a private GitHub repo and surfaces in Obsidian.

The system runs entirely on your own machine. No SaaS subscriptions. No per-request costs beyond Groq's generous free tier.

---

## Live Demo

> **[→ odeliyach.github.io/CareerOS](https://odeliyach.github.io/CareerOS)**

Paste any job description and watch the pipeline run. The dashboard shows a real pipeline — the Analyze panel fires the actual n8n webhook when run locally.

<!-- SCREENSHOT PLACEHOLDER -->
<!-- Add screenshots below once captured:
![Dashboard Overview](docs/screenshots/dashboard-overview.png)
![Analyze Panel](docs/screenshots/analyze-panel.png)
![Terminal Animation](docs/screenshots/terminal-animation.png)
![Result Card](docs/screenshots/result-card.png)
-->

---

## Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                      INPUT                                  │
│         Job Description (via Form or Webhook)               │
└────────────────────────┬────────────────────────────────────┘
                         │
                         ▼
┌─────────────────────────────────────────────────────────────┐
│                   n8n WORKFLOW ENGINE                        │
│                  (Docker · localhost:5679)                   │
│                                                             │
│  Extract Job Fields ──► Parse Job Fields                    │
│          │                                                  │
│          ▼                                                  │
│  ┌──────────────────────────────────────────────────────┐   │
│  │  TIER 1 — Core Application          (Groq · 3 calls) │   │
│  │  Resume Analysis · Cover Letter · Job Fit Score      │   │
│  │  ATS Keyword Optimization (pure JS, no LLM)          │   │
│  └──────────────────┬───────────────────────────────────┘   │
│                     │  Wait 30s                             │
│  ┌──────────────────▼───────────────────────────────────┐   │
│  │  TIER 2 — Cold Outreach             (Groq · 4 calls) │   │
│  │  Intro Email · Follow-Up · Company Research          │   │
│  │  LinkedIn Messages                                   │   │
│  └──────────────────┬───────────────────────────────────┘   │
│                     │  Wait 30s                             │
│  ┌──────────────────▼───────────────────────────────────┐   │
│  │  TIER 3 — Interview Prep            (Groq · 4 calls) │   │
│  │  Skills Gap · Interview Q&A · Talking Points         │   │
│  │  Salary Guide                                        │   │
│  └──────────────────┬───────────────────────────────────┘   │
│                     │  Wait 45s                             │
│  ┌──────────────────▼───────────────────────────────────┐   │
│  │  TIER 4 — Portfolio Matching        (Groq · 1 call)  │   │
│  │  GitHub API fetch · Repo relevance analysis          │   │
│  └──────────────────┬───────────────────────────────────┘   │
│                     │  Wait 60s                             │
│  ┌──────────────────▼───────────────────────────────────┐   │
│  │  TIER 5 — Tracking                  (no LLM)         │   │
│  │  Follow-up schedule · Status tracking                │   │
│  └──────────────────┬───────────────────────────────────┘   │
│                     │  Wait 60s                             │
│  ┌──────────────────▼───────────────────────────────────┐   │
│  │  TIER 6 — Tailored Resume           (Groq · 1 call)  │   │
│  │  Full CV rewrite against real job requirements       │   │
│  └──────────────────┬───────────────────────────────────┘   │
│                     │                                       │
│  ┌──────────────────▼───────────────────────────────────┐   │
│  │  Merge Results → GitHub Commit → Email Notification  │   │
│  └──────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────┘
                         │
          ┌──────────────┴───────────────┐
          ▼                              ▼
┌──────────────────┐          ┌──────────────────────┐
│  GitHub (private)│          │  Email Notification  │
│  job-search-data │          │  (SMTP · Gmail)       │
│                  │          └──────────────────────┘
│  Job_Applications│
│  └── Active/     │
│      Company.md  │◄── Obsidian Git plugin
│  Dashboard/      │    auto-pulls every 10 min
│  My_Materials/   │
└──────────────────┘
```

### Supporting Workflows

| Workflow | Trigger | What it does |
|---|---|---|
| **Email Listener** | Gmail trigger (on receive) | Classifies incoming emails by keyword pattern into: `rejection`, `interview_invite`, `offer`, `acknowledgement`. Detects rejection stage (phone screen / technical / final round) and generates a stage-appropriate response template. Commits an email log entry to the private GitHub repo and sends an email notification with the draft response. |
| **Follow-Up Scheduler** | 4 cron triggers (9:00 / 9:30 / 10:00 / 10:30) | Each trigger handles one follow-up type only (day_3 / day_7 / day_30 / day_90) — splitting the load so each run stays under Groq's 6000 TPM limit. Reads application files from GitHub, checks which are due today, generates personalized email drafts via Groq, and sends a digest for manual review. Emails are **never auto-sent** to recruiters — human approval required. |
| **Gmail Auto-Labeler** | Scheduled every 30 min | Fetches inbox messages by message (not thread — different ID format breaks downstream nodes), deduplicates by `threadId` in a Code node running "Run Once for All Items" so `$input.all()` spans all messages. Applies exactly one label per thread based on newest message. Time-based escalation: `FROM RECRUITER` → `NEED TO REPLY` after 12 hrs. Gmail API fields are case-sensitive: `From`, `To` (capital), `labels: [{id, name}]` — not `labelIds`. `isReply` detection uses subject `Re:` prefix only for outgoing emails — using thread labels caused false `REPLIED` on first recruiter outreach. |

---

## Email Intelligence

The system monitors your job-search Gmail account continuously via two separate workflows.

**Email Listener** fires on every incoming email matching job-search keywords. It classifies the email and branches into three paths:

```
Incoming email
      │
      ▼
 Classify Email ──► Route by Type
                        │
          ┌─────────────┼─────────────┐
          ▼             ▼             ▼
     Rejection    Interview Invite   Offer
          │             │             │
    Detect stage   Log + Notify   Log + Notify
    (phone/tech/    (action req'd)  (review offer)
     final round)
          │
    Generate stage-aware
    response template
          │
    GitHub commit (Email_Log/)
          │
    Email notification
    with draft response
```

**Gmail Auto-Labeler** runs every 30 minutes and applies exactly one label per thread based on the most recent message:

| Label | Condition |
|---|---|
| `N8N` | Sent from me to myself (workflow notifications) |
| `WAITING FOR RESPONSE` | First outreach I sent, no Re: prefix, no prior thread label |
| `REPLIED` | I replied to an existing thread (subject starts with `Re:`) |
| `FROM RECRUITER` | Incoming email, within 12-hour window, no reply from me yet |
| `NEED TO REPLY` | Incoming email, 12-hour window passed without my reply |

The labeler is 5 nodes: `Every 30 Minutes` → `Fetch Emails` (Gmail) → `Fix Logic` (Code, dedup + classify) → `Clear All` (Gmail, removes old labels) → `Apply Label` (Gmail). The Clear+Apply pattern ensures exactly one label per thread with no stale labels.

> **Production note:** `Fix Logic` contains `const TIME_LIMIT = 12 * 60 * 60 * 1000;` — change to `60 * 1000` for testing (1 minute escalation).

---

## Obsidian Integration

The system maintains a local Obsidian vault that stays in sync with the private GitHub repo via the Obsidian Git plugin (auto-pull every 10 minutes).

**What's wired (automatic):**
- `Dashboard/Main_Dashboard.md` — updated on every new application by the main workflow. Contains a Dataview table that auto-renders from frontmatter across all application files.
- Each application `.md` file in `Job_Applications/Active/` with frontmatter fields: `company`, `position`, `link`, `date_sent`, `stage`, `resume_version`, `referral`, `salary_range`, `contact`, `notes`
- Email log entries committed to `Obsidian_Vault/Email_Log/` on every classified email

**What requires manual setup (not yet done):**
- Kanban board (`Job_Tracker_Kanban.md`) — drag cards between stages manually as status changes
- Calendar plugin — daily journaling of interviews, calls, and events
- Dataview plugin installation

**How the three views work together:**
The `.md` frontmatter is the single source of truth. The Dataview table in `Main_Dashboard.md` re-renders automatically when any field changes. The Kanban board gives a drag-and-drop stage view (5 seconds to update). The Calendar gives a daily log of what happened.

---

## Tech Stack

| Layer | Technology | Why |
|---|---|---|
| **Workflow engine** | n8n (self-hosted, Docker) | Visual graph I can show in interviews; handles retries, scheduling, error routing out of the box |
| **LLM inference** | Groq API — LLaMA 3.1 8B | Free tier, ~200 tokens/sec, OpenAI-compatible API |
| **Data store** | GitHub API (private repo) | Version history on every file, human-readable, zero cost, works natively with Obsidian |
| **Local dashboard** | Obsidian + Dataview | Queries live from `.md` frontmatter — no manual maintenance |
| **Portfolio demo** | Vanilla HTML/CSS/JS | No framework overhead; SHA-256 password auth via native Web Crypto API |
| **Deployment** | GitHub Pages | Zero hosting cost, auto-deploys on push |

---

## Key Engineering Decisions

These are the interesting problems — worth understanding before an interview.

**GitHub as a database**
Each application is a `.md` file with YAML frontmatter. GitHub gives version history, diffs on every field change, and a human-readable audit trail. Obsidian's Dataview plugin queries the same files locally. For this use case it's strictly better than SQLite.

**GitHub SHA pattern**
The GitHub API returns `422` if you try to overwrite an existing file without passing its current `sha`. Every commit node does a `GET` first to extract the sha, then passes `sha || undefined` in the `PUT` body. First run creates the file; subsequent runs update it.

**Rate limit architecture**
Groq's free tier allows 6000 TPM. With 14 LLM calls per job submission, every consecutive pair of Groq requests has a 30-second wait node between them. The follow-up scheduler splits by follow-up type across 4 triggers (9:00, 9:30, 10:00, 10:30) so each run only processes one type — keeping each batch well under the limit.

**Fire-and-forget webhook**
The demo fires the n8n webhook and immediately shows a simulated result. The actual pipeline takes 8–10 minutes. Blocking the UI would destroy the interview experience — so the `fetch()` call is fire-and-forget (`.catch(()=>{})`) and the terminal animation always completes cleanly.

**n8n `$input.all()` positional indexing bug**
n8n's merge node passes items positionally — `$input.all()[0]` breaks when a node has multiple upstream inputs. Fixed by reading nodes by name (`$('Tier 1 - Core Application').first().json`) instead of position. This is a non-obvious n8n behavior that cost several debugging sessions.

**Human-in-the-loop design**
Follow-up emails are drafted but never auto-sent. The scheduler generates drafts and emails a digest for manual approval. Deliberate decision: anything that goes to a real recruiter requires a human sign-off.

**Gmail deduplication**
The Gmail Trigger fetches by message, not by thread — because switching to the thread resource breaks downstream node IDs (different format). Deduplication by `threadId` happens in a Code node running in "Run Once for All Items" mode so `$input.all()` can compare across all messages in one pass.

**Email classification: case-sensitive field names**
Gmail API returns `From` and `To` with capital letters, and `labels` as an array of `{id, name}` objects — not `labelIds`. This caused silent failures until discovered. The `isReply` detection uses subject `Re:` prefix only for outgoing emails — using thread labels for this caused false `REPLIED` on first outreach to recruiters (thread already had `FROM_RECRUITER` label from an earlier message).

**Stage-aware rejection responses**
The email listener doesn't just detect rejections — it detects which stage the rejection happened at (phone screen / technical / final round) based on body keywords. Each stage gets a different response template with appropriate tone and content.

---

## Repo Structure

```
CareerOS/
├── index.html                          # Portfolio demo (GitHub Pages)
├── docker-compose.yml                  # n8n local setup
├── Makefile                            # make start / stop / logs
├── .env.example                        # Environment variables template
│
├── n8n-workflows/
│   ├── workflow-all-tiers.json         # Main pipeline (Form + Webhook triggers)
│   ├── workflow-followup-scheduler.json# Daily follow-up digest (split by type across 4 triggers)
│   ├── workflow-email-listener.json    # Gmail classifier — rejection/invite/offer detection
│   └── workflow-gmail-labeler.json     # Inbox auto-labeling every 30 min
│
├── prompts/
│   └── PROMPTS.md                      # All LLM prompts used in workflow nodes
│
├── sample-outputs/
│   ├── sample_application_file.md      # Real output: merged application note
│   ├── sample_resume_analysis.md       # Real output: T1 resume analysis
│   └── sample_cold_email.md            # Real output: T2 cold outreach
│
└── docs/
    ├── SETUP.md                        # How to run locally
    └── TROUBLESHOOTING.md              # Real bugs fixed and why
```

---

## Setup

See **[docs/SETUP.md](docs/SETUP.md)** for full instructions.

Quick start:

```bash
git clone https://github.com/odeliyach/CareerOS.git
cd CareerOS
cp .env.example .env        # fill in your tokens
make start                  # starts n8n on localhost:5679
```

Then import the workflow JSONs from `n8n-workflows/` via n8n UI → Import from file.

---

## Roadmap

- [ ] `fetchLiveData()` — read real application stats from private GitHub repo into the demo dashboard
- [ ] Application Status Auto-Update from recruiter emails (Phase 2a)
- [ ] Weekly Summary workflow (Sunday 9am digest)
- [ ] Docker deployment so webhook is always live (not localhost-only)
- [ ] Obsidian Dataview · Kanban · Calendar setup

---

## Interview Notes

> This section exists for me. Putting it here because it's honest.

Things I'd do differently with more time: containerize n8n properly so the webhook is always accessible (not just when my laptop is on), add a real database instead of GitHub files for querying across applications, write tests for the workflow logic.

Things I'm proud of: the rate-limit architecture, the GitHub SHA pattern, the fire-and-forget demo design, and the fact that I actually use this system daily.

---

<div align="center">

Built by **Odeliya Charitonova** · [GitHub](https://github.com/odeliyach) · [LinkedIn](https://linkedin.com/in/odeliya-charitonova)

*Computer Science student @ Tel Aviv University, School of CS & AI*

</div>
