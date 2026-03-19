# Job Search Automation — N8N + Ollama + SQLite

Automated 5-tier job application system powered by N8N workflows and a local Ollama LLM.  
Generates tailored resumes, cover letters, cold emails, interview prep, and portfolio recommendations — committed automatically to a private GitHub repository.

> **Public repo** (this one): code, architecture, workflow JSON.  
> **Private repo** (`job-search-data`): actual job application files — never committed here.

---

## Architecture

```
Job URL / Description
        │
        ▼
┌───────────────────────────────────────────────────────┐
│                 N8N Workflow (10 nodes)                │
│                                                       │
│  [Trigger] → [Set Details] → [Parse Job Info]         │
│       │                                               │
│       ▼                                               │
│  [Tier 1] Resume + Cover Letter + Metadata            │
│       │  ↳ Ollama: llama3.2  ↳ files: 3 .md          │
│       ▼                                               │
│  [Tier 2] Cold Emails + Company Research              │
│       │  ↳ Ollama: llama3.2  ↳ files: 3 .md          │
│       ▼                                               │
│  [Tier 3] Interview Prep + Salary Guide               │
│       │  ↳ Ollama: llama3.2  ↳ files: 1 .md          │
│       ▼                                               │
│  [Tier 4] Portfolio Matching + GitHub Strategy        │
│       │  ↳ Ollama: llama3.2  ↳ files: 1 .md          │
│       ▼                                               │
│  [Tier 5] SQLite DB + Tracking + Analytics            │
│       │  ↳ sqlite3  ↳ files: 2 .md                   │
│       ▼                                               │
│  [Git Commit] → job-search-data (PRIVATE)             │
│       ▼                                               │
│  [Email Notification] → Gmail                         │
└───────────────────────────────────────────────────────┘
```

### Vault Structure (private repo)

```
/home/n8n/.n8n/vault/
├── 2026/
│   └── 03/
│       └── 19_Google_SoftwareEngineer/
│           ├── metadata.md
│           ├── resume.md
│           ├── cover_letter.md
│           ├── cold_email.md
│           ├── company_research.md
│           ├── personal_angle.md
│           ├── interview_prep.md
│           ├── portfolio_matching.md
│           └── tracking.md
└── analytics.md
```

---

## Repository Contents

| File | Description |
|---|---|
| `workflow-all-tiers.json` | Complete N8N workflow — import directly into N8N UI |
| `init_database.sql` | SQLite schema initialization script |
| `PROMPTS.md` | All Ollama prompt templates with variable reference |
| `database_schema.md` | Database table documentation and query examples |
| `docker-compose.yml` | Local development Docker Compose |
| `Dockerfile` | N8N Docker image (root-level for Render compatibility) |
| `config/render.yaml` | Render.com deployment configuration |

---

## Setup Instructions

### Prerequisites

- Docker and Docker Compose installed
- A Render.com account (or any Docker host)
- A Gmail account with App Password enabled
- A GitHub Personal Access Token with `repo` scope
- Ollama running at `http://ollama:11434` (Docker service)

---

### Step 1: Clone & Configure

```bash
git clone https://github.com/odeliyach/job-search-n8n.git
cd job-search-n8n
cp .env.example .env
```

Edit `.env`:
```
N8N_BASIC_AUTH_USER=admin
N8N_BASIC_AUTH_PASSWORD=your_password
GITHUB_TOKEN=ghp_your_personal_access_token
WEBHOOK_URL=https://your-n8n-instance.onrender.com
```

---

### Step 2: Initialize Database

```bash
# If running locally with Docker:
docker exec -it n8n sqlite3 /home/n8n/.n8n/job_search.db < init_database.sql

# Or copy and run inside the container:
docker cp init_database.sql n8n:/tmp/
docker exec n8n sqlite3 /home/n8n/.n8n/job_search.db ".read /tmp/init_database.sql"
```

---

### Step 3: Start with Docker Compose

```bash
docker-compose up -d
```

Services started:
- `n8n` at `http://localhost:5678`
- `ollama` at `http://localhost:11434`

---

### Step 4: Pull Ollama Model

```bash
docker exec ollama ollama pull llama3.2
```

---

### Step 5: Import Workflow into N8N

1. Open N8N at `http://localhost:5678` (or your Render URL)
2. Log in with your Basic Auth credentials
3. Click **+** → **Import from file**
4. Upload `workflow-all-tiers.json`
5. Click **Save**

---

### Step 6: Configure Credentials in N8N

#### Gmail SMTP Credential
1. Go to **Credentials** → **New**
2. Type: **SMTP**
3. Fill in:
   - Host: `smtp.gmail.com`
   - Port: `587`
   - Username: `odeliya.charitonova.dev@gmail.com`
   - Password: your Gmail App Password
4. Name it: `Gmail SMTP`
5. Save

#### GitHub Token (Environment Variable)
Set `GITHUB_TOKEN` environment variable in your Docker/Render deployment:
```yaml
# In docker-compose.yml environment section:
environment:
  - GITHUB_TOKEN=ghp_your_token_here
```

Or in Render.com: **Environment** → **Add Environment Variable** → `GITHUB_TOKEN`

---

### Step 7: Set Up Private Data Repository

1. Create a **private** GitHub repository named `job-search-data`
2. Initialize with a README
3. The workflow will automatically commit job application files there

---

### Step 8: Run Your First Application

1. Open the imported workflow in N8N
2. Click **"Set Job Details"** node and fill in:
   - `company_name`: Target company name
   - `job_title`: Exact job title
   - `job_description`: Full job description text
   - `job_url`: URL of the job posting
   - `location`: Job location
   - `user_skills`: Your skills (comma-separated)
   - `tech_stack`: Relevant tech stack for this role
3. Click **Execute Workflow** (▶)
4. Monitor execution in the workflow view
5. Check your email for the completion notification
6. Find all files committed to `job-search-data` on GitHub

---

## Deployment on Render.com

1. Fork this repo to your GitHub account
2. Create a new **Web Service** on Render.com
3. Point it to your fork
4. Set environment variables:
   - `N8N_BASIC_AUTH_USER`
   - `N8N_BASIC_AUTH_PASSWORD`
   - `GITHUB_TOKEN`
   - `N8N_ENCRYPTION_KEY` (generate with `openssl rand -hex 32`)
5. Deploy

See `config/render.yaml` for the full Render configuration.

---

## Workflow Tiers

| Tier | Node Name | Ollama Calls | Output Files |
|---|---|---|---|
| 1 | Core Application | 2 | `metadata.md`, `resume.md`, `cover_letter.md` |
| 2 | Cold Outreach | 4 | `cold_email.md`, `company_research.md`, `personal_angle.md` |
| 3 | Interview Prep | 4 | `interview_prep.md` |
| 4 | Portfolio Matching | 4 | `portfolio_matching.md` |
| 5 | Database & Tracking | 0 (SQLite) | `tracking.md`, `analytics.md` |

All Ollama calls go to `http://ollama:11434/api/generate` with model `llama3.2`.  
See [PROMPTS.md](PROMPTS.md) for all prompt templates.

---

## Database

SQLite at `/home/n8n/.n8n/job_search.db`. Tables:

| Table | Description |
|---|---|
| `applications` | One row per job application |
| `tier_outputs` | AI content per tier (5 rows/application) |
| `follow_ups` | 3 follow-up reminders per application |
| `analytics` | Single-row aggregated metrics |
| `error_logs` | Workflow errors for debugging |

See [database_schema.md](database_schema.md) for full documentation and query examples.

---

## Troubleshooting

### Ollama not responding
```bash
docker exec ollama ollama list    # Check models are downloaded
docker logs ollama                 # Check for errors
curl http://localhost:11434/api/tags  # Test connectivity
```

### Files not being written
```bash
docker exec n8n ls /home/n8n/.n8n/vault/  # Check vault exists
docker exec n8n ls -la /home/n8n/.n8n/    # Check permissions
```

### SQLite errors
```bash
docker exec n8n sqlite3 /home/n8n/.n8n/job_search.db ".tables"
docker exec n8n sqlite3 /home/n8n/.n8n/job_search.db ".schema applications"
```

### Git commit failing
- Verify `GITHUB_TOKEN` environment variable is set
- Ensure the token has `repo` scope
- Confirm `job-search-data` private repository exists

### Email not sending
- Verify Gmail App Password is correct (not your regular Gmail password)
- Enable 2FA on Gmail before generating App Passwords
- Check SMTP credential is named exactly `Gmail SMTP` in N8N

---

## Security Notes

- The `GITHUB_TOKEN` is read from environment variables — never hardcoded in the workflow
- Gmail App Passwords are stored in N8N credentials (encrypted), not in this repository
- The `.env` file is in `.gitignore` — never commit it
- Job application files go to the **private** `job-search-data` repo, not here

---

## License

MIT License — see [LICENSE](LICENSE) for details.