-- Remove health check row
DELETE FROM crawler.health_checks WHERE crawler_type = 'eu_most_wanted';

-- Drop trigger
DROP TRIGGER IF EXISTS set_eu_most_wanted_fugitives_updated_at ON crawler.eu_most_wanted_fugitives;

-- Drop indexes
DROP INDEX IF EXISTS crawler.idx_eu_most_wanted_status;
DROP INDEX IF EXISTS crawler.idx_eu_most_wanted_country;
DROP INDEX IF EXISTS crawler.idx_eu_most_wanted_name_trgm;

-- Drop table
DROP TABLE IF EXISTS crawler.eu_most_wanted_fugitives;
