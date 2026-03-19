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
┌───────────────────────────────────────────────────────────┐
│                N8N Workflow (14 nodes)                     │
│                                                           │
│  [Trigger] → [Set Details] → [Parse Job Info]             │
│                                    │                      │
│                                    ▼                      │
│                         [ATS Keyword Optimization]        │
│                    ┌────────────┼──────────────┐          │
│                    ▼            ▼               ▼          │
│              [Tier 1]      [Tier 2]        [Tier 3]        │
│              [Tier 4]      [Tier 5]  ← All run in PARALLEL │
│                    └────────────┼──────────────┘          │
│                                 ▼                         │
│                         [Merge Results]                   │
│                                 ▼                         │
│                  [Git Commit → Obsidian Vault]            │
│                                 ▼                         │
│                [Notify: Email Ready for Approval]         │
│                                 ▼                         │
│                  [Manual Approval ← User Reviews]         │
│                                 ▼                         │
│                      [Send Email Notification]            │
└───────────────────────────────────────────────────────────┘
        │
        ▼ GitHub Sync
odeliyach/job-search-data/Obsidian_Vault/
        │
        ▼ Obsidian Git plugin (auto-pull every 10 min)
C:\Users\odali\Obsidian\Job_Search_Test\
```

### Obsidian Vault Structure (synced via GitHub)

```
odeliyach/job-search-data/Obsidian_Vault/
├── Dashboard/
│   └── 01_Main_Dashboard.md        ← auto-updated
├── Job_Applications/
│   ├── Active/                     ← status: applied
│   ├── Waiting/                    ← status: phone_screen / technical
│   ├── Offers/                     ← status: offer_received
│   └── Rejected/                   ← status: rejected
├── My_Materials/
│   ├── Resume_Versions/            ← one file per company
│   └── Portfolio_Projects/
├── Interview_Prep/
│   └── Company_Specific/           ← one file per company
├── Resources/
└── Templates/
```

Each `Job_Applications/[Status]/[company].md` file includes:
- Frontmatter (company, role, dates, status, salary, etc.)
- Job Requirements vs My Skills
- Generated Materials (resume, cover letter, cold email, interview prep, portfolio)
- Communication Log (all interactions with timestamps)
- Follow-up Schedule (Day 3, Day 7, Post-Phone, Post-Technical)

---

## Repository Contents

| File | Description |
|---|---|
| `n8n-workflows/workflow-all-tiers.json` | Main N8N workflow — all 5 tiers in parallel + Obsidian sync |
| `n8n-workflows/workflow-email-listener.json` | Email listener — monitors Gmail, classifies emails, generates rejection responses |
| `n8n-workflows/workflow-followup-scheduler.json` | Daily follow-up scheduler — Day 3, Day 7, post-interviews, 90-day check-in |
| `init_database.sql` | SQLite schema initialization script |
| `PROMPTS.md` | All Ollama prompt templates with variable reference |
| `prompts/tier-1-resume.md` | Senior Architect resume analysis prompt |
| `prompts/tier-1-cover-letter.md` | Cover letter generation prompt |
| `prompts/tier-2-cold-email.md` | Cold outreach email prompt |
| `prompts/tier-3-interview-questions.md` | Interview prep prompt |
| `prompts/tier-4-portfolio.md` | Portfolio matching prompt |
| `prompts/follow-up-email-template.md` | Follow-up email templates (Day 3, 7, post-screen, post-technical, 90-day) |
| `prompts/rejection-response-template.md` | Context-aware rejection response templates |
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

### Step 5: Import Workflows into N8N

1. Open N8N at `http://localhost:5678` (or your Render URL)
2. Log in with your Basic Auth credentials
3. Import all 3 workflows:
   - Click **+** → **Import from file** → Upload `n8n-workflows/workflow-all-tiers.json`
   - Click **+** → **Import from file** → Upload `n8n-workflows/workflow-email-listener.json`
   - Click **+** → **Import from file** → Upload `n8n-workflows/workflow-followup-scheduler.json`
4. Click **Save** for each

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

### Step 8: Set Up Obsidian Sync (Obsidian Git Plugin)

1. Open Obsidian → **Settings** → **Community Plugins**
2. Search: **"Obsidian Git"**
3. Install and enable the plugin
4. Configure the plugin:
   - **Remote URL:** `https://github.com/odeliyach/job-search-data.git`
   - **Auto pull interval:** `10` (minutes)
   - **Vault location:** `Obsidian_Vault` subfolder
5. Click **"Pull from remote"** for the first sync
6. Files will now appear in `C:\Users\odali\Obsidian\Job_Search_Test` automatically

> **Sync Flow:** N8N (Render) → Commits to GitHub → Obsidian Git pulls every 10 min → Files appear in your local vault

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

All 5 tiers execute in **parallel** after the ATS Keyword Optimization node.

| Tier | Node Name | Ollama Calls | Output Files |
|---|---|---|---|
| 0 | ATS Keyword Optimization | 0 | Keyword analysis (in-memory) |
| 1 | Core Application | 2 | `metadata.md`, `resume.md`, `cover_letter.md` |
| 2 | Cold Outreach | 4 | `cold_email.md`, `company_research.md`, `personal_angle.md` |
| 3 | Interview Prep | 4 | `interview_prep.md` |
| 4 | Portfolio Matching | 4 + GitHub API | `portfolio_matching.md` (real GitHub projects) |
| 5 | Database & Tracking | 0 (SQLite) | `tracking.md`, `analytics.md` |

All Ollama calls go to `http://ollama:11434/api/generate` with model `llama3.2`.  
See [PROMPTS.md](PROMPTS.md) and the `prompts/` folder for all prompt templates.

### Additional Workflows

| Workflow | Trigger | Purpose |
|---|---|---|
| `workflow-email-listener.json` | Every 30 minutes | Monitors Gmail, classifies job emails, generates rejection responses (with approval) |
| `workflow-followup-scheduler.json` | Daily at 9 AM | Checks for due follow-ups (Day 3, Day 7, post-interviews, 90-day) — all require manual approval |

### Email Safety

**Zero emails are sent without manual user approval.** The flow is:
1. N8N generates email draft
2. N8N sends you a notification email with preview
3. You review in N8N and click **Resume** to approve
4. Only then is the email sent

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