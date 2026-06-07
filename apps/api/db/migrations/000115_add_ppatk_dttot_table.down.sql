DROP TRIGGER IF EXISTS update_ppatk_dttot_updated_at ON crawler.ppatk_dttot;

DROP INDEX IF EXISTS crawler.idx_ppatk_dttot_densus_code;
DROP INDEX IF EXISTS crawler.idx_ppatk_dttot_entity_type;

DROP TABLE IF EXISTS crawler.ppatk_dttot;
