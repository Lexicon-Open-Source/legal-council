-- Add CHECK constraint: if pdf_storage_path is set, pdf_url must also be set
ALTER TABLE crawler.mahkamah_agung_putusans
ADD CONSTRAINT ck_ma_putusans_pdf_consistency CHECK (
    (pdf_storage_path IS NULL) OR
    (pdf_storage_path IS NOT NULL AND pdf_url IS NOT NULL)
);
