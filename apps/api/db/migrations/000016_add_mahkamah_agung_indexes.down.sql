DROP INDEX IF EXISTS crawler.idx_ma_putusans_tingkat_tahun_amar;
DROP INDEX IF EXISTS crawler.idx_ma_putusans_nomor_trgm;
DROP INDEX IF EXISTS crawler.idx_ma_putusans_lembaga_trgm;
DROP INDEX IF EXISTS crawler.idx_ma_putusans_hakim_trgm;
DROP INDEX IF EXISTS crawler.idx_ma_putusans_klasifikasi_gin;
DROP INDEX IF EXISTS crawler.idx_ma_putusans_kata_kunci_gin;
-- Note: pg_trgm extension is shared, don't drop it
