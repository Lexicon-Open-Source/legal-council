DROP TABLE IF EXISTS llm_extraction.mahkamah_agung_putusans;
DROP FUNCTION IF EXISTS llm_extraction.trigger_set_timestamp();

-- Only drop schema if no other tables remain
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.tables
        WHERE table_schema = 'llm_extraction'
    ) THEN
        DROP SCHEMA IF EXISTS llm_extraction;
    END IF;
END $$;
