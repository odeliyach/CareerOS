# Setup Guide

## Prerequisites

- Docker Desktop installed and running
- A GitHub account with a **private** repo named `job-search-data`
- A [Groq API key](https://console.groq.com) (free)
- A GitHub Personal Access Token with `repo` scope
- A Gmail account with an App Password enabled (for SMTP notifications)
- Gmail OAuth2 credentials (for Gmail Trigger and Gmail nodes)

## Step 1, Clone and configure

```bash
git clone https://github.com/odeliyach/CareerOS.git
cd CareerOS
cp .env.example .env
```

Edit `.env` and fill in:
- `GITHUB_TOKEN`, your GitHub PAT
- `GROQ_API_KEY`, from console.groq.com
- `N8N_ENCRYPTION_KEY`, run `openssl rand -hex 32` to generate one

## Step 2, Start n8n

```bash
make start
# or: docker compose up -d
```

Open `http://localhost:5679` in your browser.

## Step 3, Import workflows

In n8n: click the **+** icon → **Import from file** → upload each JSON from `n8n-workflows/`.

| File | What it does |
|---|---|
| `workflow-all-tiers.json` | Main pipeline, Form Trigger + Webhook trigger, 6 tiers, GitHub commit |
| `workflow-followup-scheduler.json` | Daily follow-up digest, 4 triggers (9:00/9:30/10:00/10:30), one per follow-up type |
| `workflow-email-listener.json` | Gmail classifier, detects rejections/invites/offers, logs to GitHub, sends notifications |
| `workflow-gmail-labeler.json` | Inbox auto-labeling every 30 min, 5 labels, dedup by threadId, time-based escalation |

## Step 4, Configure credentials in n8n

Go to **Credentials** and add:

| Credential name | Type | Notes |
|---|---|---|
| `Header Auth account` | HTTP Header Auth | Header: `Authorization`, Value: `token YOUR_GITHUB_TOKEN`, used for all GitHub API calls |
| `Header Auth account 2` | HTTP Header Auth | Header: `Authorization`, Value: `Bearer YOUR_GROQ_API_KEY`, used for all Groq calls |
| Gmail SMTP | SMTP | Host: `smtp.gmail.com`, Port: `587`, use Gmail App Password (not your main password) |
| Gmail OAuth2 | Gmail OAuth2 | Used by Gmail Trigger (Email Listener) and Gmail nodes (Auto-Labeler) |

> **Note:** All workflows read credentials by credential ID, not by name, so the exact name doesn't matter as long as you assign the right credential to each node after importing.

## Step 5, Configure Gmail Auto-Labeler

The labeler requires 5 Gmail labels to exist in your account before activating. Create these in Gmail settings:

- `N8N`
- `WAITING FOR RESPONSE`
- `REPLIED`
- `FROM RECRUITER`
- `NEED TO REPLY`

Then open the `Fix Logic` node and update the label ID constants to match your actual Gmail label IDs:
```js
const ID_REPLIED       = "Label_xxxx";
const ID_WAITING       = "Label_xxxx";
const ID_N8N           = "Label_xxxx";
const ID_NEED_REPLY    = "Label_xxxx";
const ID_FROM_RECRUITER = "Label_xxxx";
```

Get your label IDs from the Gmail API: `GET https://gmail.googleapis.com/gmail/v1/users/me/labels`

Also update `MY_EMAIL` in the same node:
```js
const MY_EMAIL = "your_email@gmail.com";
```

> **TIME_LIMIT:** The node currently has `const TIME_LIMIT = 12 * 60 * 60 * 1000;` (12 hours). Change to `60 * 1000` for testing (1-minute escalation).

## Step 6, Activate workflows

| Workflow | How to activate |
|---|---|
| Main workflow | Uses a Form Trigger, just click **Save** (no Active toggle needed) |
| Follow-Up Scheduler | Toggle **Active ON** |
| Email Listener | Toggle **Active ON** |
| Gmail Auto-Labeler | Toggle **Active ON** |

## Step 7, Submit your first job

Open the main workflow → click the Form Trigger node → copy the **Production URL**.

Paste a job description into the form and submit. After ~8 minutes, check your `job-search-data` GitHub repo for the output files under `Job_Applications/Active/`.

## Step 8, Set up Obsidian (optional)

1. Install [Obsidian](https://obsidian.md) and the **Obsidian Git** community plugin
2. Open your vault pointing at a local clone of `job-search-data`
3. In Obsidian Git settings:
   - Auto-pull interval: `10` minutes
   - Auto-push: disabled (n8n handles all commits)
   - Pull on startup: enabled
4. Install the **Dataview** community plugin, the `Main_Dashboard.md` table uses it
5. (Optional) Install **Kanban** plugin for the board view and **Calendar** plugin for daily journaling

Application files appear locally within 10 minutes of each job submission.

## Demo (portfolio)

To run the portfolio demo locally with the real webhook connected:

1. Open `index.html` in VS Code → right-click → **Open with Live Server**
2. The WEBHOOK in the file points to `http://localhost:5679/webhook/job-search-demo`
3. Make sure n8n is running and the main workflow is active
4. Paste a job description and click Analyze, the real pipeline fires in the background

> The public GitHub Pages version (`odeliyach.github.io/CareerOS`) has `WEBHOOK: 'YOUR_N8N_WEBHOOK_URL'` as a placeholder, it shows the simulated result but doesn't trigger your local n8n.
