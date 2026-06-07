-- Drop composite index that includes amar column
-- btree indexes cannot handle values > 8KB

DROP INDEX IF EXISTS crawler.idx_ma_putusans_tingkat_tahun_amar;

-- Create a replacement index without amar
CREATE INDEX IF NOT EXISTS idx_ma_putusans_tingkat_tahun ON crawler.mahkamah_agung_putusans USING btree (tingkat_proses, tahun);
