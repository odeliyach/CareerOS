# Obsidian Vault Sync - Complete Setup Guide

## Overview
- **N8N automation** writes application files and commits to `odeliyach/job-search-data/Obsidian_Vault/`.  
- **GitHub (private)** stores the vault; commits include timestamps and folder moves.  
- **Obsidian Git plugin** auto-pulls every 10 minutes to the local vault at `C:\Users\odali\Obsidian\Job_Search_Test`.  
- The dashboard note auto-updates; the Kanban/Calendar manual layer is **not yet set up**.

---

## Vault Folder Structure (local)
```
C:\Users\odali\Obsidian\Job_Search_Test
├─ Dashboard/
│  └─ 01_Main_Dashboard.md      ← AUTO-UPDATE: counts, recent activity, follow-ups, quick links
│
├─ Job_Applications/
│  ├─ Active/                   ← applied / initial_contact
│  ├─ Waiting/                  ← phone_screen_scheduled / technical_scheduled
│  ├─ Offers/                   ← offer_received
│  └─ Rejected/                 ← rejected
│      └─ [Company].md          ← single source of truth per application
│
├─ My_Materials/
│  ├─ Base_Resume.md
│  ├─ Resume_Versions/          ← [Company]_Resume_v1.md + Resume_Index.md (auto-generated)
│  └─ Portfolio_Projects/       ← Projects_Summary.md + Skills_Matrix.md (auto-generated)
│
├─ Interview_Prep/
│  ├─ Company_Specific/         ← [Company]_Interview.md + Interview_Index.md (auto-generated)
│  ├─ LeetCode_Progress.md (optional)
│  ├─ System_Design_Notes.md (optional)
│  └─ Behavioral_Questions.md (optional)
│
├─ Resources/                   ← user maintained
├─ Templates/                   ← reference templates
└─ Database/
   └─ job_search.db             ← sqlite mirror (if enabled)
```

### GitHub Mirror
```
odeliyach/job-search-data/
└─ Obsidian_Vault/
   ├─ Dashboard/
   ├─ Job_Applications/{Active,Waiting,Offers,Rejected}/
   ├─ My_Materials/{Resume_Versions,Portfolio_Projects}/
   ├─ Interview_Prep/Company_Specific/
   ├─ Resources/
   ├─ Templates/
   └─ Database/job_search.db
```

---

## Source of Truth: Application Files
- Each `Job_Applications/[Status]/[Company].md` file carries frontmatter:
  ```
  company, role, job_link, applied_date/date_sent, status, stage,
  resume_version, referral, salary_range_min, salary_range_max,
  currency, location, company_industry, contact, notes, tags
  ```
- **Stage values (pipeline view):** Applied → HR → OA → Technical Interview → Final → Offer / Rejected.  
- **Status (folder move):** `applied`, `phone_screen_scheduled`, `technical_scheduled`, `offer_received`, `rejected`.
- **Auto-filled by N8N:** company, role, job_link, applied_date, follow-up dates.  
- **Manual as things evolve:** stage, resume_version, referral, contact, notes, salary ranges, tags.

---

## Auto-Organization Logic (N8N)
| Status | Destination folder | Commit message pattern |
|---|---|---|
| applied / initial_contact | `Job_Applications/Active/` | `Created {Company}.md (Applied)` |
| phone_screen_scheduled / technical_scheduled | `Job_Applications/Waiting/` | `Moved {Company}.md: Applied → Waiting` |
| offer_received | `Job_Applications/Offers/` | `Moved {Company}.md: Waiting → Offers` |
| rejected | `Job_Applications/Rejected/` | `Moved {Company}.md: {Prev} → Rejected` |

Moves happen in Git; Obsidian Git pulls the change automatically.

---

## Auto-Created / Auto-Updated Files
- `Dashboard/01_Main_Dashboard.md` — totals, upcoming follow-ups (next 7 days), recent activity, quick links to active apps.  
- `Job_Applications/.../[Company].md` — main application note with Tier 1–3 outputs plus follow-up schedule and communication log.  
- `My_Materials/Resume_Versions/` — `[Company]_Resume_v1.md` per app + `Resume_Index.md`.  
- `Interview_Prep/Company_Specific/` — `[Company]_Interview.md` per app + `Interview_Index.md`.  
- `Portfolio_Projects/` — `Projects_Summary.md` and `Skills_Matrix.md` stay in sync with portfolio metadata.  
- Email listener writes logs to `Obsidian_Vault/Email_Log/` (private repo).

---

## Auto-Folder Creation
N8N ensures required folders exist before writing:
```
Dashboard
Job_Applications
Job_Applications/Active
Job_Applications/Waiting
Job_Applications/Offers
Job_Applications/Rejected
My_Materials
My_Materials/Resume_Versions
My_Materials/Portfolio_Projects
Interview_Prep
Interview_Prep/Company_Specific
Resources
Templates
```
If missing, the workflow creates the folder (with `.gitkeep` if needed) and commits, so Obsidian always sees the structure.

---

## Views (Dataview · Kanban · Calendar)
- **Dataview table** lives in `Dashboard/01_Main_Dashboard.md` and renders directly from frontmatter—no manual maintenance.  
- **Kanban board** (`Job_Tracker_Kanban.md`) is manual: drag cards between stages when status changes.  
- **Calendar plugin** is optional for journaling interviews, calls, and events.  
- Manual layer (Dataview, Kanban, Calendar wiring) is **partial / not fully configured**; data still flows automatically via N8N + Git.

---

## Follow-Up Schedule (per application note)
Example block inside `[Company].md`:
```markdown
## Follow-Up Schedule
- [ ] Day 3 check-in: 2026-03-22
- [ ] Day 7 follow-up: 2026-03-26
- [ ] Day 30 check-in: 2026-04-18
- [ ] 90-day check-in: 2026-06-17
```
The follow-up scheduler workflow reads these dates, generates drafts, and emails a digest for manual approval. Emails are **never auto-sent**.

---

## Obsidian Git Plugin Configuration
1) Install: Obsidian → Settings → Community Plugins → search “Obsidian Git” → Install & Enable.  
2) Clone the repo locally (outside Obsidian):  
   ```bash
   git clone https://github.com/odeliyach/job-search-data.git "C:\Users\odali\Obsidian\Job_Search_Test"
   ```  
   This gives Obsidian a working copy to read from.
3) Configure in Obsidian (Settings → Obsidian Git):  
   - Remote: `https://github.com/odeliyach/job-search-data.git` (should already be set from the clone)  
   - Branch: `main`  
   - Auto-pull interval: `10` minutes  
   - Auto-push/auto-commit: disabled (N8N handles commits)  
   - Pull before push: enabled; Pull on startup: enabled
4) In Obsidian Git, click **Pull from remote** once to sync the freshly cloned folder.

---

## Quick Reference: File Purposes
| File | Purpose | Generated by |
|---|---|---|
| `[Company].md` | Frontmatter + all Tier outputs + schedule | Tier 1–3 + scheduler |
| `[Company]_Resume_v1.md` | Tailored resume (full rewrite) | Tier 6 resume node |
| `Resume_Index.md` | List of resume versions | Index node |
| `[Company]_Interview.md` | Company-specific prep | Tier 3 |
| `Interview_Index.md` | List of interview docs | Index node |
| `Projects_Summary.md` / `Skills_Matrix.md` | Portfolio overview + skills map | Portfolio node |
| `Email_Log/*.md` | Incoming email events + drafts | Email listener |
| `Dashboard/01_Main_Dashboard.md` | Counts, follow-ups, links | Main workflow |

---

## Environment Requirements
| Variable | Value |
|---|---|
| `GITHUB_TOKEN` | Repo scope for `odeliyach/job-search-data` |
| Gmail OAuth2 | For email listener workflow |
| N8N URL | Used by approval webhook in Wait nodes |

---

## Troubleshooting
- **Files not appearing?** Pull manually with Obsidian Git; confirm `GITHUB_TOKEN` has write access; check N8N Git Commit node logs.  
- **Email listener mislabels?** Adjust Gmail trigger query; review the “Classify Email” node output; tune keyword lists.  
- **Follow-ups not firing?** Ensure dates use `YYYY-MM-DD`; confirm the scheduler workflow ran; verify `GITHUB_TOKEN` read access.  
- **Folders missing?** Re-run the workflow; the auto-folder creation step will add `.gitkeep` files and commit the structure.  
