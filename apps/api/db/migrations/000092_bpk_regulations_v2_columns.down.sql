-- Remove v2 extraction metadata columns from llm_extraction.bpk_regulations
ALTER TABLE llm_extraction.bpk_regulations
    DROP COLUMN IF EXISTS extraction_version,
    DROP COLUMN IF EXISTS detection_method,
    DROP COLUMN IF EXISTS pdf_quality;
