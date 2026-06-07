-- Restore composite index with amar
DROP INDEX IF EXISTS crawler.idx_ma_putusans_tingkat_tahun;

CREATE INDEX idx_ma_putusans_tingkat_tahun_amar ON crawler.mahkamah_agung_putusans USING btree (tingkat_proses, tahun, amar);
