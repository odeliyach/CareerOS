# Job Search Automation — N8N 5-Tier Workflow

An AI-powered job search automation system built on [N8N](https://n8n.io) with local LLM support via [Ollama](https://ollama.ai).  
Feed it a job posting URL or description and it automatically generates tailored application materials, schedules follow-ups, syncs your Obsidian vault, and commits everything to a private GitHub repository.

---

## Architecture Overview

```
Webhook (job input)
        │
        ▼
 ┌──────────────────────────────────────────────────────┐
 │  Tier 1 — Core Application                           │
 │  • Tailored resume (Ollama)                          │
 │  • Cover letter (Ollama)                             │
 │  • metadata.md, resume.md, cover_letter.md           │
 └──────────────────────────────────────────────────────┘
        │
        ▼
 ┌──────────────────────────────────────────────────────┐
 │  Tier 2 — Cold Outreach                              │
 │  • Introduction + follow-up emails (Ollama)          │
 │  • Company research + personal angles (Ollama)       │
 │  • cold_email.md, company_research.md                │
 └──────────────────────────────────────────────────────┘
        │
        ▼
 ┌──────────────────────────────────────────────────────┐
 │  Tier 3 — Interview Preparation                      │
 │  • Skills gap analysis (Ollama)                      │
 │  • Interview questions + talking points (Ollama)     │
 │  • Salary negotiation guide (Ollama)                 │
 │  • interview_prep.md                                 │
 └──────────────────────────────────────────────────────┘
        │
        ▼
 ┌──────────────────────────────────────────────────────┐
 │  Tier 4 — Portfolio Matching                         │
 │  • Fetch GitHub repos (GitHub API)                   │
 │  • Project selection, metrics, context (Ollama)      │
 │  • portfolio_matching.md                             │
 └──────────────────────────────────────────────────────┘
        │
        ▼
 ┌──────────────────────────────────────────────────────┐
 │  Tier 5 — Tracking & Analytics                       │
 │  • SQLite: record + follow-ups + analytics           │
 │  • tracking.md, analytics.md                         │
 │  • Git commit → job-search-data (private)            │
 │  • Gmail confirmation email                          │
 └──────────────────────────────────────────────────────┘
```

---

## Prerequisites

| Requirement | Version | Notes |
|-------------|---------|-------|
| Docker & Docker Compose | Latest | Required to run N8N + Ollama |
| N8N | ≥ 1.x | Runs inside Docker |
| Ollama | Latest | Runs inside Docker on `http://ollama:11434` |
| SQLite 3 | ≥ 3.31 | Available inside the N8N container |
| Git | ≥ 2.x | Available inside the N8N container |

---

## Quick Start

### 1. Clone the Repository
```bash
git clone https://github.com/odeliyach/job-search-n8n.git
cd job-search-n8n
```

### 2. Configure Environment Variables
```bash
cp .env.example .env
# Edit .env with your credentials (see Environment Variables section)
```

### 3. Start Services
```bash
docker-compose up -d
```

This starts:
- **N8N** at `http://localhost:5678`
- **Ollama** at `http://localhost:11434` (also accessible inside Docker as `http://ollama:11434`)

### 4. Pull the Ollama Model
```bash
docker exec ollama ollama pull llama3
```

### 5. Initialize the SQLite Database
```bash
docker exec -i n8n sqlite3 /home/n8n/.n8n/job_search.db < init_database.sql
```

### 6. Import the N8N Workflow
1. Open `http://localhost:5678` and log in with `admin / <your password>`
2. Go to **Workflows → Import from file**
3. Select `n8n-workflows/workflow-all-tiers.json`
4. Configure credentials (see Credentials Setup section below)
5. Click **Activate**

---

## Environment Variables

Edit your `.env` file with these values:

```env
# N8N
N8N_BASIC_AUTH_ACTIVE=true
N8N_BASIC_AUTH_USER=admin
N8N_BASIC_AUTH_PASSWORD=your_password

# Paths (inside Docker container)
VAULT_PATH=/home/n8n/.n8n/vault
DB_PATH=/home/n8n/.n8n/job_search.db

# Git / GitHub
GITHUB_USERNAME=odeliyach
GITHUB_EMAIL=odaliya12@gmail.com
GITHUB_DATA_REPO=odeliyach/job-search-data

# Gmail (send notification emails)
GMAIL_ADDRESS=odeliya.charitonova.dev@gmail.com
```

---

## Credentials Setup (in N8N)

After importing the workflow, configure these credentials in **Settings → Credentials**:

### GitHub API Credential
- **Type:** GitHub API
- **Access Token:** Your GitHub Personal Access Token (PAT) with `repo` scope
- **Name:** `GitHub API` (must match the name used in the workflow)

### Gmail Credential
- **Type:** Gmail OAuth2 (recommended) **or** use SMTP with App Password:
  - SMTP Host: `smtp.gmail.com`
  - SMTP Port: `465` (SSL) or `587` (TLS)
  - Username: `odeliya.charitonova.dev@gmail.com`
  - Password: Gmail App Password (generate at https://myaccount.google.com/apppasswords)

---

## Usage

### Trigger the Workflow via Webhook

Send a `POST` request to the webhook URL (shown in the Webhook node):

```bash
curl -X POST https://job-search-n8n.onrender.com/webhook/job-search \
  -H "Content-Type: application/json" \
  -d '{
    "company": "Google",
    "job_title": "Senior Software Engineer",
    "job_url": "https://careers.google.com/...",
    "location": "Tel Aviv, Israel",
    "job_description": "We are looking for a Senior Software Engineer to join our team...",
    "requirements": "5+ years Python/Go, Kubernetes, distributed systems",
    "user_skills": "JavaScript, Python, React, Node.js, Docker, SQL"
  }'
```

### Input Fields

| Field | Required | Description |
|-------|----------|-------------|
| `company` | Yes | Company name (e.g., "Google") |
| `job_title` | Yes | Position title |
| `job_url` | No | Link to the original job posting |
| `location` | No | Job location (default: "Remote") |
| `job_description` | Yes | Full job description text |
| `requirements` | No | Key job requirements (extracted from description if omitted) |
| `user_skills` | No | Override default skills list |

### Output

After the workflow completes, you will find:

**Obsidian Vault (`/home/n8n/.n8n/vault/YYYY/MM/DD_Company/`):**
```
├── metadata.md          # Job details, URL, requirements, timestamps
├── resume.md            # AI-tailored resume
├── cover_letter.md      # AI-generated cover letter
├── cold_email.md        # Introduction + follow-up email templates
├── company_research.md  # Company intel from Ollama
├── personal_angle.md    # Connection angles for outreach
├── interview_prep.md    # Skills gap, questions, talking points, salary guide
├── portfolio_matching.md# Relevant GitHub projects + showcase strategy
└── tracking.md          # Application status + follow-up schedule
```

**Vault root:**
- `analytics.md` — Updated after every application

**SQLite Database (`/home/n8n/.n8n/job_search.db`):**
- New row in `applications`
- 3 rows in `follow_ups` (1 week, 2 weeks, 1 month)
- 4 rows in `tier_outputs` (one per AI-heavy tier)
- Updated row in `analytics`

**GitHub (`odeliyach/job-search-data`, private):**
- All vault files committed automatically

**Email:**
- Confirmation email sent to `odeliya.charitonova.dev@gmail.com`

---

## Deployment on Render.com

The repository includes a `config/render.yaml` for Render.com deployment. See [`docs/SETUP.md`](docs/SETUP.md) for full deployment instructions.

**N8N Instance URL:** `https://job-search-n8n.onrender.com`

---

## Documentation

| Document | Description |
|----------|-------------|
| [docs/SETUP.md](docs/SETUP.md) | Prerequisites and installation instructions |
| [docs/USAGE_GUIDE.md](docs/USAGE_GUIDE.md) | Detailed usage instructions |
| [docs/TROUBLESHOOTING.md](docs/TROUBLESHOOTING.md) | Common issues and solutions |
| [prompts/PROMPTS.md](prompts/PROMPTS.md) | All Ollama prompts by tier |
| [database_schema.md](database_schema.md) | SQLite schema documentation |
| [init_database.sql](init_database.sql) | Database initialization script |
| [docs/TIER1_CORE_APPLICATION.md](docs/TIER1_CORE_APPLICATION.md) | Tier 1 details |
| [docs/TIER2_COLD_OUTREACH.md](docs/TIER2_COLD_OUTREACH.md) | Tier 2 details |
| [docs/TIER3_INTERVIEW_PREP.md](docs/TIER3_INTERVIEW_PREP.md) | Tier 3 details |
| [docs/TIER4_PORTFOLIO_MATCHING.md](docs/TIER4_PORTFOLIO_MATCHING.md) | Tier 4 details |
| [docs/TIER5_TRACKING.md](docs/TIER5_TRACKING.md) | Tier 5 details |

---

## Repository Structure

```
job-search-n8n/
├── n8n-workflows/
│   ├── workflow-all-tiers.json   ← Main production workflow (all 5 tiers)
│   └── workflow.json             ← Simple workflow skeleton
├── prompts/
│   └── PROMPTS.md                ← All Ollama prompts organized by tier
├── docs/
│   ├── SETUP.md
│   ├── USAGE_GUIDE.md
│   ├── TROUBLESHOOTING.md
│   ├── WORKFLOW_SPECIFICATION.md
│   ├── TIER1_CORE_APPLICATION.md
│   ├── TIER2_COLD_OUTREACH.md
│   ├── TIER3_INTERVIEW_PREP.md
│   ├── TIER4_PORTFOLIO_MATCHING.md
│   ├── TIER5_TRACKING.md
│   └── CUSTOMIZATION.md
├── config/
│   ├── docker-compose.yml        ← Local development Docker setup
│   └── render.yaml               ← Render.com deployment config
├── sample-outputs/
│   └── sample_resume.md
├── init_database.sql             ← SQLite schema initialization
├── database_schema.md            ← Database documentation
├── docker-compose.yml            ← Root-level Docker Compose
├── Dockerfile
├── .env.example
├── .gitignore
└── README.md
```

---

## License

MIT
