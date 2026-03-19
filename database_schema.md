# Database Schema Documentation

**Database:** SQLite  
**Path:** `/home/n8n/.n8n/job_search.db`  
**Initialization:** run `sqlite3 /home/n8n/.n8n/job_search.db < init_database.sql`

---

## Table: `applications`

Stores each job application submitted through the N8N workflow.

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| `id` | INTEGER | PK, AUTOINCREMENT | Unique record identifier |
| `company_name` | TEXT | NOT NULL | Name of the target company |
| `job_title` | TEXT | NOT NULL | Job position title |
| `job_url` | TEXT | | URL to the original job posting |
| `location` | TEXT | | Job location (city / Remote) |
| `job_description` | TEXT | | Full job description text |
| `status` | TEXT | DEFAULT `'processing'` | Application status (see values below) |
| `applied_date` | TEXT | | ISO date when application was submitted |
| `created_at` | TEXT | DEFAULT `datetime('now')` | Record creation timestamp |
| `updated_at` | TEXT | DEFAULT `datetime('now')` | Last modification timestamp (auto-updated by trigger) |

**Status values:** `processing`, `applied`, `interview`, `offer`, `rejected`, `withdrawn`

---

## Table: `tier_outputs`

Stores the AI-generated content produced by each workflow tier for a given application.

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| `id` | INTEGER | PK, AUTOINCREMENT | Unique record identifier |
| `application_id` | INTEGER | NOT NULL, FK → `applications.id` | Parent application |
| `tier_number` | INTEGER | NOT NULL, 1–5 | Tier that produced this output |
| `tier_name` | TEXT | NOT NULL | Human-readable tier name |
| `output_content` | TEXT | | Full AI-generated text |
| `created_at` | TEXT | DEFAULT `datetime('now')` | Record creation timestamp |

**Tier names:** `Core Application`, `Cold Outreach`, `Interview Preparation`, `Portfolio Matching`, `Tracking & Analytics`

---

## Table: `follow_ups`

Stores scheduled follow-up reminders for each application.  
Three reminders are created automatically: **1 week**, **2 weeks**, and **1 month** after the application date.
The `reminder_type` values are `'1_week_followup'`, `'2_week_followup'`, and `'1_month_followup'`.

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| `id` | INTEGER | PK, AUTOINCREMENT | Unique record identifier |
| `application_id` | INTEGER | NOT NULL, FK → `applications.id` | Parent application |
| `scheduled_date` | TEXT | NOT NULL | ISO date the reminder is scheduled for |
| `reminder_type` | TEXT | NOT NULL | `'1_week_followup'`, `'2_week_followup'`, or `'1_month_followup'` |
| `completed` | INTEGER | DEFAULT `0` | `0` = pending, `1` = completed |
| `created_at` | TEXT | DEFAULT `datetime('now')` | Record creation timestamp |

---

## Table: `analytics`

Global metrics table. Contains a single row (id = 1) that is updated after every new application via trigger.

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| `id` | INTEGER | PK, AUTOINCREMENT | Always `1` (single-row table) |
| `total_applications` | INTEGER | DEFAULT `0` | Total applications submitted |
| `response_count` | INTEGER | DEFAULT `0` | Applications that received a response |
| `interview_count` | INTEGER | DEFAULT `0` | Applications that reached interview stage |
| `offer_count` | INTEGER | DEFAULT `0` | Applications that resulted in an offer |
| `average_response_time` | REAL | DEFAULT `0` | Average days to receive a response |
| `updated_at` | TEXT | DEFAULT `datetime('now')` | Last update timestamp |

---

## Indexes

| Index | Table | Column(s) | Purpose |
|-------|-------|-----------|---------|
| `idx_applications_status` | applications | `status` | Filter by application status |
| `idx_applications_company` | applications | `company_name` | Look up by company |
| `idx_tier_outputs_app` | tier_outputs | `application_id` | Fetch all tiers for an application |
| `idx_follow_ups_app` | follow_ups | `application_id` | Fetch follow-ups for an application |
| `idx_follow_ups_date` | follow_ups | `scheduled_date` | Find upcoming reminders |
| `idx_follow_ups_completed` | follow_ups | `completed` | Filter pending reminders |

---

## Triggers

| Trigger | Event | Action |
|---------|-------|--------|
| `trg_applications_updated_at` | AFTER UPDATE on `applications` | Sets `updated_at = datetime('now')` |
| `trg_analytics_increment` | AFTER INSERT on `applications` | Increments `analytics.total_applications` |

---

## Entity-Relationship Diagram

```
applications (1) ─────< tier_outputs
     │
     └─────────────< follow_ups

analytics (standalone, auto-updated by trigger)
```

---

## Common Queries

```sql
-- All open applications
SELECT * FROM applications WHERE status NOT IN ('rejected', 'withdrawn') ORDER BY created_at DESC;

-- Pending follow-ups for today or earlier
SELECT a.company_name, a.job_title, f.scheduled_date, f.reminder_type
FROM follow_ups f
JOIN applications a ON a.id = f.application_id
WHERE f.completed = 0 AND f.scheduled_date <= date('now')
ORDER BY f.scheduled_date;

-- Tier outputs for a specific application
SELECT tier_number, tier_name, substr(output_content, 1, 100) AS preview
FROM tier_outputs
WHERE application_id = 1
ORDER BY tier_number;

-- Current analytics snapshot
SELECT * FROM analytics WHERE id = 1;

-- Mark a follow-up as completed
UPDATE follow_ups SET completed = 1 WHERE id = ?;

-- Update application status
UPDATE applications SET status = 'interview' WHERE id = ?;
```
