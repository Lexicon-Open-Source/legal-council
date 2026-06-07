-- Add person_company column to sg_mas_enforcement_actions
ALTER TABLE crawler.sg_mas_enforcement_actions
    ADD COLUMN IF NOT EXISTS person_company TEXT;
