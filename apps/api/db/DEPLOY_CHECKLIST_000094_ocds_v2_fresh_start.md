# Deployment Checklist: Migration 000094 -- OCDS v2 Fresh Start

**Migration:** `migrations/000094_ocds_v2_fresh_start.up.sql`
**Rollback:** `migrations/000094_ocds_v2_fresh_start.down.sql`
**Risk Level:** CRITICAL -- Irreversible data destruction (TRUNCATE CASCADE)
**Estimated Downtime:** Plan for 15-30 minutes of OCDS data unavailability

---

## Summary of Changes

This migration performs a "fresh start" on the OCDS schema:

1. **ALTER 8 existing tables** -- adds ~30 new columns across releases, tender, awards, contracts, parties, planning, items, milestones, documents
2. **Replace 2 CHECK constraints** -- items_parent_check, milestones_parent_check (relaxed to allow release_id as parent)
3. **TRUNCATE CASCADE 3 tables** -- releases (cascades to tender, awards, contracts, planning, items, documents, milestones, tender_tenderers, award_suppliers, transformation_log), parties, transformation_log
4. **CREATE 6 new tables** -- amendments, related_processes, contract_implementation, contract_implementation_transactions, contract_implementation_milestones, contract_implementation_documents
5. **DROP and recreate 3 views** -- latest_releases, compiled_contracts, compiled_related_processes
6. **Deploy 2 new DAGs** -- ocds_v2_spse, ocds_v2_sirup
7. **Deactivate 3 old DAGs** -- spse_to_ocds_dag, opentender_tenders_to_ocds_dag, opentender_ocds_to_ocds_dag

### Critical Risk Factors

- `TRUNCATE TABLE ocds.releases CASCADE` destroys ALL existing OCDS data across 10+ tables
- golang-migrate does NOT wrap the entire .sql file in a single transaction; a partial failure leaves the database in an inconsistent state (e.g., columns added but data not truncated, or data truncated but tables not created)
- The `SET app.allow_release_delete = 'true'` session variable is required to bypass the immutability trigger on releases; if the trigger check fails, the TRUNCATE will error out
- Views must be explicitly DROPped before recreation because CREATE OR REPLACE cannot reorder columns
- The down migration CANNOT restore truncated data -- only schema changes are reversible
- The `latest_releases` view references `event_id` (added in migration 000070) and `nation` (added in this migration) -- if this migration partially fails after TRUNCATE but before view creation, queries against `latest_releases` will fail

---

## PHASE 0: Pre-Flight (1-2 Days Before Deploy)

### 0.1 Confirm Prerequisites

- [ ] Migration 000093 (parser_feedback_table) has been applied successfully
- [ ] Verify current migration version: `SELECT version, dirty FROM schema_migrations;` -- expect `93, false`
- [ ] Confirm the `event_id` column exists on `ocds.releases` (added in migration 000070)
- [ ] Confirm the immutability trigger exists: `SELECT tgname FROM pg_trigger WHERE tgrelid = 'ocds.releases'::regclass;`
- [ ] Confirm `app.allow_release_delete` mechanism works: `SET app.allow_release_delete = 'true'; SELECT current_setting('app.allow_release_delete', true); RESET app.allow_release_delete;`

### 0.2 Stakeholder Communication

- [ ] Notify all OCDS data consumers that OCDS data will be temporarily empty after deploy
- [ ] Confirm that no downstream reports, dashboards, or APIs depend on OCDS record counts being non-zero (or add graceful empty-state handling)
- [ ] Confirm that the old ETL DAGs (spse_to_ocds, opentender_tenders_to_ocds, opentender_ocds_to_ocds) have no in-flight runs
- [ ] Document the expected timeline for new v2 pipelines to repopulate data

### 0.3 Staging Validation

- [ ] Run the full up migration on a staging database with representative data
- [ ] Run the full down migration on staging to verify rollback works
- [ ] Run both new DAGs (ocds_v2_spse, ocds_v2_sirup) on staging and verify they produce valid records
- [ ] Verify the old DAGs are compatible with the new schema (they should be deactivated, but confirm they will not crash if accidentally triggered)

---

## PHASE 1: Pre-Deploy Baseline Audits (Read-Only)

Run these queries BEFORE deployment. Save all results -- they are your baseline for comparison and your only record of pre-migration data volumes.

### 1.1 Record Counts (SAVE THESE VALUES)

```sql
-- Total releases and breakdown by source_system
SELECT source_system, COUNT(*) AS cnt
FROM ocds.releases
GROUP BY source_system
ORDER BY source_system;

-- Total parties
SELECT COUNT(*) AS total_parties FROM ocds.parties;

-- Parties breakdown by role
SELECT role, COUNT(*) AS cnt
FROM ocds.parties
GROUP BY role
ORDER BY role;

-- Child table counts (all will be destroyed by CASCADE)
SELECT 'tender' AS tbl, COUNT(*) FROM ocds.tender
UNION ALL SELECT 'awards', COUNT(*) FROM ocds.awards
UNION ALL SELECT 'contracts', COUNT(*) FROM ocds.contracts
UNION ALL SELECT 'planning', COUNT(*) FROM ocds.planning
UNION ALL SELECT 'items', COUNT(*) FROM ocds.items
UNION ALL SELECT 'documents', COUNT(*) FROM ocds.documents
UNION ALL SELECT 'milestones', COUNT(*) FROM ocds.milestones
UNION ALL SELECT 'tender_tenderers', COUNT(*) FROM ocds.tender_tenderers
UNION ALL SELECT 'award_suppliers', COUNT(*) FROM ocds.award_suppliers
UNION ALL SELECT 'transformation_log', COUNT(*) FROM ocds.transformation_log;

-- Transformation log status breakdown (to know how much work the new pipelines need to redo)
SELECT source_system, status, COUNT(*)
FROM ocds.transformation_log
GROUP BY source_system, status
ORDER BY source_system, status;
```

**Action:** Save these results to a file or ticket. After deploy, all OCDS counts will be zero. These numbers tell you how much data the new pipelines need to regenerate.

### 1.2 Source Data Availability (New Pipelines Will Read From These)

```sql
-- SPSE source data the new pipeline will consume
SELECT COUNT(*) AS total_spse_tenders FROM crawler.spse_tenders;

-- SiRUP source data the new pipeline will consume
SELECT COUNT(*) AS total_sirup_paket FROM crawler.sirup_paket;
```

**Expected:** Both counts should be greater than zero. If either is zero, the corresponding new pipeline will have nothing to process -- investigate before deploying.

### 1.3 Schema Pre-Checks

```sql
-- Verify columns that will be added do NOT already exist (idempotent IF NOT EXISTS, but good to know)
SELECT column_name
FROM information_schema.columns
WHERE table_schema = 'ocds' AND table_name = 'releases' AND column_name = 'nation';
-- Expected: 0 rows (column does not yet exist)

-- Verify new tables do NOT already exist
SELECT table_name
FROM information_schema.tables
WHERE table_schema = 'ocds' AND table_name IN (
    'amendments', 'related_processes', 'contract_implementation',
    'contract_implementation_transactions', 'contract_implementation_milestones',
    'contract_implementation_documents'
);
-- Expected: 0 rows

-- Verify budget_source column exists (will be renamed to budget_source_description)
SELECT column_name
FROM information_schema.columns
WHERE table_schema = 'ocds' AND table_name = 'planning' AND column_name = 'budget_source';
-- Expected: 1 row (column exists and will be renamed)

-- Verify existing check constraints
SELECT conname, pg_get_constraintdef(oid)
FROM pg_constraint
WHERE conname IN ('items_parent_check', 'milestones_parent_check');
-- Document current definitions for rollback verification
```

### 1.4 Database Backup

- [ ] Take a full database backup (or at minimum, a backup of the `ocds` schema)
- [ ] Verify the backup is restorable (test restore on a scratch instance)
- [ ] Record the backup identifier/timestamp: _______________
- [ ] Confirm backup retention policy covers the rollback window (recommend 7+ days)

**THIS IS THE MOST CRITICAL PRE-DEPLOY STEP.** The down migration cannot restore data. Only a backup can.

---

## PHASE 2: Deploy Steps

### 2.1 Deactivate Old DAGs (BEFORE Migration)

Deactivate these DAGs in Airflow. Do NOT delete the DAG files.

- [ ] Deactivate `spse_to_ocds_dag` (toggle off in Airflow UI or via CLI)
- [ ] Deactivate `opentender_tenders_to_ocds` (toggle off)
- [ ] Deactivate `opentender_ocds_to_ocds` (toggle off)
- [ ] Wait for any currently running tasks in these DAGs to complete
- [ ] Verify no tasks are in `running` or `queued` state for these DAGs

```bash
# Airflow CLI alternative (if available)
airflow dags pause spse_to_ocds
airflow dags pause opentender_tenders_to_ocds
airflow dags pause opentender_ocds_to_ocds
```

### 2.2 Run the Migration

| Step | What Happens | Estimated Time | Can Fail Partially? |
|------|-------------|----------------|---------------------|
| ALTER tables (8 tables, ~30 columns) | Adds columns with defaults; non-blocking on empty-ish tables | < 10 sec | Yes -- golang-migrate runs statements sequentially |
| DROP/ADD constraints | Replaces items_parent_check, milestones_parent_check | < 1 sec | Yes |
| SET app.allow_release_delete | Session variable to bypass immutability trigger | Instant | If trigger doesn't recognize the setting, TRUNCATE fails |
| TRUNCATE releases CASCADE | Deletes ALL data from releases + 9 child tables | < 5 sec (fast for any size) | TRUNCATE is atomic per-statement |
| TRUNCATE parties CASCADE | Deletes ALL party records | < 1 sec | Atomic per-statement |
| TRUNCATE transformation_log CASCADE | Deletes ALL transformation history | < 1 sec | Atomic per-statement |
| CREATE 6 new tables + indexes | amendments, related_processes, contract_implementation + 3 children | < 5 sec | Yes -- partial table creation possible |
| DROP 3 views | latest_releases, compiled_contracts, compiled_related_processes | < 1 sec | If view doesn't exist, IF EXISTS handles it |
| CREATE 3 views | Recreate with new column lists | < 1 sec | Will fail if referenced columns don't exist |

```bash
# Run migration (adjust command for your deployment method)
migrate -path ./migrations -database "$DATABASE_URL" up 1
```

- [ ] Migration command completed without errors
- [ ] Check migration version: `SELECT version, dirty FROM schema_migrations;` -- expect `94, false`

**IF MIGRATION FAILS MID-WAY:** See "Partial Failure Recovery" in the Rollback section below. Do NOT proceed with DAG deployment.

### 2.3 Deploy New DAG Files

- [ ] Deploy `etl/dags/ocds_v2_spse_dag.py` to the Airflow DAGs folder
- [ ] Deploy `etl/dags/ocds_v2_sirup_dag.py` to the Airflow DAGs folder
- [ ] Deploy any updated pipeline modules (`lexicon_etl.pipelines.ocds_v2_spse.*`, `lexicon_etl.pipelines.ocds_v2_sirup.*`)
- [ ] Wait for Airflow to parse the new DAGs (check DAG parsing logs for import errors)
- [ ] Verify both DAGs appear in Airflow UI: `ocds_v2_spse`, `ocds_v2_sirup`
- [ ] Keep new DAGs PAUSED initially -- do not unpause until post-deploy verification passes

---

## PHASE 3: Post-Deploy Verification (Within 5 Minutes)

### 3.1 Migration Version Check

```sql
SELECT version, dirty FROM schema_migrations;
-- Expected: version = 94, dirty = false
-- STOP if dirty = true (indicates partial failure)
```

### 3.2 Verify Schema Changes Applied

```sql
-- New columns on releases
SELECT column_name, data_type, column_default
FROM information_schema.columns
WHERE table_schema = 'ocds' AND table_name = 'releases' AND column_name = 'nation';
-- Expected: 1 row, varchar, 'IDN'

-- New columns on tender (spot check)
SELECT column_name
FROM information_schema.columns
WHERE table_schema = 'ocds' AND table_name = 'tender'
  AND column_name IN ('tender_period_duration_in_days', 'contract_period_start_date', 'contract_period_duration_in_days');
-- Expected: 3 rows

-- New columns on parties (spot check)
SELECT column_name
FROM information_schema.columns
WHERE table_schema = 'ocds' AND table_name = 'parties'
  AND column_name IN ('additional_identifiers_scheme', 'fax_number', 'details');
-- Expected: 3 rows

-- budget_source renamed to budget_source_description
SELECT column_name
FROM information_schema.columns
WHERE table_schema = 'ocds' AND table_name = 'planning' AND column_name = 'budget_source_description';
-- Expected: 1 row

-- Verify budget_source no longer exists
SELECT column_name
FROM information_schema.columns
WHERE table_schema = 'ocds' AND table_name = 'planning' AND column_name = 'budget_source';
-- Expected: 0 rows

-- items.release_id FK column
SELECT column_name
FROM information_schema.columns
WHERE table_schema = 'ocds' AND table_name = 'items' AND column_name = 'release_id';
-- Expected: 1 row

-- milestones.release_id FK column
SELECT column_name
FROM information_schema.columns
WHERE table_schema = 'ocds' AND table_name = 'milestones' AND column_name = 'release_id';
-- Expected: 1 row
```

### 3.3 Verify New Tables Created

```sql
SELECT table_name
FROM information_schema.tables
WHERE table_schema = 'ocds' AND table_name IN (
    'amendments', 'related_processes', 'contract_implementation',
    'contract_implementation_transactions',
    'contract_implementation_milestones',
    'contract_implementation_documents'
)
ORDER BY table_name;
-- Expected: exactly 6 rows
```

### 3.4 Verify Indexes Created

```sql
SELECT indexname
FROM pg_indexes
WHERE schemaname = 'ocds' AND indexname IN (
    'idx_amendments_release',
    'idx_related_processes_release',
    'idx_related_processes_identifier',
    'idx_contract_impl_txn_impl',
    'idx_contract_impl_ms_impl',
    'idx_contract_impl_doc_impl'
);
-- Expected: exactly 6 rows
```

### 3.5 Verify Constraints Updated

```sql
-- Check new constraint definitions
SELECT conname, pg_get_constraintdef(oid)
FROM pg_constraint
WHERE conname IN ('items_parent_check', 'milestones_parent_check');
-- Expected:
--   items_parent_check: should include "release_id IS NOT NULL OR tender_id IS NOT NULL OR ..."
--   milestones_parent_check: should include "release_id IS NOT NULL OR tender_id IS NOT NULL OR ..."
-- Verify these are the RELAXED versions, not the old strict "exactly one parent" versions

-- Verify unique constraint on contract_implementation
SELECT conname
FROM pg_constraint
WHERE conname = 'uq_contract_impl_contract';
-- Expected: 1 row
```

### 3.6 Verify Data Truncation Completed

```sql
-- All OCDS data tables should be empty
SELECT 'releases' AS tbl, COUNT(*) FROM ocds.releases
UNION ALL SELECT 'parties', COUNT(*) FROM ocds.parties
UNION ALL SELECT 'tender', COUNT(*) FROM ocds.tender
UNION ALL SELECT 'awards', COUNT(*) FROM ocds.awards
UNION ALL SELECT 'contracts', COUNT(*) FROM ocds.contracts
UNION ALL SELECT 'planning', COUNT(*) FROM ocds.planning
UNION ALL SELECT 'items', COUNT(*) FROM ocds.items
UNION ALL SELECT 'documents', COUNT(*) FROM ocds.documents
UNION ALL SELECT 'milestones', COUNT(*) FROM ocds.milestones
UNION ALL SELECT 'tender_tenderers', COUNT(*) FROM ocds.tender_tenderers
UNION ALL SELECT 'award_suppliers', COUNT(*) FROM ocds.award_suppliers
UNION ALL SELECT 'transformation_log', COUNT(*) FROM ocds.transformation_log;
-- Expected: ALL counts = 0
-- STOP if any count > 0 (TRUNCATE CASCADE did not fully propagate)
```

### 3.7 Verify Views Exist and Are Queryable

```sql
-- latest_releases view
SELECT column_name
FROM information_schema.columns
WHERE table_schema = 'ocds' AND table_name = 'latest_releases'
ORDER BY ordinal_position;
-- Expected columns in order: id, ocid, release_id, language, tag, initiation_type,
--   buyer_id, source_system, source_id, source_url, source_updated_at,
--   date, nation, event_id, created_at, updated_at
-- Key: nation and event_id must be present

-- compiled_contracts view
SELECT column_name
FROM information_schema.columns
WHERE table_schema = 'ocds' AND table_name = 'compiled_contracts'
ORDER BY ordinal_position;
-- Key: implementation_status column must be present

-- compiled_related_processes view
SELECT column_name
FROM information_schema.columns
WHERE table_schema = 'ocds' AND table_name = 'compiled_related_processes'
ORDER BY ordinal_position;
-- Key: view must exist and be queryable

-- Smoke test: query each view (should return 0 rows, no errors)
SELECT COUNT(*) FROM ocds.latest_releases;
SELECT COUNT(*) FROM ocds.compiled_contracts;
SELECT COUNT(*) FROM ocds.compiled_related_processes;
-- Expected: all return 0 (tables are empty), no SQL errors
```

### 3.8 Verify Airflow State

- [ ] Old DAGs confirmed paused: `spse_to_ocds`, `opentender_tenders_to_ocds`, `opentender_ocds_to_ocds`
- [ ] New DAGs visible and paused: `ocds_v2_spse`, `ocds_v2_sirup`
- [ ] No DAG import errors in Airflow logs for new DAGs
- [ ] No DAG import errors in Airflow logs for old DAGs (they should still parse cleanly)

---

## PHASE 4: Activate New Pipelines

Only proceed after ALL Phase 3 checks pass.

### 4.1 First Run (Manual Trigger, Monitored)

- [ ] Unpause `ocds_v2_spse` DAG
- [ ] Manually trigger `ocds_v2_spse` (do not wait for scheduled run)
- [ ] Monitor the run in Airflow UI -- watch for:
  - `get_pending_spse` task: should find records (check log for "Found N pending SPSE tenders")
  - `transform_and_load` tasks: watch for error counts in logs
  - `report_results` task: check the summary report
- [ ] After `ocds_v2_spse` completes, verify data was loaded:

```sql
-- Should have records now
SELECT COUNT(*) FROM ocds.releases WHERE source_system = 'spse';
-- Expected: > 0

-- Check a sample release has the new nation column populated
SELECT id, ocid, nation, source_system, date
FROM ocds.releases
WHERE source_system = 'spse'
LIMIT 5;
-- Expected: nation = 'IDN' for all rows

-- Verify child tables populated
SELECT 'tender' AS tbl, COUNT(*) FROM ocds.tender
UNION ALL SELECT 'parties', COUNT(*) FROM ocds.parties
UNION ALL SELECT 'planning', COUNT(*) FROM ocds.planning;
-- Expected: counts > 0

-- Verify transformation log entries
SELECT status, COUNT(*)
FROM ocds.transformation_log
WHERE source_system = 'spse'
GROUP BY status;
-- Expected: success count > 0, error count should be low (< 5% of total)
```

- [ ] Unpause `ocds_v2_sirup` DAG
- [ ] Manually trigger `ocds_v2_sirup`
- [ ] Monitor the run, then verify:

```sql
SELECT COUNT(*) FROM ocds.releases WHERE source_system = 'sirup';
-- Expected: > 0

SELECT status, COUNT(*)
FROM ocds.transformation_log
WHERE source_system = 'sirup'
GROUP BY status;
-- Expected: success count > 0
```

### 4.2 Verify Data Integrity After First Run

```sql
-- Every release should have a tender record (for SPSE)
SELECT COUNT(*) AS releases_without_tender
FROM ocds.releases r
LEFT JOIN ocds.tender t ON t.release_id = r.id
WHERE r.source_system = 'spse' AND t.id IS NULL;
-- Expected: 0

-- Every release should have at least one party
SELECT COUNT(*) AS releases_without_parties
FROM ocds.releases r
WHERE r.source_system IN ('spse', 'sirup')
  AND NOT EXISTS (SELECT 1 FROM ocds.parties p WHERE p.id = r.buyer_id);
-- Expected: 0 (buyer should always exist)

-- No orphaned child records
SELECT COUNT(*) FROM ocds.tender WHERE release_id NOT IN (SELECT id FROM ocds.releases);
-- Expected: 0

SELECT COUNT(*) FROM ocds.contracts WHERE release_id NOT IN (SELECT id FROM ocds.releases);
-- Expected: 0

-- Views return data
SELECT COUNT(*) FROM ocds.latest_releases;
-- Expected: > 0

-- Items constraint check: every item should have at least one parent
SELECT COUNT(*) FROM ocds.items
WHERE release_id IS NULL AND tender_id IS NULL AND award_id IS NULL AND contract_id IS NULL;
-- Expected: 0

-- Milestones constraint check
SELECT COUNT(*) FROM ocds.milestones
WHERE release_id IS NULL AND tender_id IS NULL AND contract_id IS NULL;
-- Expected: 0
```

---

## PHASE 5: Rollback Plan

### 5A: Full Rollback (Schema + Data Restore from Backup)

**When to use:** Migration succeeded but new pipelines produce incorrect data, or a fundamental problem is discovered with the v2 approach.

**Can we roll back the schema?** YES -- the down migration reverses all schema changes.
**Can we roll back the data?** NO -- TRUNCATE is irreversible. Data restore requires the backup from Phase 1.4.

**Steps:**

1. [ ] Pause both new DAGs: `ocds_v2_spse`, `ocds_v2_sirup`
2. [ ] Run the down migration:
   ```bash
   migrate -path ./migrations -database "$DATABASE_URL" down 1
   ```
3. [ ] Verify migration version: `SELECT version, dirty FROM schema_migrations;` -- expect `93, false`
4. [ ] Restore OCDS data from backup taken in Phase 1.4
5. [ ] Verify restored data counts match the baseline from Phase 1.1
6. [ ] Unpause old DAGs: `spse_to_ocds`, `opentender_tenders_to_ocds`, `opentender_ocds_to_ocds`
7. [ ] Remove new DAG files from Airflow if desired (or leave paused)
8. [ ] Verify old DAGs can run successfully against restored data

### 5B: Partial Failure Recovery (Migration Failed Mid-Way)

**When to use:** The migration command exited with an error. golang-migrate does not use a single transaction, so the database may be in a partially migrated state.

**Diagnosis:**

```sql
-- Check if migration is marked dirty
SELECT version, dirty FROM schema_migrations;
-- If dirty = true, the migration failed partway through
```

**Determine what succeeded and what failed by checking:**

```sql
-- Did columns get added? (Phase 1 of migration)
SELECT column_name FROM information_schema.columns
WHERE table_schema = 'ocds' AND table_name = 'releases' AND column_name = 'nation';

-- Did TRUNCATE happen? (Phase 3 of migration)
SELECT COUNT(*) FROM ocds.releases;
-- If 0: TRUNCATE ran. If > 0: TRUNCATE did not run yet.

-- Did new tables get created? (Phase 4 of migration)
SELECT table_name FROM information_schema.tables
WHERE table_schema = 'ocds' AND table_name = 'amendments';

-- Did views get recreated? (Phase 5 of migration)
SELECT COUNT(*) FROM information_schema.views
WHERE table_schema = 'ocds' AND table_name = 'latest_releases';
```

**Recovery options for partial failure:**

- **If TRUNCATE did NOT run yet:** Safe to fix the issue and re-run. Set `dirty = false` in schema_migrations, fix the root cause, re-run migration.
- **If TRUNCATE ran but new tables/views failed:** You must either complete the migration manually (run remaining SQL statements) or restore from backup. Do NOT run the down migration because it will try to drop columns/restore constraints on empty tables, which may create further inconsistency.
- **In all partial failure cases:** Manually set the migration version:
  ```sql
  UPDATE schema_migrations SET version = 93, dirty = false;
  -- Then either: re-run migration, or restore from backup
  ```

### 5C: Forward-Fix (Preferred if Data is Already Truncated)

**When to use:** TRUNCATE succeeded but subsequent steps failed. Since old data is already gone, rolling back gains nothing. Better to fix forward.

1. [ ] Identify which SQL statements in the up migration failed
2. [ ] Run the remaining statements manually in order
3. [ ] After all statements succeed, update schema_migrations:
   ```sql
   UPDATE schema_migrations SET version = 94, dirty = false;
   ```
4. [ ] Run Phase 3 verification checks

---

## PHASE 6: Monitoring (First 72 Hours)

The new pipelines process data in daily batches. It will take multiple days to repopulate all OCDS data. Monitor closely.

### 6.1 Pipeline Health (Check Daily)

| Metric | Alert Condition | Where to Check |
|--------|----------------|----------------|
| `ocds_v2_spse` DAG status | Any task failure | Airflow UI > DAG Runs |
| `ocds_v2_sirup` DAG status | Any task failure | Airflow UI > DAG Runs |
| Error rate per run | errors > 5% of total processed | `report_results` task logs |
| Records processed per run | 0 records processed for 2+ consecutive runs | `get_pending_*` task logs |
| Old DAGs accidentally triggered | Any run after deactivation | Airflow UI > old DAG run history |

### 6.2 Data Growth Tracking

Run daily for the first 3 days:

```sql
-- Track repopulation progress
SELECT
    source_system,
    COUNT(*) AS total_releases,
    MIN(created_at) AS earliest,
    MAX(created_at) AS latest
FROM ocds.releases
GROUP BY source_system;

-- Compare against source data to track completion percentage
SELECT
    'spse' AS pipeline,
    (SELECT COUNT(*) FROM ocds.releases WHERE source_system = 'spse') AS loaded,
    (SELECT COUNT(*) FROM crawler.spse_tenders) AS total_source,
    ROUND(
        100.0 * (SELECT COUNT(*) FROM ocds.releases WHERE source_system = 'spse')
        / NULLIF((SELECT COUNT(*) FROM crawler.spse_tenders), 0), 1
    ) AS pct_complete
UNION ALL
SELECT
    'sirup',
    (SELECT COUNT(*) FROM ocds.releases WHERE source_system = 'sirup'),
    (SELECT COUNT(*) FROM crawler.sirup_paket),
    ROUND(
        100.0 * (SELECT COUNT(*) FROM ocds.releases WHERE source_system = 'sirup')
        / NULLIF((SELECT COUNT(*) FROM crawler.sirup_paket), 0), 1
    );

-- Transformation log error trend
SELECT
    source_system,
    status,
    DATE(created_at) AS day,
    COUNT(*)
FROM ocds.transformation_log
GROUP BY source_system, status, DATE(created_at)
ORDER BY day DESC, source_system;
```

### 6.3 Data Quality Checks (Run at +24h and +72h)

```sql
-- No NULL nation on any release
SELECT COUNT(*) FROM ocds.releases WHERE nation IS NULL;
-- Expected: 0

-- No orphaned records in new tables
SELECT COUNT(*) FROM ocds.amendments WHERE release_id NOT IN (SELECT id FROM ocds.releases);
-- Expected: 0

SELECT COUNT(*) FROM ocds.related_processes WHERE release_id NOT IN (SELECT id FROM ocds.releases);
-- Expected: 0

-- Views still functioning correctly
SELECT COUNT(*) FROM ocds.latest_releases;
SELECT COUNT(*) FROM ocds.compiled_contracts;
SELECT COUNT(*) FROM ocds.compiled_related_processes;
-- Expected: increasing counts over time, no errors

-- Verify SAVEPOINT error isolation is working (errors should not block successes)
SELECT
    source_system,
    status,
    COUNT(*)
FROM ocds.transformation_log
WHERE created_at > NOW() - INTERVAL '24 hours'
GROUP BY source_system, status;
-- Expected: success >> errors. If errors > 50%, investigate transform logic.
```

### 6.4 Completion Criteria

The migration is considered fully complete when:

- [ ] Both pipelines have run for 72+ hours without task failures
- [ ] Repopulation percentage for SPSE is > 95%
- [ ] Repopulation percentage for SiRUP is > 95%
- [ ] Error rate across all runs is < 2%
- [ ] All Phase 3 verification queries still pass
- [ ] No user-reported issues with OCDS data
- [ ] Old DAGs remain paused with no accidental runs
- [ ] Backup from Phase 1.4 retained for at least 7 more days

---

## Appendix A: Tables Affected by TRUNCATE CASCADE

When `TRUNCATE TABLE ocds.releases CASCADE` runs, the following tables are emptied due to `ON DELETE CASCADE` foreign keys:

| Table | FK to releases | Also cascades to |
|-------|---------------|-----------------|
| `ocds.tender` | `release_id` | `ocds.tender_tenderers` (via tender_id), `ocds.items` (via tender_id), `ocds.documents` (via tender_id), `ocds.milestones` (via tender_id) |
| `ocds.awards` | `release_id` | `ocds.award_suppliers` (via award_id), `ocds.items` (via award_id), `ocds.documents` (via award_id) |
| `ocds.contracts` | `release_id` | `ocds.items` (via contract_id), `ocds.documents` (via contract_id), `ocds.milestones` (via contract_id) |
| `ocds.planning` | `release_id` | -- |
| `ocds.items` | (indirect via tender/award/contract) | -- |
| `ocds.documents` | `release_id` + indirect | -- |
| `ocds.milestones` | (indirect via tender/contract) | -- |
| `ocds.transformation_log` | `release_id` (SET NULL) | Note: FK is ON DELETE SET NULL, but table is also explicitly truncated |

`ocds.parties` is truncated separately (not cascaded from releases) because parties have an independent lifecycle.

## Appendix B: Files Referenced

| File | Purpose |
|------|---------|
| `migrations/000094_ocds_v2_fresh_start.up.sql` | Forward migration: ALTER + TRUNCATE + CREATE + views |
| `migrations/000094_ocds_v2_fresh_start.down.sql` | Rollback migration: DROP new tables/columns, restore constraints/views (DATA NOT RECOVERABLE) |
| `etl/dags/ocds_v2_spse_dag.py` | New DAG: transforms `crawler.spse_tenders` to OCDS v2 releases |
| `etl/dags/ocds_v2_sirup_dag.py` | New DAG: transforms `crawler.sirup_paket` to OCDS v2 releases |
| `etl/dags/spse_to_ocds_dag.py` | Old DAG: DEACTIVATE (do not delete) |
| `etl/dags/opentender_tenders_to_ocds_dag.py` | Old DAG: DEACTIVATE (do not delete) |
| `etl/dags/opentender_ocds_to_ocds_dag.py` | Old DAG: DEACTIVATE (do not delete) |
