-- Add CHECK constraint for date ordering
ALTER TABLE crawler.mahkamah_agung_putusans
ADD CONSTRAINT ck_ma_putusans_date_ordering CHECK (
    (tanggal_register IS NULL OR tanggal_musyawarah IS NULL
     OR tanggal_register <= tanggal_musyawarah) AND
    (tanggal_musyawarah IS NULL OR tanggal_dibacakan IS NULL
     OR tanggal_musyawarah <= tanggal_dibacakan)
);
