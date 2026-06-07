-- Add confidence scoring columns to llm_extraction.bpk_regulations.
-- Both nullable so existing rows remain valid.

ALTER TABLE llm_extraction.bpk_regulations
    ADD COLUMN confidence_score REAL,
    ADD COLUMN text_coverage REAL;
