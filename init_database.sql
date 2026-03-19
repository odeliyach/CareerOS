-- =============================================================
-- Job Search Automation - SQLite Database Initialization
-- Database: /home/n8n/.n8n/job_search.db
-- =============================================================

PRAGMA journal_mode = WAL;
PRAGMA foreign_keys = ON;

-- =============================================================
-- TABLE: applications
-- Stores each job application submitted
-- =============================================================
CREATE TABLE IF NOT EXISTS applications (
  id               TEXT PRIMARY KEY,
  company_name     TEXT NOT NULL,
  job_title        TEXT NOT NULL,
  job_url          TEXT,
  location         TEXT,
  job_description  TEXT,
  job_requirements TEXT,
  status           TEXT NOT NULL DEFAULT 'applied',
  folder_path      TEXT,
  applied_date     TEXT,
  created_at       TEXT NOT NULL DEFAULT (datetime('now')),
  updated_at       TEXT NOT NULL DEFAULT (datetime('now'))
);

-- =============================================================
-- TABLE: tier_outputs
-- Stores the AI-generated content for each tier per application
-- =============================================================
CREATE TABLE IF NOT EXISTS tier_outputs (
  id               INTEGER PRIMARY KEY AUTOINCREMENT,
  application_id   TEXT NOT NULL,
  tier_number      INTEGER NOT NULL,
  tier_name        TEXT NOT NULL,
  output_content   TEXT,
  file_path        TEXT,
  created_at       TEXT NOT NULL DEFAULT (datetime('now')),
  FOREIGN KEY (application_id) REFERENCES applications(id) ON DELETE CASCADE
);

-- =============================================================
-- TABLE: follow_ups
-- Stores scheduled follow-up reminders per application
-- =============================================================
CREATE TABLE IF NOT EXISTS follow_ups (
  id               INTEGER PRIMARY KEY AUTOINCREMENT,
  application_id   TEXT NOT NULL,
  scheduled_date   TEXT NOT NULL,
  reminder_type    TEXT NOT NULL,
  completed        INTEGER NOT NULL DEFAULT 0,
  notes            TEXT,
  created_at       TEXT NOT NULL DEFAULT (datetime('now')),
  FOREIGN KEY (application_id) REFERENCES applications(id) ON DELETE CASCADE
);

-- =============================================================
-- TABLE: analytics
-- Aggregated metrics — one row, updated after each application
-- =============================================================
CREATE TABLE IF NOT EXISTS analytics (
  id                    TEXT PRIMARY KEY DEFAULT 'singleton',
  total_applications    INTEGER NOT NULL DEFAULT 0,
  response_count        INTEGER NOT NULL DEFAULT 0,
  interview_count       INTEGER NOT NULL DEFAULT 0,
  offer_count           INTEGER NOT NULL DEFAULT 0,
  average_response_time TEXT,
  updated_at            TEXT NOT NULL DEFAULT (datetime('now'))
);

-- =============================================================
-- TABLE: error_logs
-- Records errors from workflow execution for debugging
-- =============================================================
CREATE TABLE IF NOT EXISTS error_logs (
  id               INTEGER PRIMARY KEY AUTOINCREMENT,
  application_id   TEXT,
  tier_number      INTEGER,
  error_type       TEXT NOT NULL,
  error_message    TEXT,
  stack_trace      TEXT,
  created_at       TEXT NOT NULL DEFAULT (datetime('now'))
);

-- =============================================================
-- INDEXES
-- =============================================================
CREATE INDEX IF NOT EXISTS idx_applications_company    ON applications(company_name);
CREATE INDEX IF NOT EXISTS idx_applications_status     ON applications(status);
CREATE INDEX IF NOT EXISTS idx_applications_applied    ON applications(applied_date);
CREATE INDEX IF NOT EXISTS idx_tier_outputs_app        ON tier_outputs(application_id);
CREATE INDEX IF NOT EXISTS idx_tier_outputs_tier       ON tier_outputs(tier_number);
CREATE INDEX IF NOT EXISTS idx_follow_ups_app          ON follow_ups(application_id);
CREATE INDEX IF NOT EXISTS idx_follow_ups_scheduled    ON follow_ups(scheduled_date);
CREATE INDEX IF NOT EXISTS idx_follow_ups_completed    ON follow_ups(completed);
CREATE INDEX IF NOT EXISTS idx_error_logs_app          ON error_logs(application_id);

-- =============================================================
-- SEED DATA: Initial analytics row
-- =============================================================
INSERT OR IGNORE INTO analytics (id, total_applications, response_count, interview_count, offer_count)
VALUES ('singleton', 0, 0, 0, 0);
