-- Drop trigger first
DROP TRIGGER IF EXISTS update_interpol_notices_updated_at ON crawler.interpol_red_notices;

-- Drop indexes
DROP INDEX IF EXISTS crawler.idx_interpol_notices_wanted_nationality;
DROP INDEX IF EXISTS crawler.idx_interpol_notices_forename_trgm;
DROP INDEX IF EXISTS crawler.idx_interpol_notices_family_name_trgm;
DROP INDEX IF EXISTS crawler.idx_interpol_notices_updated_at;
DROP INDEX IF EXISTS crawler.idx_interpol_notices_wanted_by;
DROP INDEX IF EXISTS crawler.idx_interpol_notices_nationality;

-- Drop table
DROP TABLE IF EXISTS crawler.interpol_red_notices;

-- Note: We don't drop pg_trgm extension as other tables may use it
