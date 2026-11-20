# Changelog

All notable changes to CareerOS, in reverse chronological order.

---

## Phase 3, Portfolio Demo

### Added
- `index.html`, single-page dashboard with particle loader, aurora background, animated funnel, weekly chart, application table with sort/filter, follow-up panel
- Password authentication via SHA-256 (Web Crypto API, no library)
- Live/Sample toggle, unlocks Analyze panel and fires real n8n webhook
- Webhook integration: `POST /webhook/job-search-demo` triggers main pipeline
- Terminal animation simulates pipeline steps; simulated result card always renders regardless of webhook status (fire-and-forget)
- X button and click-outside-to-dismiss on auth modal
- Textarea and Analyze button enabled for all visitors (not gated behind auth)
- GitHub Pages deployment at `odeliyach.github.io/CareerOS`
- GitHub Actions CI: validates workflow JSONs on push, auto-deploys to Pages

### Fixed
- `responseMode: 'immediatelyAfter'` not valid in this n8n version, removed parameter
- CORS errors when opening HTML from `file://`, added `N8N_CORS_ALLOWED_ORIGINS=*` to docker-compose
- Webhook receiving `job_description` but workflow expecting `job_description_raw`, fixed field name in fetch call
- `$('Job Form')` throws (not returns null) when workflow triggered via webhook, removed fallback reference, normalized in `Job Input` Set node

---

## Phase 2d, Gmail Auto-Labeling

### Added
- Scheduled workflow (every 30 min) classifying all inbox threads
- 5 labels: `N8N`, `WAITING FOR RESPONSE`, `REPLIED`, `FROM RECRUITER`, `NEED TO REPLY`
- Time-based escalation: `FROM RECRUITER` → `NEED TO REPLY` after 12 hours with no reply
- Clear-then-Apply pattern: removes all job labels before applying new one (prevents label accumulation)

### Fixed
- False `REPLIED` on first recruiter outreach, switched `isReply` detection to subject `Re:` prefix only (was: checking thread labels, which caused false positives when thread already had `FROM_RECRUITER`)
- Gmail API silent failures, field names are case-sensitive: `From`, `To`, `Subject`, `labels: [{id, name}]` not `labelIds`
- Switching to thread resource broke downstream nodes, kept message fetch, added `threadId` deduplication in Code node
- `Fix Logic` node must run in "Run Once for All Items" mode for `$input.all()` to span all messages in one pass

---

## Phase 2b, Follow-Up Scheduler

### Added
- Daily digest workflow generating personalized follow-up email drafts
- 4 follow-up types: day_3, day_7, day_30, day_90
- Drafts sent to owner for manual review, never auto-sent to recruiters
- Groq API replacing local Ollama (speed + no GPU requirement)

### Fixed
- All items processed instead of just today's, `// TEMP TEST` comment was bypassing `=== today` date filter; restored and added time-based type filter
- `now is not defined`, `today` was declared as a string at top of node; `now` as a Date object was never declared; added `const now = new Date()` before the filter block
- Rate limit crashes, split workflow into 4 triggers (9:00/9:30/10:00/10:30), one per follow-up type; added 2-minute wait between items
- `$helpers.httpRequest()` deprecated in n8n v1, replaced with HTTP Request nodes using stored credentials

---

## Phase 2a, Email Listener

### Added
- Gmail Trigger workflow detecting rejections, interview invites, and offers
- Stage-aware rejection detection: phone screen / technical / final round
- Stage-appropriate response templates with correct tone per stage
- GitHub commit of email log entry on every classified email
- Email notification with draft response

### Fixed
- Gmail Trigger self-email loop, n8n workflow notifications (sent to self) were being classified as recruiter emails; added `-from:` filter on trigger and explicit `fromEmail === toEmail` check in classification
- Classify Email JSON structure error, fixed field mapping
- `$helpers.httpRequest()` → HTTP Request node with stored credential for GitHub commit
- `...data` spread on unknown objects, replaced with explicit field mapping throughout

---

## Phase 1, Core Workflow

### Added
- Main pipeline: Form Trigger → 6 tiers → GitHub commit → email notification
- Tier 1: Resume analysis, cover letter, job fit score (JSON)
- Tier 2: Cold outreach emails, company research, LinkedIn messages
- Tier 3: Skills gap, interview questions, talking points, salary guide
- Tier 4: GitHub repo fetch + portfolio relevance analysis
- Tier 5: Tracking file with follow-up schedule
- Tier 6: Full CV rewrite against job requirements
- ATS keyword optimization (pure JS, no LLM call)
- Dashboard auto-update on each submission
- SMTP email notification on completion
- Webhook trigger (`/webhook/job-search-demo`) alongside Form Trigger

### Fixed
- T2 aggregator: `$input.all()` with positional indexing → read by node name
- Merge Results race condition: sequential chain instead of built-in merge trigger
- T3 aggregator: same `$input.all()` bug
- T4/T5 data not reaching commit node: chained sequentially
- Tier data collision in `Object.assign`: each tier now returns only its own keys
- CV file not updating on second run: GitHub API requires current file `sha` for overwrite; added `Get Resume SHA` node before commit; `sha || undefined` pattern handles both first-run create and subsequent update
- Groq rate limit (6000 TPM): added 30-second wait nodes between every consecutive pair of calls across T1, T2, T3
