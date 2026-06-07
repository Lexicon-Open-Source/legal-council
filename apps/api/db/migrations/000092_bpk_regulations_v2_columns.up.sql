-- Add v2 extraction metadata columns to llm_extraction.bpk_regulations
ALTER TABLE llm_extraction.bpk_regulations
    ADD COLUMN IF NOT EXISTS extraction_version INTEGER DEFAULT 1,
    ADD COLUMN IF NOT EXISTS detection_method VARCHAR(20),
    ADD COLUMN IF NOT EXISTS pdf_quality VARCHAR(20);

COMMENT ON COLUMN llm_extraction.bpk_regulations.extraction_version IS
    '1 = v1 (LLM-only), 2 = v2 (regex-first + LLM fallback)';

COMMENT ON COLUMN llm_extraction.bpk_regulations.detection_method IS
    'regex = deterministic section detection, llm_phase1 = LLM-based outline';

COMMENT ON COLUMN llm_extraction.bpk_regulations.pdf_quality IS
    'born_digital = regex extraction, scanned_clean = LLM with OCR, image_only = LLM only';
