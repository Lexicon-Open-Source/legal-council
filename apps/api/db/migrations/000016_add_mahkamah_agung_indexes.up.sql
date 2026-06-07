-- Enable trigram extension for pattern matching
CREATE EXTENSION IF NOT EXISTS pg_trgm;

-- Composite index for common filter combinations
CREATE INDEX idx_ma_putusans_tingkat_tahun_amar
  ON crawler.mahkamah_agung_putusans (tingkat_proses, tahun, amar);

-- GIN indexes for ILIKE pattern searches
CREATE INDEX idx_ma_putusans_nomor_trgm
  ON crawler.mahkamah_agung_putusans USING gin (nomor gin_trgm_ops);

CREATE INDEX idx_ma_putusans_lembaga_trgm
  ON crawler.mahkamah_agung_putusans USING gin (lembaga_peradilan gin_trgm_ops);

CREATE INDEX idx_ma_putusans_hakim_trgm
  ON crawler.mahkamah_agung_putusans USING gin (hakim_ketua gin_trgm_ops);

-- GIN indexes for array containment queries
CREATE INDEX idx_ma_putusans_klasifikasi_gin
  ON crawler.mahkamah_agung_putusans USING gin (klasifikasi);

CREATE INDEX idx_ma_putusans_kata_kunci_gin
  ON crawler.mahkamah_agung_putusans USING gin (kata_kunci);
