-- Singapore E-Litigation Judgments: Singapore Supreme Court decisions
-- Source: https://www.elitigation.sg/gd

CREATE TABLE crawler.singapore_judgments (
    id SERIAL PRIMARY KEY,
    citation TEXT UNIQUE NOT NULL,          -- "[2025] SGHC 260" (unique identifier)
    case_number TEXT,                       -- "HC/CC 63/2025"
    case_title TEXT NOT NULL,               -- "Public Prosecutor v Gao Xiong"

    -- Court information
    court TEXT,                             -- "General Division of the High Court"
    court_type TEXT,                        -- "SGHC", "SGDC", "SGCA", etc.

    -- Decision date
    decision_date DATE,

    -- Parties (separate columns, not JSONB)
    plaintiff TEXT,
    defendant TEXT,

    -- Classification
    catchwords TEXT[] DEFAULT '{}',         -- ["Criminal Law", "Offences", "Attempted rape"]
    judges TEXT[] DEFAULT '{}',             -- ["Hoo Sheau Peng J"]

    -- PDF attachment
    pdf_url TEXT,
    pdf_storage_path TEXT,

    -- Metadata
    source_url TEXT NOT NULL,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Essential indexes for common queries
CREATE INDEX idx_sg_judgments_decision_date ON crawler.singapore_judgments (decision_date DESC);
CREATE INDEX idx_sg_judgments_court_type ON crawler.singapore_judgments (court_type);

-- Update trigger (reuses existing function from crawler schema)
CREATE TRIGGER update_sg_judgments_updated_at
    BEFORE UPDATE ON crawler.singapore_judgments
    FOR EACH ROW
    EXECUTE FUNCTION crawler.update_updated_at_column();
