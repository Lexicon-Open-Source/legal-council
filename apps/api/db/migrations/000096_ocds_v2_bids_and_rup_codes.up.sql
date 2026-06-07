-- ============================================================
-- OCDS v2: Bids table (OCDS Bid Extension) + rup_codes on tender
-- ============================================================

-- ---- 1. CREATE BIDS TABLE (OCDS Bid Extension: bids/details) ----
-- Per https://extensions.open-contracting.org/en/extensions/bids/
-- Each row represents one bid detail entry.

CREATE TABLE IF NOT EXISTS ocds.bids (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    release_id      UUID NOT NULL REFERENCES ocds.releases(id) ON DELETE CASCADE,
    bid_id          VARCHAR(150),
    date            TIMESTAMPTZ,
    status          VARCHAR(50),  -- invited, pending, valid, disqualified, withdrawn
    value_amount    NUMERIC(20,2),
    value_currency  VARCHAR(3) DEFAULT 'IDR',
    tenderer_id     UUID REFERENCES ocds.parties(id),
    -- Extension: corrected_amount stores harga_terkoreksi (Indonesia-specific)
    corrected_amount NUMERIC(20,2),
    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_bids_release ON ocds.bids(release_id);
CREATE INDEX IF NOT EXISTS idx_bids_tenderer ON ocds.bids(tenderer_id);

COMMENT ON TABLE ocds.bids IS 'OCDS Bid Extension (bids/details). Each row = one bid from one tenderer.';
COMMENT ON COLUMN ocds.bids.corrected_amount IS 'Extension: harga_terkoreksi from Indonesian procurement (corrected bid price after evaluation).';

-- ---- 2. REMOVE BID COLUMNS FROM TENDER_TENDERERS ----
-- tender_tenderers becomes a pure junction table (tender <-> party).
-- Bid-specific data now lives in ocds.bids.

ALTER TABLE ocds.tender_tenderers
    DROP COLUMN IF EXISTS bid_amount,
    DROP COLUMN IF EXISTS bid_currency,
    DROP COLUMN IF EXISTS corrected_amount,
    DROP COLUMN IF EXISTS bid_status;

-- ---- 3. ADD RUP_CODES TO TENDER ----
-- Extension: rup_codes links SPSE tenders to SiRUP planning records.
-- Used for cross-referencing via related_processes.

ALTER TABLE ocds.tender
    ADD COLUMN IF NOT EXISTS rup_codes TEXT[];

COMMENT ON COLUMN ocds.tender.rup_codes IS 'Extension: array of RUP (Rencana Umum Pengadaan) codes from SiRUP, used for cross-referencing related planning processes.';

-- GIN index for array containment queries (SiRUP cross-linking)
CREATE INDEX IF NOT EXISTS idx_tender_rup_codes ON ocds.tender USING GIN (rup_codes);

-- ---- 4. DOCUMENT EXTENSION COLUMNS ON PLANNING ----

COMMENT ON COLUMN ocds.planning.fiscal_year IS 'Extension: tahun_anggaran from Indonesian procurement (fiscal/budget year).';
COMMENT ON COLUMN ocds.planning.rup_id IS 'Extension: kode_rup from SiRUP (single RUP identifier for this planning record).';
COMMENT ON COLUMN ocds.planning.rup_codes IS 'Deprecated: rup_codes moved to ocds.tender for SPSE data. Kept for backward compatibility.';
