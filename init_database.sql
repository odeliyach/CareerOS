-- ============================================================
-- Job Search Automation - SQLite Schema Initialization Script
-- Database: /home/n8n/.n8n/job_search.db
-- Usage: sqlite3 /home/n8n/.n8n/job_search.db < init_database.sql
-- ============================================================

PRAGMA journal_mode=WAL;
PRAGMA foreign_keys=ON;

-- ============================================================
-- Table: applications
-- Stores each job application submitted through the workflow.
-- ============================================================
CREATE TABLE IF NOT EXISTS applications (
    id               INTEGER PRIMARY KEY AUTOINCREMENT,
    company_name     TEXT    NOT NULL,
    job_title        TEXT    NOT NULL,
    job_url          TEXT,
    location         TEXT,
    job_description  TEXT,
    status           TEXT    NOT NULL DEFAULT 'processing',
    applied_date     TEXT,
    created_at       TEXT    NOT NULL DEFAULT (datetime('now')),
    updated_at       TEXT    NOT NULL DEFAULT (datetime('now'))
);

-- ============================================================
-- Table: tier_outputs
-- Stores the AI-generated content from each workflow tier.
-- ============================================================
CREATE TABLE IF NOT EXISTS tier_outputs (
    id               INTEGER PRIMARY KEY AUTOINCREMENT,
    application_id   INTEGER NOT NULL REFERENCES applications(id),
    tier_number      INTEGER NOT NULL CHECK (tier_number BETWEEN 1 AND 5),
    tier_name        TEXT    NOT NULL,
    output_content   TEXT,
    created_at       TEXT    NOT NULL DEFAULT (datetime('now'))
);

-- ============================================================
-- Table: follow_ups
-- Stores scheduled follow-up reminders for each application.
-- ============================================================
CREATE TABLE IF NOT EXISTS follow_ups (
    id               INTEGER PRIMARY KEY AUTOINCREMENT,
    application_id   INTEGER NOT NULL REFERENCES applications(id),
    scheduled_date   TEXT    NOT NULL,
    reminder_type    TEXT    NOT NULL, -- '1_week_followup', '2_week_followup', '1_month_followup'
    completed        INTEGER NOT NULL DEFAULT 0,
    created_at       TEXT    NOT NULL DEFAULT (datetime('now'))
);

-- ============================================================
-- Table: analytics
-- Global metrics, updated after each new application.
-- ============================================================
CREATE TABLE IF NOT EXISTS analytics (
    id                    INTEGER PRIMARY KEY AUTOINCREMENT,
    total_applications    INTEGER NOT NULL DEFAULT 0,
    response_count        INTEGER NOT NULL DEFAULT 0,
    interview_count       INTEGER NOT NULL DEFAULT 0,
    offer_count           INTEGER NOT NULL DEFAULT 0,
    average_response_time REAL    NOT NULL DEFAULT 0,
    updated_at            TEXT    NOT NULL DEFAULT (datetime('now'))
);

-- Seed a single analytics row so updates can use UPDATE instead of INSERT
INSERT OR IGNORE INTO analytics (id, total_applications, response_count, interview_count, offer_count)
SELECT 1, 0, 0, 0, 0
WHERE NOT EXISTS (SELECT 1 FROM analytics WHERE id = 1);

-- ============================================================
-- Indexes for common query patterns
-- ============================================================
CREATE INDEX IF NOT EXISTS idx_applications_status   ON applications (status);
CREATE INDEX IF NOT EXISTS idx_applications_company  ON applications (company_name);
CREATE INDEX IF NOT EXISTS idx_tier_outputs_app      ON tier_outputs  (application_id);
CREATE INDEX IF NOT EXISTS idx_follow_ups_app        ON follow_ups    (application_id);
CREATE INDEX IF NOT EXISTS idx_follow_ups_date       ON follow_ups    (scheduled_date);
CREATE INDEX IF NOT EXISTS idx_follow_ups_completed  ON follow_ups    (completed);

-- ============================================================
-- Trigger: keep updated_at current on applications
-- ============================================================
CREATE TRIGGER IF NOT EXISTS trg_applications_updated_at
AFTER UPDATE ON applications
FOR EACH ROW
BEGIN
    UPDATE applications SET updated_at = datetime('now') WHERE id = NEW.id;
END;

-- ============================================================
-- Trigger: increment total_applications counter in analytics
-- ============================================================
CREATE TRIGGER IF NOT EXISTS trg_analytics_increment
AFTER INSERT ON applications
FOR EACH ROW
BEGIN
    UPDATE analytics
    SET    total_applications = total_applications + 1,
           updated_at         = datetime('now')
    WHERE  id = 1;
END;
