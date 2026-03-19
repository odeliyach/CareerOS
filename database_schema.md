# Database Schema Documentation

SQLite database at `/home/n8n/.n8n/job_search.db` — initialized by `init_database.sql`.

---

## Tables Overview

| Table | Purpose |
|---|---|
| `applications` | One row per job application submitted |
| `tier_outputs` | AI-generated content per tier (5 rows per application) |
| `follow_ups` | Scheduled follow-up reminders (3 rows per application) |
| `analytics` | Single-row aggregate metrics, updated after each application |
| `error_logs` | Workflow execution errors for debugging |

---

## Table: `applications`

Stores every job application created by the workflow.

| Column | Type | Constraints | Description |
|---|---|---|---|
| `id` | TEXT | PRIMARY KEY | Unique ID in format `app-{timestamp}-{random}` |
| `company_name` | TEXT | NOT NULL | Company name as entered |
| `job_title` | TEXT | NOT NULL | Job title as entered |
| `job_url` | TEXT | — | URL of the job posting |
| `location` | TEXT | — | Job location (city, remote, etc.) |
| `job_description` | TEXT | — | Full job description text |
| `job_requirements` | TEXT | — | Extracted requirements section |
| `status` | TEXT | DEFAULT `'applied'` | One of: `applied`, `interviewing`, `offered`, `rejected`, `withdrawn` |
| `folder_path` | TEXT | — | Absolute vault path: `/home/n8n/.n8n/vault/YYYY/MM/DD_Company_Title/` |
| `applied_date` | TEXT | — | ISO date string `YYYY-MM-DD` |
| `created_at` | TEXT | NOT NULL | ISO datetime when record was created |
| `updated_at` | TEXT | NOT NULL | ISO datetime when record was last modified |

**Indexes:** `company_name`, `status`, `applied_date`

### Example Row

```sql
SELECT * FROM applications LIMIT 1;
-- id: app-1710806400000-x7y2z
-- company_name: Google
-- job_title: Senior Software Engineer
-- status: applied
-- applied_date: 2026-03-19
```

---

## Table: `tier_outputs`

Stores the AI-generated output content for each tier. Every application has up to 5 rows (one per tier).

| Column | Type | Constraints | Description |
|---|---|---|---|
| `id` | INTEGER | PRIMARY KEY AUTOINCREMENT | Auto-assigned integer ID |
| `application_id` | TEXT | NOT NULL, FK | References `applications.id` |
| `tier_number` | INTEGER | NOT NULL | 1 through 5 |
| `tier_name` | TEXT | NOT NULL | Human-readable: `Core Application`, `Cold Outreach`, `Interview Prep`, `Portfolio Matching`, `Database & Tracking` |
| `output_content` | TEXT | — | Summary of what was generated |
| `file_path` | TEXT | — | Vault folder path for this tier's files |
| `created_at` | TEXT | NOT NULL | ISO datetime |

**Foreign Key:** `application_id` → `applications.id` (CASCADE DELETE)  
**Indexes:** `application_id`, `tier_number`

### Tier Names Reference

| `tier_number` | `tier_name` | Files Generated |
|---|---|---|
| 1 | Core Application | `metadata.md`, `resume.md`, `cover_letter.md` |
| 2 | Cold Outreach | `cold_email.md`, `company_research.md`, `personal_angle.md` |
| 3 | Interview Prep | `interview_prep.md` |
| 4 | Portfolio Matching | `portfolio_matching.md` |
| 5 | Database & Tracking | `tracking.md`, `analytics.md` (vault root) |

---

## Table: `follow_ups`

Three scheduled follow-up reminders per application: 1 week, 2 weeks, 1 month after applying.

| Column | Type | Constraints | Description |
|---|---|---|---|
| `id` | INTEGER | PRIMARY KEY AUTOINCREMENT | Auto-assigned integer ID |
| `application_id` | TEXT | NOT NULL, FK | References `applications.id` |
| `scheduled_date` | TEXT | NOT NULL | ISO date string `YYYY-MM-DD` |
| `reminder_type` | TEXT | NOT NULL | One of: `1_week`, `2_weeks`, `1_month` |
| `completed` | INTEGER | DEFAULT 0 | Boolean: 0 = pending, 1 = done |
| `notes` | TEXT | — | Optional notes added manually |
| `created_at` | TEXT | NOT NULL | ISO datetime |

**Foreign Key:** `application_id` → `applications.id` (CASCADE DELETE)  
**Indexes:** `application_id`, `scheduled_date`, `completed`

### Follow-up Schedule

```
Application Date: 2026-03-19
  → follow_up 1: 2026-03-26  (1 week)
  → follow_up 2: 2026-04-02  (2 weeks)
  → follow_up 3: 2026-04-18  (1 month)
```

---

## Table: `analytics`

Single-row table (keyed `'singleton'`). Updated after every new application.

| Column | Type | Description |
|---|---|---|
| `id` | TEXT | Always `'singleton'` (PRIMARY KEY) |
| `total_applications` | INTEGER | Total count of all applications |
| `response_count` | INTEGER | Applications that got a response |
| `interview_count` | INTEGER | Applications that reached interview stage |
| `offer_count` | INTEGER | Applications that received an offer |
| `average_response_time` | TEXT | Human-readable average (e.g., `"8.5 days"`) |
| `updated_at` | TEXT | ISO datetime of last update |

### Analytics Formulas

```sql
-- Response rate
SELECT ROUND(CAST(response_count AS REAL) / total_applications * 100, 1) || '%'
FROM analytics WHERE id = 'singleton';

-- Interview conversion rate
SELECT ROUND(CAST(interview_count AS REAL) / response_count * 100, 1) || '%'
FROM analytics WHERE id = 'singleton';

-- Offer conversion rate
SELECT ROUND(CAST(offer_count AS REAL) / interview_count * 100, 1) || '%'
FROM analytics WHERE id = 'singleton';
```

---

## Table: `error_logs`

Records any errors that occur during workflow execution for debugging.

| Column | Type | Description |
|---|---|---|
| `id` | INTEGER | PRIMARY KEY AUTOINCREMENT |
| `application_id` | TEXT | Related application (nullable) |
| `tier_number` | INTEGER | Which tier caused the error (nullable) |
| `error_type` | TEXT | Category: `ollama_error`, `file_write_error`, `db_error`, `git_error`, `email_error` |
| `error_message` | TEXT | Error message text |
| `stack_trace` | TEXT | Full stack trace if available |
| `created_at` | TEXT | ISO datetime |

**Index:** `application_id`

---

## Common Queries

### List all applications
```sql
SELECT id, company_name, job_title, status, applied_date
FROM applications
ORDER BY applied_date DESC;
```

### Upcoming follow-ups (next 7 days)
```sql
SELECT a.company_name, a.job_title, f.scheduled_date, f.reminder_type
FROM follow_ups f
JOIN applications a ON a.id = f.application_id
WHERE f.completed = 0
  AND date(f.scheduled_date) BETWEEN date('now') AND date('now', '+7 days')
ORDER BY f.scheduled_date;
```

### Applications by status
```sql
SELECT status, COUNT(*) as count
FROM applications
GROUP BY status
ORDER BY count DESC;
```

### Full dashboard metrics
```sql
SELECT
  a.total_applications,
  a.response_count,
  a.interview_count,
  a.offer_count,
  CASE WHEN a.total_applications > 0
    THEN ROUND(CAST(a.response_count AS REAL) / a.total_applications * 100, 1)
    ELSE 0 END AS response_rate_pct,
  CASE WHEN a.response_count > 0
    THEN ROUND(CAST(a.interview_count AS REAL) / a.response_count * 100, 1)
    ELSE 0 END AS interview_rate_pct,
  a.updated_at
FROM analytics a WHERE a.id = 'singleton';
```

### Recent errors
```sql
SELECT tier_number, error_type, error_message, created_at
FROM error_logs
ORDER BY created_at DESC
LIMIT 20;
```

---

## Entity Relationship Diagram

```
applications (1) ──── (N) tier_outputs
applications (1) ──── (N) follow_ups
applications (1) ──── (N) error_logs
analytics    (singleton row, no FK)
```

---

## Backup

```bash
# Copy database from Docker container
docker cp n8n:/home/n8n/.n8n/job_search.db ./backup_$(date +%Y%m%d).db

# Or if using a bind mount
cp /path/to/n8n/data/job_search.db ./backup_$(date +%Y%m%d).db
```
