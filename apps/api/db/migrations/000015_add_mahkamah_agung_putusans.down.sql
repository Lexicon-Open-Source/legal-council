-- Rollback Mahkamah Agung Putusans table

DROP TRIGGER IF EXISTS update_ma_putusans_updated_at ON crawler.mahkamah_agung_putusans;
DROP INDEX IF EXISTS crawler.idx_ma_putusans_tanggal_dibacakan;
DROP INDEX IF EXISTS crawler.idx_ma_putusans_amar;
DROP INDEX IF EXISTS crawler.idx_ma_putusans_tingkat_proses;
DROP INDEX IF EXISTS crawler.idx_ma_putusans_tahun;
DROP INDEX IF EXISTS crawler.idx_ma_putusans_nomor;
DROP TABLE IF EXISTS crawler.mahkamah_agung_putusans;
