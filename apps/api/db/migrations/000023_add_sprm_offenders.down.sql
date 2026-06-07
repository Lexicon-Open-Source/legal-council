-- Drop SPRM Malaysia Corruption Offenders table
-- Safety: Only drop if table has no data or explicit confirmation
DO $$
DECLARE
    row_count INTEGER;
BEGIN
    SELECT COUNT(*) INTO row_count FROM crawler.sprm_offenders;
    IF row_count > 0 THEN
        RAISE EXCEPTION 'Cannot drop crawler.sprm_offenders: table contains % rows. Backup data before dropping.', row_count;
    END IF;
END $$;

DROP TABLE IF EXISTS crawler.sprm_offenders;
