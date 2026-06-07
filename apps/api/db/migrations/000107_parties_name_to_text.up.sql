-- Ubah kolom name dan identifier_legal_name dari VARCHAR(500) ke TEXT
-- untuk menampung nama organisasi Indonesia secara lengkap.
-- ALTER COLUMN TYPE TEXT pada VARCHAR adalah metadata-only change di PostgreSQL
-- (tidak ada table rewrite), sehingga near-instant dan safe untuk production.
ALTER TABLE ocds.parties
    ALTER COLUMN name TYPE TEXT,
    ALTER COLUMN identifier_legal_name TYPE TEXT,
    ALTER COLUMN additional_identifier_legal_name TYPE TEXT;
