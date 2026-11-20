<div align="center">

<img src="https://img.shields.io/badge/CareerOS-v1.0-D4A5A5?style=for-the-badge&labelColor=393346&logo=sparkles" alt="CareerOS"/>

# CareerOS: Automated Job Intelligence System

**End-to-end job search automation: AI analysis · CV tailoring · follow-up scheduling · Gmail classification · inbox auto-labeling · portfolio dashboard**

[![Demo](https://img.shields.io/badge/Live_Demo-odeliyach.github.io%2FCareerOS-B5C99A?style=flat-square&logo=github&logoColor=white)](https://odeliyach.github.io/CareerOS)
[![n8n](https://img.shields.io/badge/n8n-Workflow_Automation-FFB5A7?style=flat-square&logo=n8n&logoColor=white)](https://n8n.io)
[![Groq](https://img.shields.io/badge/Groq-gpt--oss--120b-FFC09F?style=flat-square&logoColor=white)](https://groq.com)
[![GitHub](https://img.shields.io/badge/Data_Store-GitHub_API-AED9E0?style=flat-square&logo=github&logoColor=333)](https://github.com)
[![License: MIT](https://img.shields.io/badge/License-MIT-B5C99A?style=flat-square)](LICENSE)

</div>

---

A job search automation system I built with n8n. Paste a job description and it produces a tailored CV, cover letter, outreach emails, interview prep, and a follow-up schedule, then saves everything as Markdown files in a private GitHub repo.

The live demo is a static dashboard with sample data. The Analyze button only works against a local n8n.

## Why I built it

I was applying to a lot of roles and tracking them in spreadsheets. I wanted something that does the repetitive parts (reading the posting, tailoring the CV, reminding me to follow up) and keeps a full history I can read and diff. It is also a project to practice workflow design, LLM prompting, and working with API limits.

## How it works

The steps run in a fixed order, and the LLM writes the content of each step. That keeps the system predictable and cheap to run.

```
Job description (form or webhook)
        |
   Extract and parse job fields
        |
   Tier 1: resume analysis, cover letter, fit score, ATS keywords
   Tier 2: cold outreach emails, company research, LinkedIn messages
   Tier 3: skills gap, interview questions, talking points, salary guide
   Tier 4: fetch my GitHub repos, match them to the role
   Tier 5: follow-up schedule and status tracking
   Tier 6: tailored resume
        |
   Merge results -> commit to private GitHub repo -> email notification
```

The tiers run one after another with short waits (15 to 25 seconds) so the free Groq tier does not return rate limit errors. A full run takes a few minutes. That was a deliberate trade: I chose zero cost over speed. The detailed diagram, with every node, is in [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md).

## Workflows

| File | Trigger | What it does |
|---|---|---|
| `workflow-all-tiers.json` | Form or webhook | The main pipeline above |
| `job-scanner-workflow.json` | Daily schedule | Pulls LinkedIn postings through Apify, skips ones already seen using a Google Sheet, scores new ones with Groq, saves matches above 70 |
| `workflow-email-listener.json` | New Gmail message | Classifies replies (rejection, interview invite, offer, acknowledgement) and updates the application status |
| `workflow-followup-scheduler.json` | Four daily cron triggers | Drafts follow-up emails for day 3, 7, 30 and 90. Drafts are sent to me for review, nothing goes to a recruiter automatically |
| `workflow-gmail-labeler.json` | Every 30 minutes | Labels inbox messages for the job search |
| `helper-get-label-ids.json` | Manual | One-off helper to look up Gmail label IDs |

## Tech stack

| Part | Choice |
|---|---|
| Orchestration | n8n, self-hosted in Docker |
| LLM | `openai/gpt-oss-120b` through the Groq API (free tier) |
| Data store | Private GitHub repo, one Markdown file per application |
| Duplicate cache | Google Sheets |
| Job source | Apify (LinkedIn scraper) |
| Email | Gmail API and SMTP |
| Demo | Static HTML on GitHub Pages |
| Optional | Obsidian with the Git plugin, to browse the data locally |

## Design decisions

- **GitHub as the data store.** Each application is a Markdown file with YAML frontmatter. I get version history, readable diffs, and it works with Obsidian. The downside is that I cannot query across files without reading them all. A Google Sheet acts as a small cache for the job scanner's duplicate check.
- **Deduplicate before calling the LLM.** Already-seen jobs are dropped first, so the token budget is only spent on new postings.
- **Structured output.** Where the workflow needs to parse a result, the request itself sets `response_format: json_object` (not only the prompt wording), and the code validates the result and uses a fallback if it is broken.
- **Human in the loop.** Anything that would be sent to another person is a draft I approve.
- **Model:** `openai/gpt-oss-120b` through the Groq API. The model name is set once, in the `Job Input` node, and passed to every step. See the next two sections.

## How the main workflow is structured

- **Prompt building is separate from the API calls.** Each step has a Code node ("Prepare") that builds the prompt and request parameters. The 14 HTTP Request nodes that call Groq are identical and just send what the Prepare node gives them. To change a prompt, a model, or a setting, I edit one Code node and never touch the HTTP nodes.
- **One place for the model name.** `Job Input` sets `groq_model` and every Prepare node reads it.
- **JSON mode where I need to parse the output.** The extraction and scoring steps set `response_format: json_object` in the API request and use temperature 0.3. The code validates the result and falls back to a safe default if the JSON is broken, so one bad response does not stop the run. Writing steps use a higher temperature (0.7).
- **Retries.** The Groq nodes use Retry On Fail (3 tries, 5 seconds apart), mostly to survive 429 rate limit errors, together with the short waits between tiers.
- **Safe writes to GitHub.** Before writing a file the workflow reads its current SHA (`Get File SHA`, `Get Resume SHA`). If the file exists it is updated, if not it is created, so reruns do not fail with a conflict.

## Switching the model

The first version used `llama-3.1-8b-instant`. My Groq account no longer had access to it, so I moved the whole system to `openai/gpt-oss-120b`. What changed because of that:

- It is a much larger model and a reasoning model, so it follows the structured prompts more reliably, especially the JSON ones.
- Reasoning models spend part of their output budget on thinking. With the old limits, some answers were cut off, so I raised `max_tokens` (4096 for most steps, 8192 for the longest ones).
- To avoid wasting that budget on simple tasks, extraction and writing steps use `reasoning_effort: low`.
- It has different rate limits than the small model, so I retuned the waits between tiers (15 to 25 seconds) and added retries.
- Moving the model name into one node made this kind of change a one-line edit. The job scanner has its own copy of the model name and has to be updated separately.

## Problems I ran into

- Groq rate limits (HTTP 429): fixed with deduplication, smaller batches, and waits.
- GitHub 422 and 409 errors when overwriting files: read the file's current SHA first, and write sequentially instead of in parallel.
- A node dropping the data from earlier nodes: read upstream nodes by name instead of by position.
- Gmail API field names and thread IDs behaving differently from the docs: work with messages, then deduplicate by thread ID in a Code node.

## Running it

Full steps are in [docs/SETUP.md](docs/SETUP.md). In short:

1. Install Docker, copy `.env.example` to `.env`, and fill it in.
2. Run `make start` and open `http://localhost:5679`.
3. Import the workflows from `n8n-workflows/`.
4. Create two Header Auth credentials: one for Groq (`Bearer <key>`) and one for GitHub (`Bearer <token>`).
5. In `job-scanner-workflow.json`, replace `YOUR_GOOGLE_SHEET_ID`, `YOUR_APIFY_TOKEN` and the placeholder email addresses.
6. Create a private repo for the output files and update the repo name in the GitHub nodes.

## Limitations

- Runs locally in Docker, so it only works while my machine is on. A small VPS would fix that.
- No automated tests for the workflows.
- No monitoring or alerting.
- The public demo is a static page with sample data.

## Documentation

- [Setup](docs/SETUP.md): installing, credentials, importing the workflows
- [Architecture](docs/ARCHITECTURE.md): the full node-by-node flow
- [Troubleshooting](docs/TROUBLESHOOTING.md): errors I hit and how I fixed them
- [Obsidian sync](docs/OBSIDIAN_SYNC.md): browsing the data locally
- [Changelog](docs/CHANGELOG.md)
- [Prompts](prompts/PROMPTS.md): the prompt for each step

## Project structure

```
CareerOS/
├── .github/
│   └── workflows/
│       └── deploy.yml            validates the workflow JSONs, deploys the demo
├── docs/
│   ├── ARCHITECTURE.md
│   ├── CHANGELOG.md
│   ├── OBSIDIAN_SYNC.md
│   ├── SETUP.md
│   └── TROUBLESHOOTING.md
├── n8n-workflows/
│   ├── workflow-all-tiers.json
│   ├── job-scanner-workflow.json
│   ├── workflow-email-listener.json
│   ├── workflow-followup-scheduler.json
│   ├── workflow-gmail-labeler.json
│   └── helper-get-label-ids.json
├── prompts/
│   ├── 01-resume.md
│   ├── 02-cover-letter.md
│   ├── 03-cold-email.md
│   ├── 04-interview-prep.md
│   ├── 05-talking-points.md
│   ├── 06-skills-gap.md
│   ├── 07-portfolio-github.md
│   ├── 08-salary-negotiation.md
│   └── PROMPTS.md
├── .env.example
├── Dockerfile
├── docker-compose.yml
├── Makefile
├── index.html                    static demo dashboard (GitHub Pages)
├── PROMPTS.md
├── LICENSE
└── README.md
```

## License

MIT
