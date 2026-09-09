<div align="center">

<img src="https://img.shields.io/badge/CareerOS-v1.0-D4A5A5?style=for-the-badge&labelColor=393346&logo=sparkles" alt="CareerOS"/>

# CareerOS :Automated Job Intelligence System

**End-to-end job search automation: AI analysis · CV tailoring · follow-up scheduling · Gmail classification · inbox auto-labeling · live portfolio dashboard**

[![Demo](https://img.shields.io/badge/Live_Demo-odeliyach.github.io%2FCareerOS-B5C99A?style=flat-square&logo=github&logoColor=white)](https://odeliyach.github.io/CareerOS)
[![n8n](https://img.shields.io/badge/n8n-Workflow_Automation-FFB5A7?style=flat-square&logo=n8n&logoColor=white)](https://n8n.io)
[![Groq](https://img.shields.io/badge/Groq-LLaMA_3.1-FFC09F?style=flat-square&logoColor=white)](https://groq.com)
[![GitHub](https://img.shields.io/badge/Data_Store-GitHub_API-AED9E0?style=flat-square&logo=github&logoColor=333)](https://github.com)
[![License: MIT](https://img.shields.io/badge/License-MIT-B5C99A?style=flat-square)](LICENSE)

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

---

## Tech Stack

| Layer | Technology | Why |
|---|---|---|
| **Workflow engine** | n8n (self-hosted, Docker) | Visual graph I can show in interviews; handles retries, scheduling, error routing out of the box |
| **LLM inference** | Groq API - LLaMA 3.1 8B | Free tier, ~200 tokens/sec, OpenAI-compatible API |
| **Data store** | GitHub API (private repo) | Version history on every file, human-readable, zero cost, works natively with Obsidian |
| **Local dashboard** | Obsidian + Dataview | Queries live from `.md` frontmatter — no manual maintenance |
| **Portfolio demo** | Vanilla HTML/CSS/JS | No framework overhead; SHA-256 password auth via native Web Crypto API |
| **Deployment** | GitHub Pages | Zero hosting cost, auto-deploys on push |

---
## Repo Structure

```
CareerOS/
├── index.html                          # Portfolio demo (GitHub Pages)
├── docker-compose.yml                  # n8n local setup
├── Dockerfile                          # n8n container configuration
├── Makefile                            # make start / stop / logs / restart
├── .env.example                        # Environment variables template
├── .gitignore                          # Git ignore patterns
│
├── .github/
│   └── workflows/
│       └── deploy.yml                  # CI/CD: validates JSONs + deploys to GitHub Pages
│
├── n8n-workflows/
│   ├── workflow-all-tiers.json         # Main pipeline (6 tiers: resume → portfolio)
│   ├── workflow-followup-scheduler.json# Daily follow-up digest (4 cron triggers)
│   ├── workflow-email-listener.json    # Gmail classifier (rejection/invite/offer)
│   ├── workflow-gmail-labeler.json     # Inbox auto-labeling every 30 min
│   └── helper-get-label-ids.json       # Helper: fetch Gmail label IDs
│
├── prompts/
│   ├── 01-resume.md                    # Tier 1: Resume analysis prompt
│   ├── 02-cover-letter.md              # Tier 1: Cover letter prompt
│   ├── 03-cold-email.md                # Tier 2: Cold outreach prompt
│   ├── 04-interview-prep.md            # Tier 3: Interview prep prompt
│   ├── 05-talking-points.md            # Tier 3: Talking points prompt
│   ├── 06-skills-gap.md                # Tier 3: Skills gap analysis prompt
│   ├── 07-portfolio-github.md          # Tier 4: Portfolio matching prompt
│   ├── 08-salary-negotiation.md        # Tier 3: Salary negotiation prompt
│   └── PROMPTS.md                      # Complete prompts reference (all tiers)
│
├── sample-outputs/
│   ├── sample_application_file.md      # Example: full application with all tiers
│   ├── sample_resume_analysis.md       # Example: Tier 1 resume analysis output
│   ├── sample_cover_letter.md          # Example: Tier 1 cover letter output
│   ├── sample_cold_email.md            # Example: Tier 2 cold outreach output
│   └── sample_interview_prep.md        # Example: Tier 3 interview prep output
│
└── docs/
    ├── SETUP.md                        # Installation and local setup guide
    ├── ARCHITECTURE.md                 # System design and data flow diagrams
    ├── TROUBLESHOOTING.md              # Common issues and debugging guide
    ├── CHANGELOG.md                    # Version history and feature updates
    └── OBSIDIAN_SYNC.md                # Obsidian vault integration guide
```

---

## Documentation

- **[Setup Guide](docs/SETUP.md)** — Installation, prerequisites, and local setup
- **[Architecture](docs/ARCHITECTURE.md)** — System design, data flow, and component breakdown
- **[Troubleshooting](docs/TROUBLESHOOTING.md)** — Common issues, debugging, and real bugs fixed
- **[Changelog](docs/CHANGELOG.md)** — Version history and feature updates
- **[Obsidian Integration](docs/OBSIDIAN_SYNC.md)** — Vault setup, Git sync, and Dataview queries
- **[Prompts Reference](prompts/PROMPTS.md)** — All LLM prompts used in workflows

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


<div align="center">

Built by **Odeliya Charitonova** · [GitHub](https://github.com/odeliyach) · [LinkedIn](https://linkedin.com/in/odeliya-charitonova)

*Computer Science student @ Tel Aviv University, School of CS & AI*

</div>
