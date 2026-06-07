-- Remove confidence scoring columns from llm_extraction.bpk_regulations.

ALTER TABLE llm_extraction.bpk_regulations
    DROP COLUMN IF EXISTS confidence_score,
    DROP COLUMN IF EXISTS text_coverage;
