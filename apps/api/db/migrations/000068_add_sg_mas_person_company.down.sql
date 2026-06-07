-- Remove person_company column from sg_mas_enforcement_actions
ALTER TABLE crawler.sg_mas_enforcement_actions
    DROP COLUMN IF EXISTS person_company;
