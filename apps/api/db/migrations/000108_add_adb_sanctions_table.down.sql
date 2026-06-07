DROP TRIGGER IF EXISTS update_adb_sanctions_updated_at ON crawler.adb_sanctions;

DROP INDEX IF EXISTS crawler.idx_adb_sanctions_adb_id;
DROP INDEX IF EXISTS crawler.idx_adb_sanctions_nationality;
DROP INDEX IF EXISTS crawler.idx_adb_sanctions_name;

DROP TABLE IF EXISTS crawler.adb_sanctions;
